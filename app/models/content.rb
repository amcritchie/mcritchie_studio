class Content < ApplicationRecord
  STAGES = %w[idea hook script assets assembly posted reviewed].freeze

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :stage, inclusion: { in: STAGES }

  belongs_to :source_news, class_name: "News", foreign_key: :source_news_slug, primary_key: :slug, optional: true
  belongs_to :rival_team, class_name: "Team", foreign_key: :rival_team_slug, primary_key: :slug, optional: true

  before_validation :generate_slug, on: :create
  before_create :set_initial_position
  before_save :set_stage_timestamp, if: :stage_changed?

  scope :by_stage, ->(stage) { where(stage: stage) }
  scope :ordered, -> { order(Arel.sql("position DESC NULLS LAST, created_at DESC")) }

  def to_param
    slug
  end

  # Transition methods
  def hook!
    update!(stage: "hook")
  end

  def script!
    update!(stage: "script")
  end

  def assets!
    update!(stage: "assets")
  end

  def assemble!
    update!(stage: "assembly")
  end

  def post!
    update!(stage: "posted")
  end

  def review!
    update!(stage: "reviewed")
  end

  def archive!
    update!(stage: "idea")
  end

  private

  def set_stage_timestamp
    case stage
    when "hook"     then self.hooked_at = Time.current
    when "script"   then self.scripted_at = Time.current
    when "assets"   then self.asset_at = Time.current
    when "assembly" then self.assembled_at = Time.current
    when "posted"   then self.posted_at = Time.current
    when "reviewed" then self.reviewed_at = Time.current
    end
    unless new_record?
      self.position = (Content.where(stage: stage).maximum(:position) || 0) + 100
    end
  end

  def set_initial_position
    self.position ||= (Content.where(stage: stage).maximum(:position) || 0) + 100
  end

  def generate_slug
    self.slug ||= "content-#{SecureRandom.hex(6)}"
  end
end
