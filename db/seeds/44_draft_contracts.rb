require_relative "../../app/models/concerns/position_concern"

# Test draft_pick contracts: Cam Ward → Titans, Will Campbell → Patriots
DRAFT_PICKS = [
  { person_slug: "cam-ward",       team_slug: "tennessee-titans",       position: "QB" },
  { person_slug: "will-campbell",   team_slug: "new-england-patriots",   position: "OT" }
]

nfl_season = Season.find_by(year: 2025, league: "nfl")
offseason  = nfl_season&.slates&.find_by(sequence: 0)

DRAFT_PICKS.each do |data|
  person = Person.find_by(slug: data[:person_slug])
  team   = Team.find_by(slug: data[:team_slug])
  next unless person && team

  # Expire college contracts
  person.contracts.where(contract_type: "college").find_each do |c|
    c.update!(expires_at: Date.current) unless c.expired?
    puts "  Expired college contract: #{c.slug}"
  end

  # Create draft contract
  contract = Contract.find_or_create_by!(person_slug: person.slug, team_slug: team.slug) do |c|
    c.contract_type = "draft_pick"
    c.position      = data[:position]
  end
  puts "Draft: #{person.full_name} → #{team.name} (#{data[:position]}) [#{contract.slug}]"

  # Add to offseason roster
  if offseason
    roster = Roster.find_by(team_slug: team.slug, slate_slug: offseason.slug)
    if roster
      side = PositionConcern.side_for(data[:position])
      existing_depth = roster.roster_spots.where(position: data[:position]).maximum(:depth) || 0
      RosterSpot.find_or_create_by!(roster: roster, person_slug: person.slug, position: data[:position]) do |rs|
        rs.side  = side
        rs.depth = existing_depth + 1
      end
      puts "  Added to #{team.name} roster at depth #{existing_depth + 1}"
    end
  end
end
