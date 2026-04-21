require_relative "../../app/models/concerns/position_concern"

nfl_season = Season.find_by(year: 2025, league: "nfl")
offseason  = nfl_season&.slates&.find_by(sequence: 0)

if offseason
  Team.nfl.find_each do |team|
    roster = Roster.find_or_create_by!(team_slug: team.slug, slate_slug: offseason.slug)

    # Add the seeded star as the starter
    star_contract = team.contracts.where.not(annual_value_cents: nil).first
    next unless star_contract

    person  = star_contract.person
    pos     = star_contract.position || "QB"
    side    = PositionConcern.side_for(pos)

    RosterSpot.find_or_create_by!(roster: roster, position: pos, depth: 1) do |rs|
      rs.person_slug = person.slug
      rs.side        = side
    end

    puts "Roster: #{team.name} — #{person.full_name} (#{pos})"
  end
end

puts "Rosters: #{Roster.count}, RosterSpots: #{RosterSpot.count}"
