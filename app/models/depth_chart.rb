class DepthChart < ApplicationRecord
  include Sluggable

  belongs_to :team, foreign_key: :team_slug, primary_key: :slug
  has_many :depth_chart_entries, foreign_key: :depth_chart_slug, primary_key: :slug, dependent: :destroy

  validates :team_slug, presence: true, uniqueness: true

  def name_slug
    "#{team_slug}-depth"
  end
end
