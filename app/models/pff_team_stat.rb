class PffTeamStat < ApplicationRecord
  include Sluggable

  belongs_to :team, foreign_key: :team_slug, primary_key: :slug
  belongs_to :season, foreign_key: :season_slug, primary_key: :slug

  validates :team_slug, presence: true
  validates :season_slug, presence: true
  validates :stat_type, presence: true
  validates :team_slug, uniqueness: { scope: [:season_slug, :stat_type] }

  scope :for_season, ->(slug) { where(season_slug: slug) }
  scope :of_type, ->(type) { where(stat_type: type) }

  def name_slug
    "#{team_slug}-#{season_slug}-#{stat_type}"
  end
end
