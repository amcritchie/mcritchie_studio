class Activity < ApplicationRecord
  belongs_to :agent, foreign_key: :agent_slug, primary_key: :slug, optional: true
  belongs_to :task, foreign_key: :task_slug, primary_key: :slug, optional: true

  after_create :set_slug

  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(activity_type: type) }

  private

  def set_slug
    update_column(:slug, "activity-#{id}")
  end
end
