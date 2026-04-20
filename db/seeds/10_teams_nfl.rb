# 32 NFL Teams with sport/league/conference/division
NFL_TEAMS = [
  # AFC East
  { name: "Buffalo Bills",         short_name: "BUF", location: "Buffalo",        emoji: "\u{1F9AC}", color_primary: "#00338D", color_secondary: "#C60C30", conference: "AFC", division: "East" },
  { name: "Miami Dolphins",        short_name: "MIA", location: "Miami",          emoji: "\u{1F42C}", color_primary: "#008E97", color_secondary: "#FC4C02", conference: "AFC", division: "East" },
  { name: "New England Patriots",  short_name: "NE",  location: "New England",    emoji: "\u{1F3F4}", color_primary: "#002244", color_secondary: "#C60C30", conference: "AFC", division: "East" },
  { name: "New York Jets",         short_name: "NYJ", location: "New York",       emoji: "\u2708\uFE0F",  color_primary: "#125740", color_secondary: "#FFFFFF", conference: "AFC", division: "East" },
  # AFC North
  { name: "Baltimore Ravens",      short_name: "BAL", location: "Baltimore",      emoji: "\u{1F426}\u200D\u2B1B", color_primary: "#241773", color_secondary: "#000000", conference: "AFC", division: "North" },
  { name: "Cincinnati Bengals",    short_name: "CIN", location: "Cincinnati",     emoji: "\u{1F42F}", color_primary: "#FB4F14", color_secondary: "#000000", conference: "AFC", division: "North" },
  { name: "Cleveland Browns",      short_name: "CLE", location: "Cleveland",      emoji: "\u{1F7E4}", color_primary: "#311D00", color_secondary: "#FF3C00", conference: "AFC", division: "North" },
  { name: "Pittsburgh Steelers",   short_name: "PIT", location: "Pittsburgh",     emoji: "\u2699\uFE0F",  color_primary: "#FFB612", color_secondary: "#101820", color_text_light: true, conference: "AFC", division: "North" },
  # AFC South
  { name: "Houston Texans",        short_name: "HOU", location: "Houston",        emoji: "\u{1F920}", color_primary: "#03202F", color_secondary: "#A71930", conference: "AFC", division: "South" },
  { name: "Indianapolis Colts",    short_name: "IND", location: "Indianapolis",   emoji: "\u{1F434}", color_primary: "#002C5F", color_secondary: "#A2AAAD", conference: "AFC", division: "South" },
  { name: "Jacksonville Jaguars",  short_name: "JAX", location: "Jacksonville",   emoji: "\u{1F406}", color_primary: "#006778", color_secondary: "#D7A22A", conference: "AFC", division: "South" },
  { name: "Tennessee Titans",      short_name: "TEN", location: "Tennessee",      emoji: "\u2694\uFE0F",  color_primary: "#0C2340", color_secondary: "#4B92DB", conference: "AFC", division: "South" },
  # AFC West
  { name: "Denver Broncos",        short_name: "DEN", location: "Denver",         emoji: "\u{1F40E}", color_primary: "#FB4F14", color_secondary: "#002244", conference: "AFC", division: "West" },
  { name: "Kansas City Chiefs",    short_name: "KC",  location: "Kansas City",    emoji: "\u{1F3F9}", color_primary: "#E31837", color_secondary: "#FFB81C", conference: "AFC", division: "West" },
  { name: "Las Vegas Raiders",     short_name: "LV",  location: "Las Vegas",      emoji: "\u2620\uFE0F",  color_primary: "#000000", color_secondary: "#A5ACAF", conference: "AFC", division: "West" },
  { name: "Los Angeles Chargers",  short_name: "LAC", location: "Los Angeles",    emoji: "\u26A1",    color_primary: "#0080C6", color_secondary: "#FFC20E", conference: "AFC", division: "West" },
  # NFC East
  { name: "Dallas Cowboys",        short_name: "DAL", location: "Dallas",         emoji: "\u2B50",    color_primary: "#003594", color_secondary: "#869397", conference: "NFC", division: "East" },
  { name: "New York Giants",       short_name: "NYG", location: "New York",       emoji: "\u{1F5FD}", color_primary: "#0B2265", color_secondary: "#A71930", conference: "NFC", division: "East" },
  { name: "Philadelphia Eagles",   short_name: "PHI", location: "Philadelphia",   emoji: "\u{1F985}", color_primary: "#004C54", color_secondary: "#A5ACAF", conference: "NFC", division: "East" },
  { name: "Washington Commanders", short_name: "WAS", location: "Washington",     emoji: "\u{1F396}\uFE0F", color_primary: "#5A1414", color_secondary: "#FFB612", conference: "NFC", division: "East" },
  # NFC North
  { name: "Chicago Bears",         short_name: "CHI", location: "Chicago",        emoji: "\u{1F43B}", color_primary: "#0B162A", color_secondary: "#C83803", conference: "NFC", division: "North" },
  { name: "Detroit Lions",         short_name: "DET", location: "Detroit",        emoji: "\u{1F981}", color_primary: "#0076B6", color_secondary: "#B0B7BC", conference: "NFC", division: "North" },
  { name: "Green Bay Packers",     short_name: "GB",  location: "Green Bay",      emoji: "\u{1F9C0}", color_primary: "#203731", color_secondary: "#FFB612", conference: "NFC", division: "North" },
  { name: "Minnesota Vikings",     short_name: "MIN", location: "Minnesota",      emoji: "\u2694\uFE0F",  color_primary: "#4F2683", color_secondary: "#FFC62F", conference: "NFC", division: "North" },
  # NFC South
  { name: "Atlanta Falcons",       short_name: "ATL", location: "Atlanta",        emoji: "\u{1F985}", color_primary: "#A71930", color_secondary: "#000000", conference: "NFC", division: "South" },
  { name: "Carolina Panthers",     short_name: "CAR", location: "Carolina",       emoji: "\u{1F406}", color_primary: "#0085CA", color_secondary: "#101820", conference: "NFC", division: "South" },
  { name: "New Orleans Saints",    short_name: "NO",  location: "New Orleans",    emoji: "\u269C\uFE0F",  color_primary: "#D3BC8D", color_secondary: "#101820", color_text_light: true, conference: "NFC", division: "South" },
  { name: "Tampa Bay Buccaneers",  short_name: "TB",  location: "Tampa Bay",      emoji: "\u{1F3F4}\u200D\u2620\uFE0F", color_primary: "#D50A0A", color_secondary: "#FF7900", conference: "NFC", division: "South" },
  # NFC West
  { name: "Arizona Cardinals",     short_name: "ARI", location: "Arizona",        emoji: "\u{1F426}", color_primary: "#97233F", color_secondary: "#000000", conference: "NFC", division: "West" },
  { name: "Los Angeles Rams",      short_name: "LAR", location: "Los Angeles",    emoji: "\u{1F40F}", color_primary: "#003594", color_secondary: "#FFA300", conference: "NFC", division: "West" },
  { name: "San Francisco 49ers",   short_name: "SF",  location: "San Francisco",  emoji: "\u26CF\uFE0F",  color_primary: "#AA0000", color_secondary: "#B3995D", conference: "NFC", division: "West" },
  { name: "Seattle Seahawks",      short_name: "SEA", location: "Seattle",        emoji: "\u{1F985}", color_primary: "#002244", color_secondary: "#69BE28", conference: "NFC", division: "West" },
]

NFL_TEAMS.each do |data|
  team = Team.find_or_create_by!(slug: data[:name].parameterize) do |t|
    t.name = data[:name]
    t.short_name = data[:short_name]
    t.location = data[:location]
    t.emoji = data[:emoji]
    t.color_primary = data[:color_primary]
    t.color_secondary = data[:color_secondary]
    t.color_text_light = data[:color_text_light] || false
  end
  team.update!(
    sport: "football",
    league: "nfl",
    conference: data[:conference],
    division: data[:division],
    color_text_light: data[:color_text_light] || false
  )
  puts "Team: #{team.emoji} #{team.name} (NFL #{data[:conference]} #{data[:division]})"
end
