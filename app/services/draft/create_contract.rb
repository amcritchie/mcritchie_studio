module Draft
  class CreateContract
    attr_reader :person_slug, :team_slug, :position

    def initialize(person_slug:, team_slug:, position: nil)
      @person_slug = person_slug
      @team_slug   = team_slug
      @position    = position
    end

    def call
      person = Person.find_by(slug: person_slug)
      raise "Person not found: #{person_slug}" unless person

      team = Team.find_by(slug: team_slug)
      raise "Team not found: #{team_slug}" unless team

      athlete = Athlete.find_by(person_slug: person_slug)
      resolved_position = position || athlete&.position || "QB"

      # Expire college contracts
      person.contracts.where(contract_type: "college").find_each do |c|
        unless c.expired?
          c.update!(expires_at: Date.current)
          puts "  Expired college contract: #{c.slug}"
        end
      end

      # Create draft contract
      contract = Contract.find_or_create_by!(person_slug: person.slug, team_slug: team.slug) do |c|
        c.contract_type = "draft_pick"
        c.position      = resolved_position
      end
      puts "Draft contract: #{person.full_name} → #{team.name} (#{resolved_position}) [#{contract.slug}]"

      # Add to team's current roster
      add_to_roster(team, person, resolved_position)

      contract
    end

    private

    def add_to_roster(team, person, pos)
      roster = team.current_roster
      return puts("  No roster found for #{team.name}") unless roster

      side = PositionConcern.side_for(pos)
      existing_depth = roster.roster_spots.where(position: pos).maximum(:depth) || 0
      new_depth = existing_depth + 1

      RosterSpot.find_or_create_by!(roster: roster, person_slug: person.slug, position: pos) do |rs|
        rs.side  = side
        rs.depth = new_depth
      end
      puts "  Added to #{team.name} roster: #{pos} depth #{new_depth}"
    end
  end
end
