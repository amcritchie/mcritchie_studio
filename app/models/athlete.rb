class Athlete < ApplicationRecord
  include Sluggable

  belongs_to :person, foreign_key: :person_slug, primary_key: :slug

  has_many :grades, class_name: "AthleteGrade", foreign_key: :athlete_slug, primary_key: :slug
  has_many :pff_stats, foreign_key: :athlete_slug, primary_key: :slug

  validates :person_slug, presence: true, uniqueness: true
  validates :sport, presence: true

  def name_slug
    "#{person_slug}-athlete"
  end

  def headshot_url
    return nil unless headshot_s3_key.present?
    Studio::S3.url(key: headshot_s3_key)
  end
end
