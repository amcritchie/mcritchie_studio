# 2026 NFL Mock Draft Prospects (~50 picks)
# Person records + Athlete records + College Contract + NFL Mock Pick Contract
#
# Sources: NFL.com (Chad Reuter 7-round mock), Daniel Jeremiah top 150
# Draft scheduled April 23-25, 2026 in Pittsburgh
#
# Round 1: NFL.com mock draft team assignments
# Round 2: Top remaining prospects from DJ's big board, approximate team order

require_relative "../../app/models/concerns/position_concern"

# ── Add missing NCAA teams for 2026 prospects ────────────────────────────────
MISSING_NCAA_2026 = [
  { name: "Indiana Hoosiers",          short_name: "IND",  location: "Bloomington, IN",     emoji: "\u{1F534}",    color_primary: "#990000", color_secondary: "#FFFFFF", conference: "Big Ten" },
  { name: "Vanderbilt Commodores",     short_name: "VAN",  location: "Nashville, TN",       emoji: "\u2693",       color_primary: "#866D4B", color_secondary: "#000000", color_text_light: true, conference: "SEC" },
  { name: "San Diego State Aztecs",    short_name: "SDSU", location: "San Diego, CA",       emoji: "\u{1F3DB}\uFE0F", color_primary: "#A6192E", color_secondary: "#000000", conference: "MWC" },
  { name: "Georgia Tech Yellow Jackets", short_name: "GT", location: "Atlanta, GA",         emoji: "\u{1F41D}",    color_primary: "#B3A369", color_secondary: "#003057", color_text_light: true, conference: "ACC" },
]

MISSING_NCAA_2026.each do |data|
  team = Team.find_or_create_by!(slug: data[:name].parameterize) do |t|
    t.name = data[:name]
    t.short_name = data[:short_name]
    t.location = data[:location]
    t.emoji = data[:emoji]
    t.color_primary = data[:color_primary]
    t.color_secondary = data[:color_secondary]
    t.color_text_light = data[:color_text_light] || false
  end
  team.update!(sport: "football", league: "ncaa", conference: data[:conference])
end

