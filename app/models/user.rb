class User < ApplicationRecord
  has_secure_password validations: false
  has_many :runs, dependent: :destroy
  has_many :plays, dependent: :destroy
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :firstname, presence: true
  validates :lastname, presence: true
  validates :password, length: { minimum: 4 }, if: -> { password.present? }

  before_validation :normalize_email
  before_create :set_first_user_as_admin

  # Class method for case-insensitive email lookup
  def self.find_by_email(email)
    return nil if email.blank?
    where("LOWER(email) = ?", email.to_s.strip.downcase).first
  end

  def has_password?
    password_digest.present?
  end

  def needs_password_setup?
    !has_password?
  end

  def full_name
    "#{firstname} #{lastname}"
  end

  def five_k_runs
    runs.five_k.order(:time)
  end

  def bronco_runs
    runs.bronco.order(:time)
  end

  def track_login!
    self.update_columns(
      last_login_at: Time.current,
      login_count: (login_count || 0) + 1
    )
  end

  def login_status
    return "Never logged in" unless last_login_at

    time_ago = Time.current - last_login_at
    case time_ago
    when 0..1.hour
      "Active now"
    when 1.hour..1.day
      "Active today"
    when 1.day..1.week
      "Active this week"
    when 1.week..1.month
      "Active this month"
    else
      "Inactive (#{last_login_at.strftime('%b %d, %Y')})"
    end
  end

  private

  def normalize_email
    self.email = email&.strip&.downcase
  end

  def set_first_user_as_admin
    self.admin = true if User.count == 0
  end
end
