# 2025 NFL Draft Prospects (102 picks + 1 hypothetical)
# Person records + Athlete records + College Contract + NFL Draft Contract
#
# Sources: ESPN, NFL.com, Tankathon — actual 2025 NFL Draft results
# Draft held April 24-26, 2025 at Lambeau Field, Green Bay, Wisconsin

require_relative "../../app/models/concerns/position_concern"

NFL_PROSPECTS = [
  # ── Round 1 (Picks 1-32) ──────────────────────────────────────────────────
  { first_name: "Cameron",    last_name: "Ward",            position: "QB",    draft_round: 1, draft_pick: 1,   college_slug: "miami-hurricanes",            nfl_team_slug: "tennessee-titans" },
  { first_name: "Travis",     last_name: "Hunter",          position: "CB/WR", draft_round: 1, draft_pick: 2,   college_slug: "colorado-buffaloes",          nfl_team_slug: "jacksonville-jaguars" },
  { first_name: "Abdul",      last_name: "Carter",          position: "EDGE",  draft_round: 1, draft_pick: 3,   college_slug: "penn-state-nittany-lions",    nfl_team_slug: "new-york-giants" },
  { first_name: "Will",       last_name: "Campbell",        position: "OT",    draft_round: 1, draft_pick: 4,   college_slug: "lsu-tigers",                  nfl_team_slug: "new-england-patriots" },
  { first_name: "Mason",      last_name: "Graham",          position: "DT",    draft_round: 1, draft_pick: 5,   college_slug: "michigan-wolverines",         nfl_team_slug: "cleveland-browns" },
  { first_name: "Ashton",     last_name: "Jeanty",          position: "RB",    draft_round: 1, draft_pick: 6,   college_slug: "boise-state-broncos",         nfl_team_slug: "las-vegas-raiders" },
  { first_name: "Armand",     last_name: "Membou",          position: "OT",    draft_round: 1, draft_pick: 7,   college_slug: "missouri-tigers",             nfl_team_slug: "new-york-jets" },
  { first_name: "Tetairoa",   last_name: "McMillan",        position: "WR",    draft_round: 1, draft_pick: 8,   college_slug: "arizona-wildcats",            nfl_team_slug: "carolina-panthers" },
  { first_name: "Kelvin",     last_name: "Banks Jr.",       position: "OT",    draft_round: 1, draft_pick: 9,   college_slug: "texas-longhorns",             nfl_team_slug: "new-orleans-saints" },
  { first_name: "Colston",    last_name: "Loveland",        position: "TE",    draft_round: 1, draft_pick: 10,  college_slug: "michigan-wolverines",         nfl_team_slug: "chicago-bears" },
  { first_name: "Mykel",      last_name: "Williams",        position: "EDGE",  draft_round: 1, draft_pick: 11,  college_slug: "georgia-bulldogs",            nfl_team_slug: "san-francisco-49ers" },
  { first_name: "Tyler",      last_name: "Booker",          position: "OG",    draft_round: 1, draft_pick: 12,  college_slug: "alabama-crimson-tide",        nfl_team_slug: "dallas-cowboys" },
  { first_name: "Kenneth",    last_name: "Grant",           position: "DT",    draft_round: 1, draft_pick: 13,  college_slug: "michigan-wolverines",         nfl_team_slug: "miami-dolphins" },
  { first_name: "Tyler",      last_name: "Warren",          position: "TE",    draft_round: 1, draft_pick: 14,  college_slug: "penn-state-nittany-lions",    nfl_team_slug: "indianapolis-colts" },
  { first_name: "Jalon",      last_name: "Walker",          position: "LB",    draft_round: 1, draft_pick: 15,  college_slug: "georgia-bulldogs",            nfl_team_slug: "atlanta-falcons" },
  { first_name: "Walter",     last_name: "Nolen",           position: "DT",    draft_round: 1, draft_pick: 16,  college_slug: "ole-miss-rebels",             nfl_team_slug: "arizona-cardinals" },
  { first_name: "Shemar",     last_name: "Stewart",         position: "EDGE",  draft_round: 1, draft_pick: 17,  college_slug: "texas-a-m-aggies",            nfl_team_slug: "cincinnati-bengals" },
  { first_name: "Grey",       last_name: "Zabel",           position: "OG",    draft_round: 1, draft_pick: 18,  college_slug: "north-dakota-state-bison",    nfl_team_slug: "seattle-seahawks" },
  { first_name: "Emeka",      last_name: "Egbuka",          position: "WR",    draft_round: 1, draft_pick: 19,  college_slug: "ohio-state-buckeyes",         nfl_team_slug: "denver-broncos" },
  { first_name: "Jahdae",     last_name: "Barron",          position: "CB",    draft_round: 1, draft_pick: 20,  college_slug: "texas-longhorns",             nfl_team_slug: "tampa-bay-buccaneers" },
  { first_name: "Derrick",    last_name: "Harmon",          position: "DT",    draft_round: 1, draft_pick: 21,  college_slug: "oregon-ducks",                nfl_team_slug: "pittsburgh-steelers" },
  { first_name: "Omarion",    last_name: "Hampton",         position: "RB",    draft_round: 1, draft_pick: 22,  college_slug: "north-carolina-tar-heels",    nfl_team_slug: "los-angeles-rams" },
  { first_name: "Matthew",    last_name: "Golden",          position: "WR",    draft_round: 1, draft_pick: 23,  college_slug: "texas-longhorns",             nfl_team_slug: "los-angeles-chargers" },
  { first_name: "Donovan",    last_name: "Jackson",         position: "OG",    draft_round: 1, draft_pick: 24,  college_slug: "ohio-state-buckeyes",         nfl_team_slug: "green-bay-packers" },
  { first_name: "Jaxson",     last_name: "Dart",            position: "QB",    draft_round: 1, draft_pick: 25,  college_slug: "ole-miss-rebels",             nfl_team_slug: "minnesota-vikings" },
  { first_name: "James",      last_name: "Pearce Jr.",      position: "EDGE",  draft_round: 1, draft_pick: 26,  college_slug: "tennessee-volunteers",        nfl_team_slug: "houston-texans" },
  { first_name: "Malaki",     last_name: "Starks",          position: "S",     draft_round: 1, draft_pick: 27,  college_slug: "georgia-bulldogs",            nfl_team_slug: "baltimore-ravens" },
  { first_name: "Tyleik",     last_name: "Williams",        position: "DT",    draft_round: 1, draft_pick: 28,  college_slug: "ohio-state-buckeyes",         nfl_team_slug: "detroit-lions" },
  { first_name: "Josh",       last_name: "Conerly Jr.",     position: "OT",    draft_round: 1, draft_pick: 29,  college_slug: "oregon-ducks",                nfl_team_slug: "buffalo-bills" },
  { first_name: "Maxwell",    last_name: "Hairston",        position: "CB",    draft_round: 1, draft_pick: 30,  college_slug: "kentucky-wildcats",           nfl_team_slug: "philadelphia-eagles" },
  { first_name: "Jihaad",     last_name: "Campbell",        position: "LB",    draft_round: 1, draft_pick: 31,  college_slug: "alabama-crimson-tide",        nfl_team_slug: "washington-commanders" },
  { first_name: "Josh",       last_name: "Simmons",         position: "OT",    draft_round: 1, draft_pick: 32,  college_slug: "ohio-state-buckeyes",         nfl_team_slug: "kansas-city-chiefs" },

  # ── Round 2 (Picks 33-64) ─────────────────────────────────────────────────
  { first_name: "Carson",     last_name: "Schwesinger",     position: "LB",    draft_round: 2, draft_pick: 33,  college_slug: "ucla-bruins",                 nfl_team_slug: "tennessee-titans" },
  { first_name: "Jayden",     last_name: "Higgins",         position: "WR",    draft_round: 2, draft_pick: 34,  college_slug: "iowa-state-cyclones",         nfl_team_slug: "cleveland-browns" },
  { first_name: "Nick",       last_name: "Emmanwori",       position: "S",     draft_round: 2, draft_pick: 35,  college_slug: "south-carolina-gamecocks",    nfl_team_slug: "new-york-giants" },
  { first_name: "Quinshon",   last_name: "Judkins",         position: "RB",    draft_round: 2, draft_pick: 36,  college_slug: "ohio-state-buckeyes",         nfl_team_slug: "new-england-patriots" },
  { first_name: "Jonah",      last_name: "Savaiinaea",      position: "OG",    draft_round: 2, draft_pick: 37,  college_slug: "arizona-wildcats",            nfl_team_slug: "jacksonville-jaguars" },
  { first_name: "TreVeyon",   last_name: "Henderson",       position: "RB",    draft_round: 2, draft_pick: 38,  college_slug: "ohio-state-buckeyes",         nfl_team_slug: "las-vegas-raiders" },
  { first_name: "Luther",     last_name: "Burden III",      position: "WR",    draft_round: 2, draft_pick: 39,  college_slug: "missouri-tigers",             nfl_team_slug: "new-york-jets" },
  { first_name: "Tyler",      last_name: "Shough",          position: "QB",    draft_round: 2, draft_pick: 40,  college_slug: "louisville-cardinals",        nfl_team_slug: "carolina-panthers" },
  { first_name: "T.J.",       last_name: "Sanders",         position: "DT",    draft_round: 2, draft_pick: 41,  college_slug: "south-carolina-gamecocks",    nfl_team_slug: "new-orleans-saints" },
  { first_name: "Mason",      last_name: "Taylor",          position: "TE",    draft_round: 2, draft_pick: 42,  college_slug: "lsu-tigers",                  nfl_team_slug: "chicago-bears" },
  { first_name: "Alfred",     last_name: "Collins",         position: "DT",    draft_round: 2, draft_pick: 43,  college_slug: "texas-longhorns",             nfl_team_slug: "san-francisco-49ers" },
  { first_name: "Donovan",    last_name: "Ezeiruaku",       position: "EDGE",  draft_round: 2, draft_pick: 44,  college_slug: "boston-college-eagles",        nfl_team_slug: "dallas-cowboys" },
  { first_name: "JT",         last_name: "Tuimoloau",       position: "EDGE",  draft_round: 2, draft_pick: 45,  college_slug: "ohio-state-buckeyes",         nfl_team_slug: "miami-dolphins" },
  { first_name: "Terrence",   last_name: "Ferguson",        position: "TE",    draft_round: 2, draft_pick: 46,  college_slug: "oregon-ducks",                nfl_team_slug: "indianapolis-colts" },
  { first_name: "Will",       last_name: "Johnson",         position: "CB",    draft_round: 2, draft_pick: 47,  college_slug: "michigan-wolverines",         nfl_team_slug: "arizona-cardinals" },
  { first_name: "Aireontae",  last_name: "Ersery",          position: "OT",    draft_round: 2, draft_pick: 48,  college_slug: "minnesota-golden-gophers",    nfl_team_slug: "atlanta-falcons" },
  { first_name: "Demetrius",  last_name: "Knight Jr.",      position: "LB",    draft_round: 2, draft_pick: 49,  college_slug: "south-carolina-gamecocks",    nfl_team_slug: "cincinnati-bengals" },
  { first_name: "Elijah",     last_name: "Arroyo",          position: "TE",    draft_round: 2, draft_pick: 50,  college_slug: "miami-hurricanes",            nfl_team_slug: "seattle-seahawks" },
  { first_name: "Nic",        last_name: "Scourton",        position: "EDGE",  draft_round: 2, draft_pick: 51,  college_slug: "texas-a-m-aggies",            nfl_team_slug: "denver-broncos" },
  { first_name: "Oluwafemi",  last_name: "Oladejo",         position: "EDGE",  draft_round: 2, draft_pick: 52,  college_slug: "ucla-bruins",                 nfl_team_slug: "tampa-bay-buccaneers" },
  { first_name: "Benjamin",   last_name: "Morrison",        position: "CB",    draft_round: 2, draft_pick: 53,  college_slug: "notre-dame-fighting-irish",   nfl_team_slug: "pittsburgh-steelers" },
  { first_name: "Anthony",    last_name: "Belton",          position: "OT",    draft_round: 2, draft_pick: 54,  college_slug: "nc-state-wolfpack",           nfl_team_slug: "los-angeles-rams" },
  { first_name: "Tre",        last_name: "Harris",          position: "WR",    draft_round: 2, draft_pick: 55,  college_slug: "ole-miss-rebels",             nfl_team_slug: "los-angeles-chargers" },
  { first_name: "Ozzy",       last_name: "Trapilo",         position: "OT",    draft_round: 2, draft_pick: 56,  college_slug: "boston-college-eagles",        nfl_team_slug: "green-bay-packers" },
  { first_name: "Tate",       last_name: "Ratledge",        position: "OG",    draft_round: 2, draft_pick: 57,  college_slug: "georgia-bulldogs",            nfl_team_slug: "houston-texans" },
  { first_name: "Jack",       last_name: "Bech",            position: "WR",    draft_round: 2, draft_pick: 58,  college_slug: "tcu-horned-frogs",            nfl_team_slug: "baltimore-ravens" },
  { first_name: "Mike",       last_name: "Green",           position: "EDGE",  draft_round: 2, draft_pick: 59,  college_slug: "marshall-thundering-herd",    nfl_team_slug: "minnesota-vikings" },
  { first_name: "RJ",         last_name: "Harvey",          position: "RB",    draft_round: 2, draft_pick: 60,  college_slug: "ucf-knights",                 nfl_team_slug: "detroit-lions" },
  { first_name: "Trey",       last_name: "Amos",            position: "CB",    draft_round: 2, draft_pick: 61,  college_slug: "ole-miss-rebels",             nfl_team_slug: "buffalo-bills" },
  { first_name: "Shemar",     last_name: "Turner",          position: "DT",    draft_round: 2, draft_pick: 62,  college_slug: "texas-a-m-aggies",            nfl_team_slug: "philadelphia-eagles" },
  { first_name: "Omarr",      last_name: "Norman-Lott",     position: "DT",    draft_round: 2, draft_pick: 63,  college_slug: "tennessee-volunteers",        nfl_team_slug: "washington-commanders" },
  { first_name: "Andrew",     last_name: "Mukuba",          position: "S",     draft_round: 2, draft_pick: 64,  college_slug: "texas-longhorns",             nfl_team_slug: "kansas-city-chiefs" },

  # ── Round 3 (Picks 65-100) ────────────────────────────────────────────────
  { first_name: "Darius",     last_name: "Alexander",       position: "DT",    draft_round: 3, draft_pick: 65,  college_slug: "toledo-rockets",              nfl_team_slug: "tennessee-titans" },
  { first_name: "Ashton",     last_name: "Gillotte",        position: "EDGE",  draft_round: 3, draft_pick: 66,  college_slug: "louisville-cardinals",        nfl_team_slug: "cleveland-browns" },
  { first_name: "Harold",     last_name: "Fannin Jr.",      position: "TE",    draft_round: 3, draft_pick: 67,  college_slug: "bowling-green-falcons",       nfl_team_slug: "new-york-giants" },
  { first_name: "Darien",     last_name: "Porter",          position: "CB",    draft_round: 3, draft_pick: 68,  college_slug: "iowa-state-cyclones",         nfl_team_slug: "new-england-patriots" },
  { first_name: "Kyle",       last_name: "Williams",        position: "WR",    draft_round: 3, draft_pick: 69,  college_slug: "washington-state-cougars",    nfl_team_slug: "jacksonville-jaguars" },
  { first_name: "Isaac",      last_name: "TeSlaa",          position: "WR",    draft_round: 3, draft_pick: 70,  college_slug: "arkansas-razorbacks",         nfl_team_slug: "las-vegas-raiders" },
  { first_name: "Vernon",     last_name: "Broughton",       position: "DT",    draft_round: 3, draft_pick: 71,  college_slug: "texas-longhorns",             nfl_team_slug: "new-york-jets" },
  { first_name: "Landon",     last_name: "Jackson",         position: "EDGE",  draft_round: 3, draft_pick: 72,  college_slug: "arkansas-razorbacks",         nfl_team_slug: "carolina-panthers" },
  { first_name: "Azareye'h",  last_name: "Thomas",          position: "CB",    draft_round: 3, draft_pick: 73,  college_slug: "florida-state-seminoles",     nfl_team_slug: "new-orleans-saints" },
  { first_name: "Pat",        last_name: "Bryant",          position: "WR",    draft_round: 3, draft_pick: 74,  college_slug: "illinois-fighting-illini",    nfl_team_slug: "chicago-bears" },
  { first_name: "Nick",       last_name: "Martin",          position: "LB",    draft_round: 3, draft_pick: 75,  college_slug: "oklahoma-state-cowboys",      nfl_team_slug: "san-francisco-49ers" },
  { first_name: "Shavon",     last_name: "Revel Jr.",       position: "CB",    draft_round: 3, draft_pick: 76,  college_slug: "east-carolina-pirates",       nfl_team_slug: "dallas-cowboys" },
  { first_name: "Princely",   last_name: "Umanmielen",      position: "EDGE",  draft_round: 3, draft_pick: 77,  college_slug: "ole-miss-rebels",             nfl_team_slug: "miami-dolphins" },
  { first_name: "Jordan",     last_name: "Burch",           position: "EDGE",  draft_round: 3, draft_pick: 78,  college_slug: "oregon-ducks",                nfl_team_slug: "indianapolis-colts" },
  { first_name: "Jaylin",     last_name: "Noel",            position: "WR",    draft_round: 3, draft_pick: 79,  college_slug: "iowa-state-cyclones",         nfl_team_slug: "atlanta-falcons" },
  { first_name: "Justin",     last_name: "Walley",          position: "CB",    draft_round: 3, draft_pick: 80,  college_slug: "minnesota-golden-gophers",    nfl_team_slug: "arizona-cardinals" },
  { first_name: "Dylan",      last_name: "Fairchild",       position: "OG",    draft_round: 3, draft_pick: 81,  college_slug: "georgia-bulldogs",            nfl_team_slug: "cincinnati-bengals" },
  { first_name: "Kevin",      last_name: "Winston Jr.",     position: "S",     draft_round: 3, draft_pick: 82,  college_slug: "penn-state-nittany-lions",    nfl_team_slug: "seattle-seahawks" },
  { first_name: "Kaleb",      last_name: "Johnson",         position: "RB",    draft_round: 3, draft_pick: 83,  college_slug: "iowa-hawkeyes",               nfl_team_slug: "tampa-bay-buccaneers" },
  { first_name: "Jacob",      last_name: "Parrish",         position: "CB",    draft_round: 3, draft_pick: 84,  college_slug: "kansas-state-wildcats",       nfl_team_slug: "pittsburgh-steelers" },
  { first_name: "Nohl",       last_name: "Williams",        position: "CB",    draft_round: 3, draft_pick: 85,  college_slug: "california-golden-bears",     nfl_team_slug: "los-angeles-rams" },
  { first_name: "Jamaree",    last_name: "Caldwell",        position: "DT",    draft_round: 3, draft_pick: 86,  college_slug: "oregon-ducks",                nfl_team_slug: "los-angeles-chargers" },
  { first_name: "Savion",     last_name: "Williams",        position: "WR",    draft_round: 3, draft_pick: 87,  college_slug: "tcu-horned-frogs",            nfl_team_slug: "green-bay-packers" },
  { first_name: "Caleb",      last_name: "Ransaw",          position: "CB",    draft_round: 3, draft_pick: 88,  college_slug: "tulane-green-wave",           nfl_team_slug: "houston-texans" },
  { first_name: "Wyatt",      last_name: "Milum",           position: "OG",    draft_round: 3, draft_pick: 89,  college_slug: "west-virginia-mountaineers",  nfl_team_slug: "baltimore-ravens" },
  { first_name: "Josaiah",    last_name: "Stewart",         position: "EDGE",  draft_round: 3, draft_pick: 90,  college_slug: "michigan-wolverines",         nfl_team_slug: "minnesota-vikings" },
  { first_name: "Emery",      last_name: "Jones Jr.",       position: "OT",    draft_round: 3, draft_pick: 91,  college_slug: "lsu-tigers",                  nfl_team_slug: "detroit-lions" },
  { first_name: "Jalen",      last_name: "Milroe",          position: "QB",    draft_round: 3, draft_pick: 92,  college_slug: "alabama-crimson-tide",        nfl_team_slug: "buffalo-bills" },
  { first_name: "Jonas",      last_name: "Sanker",          position: "S",     draft_round: 3, draft_pick: 93,  college_slug: "virginia-cavaliers",          nfl_team_slug: "philadelphia-eagles" },
  { first_name: "Dillon",     last_name: "Gabriel",         position: "QB",    draft_round: 3, draft_pick: 94,  college_slug: "oregon-ducks",                nfl_team_slug: "washington-commanders" },
  { first_name: "Jared",      last_name: "Wilson",          position: "C",     draft_round: 3, draft_pick: 95,  college_slug: "georgia-bulldogs",            nfl_team_slug: "kansas-city-chiefs" },
  { first_name: "Xavier",     last_name: "Watts",           position: "S",     draft_round: 3, draft_pick: 96,  college_slug: "notre-dame-fighting-irish",   nfl_team_slug: "tennessee-titans" },
  { first_name: "Jaylin",     last_name: "Smith",           position: "CB",    draft_round: 3, draft_pick: 97,  college_slug: "usc-trojans",                 nfl_team_slug: "cleveland-browns" },
  { first_name: "Caleb",      last_name: "Rogers",          position: "OT",    draft_round: 3, draft_pick: 98,  college_slug: "texas-tech-red-raiders",      nfl_team_slug: "new-york-giants" },
  { first_name: "Charles",    last_name: "Grant",           position: "OT",    draft_round: 3, draft_pick: 99,  college_slug: "william-mary-tribe",          nfl_team_slug: "new-england-patriots" },
  { first_name: "Upton",      last_name: "Stout",           position: "CB",    draft_round: 3, draft_pick: 100, college_slug: "western-kentucky-hilltoppers", nfl_team_slug: "jacksonville-jaguars" },

  # ── Compensatory picks (101-102) ──────────────────────────────────────────
  { first_name: "Sai'vion",   last_name: "Jones",           position: "EDGE",  draft_round: 3, draft_pick: 101, college_slug: "lsu-tigers",                  nfl_team_slug: "denver-broncos" },
  { first_name: "Tai",        last_name: "Felton",          position: "WR",    draft_round: 3, draft_pick: 102, college_slug: "maryland-terrapins",          nfl_team_slug: "minnesota-vikings" },

  # ── Hypothetical prospect for Player Impact Simulator ────────────────────
  { first_name: "David",      last_name: "Bailey",          position: "EDGE",  draft_round: 1, draft_pick: 103, college_slug: nil, nfl_team_slug: nil },
]

