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
  scope :paused, -> { where(status: "paused") }
  scope :inactive, -> { where(status: "inactive") }

  def touch_active!
    update_column(:last_active_at, Time.current)
  end

  def name_slug
    name.parameterize
  end
end
