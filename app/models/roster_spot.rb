class RosterSpot < ApplicationRecord
  belongs_to :roster
  belongs_to :person, foreign_key: :person_slug, primary_key: :slug

  validates :person_slug, presence: true
  validates :position, presence: true
  validates :side, presence: true
  validates :depth, presence: true
  validates :depth, uniqueness: { scope: [:roster_id, :position] }

  def to_param
    nil
  end
end
