# Per-team DepthChart with one DepthChartEntry per (person, position).
# Runs BEFORE 31_rosters.rb so rosters can derive depth from the depth chart.
#
# Re-seed semantics:
#   * locked entries keep their (depth, position) — auto-rank slots around them
#   * unlocked entries get reranked by overall_grade_pff DESC, salary DESC
#   * new contracts get added; departed players' entries get dropped
require_relative "../../app/models/concerns/position_concern"

nfl_season = Season.find_by(year: 2025, league: "nfl")

if nfl_season
  grades_by_athlete   = AthleteGrade.where(season_slug: nfl_season.slug).index_by(&:athlete_slug)
  athletes_by_person  = Athlete.where(sport: "football").index_by(&:person_slug)

  Team.nfl.find_each do |team|
    chart = DepthChart.find_or_create_by!(team_slug: team.slug)

    contracts = team.contracts.where(contract_type: "active").includes(:person).to_a

    # Build the desired (person, position) set with rank info
    desired = contracts.map do |contract|
      pos      = PositionConcern.normalize_position(contract.position) || "QB"
      side     = PositionConcern.side_for(pos)
      athlete  = athletes_by_person[contract.person_slug]
      grade    = athlete && grades_by_athlete[athlete.slug]
      {
        person_slug: contract.person_slug,
        position:    pos,
        side:        side,
        score:       grade&.overall_grade_pff,
        salary:      contract.annual_value_cents
      }
    end

    desired_keys = desired.map { |d| [d[:person_slug], d[:position]] }.to_set

    # Drop entries no longer matching any contract
    chart.depth_chart_entries.find_each do |entry|
      unless desired_keys.include?([entry.person_slug, entry.position])
        entry.destroy if !entry.locked
      end
    end

    # Group by position; assign depth, respecting locked rows
    desired.group_by { |d| d[:position] }.each do |position, rows|
      existing      = chart.depth_chart_entries.where(position: position).to_a
      existing_by_p = existing.index_by(&:person_slug)
      locked_rows   = existing.select(&:locked).sort_by(&:depth)
      locked_persons = locked_rows.map(&:person_slug).to_set

      unlocked = rows.reject { |r| locked_persons.include?(r[:person_slug]) }
      ranked   = unlocked.sort_by { |r| [-(r[:score] || -1.0), -(r[:salary] || 0)] }

      slots_total = rows.size
      locked_depths = locked_rows.map(&:depth)
      free_depths   = (1..slots_total).to_a - locked_depths

      ranked.each_with_index do |row, i|
        depth = free_depths[i] || (slots_total + i + 1)  # fallback if locked depth > slots
        entry = existing_by_p[row[:person_slug]] ||
                chart.depth_chart_entries.build(person_slug: row[:person_slug], position: position)
        entry.assign_attributes(depth: depth, side: row[:side])
        entry.save!
      end
    end

    puts "DepthChart: #{team.short_name || team.name} — #{chart.depth_chart_entries.count} entries"
  end
end

puts "DepthCharts: #{DepthChart.count}, DepthChartEntries: #{DepthChartEntry.count}"
