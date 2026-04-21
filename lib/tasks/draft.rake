namespace :draft do
  desc "Create draft contract. PERSON=cam-ward TEAM=tennessee-titans POSITION=QB"
  task create_contract: :environment do
    person_slug = ENV.fetch("PERSON") { abort "PERSON= required (e.g. cam-ward)" }
    team_slug   = ENV.fetch("TEAM")   { abort "TEAM= required (e.g. tennessee-titans)" }
    position    = ENV["POSITION"]

    puts "Creating draft contract: #{person_slug} → #{team_slug}..."
    Draft::CreateContract.new(
      person_slug: person_slug,
      team_slug: team_slug,
      position: position
    ).call
  end
end
