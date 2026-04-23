require_relative "../../app/models/concerns/position_concern"

# ── Find 2025 NFL Season + Week 1 Slate ─────────────────────────────────────
nfl_season = Season.find_by(year: 2025, league: "nfl")
week1      = nfl_season&.slates&.find_by(sequence: 1)
offseason  = nfl_season&.slates&.find_by(sequence: 0)

if nfl_season && week1
  # ── 16 Fictitious 2026 Week 1 Games ───────────────────────────────────────
  week1_games = [
    # Thursday Night
    { away: "kansas-city-chiefs",      home: "baltimore-ravens",        day: :thursday,    time: "20:20" },

    # Sunday 1:00 PM ET
    { away: "buffalo-bills",           home: "miami-dolphins",          day: :sunday_early, time: "13:00" },
    { away: "cleveland-browns",        home: "cincinnati-bengals",      day: :sunday_early, time: "13:00" },
    { away: "houston-texans",          home: "indianapolis-colts",      day: :sunday_early, time: "13:00" },
    { away: "chicago-bears",           home: "green-bay-packers",       day: :sunday_early, time: "13:00" },
    { away: "dallas-cowboys",          home: "philadelphia-eagles",     day: :sunday_early, time: "13:00" },
    { away: "tampa-bay-buccaneers",    home: "new-orleans-saints",      day: :sunday_early, time: "13:00" },
    { away: "denver-broncos",          home: "los-angeles-chargers",    day: :sunday_early, time: "13:00" },

    # Sunday 4:05/4:25 PM ET
    { away: "new-york-giants",         home: "washington-commanders",   day: :sunday_late,  time: "16:25" },
    { away: "jacksonville-jaguars",    home: "tennessee-titans",        day: :sunday_late,  time: "16:05" },
    { away: "minnesota-vikings",       home: "detroit-lions",           day: :sunday_late,  time: "16:25" },
    { away: "arizona-cardinals",       home: "los-angeles-rams",        day: :sunday_late,  time: "16:25" },

    # Sunday Night
    { away: "pittsburgh-steelers",     home: "new-england-patriots",    day: :sunday_night, time: "20:20" },

    # Monday Night
    { away: "san-francisco-49ers",     home: "seattle-seahawks",        day: :monday,       time: "20:15" },
    { away: "atlanta-falcons",         home: "carolina-panthers",       day: :monday,       time: "20:15" },
    { away: "las-vegas-raiders",       home: "new-york-jets",           day: :monday,       time: "20:15" },
  ]

  # Week 1 2025: Sep 4 (Thu) → Sep 8 (Mon)
  day_offsets = {
    thursday:     0,
    sunday_early: 3,
    sunday_late:  3,
    sunday_night: 3,
    monday:       4,
  }

  venues = {
    "baltimore-ravens"        => "M&T Bank Stadium",
    "miami-dolphins"          => "Hard Rock Stadium",
    "cincinnati-bengals"      => "Paycor Stadium",
    "indianapolis-colts"      => "Lucas Oil Stadium",
    "green-bay-packers"       => "Lambeau Field",
    "philadelphia-eagles"     => "Lincoln Financial Field",
    "new-orleans-saints"      => "Caesars Superdome",
    "los-angeles-chargers"    => "SoFi Stadium",
    "washington-commanders"   => "Northwest Stadium",
    "tennessee-titans"        => "Nissan Stadium",
    "detroit-lions"           => "Ford Field",
    "los-angeles-rams"        => "SoFi Stadium",
    "new-england-patriots"    => "Gillette Stadium",
    "seattle-seahawks"        => "Lumen Field",
    "carolina-panthers"       => "Bank of America Stadium",
    "new-york-jets"           => "MetLife Stadium",
  }

  base_date = Date.new(2025, 9, 4) # Thursday Week 1

  week1_games.each do |data|
    day_offset = day_offsets[data[:day]]
    eastern = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
    kickoff = eastern.parse("#{base_date + day_offset} #{data[:time]}")

    slug = "#{Team.find_by(slug: data[:away])&.short_name&.downcase}-at-#{Team.find_by(slug: data[:home])&.short_name&.downcase}"

    Game.find_or_create_by!(slug: slug) do |g|
      g.slate_slug     = week1.slug
      g.away_team_slug = data[:away]
      g.home_team_slug = data[:home]
      g.kickoff_at     = kickoff
      g.venue          = venues[data[:home]]
    end

    puts "Game: #{slug} (#{data[:day]})"
  end

  puts "Games: #{Game.count}"

  # ── Copy Offseason Rosters → Week 1 Rosters ───────────────────────────────
  if offseason
    Team.nfl.find_each do |team|
      offseason_roster = Roster.find_by(team_slug: team.slug, slate_slug: offseason.slug)
      next unless offseason_roster

      week1_roster = Roster.find_or_create_by!(team_slug: team.slug, slate_slug: week1.slug)

      offseason_roster.roster_spots.find_each do |os_spot|
        RosterSpot.find_or_create_by!(roster: week1_roster, position: os_spot.position, depth: os_spot.depth) do |rs|
          rs.person_slug = os_spot.person_slug
          rs.side        = os_spot.side
        end
      end

      puts "Roster copied: #{team.short_name} offseason -> Week 1"
    end
  end

  puts "Week 1 Rosters: #{Roster.where(slate_slug: week1.slug).count}"
  puts "Week 1 RosterSpots: #{RosterSpot.joins(:roster).where(rosters: { slate_slug: week1.slug }).count}"
else
  puts "Skipping games seed — missing NFL season or Week 1 slate"
end
