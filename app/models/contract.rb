class Contract < ApplicationRecord
  include Sluggable

  CONTRACT_TYPES = %w[college active draft_pick mock_pick].freeze

  belongs_to :person, foreign_key: :person_slug, primary_key: :slug
  belongs_to :team, foreign_key: :team_slug, primary_key: :slug

  validates :person_slug, uniqueness: { scope: :team_slug }
  validates :contract_type, inclusion: { in: CONTRACT_TYPES }

  def name_slug
    "#{person_slug}-#{team_slug}"
  end

  def active?
    expires_at.nil? || expires_at > Date.current
  end

  def expired?
    expires_at.present? && expires_at <= Date.current
  end
end
