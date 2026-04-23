# Athlete grades for all NFL players with position-specific sub-grades
#
# Each position group gets relevant sub-grades derived from the overall grade
# with realistic variance. This ensures all rankings pages have data to sort on.
#
# NFL vets: salary-based heuristic
# Prospects: tier-based by draft pick with grade_ranges JSONB

# Deterministic variance from overall grade — seeded by athlete slug for consistency
def grade_variance(slug, column_name, overall, range)
  seed = Digest::MD5.hexdigest("#{slug}-#{column_name}").to_i(16) % 10000
  offset = (seed / 10000.0) * (range * 2) - range
  [(overall + offset).round(1), 99.9].min.clamp(40.0, 99.9)
end

# Position-specific grade assignment
def position_grades(position, overall, slug)
  grades = {}

  case position
  when "QB"
    grades[:pass_grade]  = grade_variance(slug, "pass",  overall, 4)
    grades[:run_grade]   = grade_variance(slug, "run",   overall - 8, 6)
    grades[:offense_grade] = overall

  when "WR", "TE"
    grades[:pass_route_grade] = grade_variance(slug, "route", overall, 4)
    grades[:run_grade]        = grade_variance(slug, "run",   overall - 10, 5)
    grades[:offense_grade]    = overall

  when "RB", "FB", "HB"
    grades[:run_grade]        = grade_variance(slug, "run",   overall, 4)
    grades[:pass_route_grade] = grade_variance(slug, "route", overall - 8, 5)
    grades[:offense_grade]    = overall

  when "OT", "OG", "C", "LT", "LG", "RT", "RG"
    grades[:pass_block_grade] = grade_variance(slug, "pb", overall, 4)
    grades[:run_block_grade]  = grade_variance(slug, "rb", overall, 4)
    grades[:offense_grade]    = overall

  when "EDGE", "DE"
    grades[:pass_rush_grade]    = grade_variance(slug, "pr",  overall, 4)
    grades[:rush_defense_grade] = grade_variance(slug, "rd",  overall - 5, 5)
    grades[:coverage_grade]     = grade_variance(slug, "cov", overall - 12, 6)
    grades[:defense_grade]      = overall

  when "DT", "NT", "DL"
    grades[:pass_rush_grade]    = grade_variance(slug, "pr",  overall - 3, 5)
    grades[:rush_defense_grade] = grade_variance(slug, "rd",  overall, 4)
    grades[:coverage_grade]     = grade_variance(slug, "cov", overall - 15, 5)
    grades[:defense_grade]      = overall

  when "LB", "ILB", "OLB", "MLB"
    grades[:coverage_grade]     = grade_variance(slug, "cov", overall - 3, 5)
    grades[:rush_defense_grade] = grade_variance(slug, "rd",  overall, 4)
    grades[:pass_rush_grade]    = grade_variance(slug, "pr",  overall - 6, 6)
    grades[:defense_grade]      = overall

  when "CB"
    grades[:coverage_grade]     = grade_variance(slug, "cov", overall, 4)
    grades[:rush_defense_grade] = grade_variance(slug, "rd",  overall - 10, 5)
    grades[:defense_grade]      = overall

  when "S", "FS", "SS"
    grades[:coverage_grade]     = grade_variance(slug, "cov", overall, 4)
    grades[:rush_defense_grade] = grade_variance(slug, "rd",  overall - 4, 5)
    grades[:pass_rush_grade]    = grade_variance(slug, "pr",  overall - 12, 5)
    grades[:defense_grade]      = overall

  when "K"
    grades[:fg_grade]     = grade_variance(slug, "fg",   overall, 4)
    grades[:kickoff_grade] = grade_variance(slug, "kick", overall - 3, 5)
    grades[:offense_grade] = overall

  when "P"
    grades[:punting_grade] = grade_variance(slug, "punt", overall, 4)
    grades[:offense_grade] = overall

  when "LS"
    grades[:offense_grade] = overall
  end

  grades
end

# ── Prospect tier system ─────────────────────────────────────────────────────
# Tier-based grades with position-specific ranges for draft prospects

