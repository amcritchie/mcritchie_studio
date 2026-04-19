class News
  class Process
    attr_reader :created_records

    def initialize(news)
      @news = news
      @created_records = []
    end

    def call
      # Generate slugs
      primary_person_slug = @news.primary_person&.parameterize
      primary_team_slug = @news.primary_team&.parameterize
      secondary_person_slug = @news.secondary_person&.parameterize
      secondary_team_slug = @news.secondary_team&.parameterize

      # Find or create Person records
      primary_person_record = find_or_create_person(@news.primary_person, "primary_person") if @news.primary_person.present?
      secondary_person_record = find_or_create_person(@news.secondary_person, "secondary_person") if @news.secondary_person.present?

      # Find Team records (from seeded data)
      primary_team_record = find_team(primary_team_slug, "primary_team") if primary_team_slug.present?
      secondary_team_record = find_team(secondary_team_slug, "secondary_team") if secondary_team_slug.present?

      # Create Contract associations
      create_contract(primary_person_record, primary_team_record) if primary_person_record && primary_team_record
      create_contract(secondary_person_record, secondary_team_record) if secondary_person_record && secondary_team_record

      # Update slugs on News record
      @news.update!(
        primary_person_slug: primary_person_slug,
        primary_team_slug: primary_team_slug,
        secondary_person_slug: secondary_person_slug,
        secondary_team_slug: secondary_team_slug
      )
      @news.process_news!
      @news
    end

    private

    def find_or_create_person(full_name, role)
      parts = full_name.strip.split(/\s+/, 2)
      first_name = parts[0]
      last_name = parts[1] || parts[0]
      slug = full_name.parameterize

      existing = Person.find_by(slug: slug)
      if existing
        @created_records << { role: role, type: "Person", slug: slug, status: "found" }
        existing
      else
        person = Person.create!(first_name: first_name, last_name: last_name, slug: slug, athlete: true)
        @created_records << { role: role, type: "Person", slug: slug, status: "created" }
        person
      end
    end

    def find_team(slug, role)
      team = Team.find_by(slug: slug)
      if team
        @created_records << { role: role, type: "Team", slug: slug, status: "found" }
      else
        @created_records << { role: role, type: "Team", slug: slug, status: "not_found" }
      end
      team
    end

    def create_contract(person, team)
      Contract.find_or_create_by!(person_slug: person.slug, team_slug: team.slug)
    end
  end
end
