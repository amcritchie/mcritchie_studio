require "csv"
require_relative "../../../lib/encoding_sanitizer"

module Pff
  class ImportCsv
    attr_reader :csv_path, :season_slug, :stat_type, :stats

    # Team-level stat types — no player column, keyed by team
    TEAM_LEVEL_TYPES = %w[line_pass_blocking_efficiency].freeze

    # PFF uses non-standard team abbreviations for some teams
    TEAM_ALIASES = {
      "ARZ" => "ARI",
      "BLT" => "BAL",
      "CLV" => "CLE",
      "HST" => "HOU",
      "LA"  => "LAR"
    }.freeze

    # Restrict each stat_type to athletes whose position belongs in that stat.
    # Prevents trick-play passes (a WR throwing once in passing_summary) from
    # clobbering a player's real grades. Position checked AFTER normalization.
    POSITION_FILTER = {
      "passing_summary"          => %w[QB],
      "rushing_summary"          => %w[RB FB],
      "receiving_summary"        => %w[WR TE],
      "offense_pass_blocking"    => %w[OT OG C TE],
      "offense_run_blockng"      => %w[OT OG C TE FB],
      "pass_rush_summary"        => %w[EDGE DE DT NT DL LB ILB OLB MLB],
      "run_defense_summary"      => %w[EDGE DE DT NT DL LB ILB OLB MLB S FS SS],
      "defense_coverage_summary" => %w[CB S FS SS LB ILB OLB MLB],
      "defense_summary"          => %w[EDGE DE DT NT DL LB ILB OLB MLB CB S FS SS],
      "field_goal_summary"       => %w[K],
      "return_summary"           => %w[WR RB FB CB S TE LB ILB OLB MLB]
    }.freeze

    # Maps stat_type → { csv_column → AthleteGrade column }
    GRADE_BACKFILL = {
      "passing_summary" => {
        "grades_pass" => :pass_grade,
        "grades_run" => :run_grade,
        "grades_offense" => :offense_grade
      },
      "rushing_summary" => {
        "grades_run" => :run_grade,
        "grades_offense" => :offense_grade
      },
      "receiving_summary" => {
        "grades_pass_route" => :pass_route_grade,
        "grades_offense" => :offense_grade
      },
      "offense_blocking" => {
        "grades_pass_block" => :pass_block_grade,
        "grades_run_block" => :run_block_grade
      },
      "offense_pass_blocking" => {
        "grades_pass_block" => :pass_block_grade
      },
      "offense_run_blocking" => {
        "grades_run_block" => :run_block_grade
      },
      "offense_run_blockng" => {
        "grades_run_block" => :run_block_grade
      },
      "defense_summary" => {
        "grades_defense" => :defense_grade,
        "grades_coverage_defense" => :coverage_grade,
        "grades_pass_rush_defense" => :pass_rush_grade,
        "grades_run_defense" => :rush_defense_grade
      },
      "pass_rush_summary" => {
        "grades_pass_rush_defense" => :pass_rush_grade
      },
      "run_defense_summary" => {
        "grades_run_defense" => :rush_defense_grade
      },
      "defense_coverage_summary" => {
        "grades_coverage_defense" => :coverage_grade
      },
      "field_goal_summary" => {
        "grades_fgep_kicker" => :fg_grade
      },
      "kickoff_summary" => {
        "grades_kickoff_kicker" => :kickoff_grade
      },
      "punting_summary" => {
        "grades_punter" => :punting_grade
      },
      "return_summary" => {
        "grades_return" => :return_grade
      },
      "special_teams_summary" => {
        "grades_fgep_kicker" => :fg_grade,
        "grades_kickoff_kicker" => :kickoff_grade,
        "grades_punter" => :punting_grade
      }
    }.freeze

    def initialize(csv_path:, season_slug:, stat_type: nil)
      @csv_path    = csv_path
      @season_slug = season_slug
      @stat_type   = stat_type || detect_stat_type(csv_path)
      @stats       = { created: 0, updated: 0, grades_backfilled: 0, skipped: 0 }
    end

    def call
      season = Season.find_by(slug: season_slug)
      raise "Season not found: #{season_slug}" unless season

      if team_level?
        import_team_stats(season)
      else
        import_player_stats(season)
      end

      puts "  Import complete (#{stat_type}): #{@stats.inspect}"
      @stats
    end

    private

    def team_level?
      TEAM_LEVEL_TYPES.include?(stat_type)
    end

    def detect_stat_type(path)
      basename = File.basename(path, ".csv")
      # Strip trailing " (1)", " (2)", etc.
      basename.gsub(/\s*\(\d+\)\s*$/, "").strip.downcase.gsub(/\s+/, "_")
    end

    def import_team_stats(season)
      each_csv_row do |row, data|
        team_name = row["team_name"]&.strip
        next if team_name.blank?

        team = find_team(team_name)
        unless team
          puts "  [?] Team not found: #{EncodingSanitizer.sanitize_utf8(team_name)}"
          @stats[:skipped] += 1
          next
        end

        record = PffTeamStat.find_or_initialize_by(
          team_slug: team.slug,
          season_slug: season_slug,
          stat_type: stat_type
        )
        was_new = record.new_record?
        record.data = data
        record.save!

        @stats[was_new ? :created : :updated] += 1
        puts "  [#{was_new ? '+' : '~'}] #{EncodingSanitizer.sanitize_utf8(team.short_name || team.name)} (#{stat_type})"
      end
    end

    def import_player_stats(season)
      each_csv_row do |row, data|
        player_name = row["player"]&.strip
        pff_id = row["player_id"]&.to_i
        position = row["position"]&.strip
        team_name = row["team_name"]&.strip
        games = row["player_game_count"]&.to_i

        next if player_name.blank?

        # Position filter — skip rows whose position isn't a primary fit for this stat_type
        # (e.g. a WR who threw a trick pass shows up in passing_summary; ignore those rows).
        allowed = POSITION_FILTER[stat_type]
        normalized = PositionConcern.normalize_position(position)
        if allowed && !allowed.include?(normalized)
          @stats[:skipped] += 1
          next
        end

        # Find or create athlete
        athlete = find_or_create_athlete(player_name, pff_id, position)
        unless athlete
          @stats[:skipped] += 1
          next
        end

        # Stamp pff_id if missing
        if pff_id && pff_id > 0 && athlete.pff_id != pff_id
          athlete.update_column(:pff_id, pff_id)
        end

        # Find team
        team = team_name.present? ? find_team(team_name) : nil

        # Upsert PffStat
        record = PffStat.find_or_initialize_by(
          athlete_slug: athlete.slug,
          season_slug: season_slug,
          stat_type: stat_type
        )
        was_new = record.new_record?
        record.team_slug = team&.slug
        record.pff_player_id = pff_id if pff_id && pff_id > 0
        record.games_played = games
        record.data = data
        record.save!

        @stats[was_new ? :created : :updated] += 1

        # Backfill AthleteGrade
        backfill_grade(athlete, data, position, games)

        label = EncodingSanitizer.sanitize_utf8("#{team&.short_name || '???'} #{position}: #{player_name}")
        puts "  [#{was_new ? '+' : '~'}] #{label} (#{stat_type})"
      end
    end

    def each_csv_row
      CSV.foreach(csv_path, headers: true) do |row|
        sanitized = {}
        row.each do |key, value|
          next if key.nil?
          clean_key = EncodingSanitizer.sanitize_utf8(key.strip)
          clean_val = EncodingSanitizer.sanitize_utf8(value&.strip)
          sanitized[clean_key] = coerce_value(clean_val)
        end
        yield row, sanitized
      end
    end

    def coerce_value(val)
      return nil if val.nil? || val.empty?
      # Try integer first, then float, else keep string
      if val.match?(/\A-?\d+\z/)
        val.to_i
      elsif val.match?(/\A-?\d+\.\d+\z/)
        val.to_f
      else
        val
      end
    end

    def find_or_create_athlete(player_name, pff_id, position)
      # Try pff_id lookup first (fast, reliable)
      if pff_id && pff_id > 0
        athlete = Athlete.find_by(pff_id: pff_id)
        return athlete if athlete
      end

      # Fall back to smart name-based matching
      parts = player_name.split(/\s+/, 2)
      first_name = parts[0]
      last_name  = parts[1] || ""

      person = Person.find_or_create_by_name!(first_name, last_name, athlete: true)

      normalized_pos = PositionConcern.normalize_position(position)
      Athlete.find_or_create_by!(person_slug: person.slug) do |a|
        a.sport    = "football"
        a.position = normalized_pos
      end
    end

    def backfill_grade(athlete, data, position, games)
      mapping = GRADE_BACKFILL[stat_type]
      return unless mapping

      grade = AthleteGrade.find_or_initialize_by(
        athlete_slug: athlete.slug,
        season_slug: season_slug
      )

      changed = false
      mapping.each do |csv_col, grade_col|
        value = data[csv_col]
        next unless value.is_a?(Numeric) && value > 0
        grade.send(:"#{grade_col}=", value)
        changed = true
      end

      # Set games_played from CSV
      if games && games > 0
        grade.games_played = games
        changed = true
      end

      # Set overall_grade based on side of ball
      if changed
        side = PositionConcern.side_for(position)
        if side == "defense" && data["grades_defense"].is_a?(Numeric)
          grade.overall_grade = data["grades_defense"]
        elsif side == "defense"
          # Defense sub-CSV without grades_defense (e.g. pass_rush_summary) — derive from sub-grades
          parts = [grade.coverage_grade, grade.pass_rush_grade, grade.rush_defense_grade].compact
          grade.overall_grade = (parts.sum / parts.size).round(1) if parts.any?
        elsif side == "special_teams"
          # Use the primary ST grade as overall for special teamers
          st_grade = data["grades_fgep_kicker"] || data["grades_punter"] || data["grades_return"]
          grade.overall_grade = st_grade if st_grade.is_a?(Numeric)
        elsif data["grades_offense"].is_a?(Numeric)
          grade.overall_grade = data["grades_offense"]
        elsif %w[offense_pass_blocking offense_run_blockng offense_blocking].include?(stat_type)
          # Blocking CSVs have no grades_offense — derive overall from the block grades we have
          pb, rb = grade.pass_block_grade, grade.run_block_grade
          derived = pb && rb ? (pb + rb) / 2.0 : (pb || rb)
          grade.overall_grade = derived.round(1) if derived
        end

        grade.save!
        @stats[:grades_backfilled] += 1
      end
    end

    def find_team(name)
      # Resolve PFF aliases first (ARZ→ARI, BLT→BAL, etc.)
      resolved = TEAM_ALIASES[name] || name

      team = Team.find_by(short_name: resolved)
      return team if team

      slug = resolved.parameterize
      team = Team.find_by(slug: slug)
      return team if team

      # ILIKE fallback
      Team.where("LOWER(name) = ?", resolved.downcase).first ||
        Team.where("LOWER(short_name) = ?", resolved.downcase).first
    end
  end
end
