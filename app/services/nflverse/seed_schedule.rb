require "csv"
require "open-uri"

module Nflverse
  # Seeds NFL Season + Slates + Games for a given year from nflverse's
  # combined schedule CSV (preseason + regular season + playoffs).
  #
  # Usage:
  #   Nflverse::SeedSchedule.new(year: 2026).call
  #   #=> { season: "2026-nfl", slates: 23, games: 285, skipped: 0, ... }
  #
  # Idempotent — uses find_or_create_by! on Season, Slate, and Game.
  #
  # Data source: nflverse-data combined games.csv (filterable by season).
  # game_type values handled: PRE, REG, WC, DIV, CON, SB.
  # Team abbrev mapping handles the nflverse → our `Team.short_name` quirk
  # where LA Rams come through as "LA" not "LAR".
  class SeedSchedule
    SOURCE_URL = "https://raw.githubusercontent.com/nflverse/nfldata/master/data/games.csv".freeze

    # nflverse uses 2-letter "LA" for Rams; our Team.short_name uses "LAR".
    TEAM_ABBREV_OVERRIDES = { "LA" => "LAR" }.freeze

    GAME_TYPES = {
      "PRE" => { slate_type: "preseason",      seq: ->(week) { -week }, label: ->(week) { "Preseason Week #{week}" }, slug: ->(year, week) { "#{year}-nfl-preseason-week-#{week}" } },
      "REG" => { slate_type: "regular_season", seq: ->(week) { week },  label: ->(week) { "Week #{week}" },           slug: ->(year, week) { "#{year}-nfl-week-#{week}" } },
      "WC"  => { slate_type: "playoffs",       seq: ->(_)    { 19 },    label: ->(_)    { "Wild Card" },              slug: ->(year, _) { "#{year}-nfl-wild-card" } },
      "DIV" => { slate_type: "playoffs",       seq: ->(_)    { 20 },    label: ->(_)    { "Divisional" },             slug: ->(year, _) { "#{year}-nfl-divisional" } },
      "CON" => { slate_type: "playoffs",       seq: ->(_)    { 21 },    label: ->(_)    { "Conference" },             slug: ->(year, _) { "#{year}-nfl-conference" } },
      "SB"  => { slate_type: "playoffs",       seq: ->(_)    { 22 },    label: ->(_)    { "Super Bowl" },             slug: ->(year, _) { "#{year}-nfl-super-bowl" } }
    }.freeze

    SLUG_PREFIX = { "PRE" => "pre", "REG" => "w", "WC" => "wc", "DIV" => "div", "CON" => "cc", "SB" => "sb" }.freeze

    def initialize(year:, verbose: true)
      @year = year.to_i
      @verbose = verbose
    end

    def call
      csv_text = fetch_csv
      rows = CSV.parse(csv_text, headers: true).select { |r| r["season"].to_i == @year }
      raise "No games found in source CSV for season #{@year}" if rows.empty?

      season = ensure_season
      stats = { season: season.slug, slates: 0, games: 0, skipped: 0, slate_counts: Hash.new(0) }

      slate_cache = {}
      rows.each do |row|
        gtype = row["game_type"]
        week  = row["week"].to_i
        next stats[:skipped] += 1 unless GAME_TYPES.key?(gtype)

        slate = slate_cache[[gtype, week]] ||= ensure_slate(season, gtype, week)
        next stats[:skipped] += 1 unless slate

        away_team = team_for(row["away_team"])
        home_team = team_for(row["home_team"])
        unless away_team && home_team
          vputs "  [!] skipping #{row["game_id"]} (unknown team: #{row["away_team"]}/#{row["home_team"]})"
          stats[:skipped] += 1
          next
        end

        slug = build_game_slug(gtype: gtype, week: week, away: away_team.short_name, home: home_team.short_name)
        kickoff = parse_kickoff(row["gameday"], row["gametime"])

        game = Game.find_or_create_by!(slug: slug) do |g|
          g.slate_slug      = slate.slug
          g.away_team_slug  = away_team.slug
          g.home_team_slug  = home_team.slug
          g.kickoff_at      = kickoff
          g.venue           = row["stadium"]
          g.location        = row["location"]  # "Home" or "Neutral"
          g.status          = row["home_score"].present? ? "completed" : "scheduled"
        end
        # Backfill location on existing rows (added after initial seed)
        game.update_columns(location: row["location"]) if game.location.blank? && row["location"].present?
        stats[:games] += 1
        stats[:slate_counts][slate.slate_type] += 1
      end

      # Backfill Slate.starts_at + ends_at from the slate's games' kickoffs.
      # Cheap, helpful for "current week" / "next upcoming week" UI logic.
      slate_cache.each_value do |slate|
        kickoffs = Game.where(slate_slug: slate.slug).where.not(kickoff_at: nil).pluck(:kickoff_at)
        next if kickoffs.empty?
        slate.update_columns(
          starts_at: kickoffs.min.to_date,
          ends_at:   kickoffs.max.to_date
        )
      end

      stats[:slates] = slate_cache.size
      stats
    end

    private

    def fetch_csv
      vputs "Fetching #{SOURCE_URL}"
      URI.open(SOURCE_URL, read_timeout: 60).read.force_encoding("UTF-8")
    end

    def ensure_season
      Season.find_or_create_by!(year: @year, league: "nfl") do |s|
        s.sport  = "football"
        s.name   = "#{@year} NFL Season"
        s.active = false  # don't auto-activate; existing active season stays active
      end
    end

    def ensure_slate(season, game_type, week)
      mapping = GAME_TYPES[game_type]
      slug    = mapping[:slug].call(@year, week)

      Slate.find_or_create_by!(slug: slug) do |s|
        s.season_slug = season.slug
        s.sequence    = mapping[:seq].call(week)
        s.label       = mapping[:label].call(week)
        s.slate_type  = mapping[:slate_type]
      end
    end

    def team_for(abbrev)
      @teams ||= Team.where(league: "nfl").index_by(&:short_name)
      mapped = TEAM_ABBREV_OVERRIDES[abbrev] || abbrev
      @teams[mapped]
    end

    def build_game_slug(gtype:, week:, away:, home:)
      prefix = SLUG_PREFIX[gtype]
      week_part = (gtype == "REG" || gtype == "PRE") ? "#{prefix}#{week}" : prefix
      "#{@year}-#{week_part}-#{away.downcase}-at-#{home.downcase}"
    end

    def parse_kickoff(gameday, gametime)
      return nil if gameday.blank?
      tz = ActiveSupport::TimeZone["America/New_York"]
      time = gametime.presence || "13:00"
      tz.parse("#{gameday} #{time}")
    rescue ArgumentError
      nil
    end

    def vputs(msg)
      puts msg if @verbose
    end
  end
end
