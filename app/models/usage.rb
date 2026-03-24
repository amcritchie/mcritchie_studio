class Usage < ApplicationRecord
  include Sluggable

  belongs_to :agent, foreign_key: :agent_slug, primary_key: :slug, optional: true

  validates :period_date, presence: true
  validates :period_type, presence: true

  scope :recent, -> { order(period_date: :desc) }
  scope :for_agent, ->(slug) { where(agent_slug: slug) }

  def name_slug
    [agent_slug, period_date, period_type, model].compact.join("-")
  end
end
