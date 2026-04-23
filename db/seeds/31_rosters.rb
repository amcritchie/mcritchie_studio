require_relative "../../app/models/concerns/position_concern"

nfl_season = Season.find_by(year: 2025, league: "nfl")
offseason  = nfl_season&.slates&.find_by(sequence: 0)

if offseason
  Team.nfl.find_each do |team|
    roster = Roster.find_or_create_by!(team_slug: team.slug, slate_slug: offseason.slug)

    # Get all active contracts sorted by salary DESC (highest paid = depth 1)
    contracts = team.contracts.where(contract_type: "active")
                    .where.not(annual_value_cents: nil)
                    .order(annual_value_cents: :desc)

    depth_tracker = Hash.new(0)
    spot_count = 0

    contracts.each do |contract|
      pos  = PositionConcern.normalize_position(contract.position) || "QB"
      side = PositionConcern.side_for(pos)
      depth_tracker[pos] += 1
      depth = depth_tracker[pos]

      RosterSpot.find_or_create_by!(roster: roster, position: pos, depth: depth) do |rs|
        rs.person_slug = contract.person_slug
        rs.side        = side
      end
      spot_count += 1
    end

    puts "Roster: #{team.name} — #{spot_count} spots"
  end
end

puts "Rosters: #{Roster.count}, RosterSpots: #{RosterSpot.count}"
