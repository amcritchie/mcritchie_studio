class ExpenseUpload < ApplicationRecord
  include Sluggable

  belongs_to :user
  has_many :expense_transactions, dependent: :destroy
  has_one_attached :file

  after_create :set_slug_from_id

  validates :filename, presence: true

  CARD_TYPES = {
    "citi" => "Citi",
    "capital_one_spark" => "Capital One Spark",
    "amex_platinum" => "Amex Platinum",
    "robinhood" => "Robinhood"
  }.freeze

  STATUS_VALUES = %w[pending processed evaluated].freeze

  scope :recent, -> { order(created_at: :desc) }

  def pending?
    status == "pending"
  end

  def processed?
    status == "processed"
  end

  def evaluated?
    status == "evaluated"
  end

  def card_type_display
    CARD_TYPES[card_type] || card_type&.titleize || "Unknown"
  end

  private

  def set_slug_from_id
    update_column(:slug, "upload-#{id}")
  end

  def name_slug
    "upload-#{id}"
  end
end
