# 32 NFL Teams × 4 Coaches (HC, OC, DC, STC) = 128 records
NFL_COACHES = [
  # AFC East
  { team: "Buffalo Bills",         hc: "Joe Brady",            hc_lean: "offense",  oc: "Pete Carmichael Jr.", dc: "Jim Leonhard",       stc: "Jeff Rodgers" },
  { team: "Miami Dolphins",        hc: "Jeff Hafley",          hc_lean: "defense",  oc: "Bobby Slowik",       dc: "Sean Duggan",        stc: "Chris Tabor" },
  { team: "New England Patriots",  hc: "Mike Vrabel",          hc_lean: "defense",  oc: "Josh McDaniels",     dc: "Terrell Williams",   stc: "Jeremy Springer" },
  { team: "New York Jets",         hc: "Aaron Glenn",          hc_lean: "defense",  oc: "Tanner Engstrand",   dc: "Steve Wilks",        stc: "Chris Banjo" },
  # AFC North
  { team: "Baltimore Ravens",      hc: "Jesse Minter",         hc_lean: "defense",  oc: "Declan Doyle",       dc: "Anthony Weaver",     stc: "Anthony Levine Sr." },
  { team: "Cincinnati Bengals",    hc: "Zac Taylor",           hc_lean: "offense",  oc: "Dan Pitcher",        dc: "Al Golden",          stc: "Darrin Simmons" },
  { team: "Cleveland Browns",      hc: "Todd Monken",          hc_lean: "offense",  oc: "Travis Switzer",     dc: "Mike Rutenberg",     stc: "Byron Storer" },
  { team: "Pittsburgh Steelers",   hc: "Mike McCarthy",        hc_lean: "offense",  oc: "Brian Angelichio",   dc: "Patrick Graham",     stc: "Danny Crossman" },
  # AFC South
  { team: "Houston Texans",        hc: "DeMeco Ryans",         hc_lean: "defense",  oc: "Nick Caley",         dc: "Matt Burke",         stc: "Frank Ross" },
  { team: "Indianapolis Colts",    hc: "Shane Steichen",       hc_lean: "offense",  oc: "Jim Bob Cooter",     dc: "Lou Anarumo",        stc: "Brian Mason" },
  { team: "Jacksonville Jaguars",  hc: "Liam Coen",            hc_lean: "offense",  oc: "Grant Udinski",      dc: "Anthony Campanile",  stc: "Heath Farwell" },
  { team: "Tennessee Titans",      hc: "Robert Saleh",         hc_lean: "defense",  oc: "Brian Daboll",       dc: "Gus Bradley",        stc: "John Fassel" },
  # AFC West
  { team: "Denver Broncos",        hc: "Sean Payton",          hc_lean: "offense",  oc: "Joe Lombardi",       dc: "Vance Joseph",       stc: "Darren Rizzi" },
  { team: "Kansas City Chiefs",    hc: "Andy Reid",            hc_lean: "offense",  oc: "Eric Bieniemy",      dc: "Steve Spagnuolo",    stc: "Dave Toub" },
  { team: "Las Vegas Raiders",     hc: "Klint Kubiak",         hc_lean: "offense",  oc: "Andrew Janocko",     dc: "Rob Leonard",        stc: "Joe DeCamillis" },
  { team: "Los Angeles Chargers",  hc: "Jim Harbaugh",         hc_lean: "offense",  oc: "Greg Roman",         dc: "Chris O'Leary",      stc: "Ryan Ficken" },
  # NFC East
  { team: "Dallas Cowboys",        hc: "Brian Schottenheimer",  hc_lean: "offense", oc: "Klayton Adams",      dc: "Christian Parker",   stc: "Nick Sorensen" },
  { team: "New York Giants",       hc: "John Harbaugh",        hc_lean: "defense",  oc: "Matt Nagy",          dc: "Dennard Wilson",     stc: "Chris Horton" },
  { team: "Philadelphia Eagles",   hc: "Nick Sirianni",        hc_lean: "offense",  oc: "Kellen Moore",       dc: "Vic Fangio",         stc: "Michael Clay" },
  { team: "Washington Commanders", hc: "Dan Quinn",            hc_lean: "defense",  oc: "David Blough",       dc: "Daronte Jones",      stc: "Larry Izzo" },
  # NFC North
  { team: "Chicago Bears",         hc: "Ben Johnson",          hc_lean: "offense",  oc: "Press Taylor",       dc: "Dennis Allen",       stc: "Richard Hightower" },
  { team: "Detroit Lions",         hc: "Dan Campbell",         hc_lean: "offense",  oc: "Drew Petzing",       dc: "Kelvin Sheppard",    stc: "Dave Fipp" },
  { team: "Green Bay Packers",     hc: "Matt LaFleur",         hc_lean: "offense",  oc: "Adam Stenavich",     dc: "Jonathan Gannon",    stc: "Rich Bisaccia" },
  { team: "Minnesota Vikings",     hc: "Kevin O'Connell",      hc_lean: "offense",  oc: "Wes Phillips",       dc: "Brian Flores",       stc: "Matt Daniels" },
  # NFC South
  { team: "Atlanta Falcons",       hc: "Kevin Stefanski",      hc_lean: "offense",  oc: "Tommy Rees",         dc: "Jeff Ulbrich",       stc: "Craig Aukerman" },
  { team: "Carolina Panthers",     hc: "Dave Canales",         hc_lean: "offense",  oc: "Brad Idzik",         dc: "Ejiro Evero",        stc: "Tracy Smith" },
  { team: "New Orleans Saints",    hc: "Kellen Moore",         hc_lean: "offense",  oc: "Doug Nussmeier",     dc: "Brandon Staley",     stc: "Phil Galiano" },
  { team: "Tampa Bay Buccaneers",  hc: "Todd Bowles",          hc_lean: "defense",  oc: "Josh Grizzard",      dc: "Larry Foote",        stc: "Thomas McGaughey" },
  # NFC West
  { team: "Arizona Cardinals",     hc: "Mike LaFleur",         hc_lean: "offense",  oc: "Nathaniel Hackett",  dc: "Nick Rallis",        stc: "Michael Ghobrial" },
  { team: "Los Angeles Rams",      hc: "Sean McVay",           hc_lean: "offense",  oc: "Nate Scheelhaase",   dc: "Chris Shula",        stc: "Bubba Ventrone" },
  { team: "San Francisco 49ers",   hc: "Kyle Shanahan",        hc_lean: "offense",  oc: "Klay Kubiak",        dc: "Raheem Morris",      stc: "Brant Boyer" },
  { team: "Seattle Seahawks",      hc: "Mike Macdonald",       hc_lean: "defense",  oc: "Brian Fleury",       dc: "Aden Durde",         stc: "Jay Harbaugh" },
]

