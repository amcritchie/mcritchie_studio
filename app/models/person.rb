class Person < ApplicationRecord
  include Sluggable

  has_one :athlete_profile, class_name: "Athlete", foreign_key: :person_slug, primary_key: :slug
  has_many :contracts, foreign_key: :person_slug, primary_key: :slug
  has_many :teams, through: :contracts
  has_many :roster_spots, foreign_key: :person_slug, primary_key: :slug

  validates :first_name, :last_name, presence: true

  def name_slug
    "#{first_name} #{last_name}".parameterize
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
