class Agent < ApplicationRecord
  include Sluggable

  has_many :tasks, foreign_key: :agent_slug, primary_key: :slug, dependent: :nullify
  has_many :activities, foreign_key: :agent_slug, primary_key: :slug, dependent: :destroy
  has_many :usages, foreign_key: :agent_slug, primary_key: :slug, dependent: :destroy
  has_many :skill_assignments, foreign_key: :agent_slug, primary_key: :slug, dependent: :destroy
  has_many :skills, through: :skill_assignments

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :active, -> { where(status: "active") }

  AVATAR_COLORS = %w[#EF4444 #F97316 #EAB308 #22C55E #06B6D4 #3B82F6 #8B5CF6 #EC4899].freeze

  def name_slug
    name.parameterize
  end

  def avatar_initials
    name.to_s.first.presence&.upcase || "?"
  end

  def avatar_color
    AVATAR_COLORS[Digest::MD5.hexdigest(slug.to_s).hex % AVATAR_COLORS.size]
  end
end
