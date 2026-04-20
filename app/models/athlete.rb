class Athlete < ApplicationRecord
  include Sluggable

  belongs_to :person, foreign_key: :person_slug, primary_key: :slug

  validates :person_slug, presence: true, uniqueness: true
  validates :sport, presence: true

  def name_slug
    "#{person_slug}-athlete"
  end
end
