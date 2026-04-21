class AthleteGrade < ApplicationRecord
  include Sluggable

  belongs_to :athlete, foreign_key: :athlete_slug, primary_key: :slug
  belongs_to :season, foreign_key: :season_slug, primary_key: :slug

  validates :athlete_slug, presence: true, uniqueness: { scope: :season_slug }
  validates :season_slug, presence: true

  def name_slug
    "#{athlete_slug}-#{season_slug}"
  end
end
