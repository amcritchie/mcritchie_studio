class DepthChartEntry < ApplicationRecord
  belongs_to :depth_chart, foreign_key: :depth_chart_slug, primary_key: :slug
  belongs_to :person, foreign_key: :person_slug, primary_key: :slug

  validates :person_slug, :position, :side, :depth, presence: true
  validates :person_slug, uniqueness: { scope: [:depth_chart_slug, :position] }

  scope :offense,        -> { where(side: "offense") }
  scope :defense,        -> { where(side: "defense") }
  scope :special_teams,  -> { where(side: "special_teams") }
end
