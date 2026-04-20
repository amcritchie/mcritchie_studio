class PeopleController < ApplicationController
  skip_before_action :require_authentication, only: [:index]

  def index
    @people = Person.includes(:teams, :athlete_profile, contracts: :team).order(:last_name, :first_name)
  end

  def search
    query = params[:q].to_s.strip
    people = if query.present?
      Person.where("first_name ILIKE :q OR last_name ILIKE :q OR slug ILIKE :q OR aliases::text ILIKE :q",
                    q: "%#{query}%")
            .order(created_at: :desc)
            .limit(20)
    else
      Person.order(created_at: :desc).limit(10)
    end

    render json: people.map { |p|
      { id: p.id, slug: p.slug, full_name: p.full_name, aliases: p.aliases, teams: p.teams.pluck(:name) }
    }
  end
end