PROSPECT_TIERS = [
  { picks: 1..10,   overall: [68, 92], spread: 5 },
  { picks: 11..20,  overall: [60, 85], spread: 6 },
  { picks: 21..32,  overall: [55, 80], spread: 6 },
  { picks: 33..50,  overall: [50, 74], spread: 7 },
  { picks: 51..70,  overall: [46, 68], spread: 7 },
  { picks: 71..103, overall: [42, 64], spread: 8 },
]

# Position skill offsets from overall for prospect grade computation
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
}

# Also handle CB/WR (Travis Hunter)
POSITION_OFFSETS["CB/WR"] = { coverage_grade: 2, pass_route_grade: 0, rush_defense_grade: -8 }

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

def prospect_grade_ranges(position, overall, slug, pick)
  tier = prospect_tier_for(pick) || PROSPECT_TIERS.last
  spread = tier[:spread]
  offsets = POSITION_OFFSETS[position] || {}
  ranges = {}

  offsets.each do |grade_key, offset|
    midpoint = (overall + offset).clamp(40.0, 99.9)
    low = [midpoint - spread, 40.0].max.round(1)
    high = [midpoint + spread, 99.9].min.round(1)
    ranges[grade_key.to_s] = [low, high]
  end

  # Add overall range
  ranges["overall_grade"] = [[overall - spread, 40.0].max.round(1), [overall + spread, 99.9].min.round(1)]
  ranges
end

nfl_season = Season.find_by(year: 2025, league: "nfl")

if nfl_season
  # NFL Stars — salary-based heuristic grade
  Athlete.joins(:person).joins("INNER JOIN contracts ON contracts.person_slug = people.slug")
         .where(sport: "football")
         .where("contracts.annual_value_cents IS NOT NULL")
         .distinct.each do |athlete|
    contract = Contract.where(person_slug: athlete.person_slug)
                       .where.not(annual_value_cents: nil).first
    next unless contract

    # Heuristic: $60M/yr → 92, $25M/yr → 72 (linear scale)
    salary_m = contract.annual_value_cents / 100_000_000.0
    base_grade = [60.0 + (salary_m * 0.55), 95.0].min.round(1)

    AthleteGrade.find_or_create_by!(athlete_slug: athlete.slug, season_slug: nfl_season.slug) do |g|
      g.overall_grade = base_grade
      g.games_played  = 17
      g.snaps         = rand(800..1100)
      position_grades(athlete.position, base_grade, athlete.slug).each { |k, v| g.send(:"#{k}=", v) }
    end

    puts "Grade: #{athlete.person.full_name} (#{athlete.position}) -- #{base_grade} (salary heuristic)"
  end

  # NCAA Prospects — tier-based grade with ranges
  Athlete.where(sport: "football").where.not(draft_pick: nil).each do |athlete|
    pick = athlete.draft_pick
    overall = prospect_overall(pick, athlete.slug)
    tier = prospect_tier_for(pick)
    spread = tier ? tier[:spread] : 6

    # Compute position-specific grades using offsets
    pos = athlete.position
    offsets = POSITION_OFFSETS[pos] || {}
    computed_grades = {}
    offsets.each do |grade_key, offset|
      midpoint = (overall + offset).clamp(40.0, 99.9).round(1)
      computed_grades[grade_key] = midpoint
    end

    # Set side grade (offense_grade or defense_grade)
    offense_positions = %w[QB WR TE RB FB HB OT OG C LT LG RT RG]
    if offense_positions.include?(pos) || pos == "CB/WR"
      computed_grades[:offense_grade] = overall
    else
      computed_grades[:defense_grade] = overall
    end
    # CB/WR gets both
    computed_grades[:defense_grade] = overall if pos == "CB/WR"

    # Build grade_ranges JSONB
    ranges = prospect_grade_ranges(pos, overall, athlete.slug, pick)

    AthleteGrade.find_or_create_by!(athlete_slug: athlete.slug, season_slug: nfl_season.slug) do |g|
      g.overall_grade = overall
      g.games_played  = rand(10..14)
      g.snaps         = rand(400..900)
      g.grade_ranges  = ranges
      computed_grades.each { |k, v| g.send(:"#{k}=", v) }
    end

    puts "Grade: #{athlete.person.full_name} (#{athlete.position}, Pick #{pick}) -- #{overall} [tier #{tier ? tier[:picks] : '?'}]"
  end
end

puts "AthleteGrades: #{AthleteGrade.count}"
