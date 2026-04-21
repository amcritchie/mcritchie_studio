class Roster < ApplicationRecord
  include Sluggable

  belongs_to :team, foreign_key: :team_slug, primary_key: :slug
  belongs_to :slate, foreign_key: :slate_slug, primary_key: :slug

  has_many :roster_spots, dependent: :destroy

  validates :team_slug, presence: true, uniqueness: { scope: :slate_slug }
  validates :slate_slug, presence: true

  def starters
    roster_spots.where(depth: 1)
  end

  def offense_starters
    roster_spots.where(depth: 1, side: "offense")
  end

  def defense_starters
    roster_spots.where(depth: 1, side: "defense")
  end

  def person_at(position, depth: 1)
    spot = roster_spots.find_by(position: position, depth: depth)
    spot&.person
  end

  def name_slug
    "#{team_slug}-#{slate_slug}"
  end
end
