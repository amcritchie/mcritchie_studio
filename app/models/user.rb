class User < ApplicationRecord
  include Sluggable

  has_secure_password

  validates :email, presence: true, uniqueness: true

  before_save :set_name_parts, if: -> { name_changed? }

  def self.from_omniauth(auth)
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    user = find_by(email: auth.info.email)
    if user
      user.update!(provider: auth.provider, uid: auth.uid)
      return user
    end

    create!(
      email: auth.info.email,
      name: auth.info.name,
      provider: auth.provider,
      uid: auth.uid,
      password: SecureRandom.hex(16)
    )
  end

  def display_name
    name.presence || email.split("@").first.capitalize
  end

  def admin?
    role == "admin"
  end

  private

  def set_name_parts
    parts = name.to_s.strip.split(" ")
    self.first_name = parts.first
    self.last_name = parts.last if parts.size > 1
  end

  def name_slug
    "#{name}-#{email}".downcase.gsub(/\s+/, "-")
  end
end
