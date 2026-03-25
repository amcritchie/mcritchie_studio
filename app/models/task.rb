class Task < ApplicationRecord
  belongs_to :agent, foreign_key: :agent_slug, primary_key: :slug, optional: true

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :stage, inclusion: { in: %w[new queued in_progress done failed archived] }
  validates :priority, inclusion: { in: [0, 1, 2] }

  before_validation :generate_slug, on: :create

  def to_param
    slug
  end

  scope :by_stage, ->(stage) { where(stage: stage) }
  scope :active, -> { where(stage: %w[new queued in_progress]) }
  scope :recent, -> { order(created_at: :desc) }

  def queue!
    update!(stage: "queued", queued_at: Time.current)
  end

  def start!
    update!(stage: "in_progress", started_at: Time.current)
  end

  def complete!(result_data = {})
    update!(stage: "done", completed_at: Time.current, result: result_data)
  end

  def fail!(message = nil)
    update!(stage: "failed", failed_at: Time.current, error_message: message)
  end

  def archive!
    update!(stage: "archived", archived_at: Time.current)
  end

  private

  def generate_slug
    self.slug ||= "task-#{SecureRandom.hex(6)}"
  end
end
