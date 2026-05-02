module Athletes
  # League-wide, per-position-bucket pass/run rank + 0-10 grade derived from
  # PFF inputs. Each AthleteGrade gets two rank/grade pairs:
  #   - position_pass_rank / position_pass_grade
  #   - position_run_rank  / position_run_grade
  #
  # Rank is 1..N within the bucket (1 = best). Grade is the linear percentile
  # mapping 0..10: best rank = 10, worst = 0. Letter conversion (A/B/C/D)
  # happens at the view layer via LetterGradeHelper.
  #
  # Input cascade per athlete:
  #   1. Bucket's position-specific input (e.g. coverage_grade_pff for LB pass)
  #   2. Side-of-ball overall (offense_grade_pff or defense_grade_pff)
  #   3. No input → bottom of the list, grade 0 (renders as D)
  #
  # Usage:
  #   Athletes::ComputeProprietaryGrades.new(season_slug: "2025-nfl").call
  class ComputeProprietaryGrades
    # QBs are scored on passing for both axes; no separate "run" grade.
    # RB pass uses offense_grade_pff directly — pass_block_grade_pff is sparse
    # for non-3rd-down backs and offense gives a more representative signal.
    POSITION_BUCKETS = {
      qb:    { positions: %w[QB], side: :offense,
               pass_input: :pass_grade_pff,
               run_input:  :pass_grade_pff },
      rb:    { positions: %w[RB FB HB], side: :offense,
               pass_input: :offense_grade_pff,
               run_input:  :run_grade_pff },
      wr_te: { positions: %w[WR TE], side: :offense,
               pass_input: :pass_route_grade_pff,
               run_input:  :run_block_grade_pff },
      ol:    { positions: %w[OT OG C T G LT LG RG RT], side: :offense,
               pass_input: :pass_block_grade_pff,
               run_input:  :run_block_grade_pff },
      dl:    { positions: %w[EDGE DE DT NT DL DI], side: :defense,
               pass_input: :pass_rush_grade_pff,
               run_input:  :rush_defense_grade_pff },
      lb:    { positions: %w[LB ILB OLB MLB], side: :defense,
               pass_input: :coverage_grade_pff,
               run_input:  :rush_defense_grade_pff },
      db:    { positions: %w[CB S FS SS], side: :defense,
               pass_input: :coverage_grade_pff,
               run_input:  :rush_defense_grade_pff }
    }.freeze

    SIDE_OVERALL = {
      offense: :offense_grade_pff,
      defense: :defense_grade_pff
    }.freeze

    attr_reader :season_slug, :stats

    def initialize(season_slug:)
      @season_slug = season_slug
      @stats = Hash.new(0)
    end

    def call
      POSITION_BUCKETS.each do |bucket, config|
        grades   = grades_for_positions(config[:positions])
        fallback = SIDE_OVERALL.fetch(config[:side])
        rank_axis(grades, config[:pass_input], fallback, :position_pass_rank, :position_pass_grade)
        rank_axis(grades, config[:run_input],  fallback, :position_run_rank,  :position_run_grade)
        @stats[bucket] = grades.size
      end
      puts "proprietary grades: #{@stats.inspect}"
      @stats
    end

    private

    def grades_for_positions(positions)
      AthleteGrade
        .joins("INNER JOIN athletes ON athletes.slug = athlete_grades.athlete_slug")
        .where(season_slug: season_slug, athletes: { position: positions })
        .to_a
    end

    # Two-tier cascade: athletes with the primary input rank first (sorted
    # high→low), athletes with only the fallback rank next (sorted high→low),
    # athletes with neither go to the bottom with grade 0.
    def rank_axis(grades, primary_col, fallback_col, rank_col, grade_col)
      primary, rest      = grades.partition { |g| usable?(g.public_send(primary_col)) }
      fallback, no_input = rest.partition { |g| usable?(g.public_send(fallback_col)) }

      ranked = primary.sort_by  { |g| -g.public_send(primary_col) } +
               fallback.sort_by { |g| -g.public_send(fallback_col) }

      n = ranked.size
      ranked.each_with_index do |g, idx|
        rank = idx + 1
        grade = n > 1 ? ((n - rank).to_f / (n - 1) * 10).round.clamp(0, 10) : 10
        g.update_columns(rank_col => rank, grade_col => grade)
      end

      no_input.each_with_index do |g, idx|
        g.update_columns(rank_col => n + idx + 1, grade_col => 0)
      end
    end

    def usable?(value)
      value.is_a?(Numeric) && value > 0
    end
  end
end
