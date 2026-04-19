class Task < ApplicationRecord
  belongs_to :agent, foreign_key: :agent_slug, primary_key: :slug, optional: true

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :stage, inclusion: { in: %w[new queued in_progress done failed archived] }
  validates :priority, inclusion: { in: [0, 1, 2] }

  before_validation :generate_slug, on: :create
  before_create :set_initial_position
  before_save :set_stage_timestamp, if: :stage_changed?

  def to_param
    slug
  end

  scope :by_stage, ->(stage) { where(stage: stage) }
  scope :recent, -> { order(created_at: :desc) }
  scope :ordered, -> { order(Arel.sql("position ASC NULLS LAST, created_at DESC")) }

  def queue!
    update!(stage: "queued")
  end

  def start!
    update!(stage: "in_progress")
  end

  def complete!(result_data = {})
    update!(stage: "done", result: result_data)
  end

  def fail!(message = nil)
    update!(stage: "failed", error_message: message)
  end

  def archive!
    update!(stage: "archived")
  end

  private

  def set_stage_timestamp
    case stage
    when "queued"      then self.queued_at = Time.current
    when "in_progress" then self.started_at = Time.current
    when "done"        then self.completed_at = Time.current
    when "failed"      then self.failed_at = Time.current
    when "archived"    then self.archived_at = Time.current
    end
    self.position = (Task.where(stage: stage).maximum(:position) || -1) + 1 unless new_record?
  end

  def set_initial_position
    self.position ||= (Task.where(stage: stage).maximum(:position) || -1) + 1
  end

  def generate_slug
    self.slug ||= "task-#{SecureRandom.hex(6)}"
  end
end
