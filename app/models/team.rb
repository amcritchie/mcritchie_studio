class Team < ApplicationRecord
  include Sluggable

  has_many :contracts, foreign_key: :team_slug, primary_key: :slug
  has_many :people, through: :contracts

  validates :name, presence: true

  scope :nfl, -> { where(league: "nfl") }
  scope :ncaa, -> { where(league: "ncaa") }
  scope :fifa, -> { where(league: "fifa") }
  scope :football, -> { where(sport: "football") }
  scope :soccer, -> { where(sport: "soccer") }

  def name_slug
    name.parameterize
  end
end