NFL_COACHES.each do |data|
  team_slug = data[:team].parameterize
  team = Team.find_by(slug: team_slug)
  unless team
    puts "  [!] Team not found: #{data[:team]}"
    next
  end

  # HC, OC, DC, STC — each gets a Person + Coach record
  [
    { name: data[:hc],  role: "head_coach",                  lean: data[:hc_lean] },
    { name: data[:oc],  role: "offensive_coordinator",       lean: nil },
    { name: data[:dc],  role: "defensive_coordinator",       lean: nil },
    { name: data[:stc], role: "special_teams_coordinator",   lean: nil },
  ].each do |coach_data|
    parts = coach_data[:name].split(/\s+/, 2)
    first_name = parts[0]
    last_name  = parts[1].presence || parts[0]

    person = Person.find_or_create_by_name!(first_name, last_name, coach: true)

    Coach.find_or_create_by!(
      person_slug: person.slug,
      team_slug: team.slug,
      role: coach_data[:role]
    ) do |c|
      c.lean  = coach_data[:lean]
      c.sport = "football"
    end
  end

  puts "  NFL Coaches: #{team.emoji} #{team.name} — #{data[:hc]} (HC), #{data[:oc]} (OC), #{data[:dc]} (DC), #{data[:stc]} (STC)"
end
