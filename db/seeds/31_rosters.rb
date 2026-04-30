require_relative "../../app/models/concerns/position_concern"

# Builds Roster + RosterSpot for each NFL team's offseason slate.
# Depth is denormalized from DepthChart (which 31_depth_charts.rb populated).
nfl_season = Season.find_by(year: 2025, league: "nfl")
offseason  = nfl_season&.slates&.find_by(sequence: 0)

if offseason
  Team.nfl.find_each do |team|
    roster = Roster.find_or_create_by!(team_slug: team.slug, slate_slug: offseason.slug)
    chart  = team.depth_chart

    spot_count = 0
    chart&.depth_chart_entries&.find_each do |entry|
      RosterSpot.find_or_create_by!(roster: roster, position: entry.position, depth: entry.depth) do |rs|
        rs.person_slug = entry.person_slug
        rs.side        = entry.side
      end
      spot_count += 1
    end

    puts "Roster: #{team.name} — #{spot_count} spots"
  end
end

puts "Rosters: #{Roster.count}, RosterSpots: #{RosterSpot.count}"
