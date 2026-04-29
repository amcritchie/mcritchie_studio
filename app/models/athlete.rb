class Athlete < ApplicationRecord
  include Sluggable

  belongs_to :person, foreign_key: :person_slug, primary_key: :slug

  has_many :grades, class_name: "AthleteGrade", foreign_key: :athlete_slug, primary_key: :slug
  has_many :pff_stats, foreign_key: :athlete_slug, primary_key: :slug
  has_many :image_caches, as: :owner, class_name: "ImageCache"

  validates :person_slug, presence: true, uniqueness: true
  validates :sport, presence: true

  def name_slug
    "#{person_slug}-athlete"
  end

  def headshot_url(width: 400)
    cache = image_caches.detect { |c| c.purpose == "headshot" && c.variant == width.to_s }
    cache&.url
  end
end
