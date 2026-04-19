class Team < ApplicationRecord
  include Sluggable

  has_many :contracts, foreign_key: :team_slug, primary_key: :slug
  has_many :people, through: :contracts

  validates :name, presence: true

  def name_slug
    name.parameterize
  end
end
