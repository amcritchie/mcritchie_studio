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

  TRANSITIONS = {
    "new"         => %w[queued],
    "queued"      => %w[in_progress failed],
    "in_progress" => %w[done failed],
    "done"        => %w[archived],
    "failed"      => %w[archived queued],
    "archived"    => %w[]
  }.freeze

  def queue!
    transition_to!("queued", queued_at: Time.current)
  end

  def start!
    transition_to!("in_progress", started_at: Time.current)
  end

  def complete!(result_data = {})
    transition_to!("done", completed_at: Time.current, result: result_data)
  end

  def fail!(message = nil)
    transition_to!("failed", failed_at: Time.current, error_message: message)
  end

  def archive!
    transition_to!("archived", archived_at: Time.current)
  end

  private

  def transition_to!(new_stage, **attrs)
    allowed = TRANSITIONS.fetch(stage, [])
    unless allowed.include?(new_stage)
      raise "Cannot transition from #{stage} to #{new_stage} (allowed: #{allowed.join(', ')})"
    end
    update!(stage: new_stage, **attrs)
  end

  def generate_slug
    self.slug ||= "task-#{SecureRandom.hex(6)}"
  end
end
