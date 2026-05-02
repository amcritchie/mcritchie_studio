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
  # Athletes whose PFF input is nil or 0 get nil rank + nil grade for that
  # axis (no signal to rank against).
  #
  # Usage:
  #   Athletes::ComputeProprietaryGrades.new(season_slug: "2025-nfl").call
  class ComputeProprietaryGrades
    POSITION_BUCKETS = {
      # QBs are scored on passing for both axes — there's no separate "run"
      # grade for QBs at this level, so we reuse pass_grade_pff for the run
      # rank as well. Means QB pass and run rankings are identical.
      qb:    { positions: %w[QB],
               pass_input: :pass_grade_pff,
               run_input:  :pass_grade_pff },
      rb:    { positions: %w[RB FB HB],
               pass_input: :pass_block_grade_pff,
               run_input:  :run_grade_pff },
      wr_te: { positions: %w[WR TE],
               pass_input: :pass_route_grade_pff,
               run_input:  :run_block_grade_pff },
      ol:    { positions: %w[OT OG C T G LT LG RG RT],
               pass_input: :pass_block_grade_pff,
               run_input:  :run_block_grade_pff },
      dl:    { positions: %w[EDGE DE DT NT DL DI],
               pass_input: :pass_rush_grade_pff,
               run_input:  :rush_defense_grade_pff },
      lb:    { positions: %w[LB ILB OLB MLB],
               pass_input: :coverage_grade_pff,
               run_input:  :rush_defense_grade_pff },
      db:    { positions: %w[CB S FS SS],
               pass_input: :coverage_grade_pff,
               run_input:  :rush_defense_grade_pff }
    }.freeze

    attr_reader :season_slug, :stats

    def initialize(season_slug:)
      @season_slug = season_slug
      @stats = Hash.new(0)
    end

    def call
      POSITION_BUCKETS.each do |bucket, config|
        grades = grades_for_positions(config[:positions])
        rank_axis(grades, config[:pass_input], :position_pass_rank, :position_pass_grade)
        rank_axis(grades, config[:run_input],  :position_run_rank,  :position_run_grade)
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

    def rank_axis(grades, input_col, rank_col, grade_col)
      with_input, without_input = grades.partition { |g| usable?(g.public_send(input_col)) }

      sorted = with_input.sort_by { |g| -g.public_send(input_col) }
      n = sorted.size
      sorted.each_with_index do |g, idx|
        rank = idx + 1
        grade = n > 1 ? ((n - rank).to_f / (n - 1) * 10).round.clamp(0, 10) : 10
        g.update_columns(rank_col => rank, grade_col => grade)
      end

      without_input.each { |g| g.update_columns(rank_col => nil, grade_col => nil) }
    end

    def usable?(value)
      value.is_a?(Numeric) && value > 0
    end
  end
end