# ── 2026 Mock Draft Prospects ────────────────────────────────────────────────
NFL_MOCK_2026 = [
  # ── Round 1 (Picks 1-32) — NFL.com Chad Reuter mock ───────────────────────
  { first_name: "Fernando",   last_name: "Mendoza",         position: "QB",    draft_round: 1, draft_pick: 1,   college_slug: "indiana-hoosiers",            nfl_team_slug: "las-vegas-raiders" },
  { first_name: "Arvell",     last_name: "Reese",           position: "EDGE",  draft_round: 1, draft_pick: 2,   college_slug: "ohio-state-buckeyes",         nfl_team_slug: "new-york-jets" },
  { first_name: "David",      last_name: "Bailey",          position: "EDGE",  draft_round: 1, draft_pick: 3,   college_slug: "texas-tech-red-raiders",      nfl_team_slug: "arizona-cardinals" },
  { first_name: "Jeremiyah",  last_name: "Love",            position: "RB",    draft_round: 1, draft_pick: 4,   college_slug: "notre-dame-fighting-irish",   nfl_team_slug: "tennessee-titans" },
  { first_name: "Francis",    last_name: "Mauigoa",         position: "OT",    draft_round: 1, draft_pick: 5,   college_slug: "miami-hurricanes",            nfl_team_slug: "new-york-giants" },
  { first_name: "Monroe",     last_name: "Freeling",        position: "OT",    draft_round: 1, draft_pick: 6,   college_slug: "georgia-bulldogs",            nfl_team_slug: "cleveland-browns" },
  { first_name: "Mansoor",    last_name: "Delane",          position: "CB",    draft_round: 1, draft_pick: 7,   college_slug: "lsu-tigers",                  nfl_team_slug: "washington-commanders" },
  { first_name: "Rueben",     last_name: "Bain Jr.",        position: "EDGE",  draft_round: 1, draft_pick: 8,   college_slug: "miami-hurricanes",            nfl_team_slug: "new-orleans-saints" },
  { first_name: "Kadyn",      last_name: "Proctor",         position: "OT",    draft_round: 1, draft_pick: 9,   college_slug: "alabama-crimson-tide",        nfl_team_slug: "kansas-city-chiefs" },
  { first_name: "Caleb",      last_name: "Downs",           position: "S",     draft_round: 1, draft_pick: 10,  college_slug: "ohio-state-buckeyes",         nfl_team_slug: "new-york-giants" },
  { first_name: "Carnell",    last_name: "Tate",            position: "WR",    draft_round: 1, draft_pick: 11,  college_slug: "ohio-state-buckeyes",         nfl_team_slug: "miami-dolphins" },
  { first_name: "Sonny",      last_name: "Styles",          position: "LB",    draft_round: 1, draft_pick: 12,  college_slug: "ohio-state-buckeyes",         nfl_team_slug: "dallas-cowboys" },
  { first_name: "Spencer",    last_name: "Fano",            position: "OT",    draft_round: 1, draft_pick: 13,  college_slug: "utah-utes",                   nfl_team_slug: "los-angeles-rams" },
  { first_name: "Caleb",      last_name: "Banks",           position: "DT",    draft_round: 1, draft_pick: 14,  college_slug: "florida-gators",              nfl_team_slug: "baltimore-ravens" },
  { first_name: "Akheem",     last_name: "Mesidor",         position: "EDGE",  draft_round: 1, draft_pick: 15,  college_slug: "miami-hurricanes",            nfl_team_slug: "tampa-bay-buccaneers" },
  { first_name: "Ty",         last_name: "Simpson",         position: "QB",    draft_round: 1, draft_pick: 16,  college_slug: "alabama-crimson-tide",        nfl_team_slug: "new-york-jets" },
  { first_name: "Makai",      last_name: "Lemon",           position: "WR",    draft_round: 1, draft_pick: 17,  college_slug: "usc-trojans",                 nfl_team_slug: "detroit-lions" },
  { first_name: "Colton",     last_name: "Hood",            position: "CB",    draft_round: 1, draft_pick: 18,  college_slug: "tennessee-volunteers",        nfl_team_slug: "minnesota-vikings" },
  { first_name: "Kenyon",     last_name: "Sadiq",           position: "TE",    draft_round: 1, draft_pick: 19,  college_slug: "oregon-ducks",                nfl_team_slug: "carolina-panthers" },
  { first_name: "Jordyn",     last_name: "Tyson",           position: "WR",    draft_round: 1, draft_pick: 20,  college_slug: "arizona-state-sun-devils",    nfl_team_slug: "cleveland-browns" },
  { first_name: "Olaivavega", last_name: "Ioane",           position: "OG",    draft_round: 1, draft_pick: 21,  college_slug: "penn-state-nittany-lions",    nfl_team_slug: "pittsburgh-steelers" },
  { first_name: "Jermod",     last_name: "McCoy",           position: "CB",    draft_round: 1, draft_pick: 22,  college_slug: "tennessee-volunteers",        nfl_team_slug: "los-angeles-chargers" },
  { first_name: "Omar",       last_name: "Cooper Jr.",      position: "WR",    draft_round: 1, draft_pick: 23,  college_slug: "indiana-hoosiers",            nfl_team_slug: "philadelphia-eagles" },
  { first_name: "Chris",      last_name: "Johnson",         position: "CB",    draft_round: 1, draft_pick: 24,  college_slug: "san-diego-state-aztecs",      nfl_team_slug: "dallas-cowboys" },
  { first_name: "Keldric",    last_name: "Faulk",           position: "EDGE",  draft_round: 1, draft_pick: 25,  college_slug: "auburn-tigers",               nfl_team_slug: "chicago-bears" },
  { first_name: "KC",         last_name: "Concepcion",      position: "WR",    draft_round: 1, draft_pick: 26,  college_slug: "texas-a-m-aggies",            nfl_team_slug: "buffalo-bills" },
  { first_name: "Caleb",      last_name: "Lomu",            position: "OT",    draft_round: 1, draft_pick: 27,  college_slug: "utah-utes",                   nfl_team_slug: "san-francisco-49ers" },
  { first_name: "Blake",      last_name: "Miller",          position: "OT",    draft_round: 1, draft_pick: 28,  college_slug: "clemson-tigers",              nfl_team_slug: "houston-texans" },
  { first_name: "Kayden",     last_name: "McDonald",        position: "DT",    draft_round: 1, draft_pick: 29,  college_slug: "ohio-state-buckeyes",         nfl_team_slug: "kansas-city-chiefs" },
  { first_name: "Dillon",     last_name: "Thieneman",       position: "S",     draft_round: 1, draft_pick: 30,  college_slug: "oregon-ducks",                nfl_team_slug: "miami-dolphins" },
  { first_name: "Eli",        last_name: "Stowers",         position: "TE",    draft_round: 1, draft_pick: 31,  college_slug: "vanderbilt-commodores",       nfl_team_slug: "new-england-patriots" },
  { first_name: "R Mason",    last_name: "Thomas",          position: "EDGE",  draft_round: 1, draft_pick: 32,  college_slug: "oklahoma-sooners",            nfl_team_slug: "seattle-seahawks" },

  # ── Round 2 (Picks 33-50) — DJ big board remainders, approximate teams ─────
  { first_name: "Emmanuel",   last_name: "McNeil-Warren",   position: "S",     draft_round: 2, draft_pick: 33,  college_slug: "toledo-rockets",              nfl_team_slug: "las-vegas-raiders" },
  { first_name: "Cashius",    last_name: "Howell",          position: "EDGE",  draft_round: 2, draft_pick: 34,  college_slug: "texas-a-m-aggies",            nfl_team_slug: "arizona-cardinals" },
  { first_name: "Max",        last_name: "Iheanachor",      position: "OT",    draft_round: 2, draft_pick: 35,  college_slug: "arizona-state-sun-devils",    nfl_team_slug: "tennessee-titans" },
  { first_name: "CJ",         last_name: "Allen",           position: "LB",    draft_round: 2, draft_pick: 36,  college_slug: "georgia-bulldogs",            nfl_team_slug: "new-york-giants" },
  { first_name: "Jadarian",   last_name: "Price",           position: "RB",    draft_round: 2, draft_pick: 37,  college_slug: "notre-dame-fighting-irish",   nfl_team_slug: "cleveland-browns" },
  { first_name: "Anthony",    last_name: "Hill Jr.",        position: "LB",    draft_round: 2, draft_pick: 38,  college_slug: "texas-longhorns",             nfl_team_slug: "washington-commanders" },
  { first_name: "Avieon",     last_name: "Terrell",         position: "CB",    draft_round: 2, draft_pick: 39,  college_slug: "clemson-tigers",              nfl_team_slug: "new-orleans-saints" },
  { first_name: "Peter",      last_name: "Woods",           position: "DT",    draft_round: 2, draft_pick: 40,  college_slug: "clemson-tigers",              nfl_team_slug: "miami-dolphins" },
  { first_name: "Malachi",    last_name: "Lawrence",        position: "EDGE",  draft_round: 2, draft_pick: 41,  college_slug: "ucf-knights",                 nfl_team_slug: "dallas-cowboys" },
  { first_name: "Lee",        last_name: "Hunter",          position: "DT",    draft_round: 2, draft_pick: 42,  college_slug: "texas-tech-red-raiders",      nfl_team_slug: "baltimore-ravens" },
  { first_name: "Jacob",      last_name: "Rodriguez",       position: "LB",    draft_round: 2, draft_pick: 43,  college_slug: "texas-tech-red-raiders",      nfl_team_slug: "tampa-bay-buccaneers" },
  { first_name: "Brandon",    last_name: "Cisse",           position: "CB",    draft_round: 2, draft_pick: 44,  college_slug: "south-carolina-gamecocks",    nfl_team_slug: "detroit-lions" },
  { first_name: "Zion",       last_name: "Young",           position: "EDGE",  draft_round: 2, draft_pick: 45,  college_slug: "missouri-tigers",             nfl_team_slug: "minnesota-vikings" },
  { first_name: "Christen",   last_name: "Miller",          position: "DT",    draft_round: 2, draft_pick: 46,  college_slug: "georgia-bulldogs",            nfl_team_slug: "pittsburgh-steelers" },
  { first_name: "Keylan",     last_name: "Rutledge",        position: "OG",    draft_round: 2, draft_pick: 47,  college_slug: "georgia-tech-yellow-jackets", nfl_team_slug: "los-angeles-chargers" },
  { first_name: "Treydan",    last_name: "Stukes",          position: "S",     draft_round: 2, draft_pick: 48,  college_slug: "arizona-wildcats",            nfl_team_slug: "philadelphia-eagles" },
  { first_name: "Germie",     last_name: "Bernard",         position: "WR",    draft_round: 2, draft_pick: 49,  college_slug: "alabama-crimson-tide",        nfl_team_slug: "chicago-bears" },
  { first_name: "D'Angelo",   last_name: "Ponds",           position: "CB",    draft_round: 2, draft_pick: 50,  college_slug: "indiana-hoosiers",            nfl_team_slug: "buffalo-bills" },
]