nfl_season = Season.find_by(year: 2025, league: "nfl")
offseason  = nfl_season&.slates&.find_by(sequence: 0)

NFL_PROSPECTS.each do |data|
  # Smart name matching — handles Cameron/Cam Ward, Tetairoa/Tet McMillan, J.T./JT Tuimoloau, etc.
  person = Person.find_or_create_by_name!(data[:first_name], data[:last_name], athlete: true)

  athlete = Athlete.find_or_create_by!(person_slug: person.slug) do |a|
    a.sport = "football"
    a.position = data[:position]
    a.draft_year = 2025
    a.draft_round = data[:draft_round]
    a.draft_pick = data[:draft_pick]
  end
  # Update draft info on existing athletes (Spotrac creates them first without draft data)
  if athlete.draft_pick.nil?
    athlete.update!(draft_year: 2025, draft_round: data[:draft_round], draft_pick: data[:draft_pick])
  end

  # Create contract to college team
  if data[:college_slug].present?
    Contract.find_or_create_by!(person_slug: person.slug, team_slug: data[:college_slug]) do |c|
      c.expires_at = Date.new(2026, 4, 1)
      c.position = data[:position]
      c.contract_type = "college"
    end
  end

  # Create draft_pick contract to NFL team
  if data[:nfl_team_slug].present?
    nfl_team = Team.find_by(slug: data[:nfl_team_slug])
    if nfl_team
      # Expire college contracts
      person.contracts.where(contract_type: "college").find_each do |c|
        c.update!(expires_at: Date.current) unless c.expired?
      end

      # Create or update draft contract
      contract = Contract.find_or_create_by!(person_slug: person.slug, team_slug: nfl_team.slug) do |c|
        c.contract_type = "draft_pick"
        c.position      = data[:position]
      end
      contract.update!(contract_type: "draft_pick") unless contract.contract_type == "draft_pick"

      # Add to offseason roster
      if offseason
        roster = Roster.find_by(team_slug: nfl_team.slug, slate_slug: offseason.slug)
        if roster
          side = PositionConcern.side_for(data[:position])
          existing_depth = roster.roster_spots.where(position: data[:position]).maximum(:depth) || 0
          RosterSpot.find_or_create_by!(roster: roster, person_slug: person.slug, position: data[:position]) do |rs|
            rs.side  = side
            rs.depth = existing_depth + 1
          end
        end
      end

      puts "Draft: #{person.full_name} (Rd #{data[:draft_round]}, Pick #{data[:draft_pick]}) -> #{nfl_team.name}"
    end
  else
    puts "Prospect: #{person.full_name} (Rd #{data[:draft_round]}, Pick #{data[:draft_pick]}) - #{data[:position]}"
  end
end
