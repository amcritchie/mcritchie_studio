season = Season.find_by(year: 2025, league: "nfl")
unless season
  puts "  [!] NFL 2025 season not found — skipping coach rankings"
  return
end

# Tier assignment by rank
def tier_for_rank(rank)
  case rank
  when 1..5   then "Air Raid"
  when 6..12  then "Pass Enthusiast"
  when 13..18 then "Balanced-Pass"
  when 19..22 then "True Balance"
  when 23..27 then "Balanced-Run"
  when 28..32 then "Ground & Pound"
  end
end

# Lookup coach by team slug + head_coach role
def find_hc(team_name)
  team_slug = team_name.parameterize
  Coach.find_by(team_slug: team_slug, role: "head_coach", sport: "football")
end

# Pass-first rankings (1 = most pass-first scheme)
PASS_FIRST_ORDER = [
  "Tampa Bay Buccaneers",
  "Cincinnati Bengals",
  "Buffalo Bills",
  "New Orleans Saints",
  "Minnesota Vikings",
  "Detroit Lions",
  "Dallas Cowboys",
  "Philadelphia Eagles",
  "Los Angeles Rams",
  "Arizona Cardinals",
  "Atlanta Falcons",
  "Jacksonville Jaguars",
  "Chicago Bears",
  "Cleveland Browns",
  "Indianapolis Colts",
  "Carolina Panthers",
  "New York Giants",
  "Green Bay Packers",
  "Pittsburgh Steelers",
  "Miami Dolphins",
  "Denver Broncos",
  "Seattle Seahawks",
  "San Francisco 49ers",
  "Kansas City Chiefs",
  "New England Patriots",
  "Washington Commanders",
  "Tennessee Titans",
  "Houston Texans",
  "New York Jets",
  "Las Vegas Raiders",
  "Baltimore Ravens",
  "Los Angeles Chargers",
].freeze

# Pass-heavy rankings (1 = most pass-heavy game script)
PASS_HEAVY_ORDER = [
  "New York Giants",
  "Carolina Panthers",
  "Cleveland Browns",
  "Jacksonville Jaguars",
  "Tampa Bay Buccaneers",
  "Cincinnati Bengals",
  "New Orleans Saints",
  "Las Vegas Raiders",
  "Dallas Cowboys",
  "New York Jets",
  "Minnesota Vikings",
  "Indianapolis Colts",
  "Atlanta Falcons",
  "Miami Dolphins",
  "Arizona Cardinals",
  "Chicago Bears",
  "Tennessee Titans",
  "Los Angeles Rams",
  "Buffalo Bills",
  "Seattle Seahawks",
  "Pittsburgh Steelers",
  "Denver Broncos",
  "Green Bay Packers",
  "Detroit Lions",
  "San Francisco 49ers",
  "Philadelphia Eagles",
  "New England Patriots",
  "Washington Commanders",
  "Houston Texans",
  "Kansas City Chiefs",
  "Baltimore Ravens",
  "Los Angeles Chargers",
].freeze

created = 0

{ "pass_first" => PASS_FIRST_ORDER, "pass_heavy" => PASS_HEAVY_ORDER }.each do |rank_type, order|
  order.each_with_index do |team_name, i|
    coach = find_hc(team_name)
    unless coach
      puts "  [!] HC not found for #{team_name}"
      next
    end

    rank = i + 1
    CoachRanking.find_or_create_by!(
      coach_slug: coach.slug,
      rank_type: rank_type,
      season_slug: season.slug
    ) do |cr|
      cr.rank = rank
      cr.tier = tier_for_rank(rank)
    end
    created += 1
  end
end

puts "  CoachRankings: #{created} created (#{CoachRanking.pass_first.count} pass_first, #{CoachRanking.pass_heavy.count} pass_heavy)"
