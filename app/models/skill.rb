class Skill < ApplicationRecord
  include Sluggable

  has_many :skill_assignments, foreign_key: :skill_slug, primary_key: :slug, dependent: :destroy
  has_many :agents, through: :skill_assignments

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  def name_slug
    name.parameterize
  end
end
