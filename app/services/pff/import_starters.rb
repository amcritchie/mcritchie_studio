require "csv"
require_relative "../../../lib/encoding_sanitizer"

module Pff
  class ImportStarters
    attr_reader :csv_path, :season_slug, :stats

    def initialize(csv_path:, season_slug:)
      @csv_path    = csv_path
      @season_slug = season_slug
      @stats       = { people: 0, athletes: 0, contracts: 0, grades: 0, roster_spots: 0, skipped: 0 }
    end

    def call
      season = Season.find_by(slug: season_slug)
      raise "Season not found: #{season_slug}" unless season

      offseason = season.slates.find_by(sequence: 0)
      raise "Offseason slate not found for #{season_slug}" unless offseason

      depth_tracker = Hash.new(0)

      CSV.foreach(csv_path, headers: true) do |row|
        team_name = EncodingSanitizer.sanitize_utf8(row["Team"]&.strip)
        unit      = EncodingSanitizer.sanitize_utf8(row["Unit"]&.strip)
        position  = EncodingSanitizer.sanitize_utf8(row["Position"]&.strip)
        player    = EncodingSanitizer.sanitize_utf8(row["Player"]&.strip)
        grade_str = EncodingSanitizer.sanitize_utf8(row["Grade"]&.strip)

        next if team_name.blank? || player.blank?

        team = find_team(team_name)
        unless team
          puts "  [?] Team not found: #{EncodingSanitizer.sanitize_utf8(team_name)}"
          @stats[:skipped] += 1
          next
        end

        # Parse player name
        parts = player.split(/\s+/, 2)
        first_name = parts[0]
        last_name  = parts[1] || ""

        # Find or create Person (smart name matching)
        person = Person.find_or_create_by_name!(first_name, last_name, athlete: true)
        @stats[:people] += 1

        # Find or create Athlete
        normalized_pos = PositionConcern.normalize_position(position, source: :pff)
        athlete = Athlete.find_or_create_by!(person_slug: person.slug) do |a|
          a.sport    = "football"
          a.position = normalized_pos
        end
        @stats[:athletes] += 1

        # Find or create Contract (active)
        Contract.find_or_create_by!(person_slug: person.slug, team_slug: team.slug) do |c|
          c.contract_type = "active"
          c.position      = normalized_pos
        end
        @stats[:contracts] += 1

        # Parse grade (strip asterisks like "77.9**")
        grade_value = grade_str&.gsub(/[^0-9.]/, "")&.to_f if grade_str.present?

        # Find or create AthleteGrade
        if grade_value && grade_value > 0
          AthleteGrade.find_or_create_by!(athlete_slug: athlete.slug, season_slug: season_slug) do |g|
            g.overall_grade_pff = grade_value
          end
          @stats[:grades] += 1
        end

        # Find or create Roster + RosterSpot
        roster = Roster.find_or_create_by!(team_slug: team.slug, slate_slug: offseason.slug)

        side = PositionConcern.side_for(normalized_pos)
        roster_key = "#{team.slug}-#{normalized_pos}"
        depth_tracker[roster_key] = depth_tracker[roster_key] + 1
        depth = depth_tracker[roster_key]

        RosterSpot.find_or_create_by!(roster: roster, position: normalized_pos, depth: depth) do |rs|
          rs.person_slug = person.slug
          rs.side        = side
        end
        @stats[:roster_spots] += 1

        puts "  [+] #{EncodingSanitizer.sanitize_utf8(team.short_name || team.name)} #{normalized_pos}#{depth > 1 ? " (depth #{depth})" : ""}: #{EncodingSanitizer.sanitize_utf8(person.full_name)} — #{grade_value || 'N/A'}"
      end

      puts "\nImport complete: #{@stats.inspect}"
      @stats
    end

    private

    def find_team(name)
      slug = name.parameterize
      team = Team.find_by(slug: slug)
      return team if team

      # Try ILIKE fallback on name
      Team.where("LOWER(name) = ?", name.downcase).first ||
        Team.where("LOWER(name) LIKE ?", "%#{name.downcase}%").first
    end
  end
end
