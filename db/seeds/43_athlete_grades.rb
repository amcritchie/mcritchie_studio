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
    end

    puts "Grade: #{athlete.person.full_name} — #{base_grade} (salary heuristic)"
  end

  # NCAA Prospects — pick-based heuristic grade
  Athlete.where(sport: "football").where.not(draft_pick: nil).each do |athlete|
    # Pick 1 → 85, Pick 100 → 65 (linear scale)
    base_grade = (85.0 - (athlete.draft_pick - 1) * 0.2).round(1)

    AthleteGrade.find_or_create_by!(athlete_slug: athlete.slug, season_slug: nfl_season.slug) do |g|
      g.overall_grade = base_grade
      g.games_played  = rand(10..14)
      g.snaps         = rand(400..900)
    end

    puts "Grade: #{athlete.person.full_name} (Pick #{athlete.draft_pick}) — #{base_grade}"
  end
end

puts "AthleteGrades: #{AthleteGrade.count}"
