# Athlete grades — fallback layer for athletes not in any PFF CSV.
#
# By the time this runs:
#   29_pff_grades.rb has imported ~570 real PFF grades for active starters/role
#   players. The athletes left here are backups + practice-squad — by definition
#   non-stars without enough snaps for a meaningful PFF grade. We give them a
#   flat baseline so the depth-chart ranking (in 31_depth_charts.rb) has a value
#   to sort against; salary acts as the natural tiebreaker.
#
# Prospects keep the tier-based grading with grade_ranges JSONB since draft
# slot is the only signal we have for them pre-NFL.

PROSPECT_TIERS = [
  { picks: 1..10,   overall: [68, 92], spread: 5 },
  { picks: 11..20,  overall: [60, 85], spread: 6 },
  { picks: 21..32,  overall: [55, 80], spread: 6 },
  { picks: 33..50,  overall: [50, 74], spread: 7 },
  { picks: 51..70,  overall: [46, 68], spread: 7 },
  { picks: 71..103, overall: [42, 64], spread: 8 },
]

POSITION_OFFSETS = {
  "QB"   => { pass_grade: 2,         run_grade: -10 },
  "WR"   => { pass_route_grade: 2,   run_grade: -10 },
  "TE"   => { pass_route_grade: 2,   run_grade: -6 },
  "RB"   => { run_grade: 2,          pass_route_grade: -8 },
  "FB"   => { run_grade: 2,          pass_route_grade: -8 },
  "HB"   => { run_grade: 2,          pass_route_grade: -8 },
  "OT"   => { pass_block_grade: 2,   run_block_grade: -2 },
  "OG"   => { pass_block_grade: 2,   run_block_grade: -2 },
  "C"    => { pass_block_grade: 2,   run_block_grade: -2 },
  "EDGE" => { pass_rush_grade: 2,    rush_defense_grade: -5,  coverage_grade: -12 },
  "DE"   => { pass_rush_grade: 2,    rush_defense_grade: -5,  coverage_grade: -12 },
  "DT"   => { rush_defense_grade: 2, pass_rush_grade: -3,     coverage_grade: -15 },
  "DL"   => { rush_defense_grade: 2, pass_rush_grade: -3,     coverage_grade: -15 },
  "NT"   => { rush_defense_grade: 2, pass_rush_grade: -3,     coverage_grade: -15 },
  "LB"   => { rush_defense_grade: 0, coverage_grade: -2,      pass_rush_grade: -6 },
  "CB"   => { coverage_grade: 2,     rush_defense_grade: -10 },
  "S"    => { coverage_grade: 2,     rush_defense_grade: -4,  pass_rush_grade: -12 },
  "CB/WR" => { coverage_grade: 2, pass_route_grade: 0, rush_defense_grade: -8 }
}.freeze

OFFENSE_POSITIONS = %w[QB WR TE RB FB HB OT OG C LT LG RT RG CB/WR].freeze

def prospect_tier_for(pick)
  PROSPECT_TIERS.find { |t| t[:picks].include?(pick) }
end

def prospect_overall(pick, slug)
  tier = prospect_tier_for(pick)
  return 65.0 unless tier

  low, high = tier[:overall]
  range = high - low
  seed = Digest::MD5.hexdigest("#{slug}-overall").to_i(16) % 10000
  (low + (seed / 10000.0) * range).round(1)
end

def prospect_grade_ranges(position, overall, _slug, pick)
  tier = prospect_tier_for(pick) || PROSPECT_TIERS.last
  spread = tier[:spread]
  offsets = POSITION_OFFSETS[position] || {}
  ranges = {}

  offsets.each do |grade_key, offset|
    midpoint = (overall + offset).clamp(40.0, 99.9)
    low  = [midpoint - spread, 40.0].max.round(1)
    high = [midpoint + spread, 99.9].min.round(1)
    ranges[grade_key.to_s] = [low, high]
  end

  ranges["overall_grade"] = [[overall - spread, 40.0].max.round(1), [overall + spread, 99.9].min.round(1)]
  ranges
end

nfl_season = Season.find_by(year: 2025, league: "nfl")

if nfl_season
  # Non-PFF active NFL athletes — flat baseline, find_or_create skips PFF rows
  Athlete.joins(:person).joins("INNER JOIN contracts ON contracts.person_slug = people.slug AND contracts.contract_type = 'active'")
         .where(sport: "football")
         .distinct.find_each do |athlete|
    AthleteGrade.find_or_create_by!(athlete_slug: athlete.slug, season_slug: nfl_season.slug) do |g|
      g.overall_grade = 60.0
      g.games_played  = 17
    end
  end

  # NCAA prospects — tier-based grades with ranges JSONB
  Athlete.where(sport: "football").where.not(draft_pick: nil).find_each do |athlete|
    pick    = athlete.draft_pick
    overall = prospect_overall(pick, athlete.slug)
    pos     = athlete.position
    offsets = POSITION_OFFSETS[pos] || {}

    computed = offsets.transform_values { |o| (overall + o).clamp(40.0, 99.9).round(1) }
    if OFFENSE_POSITIONS.include?(pos)
      computed[:offense_grade] = overall
      computed[:defense_grade] = overall if pos == "CB/WR"
    else
      computed[:defense_grade] = overall
    end

    AthleteGrade.find_or_create_by!(athlete_slug: athlete.slug, season_slug: nfl_season.slug) do |g|
      g.overall_grade = overall
      g.games_played  = rand(10..14)
      g.snaps         = rand(400..900)
      g.grade_ranges  = prospect_grade_ranges(pos, overall, athlete.slug, pick)
      computed.each { |k, v| g.public_send(:"#{k}=", v) }
    end
  end
end

puts "AthleteGrades: #{AthleteGrade.count}"
