class News < ApplicationRecord
  STAGES = %w[new reviewed processed refined concluded archived].freeze

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :stage, inclusion: { in: STAGES }

  before_validation :generate_slug, on: :create
  before_create :set_initial_position
  before_save :set_stage_timestamp, if: :stage_changed?

  scope :by_stage, ->(stage) { where(stage: stage) }
  scope :ordered, -> { order(Arel.sql("position DESC NULLS LAST, created_at DESC")) }

  def to_param
    slug
  end

  # Transition methods
  def review!
    update!(stage: "reviewed")
  end

  def process_news!
    update!(stage: "processed")
  end

  def refine!
    update!(stage: "refined")
  end

  def conclude!
    update!(stage: "concluded")
  end

  def archive!
    update!(stage: "archived")
  end

  private

  def set_stage_timestamp
    case stage
    when "reviewed"  then self.reviewed_at = Time.current
    when "processed" then self.processed_at = Time.current
    when "refined"   then self.refined_at = Time.current
    when "concluded" then self.concluded_at = Time.current
    when "archived"  then self.archived_at = Time.current
    end
    unless new_record?
      self.position = (News.where(stage: stage).maximum(:position) || 0) + 100
    end
  end

  def set_initial_position
    self.position ||= (News.where(stage: stage).maximum(:position) || 0) + 100
  end

  def generate_slug
    self.slug ||= "news-#{SecureRandom.hex(6)}"
  end
end
