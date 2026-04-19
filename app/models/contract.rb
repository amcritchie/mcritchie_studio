class Contract < ApplicationRecord
  include Sluggable

  belongs_to :person, foreign_key: :person_slug, primary_key: :slug
  belongs_to :team, foreign_key: :team_slug, primary_key: :slug

  validates :person_slug, uniqueness: { scope: :team_slug }

  def name_slug
    "#{person_slug}-#{team_slug}"
  end
end
