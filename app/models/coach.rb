class Coach < ApplicationRecord
  include Sluggable

  belongs_to :person, foreign_key: :person_slug, primary_key: :slug
  belongs_to :team, foreign_key: :team_slug, primary_key: :slug
  has_many :coach_rankings, foreign_key: :coach_slug, primary_key: :slug
  has_many :image_caches, as: :owner, class_name: "ImageCache"

  ROLES = %w[head_coach offensive_coordinator defensive_coordinator special_teams_coordinator].freeze
  LEANS = %w[offense defense].freeze
  SPORTS = %w[football soccer].freeze

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :sport, presence: true, inclusion: { in: SPORTS }
  validates :lean, inclusion: { in: LEANS }, allow_nil: true
  validates :person_slug, uniqueness: { scope: [:team_slug, :role] }

  def name_slug
    "#{person_slug}-#{team_slug}-#{role.parameterize}"
  end

  def headshot_url(width: 400)
    cache = image_caches.detect { |c| c.purpose == "headshot" && c.variant == width.to_s }
    cache&.url
  end
end