nfl_season = Season.find_by(year: 2025, league: "nfl")
offseason  = nfl_season&.slates&.find_by(sequence: 0)

NFL_MOCK_2026.each do |data|
  person = Person.find_or_create_by_name!(data[:first_name], data[:last_name], athlete: true)

  athlete = Athlete.find_or_create_by!(person_slug: person.slug) do |a|
    a.sport = "football"
    a.position = data[:position]
    a.draft_year = 2026
    a.draft_round = data[:draft_round]
    a.draft_pick = data[:draft_pick]
  end
  # Update draft info for 2026 (e.g. David Bailey moves from 2025 hypothetical to 2026 actual)
  if athlete.draft_year != 2026
    athlete.update!(draft_year: 2026, draft_round: data[:draft_round], draft_pick: data[:draft_pick])
  end

  # Create contract to college team
  if data[:college_slug].present?
    Contract.find_or_create_by!(person_slug: person.slug, team_slug: data[:college_slug]) do |c|
      c.expires_at = Date.new(2026, 4, 23)
      c.position = data[:position]
      c.contract_type = "college"
    end
  end

  # Create mock_pick contract to projected NFL team
  if data[:nfl_team_slug].present?
    nfl_team = Team.find_by(slug: data[:nfl_team_slug])
    if nfl_team
      contract = Contract.find_or_create_by!(person_slug: person.slug, team_slug: nfl_team.slug) do |c|
        c.contract_type = "mock_pick"
        c.position      = data[:position]
      end
      contract.update!(contract_type: "mock_pick") unless contract.contract_type == "mock_pick"

      puts "Mock: #{person.full_name} (Rd #{data[:draft_round]}, Pick #{data[:draft_pick]}) -> #{nfl_team.name}"
    end
  end
end
