class User < ApplicationRecord
  has_secure_password
  has_many :runs, dependent: :destroy
  has_many :plays, dependent: :destroy
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :firstname, presence: true
  validates :lastname, presence: true

  before_validation :normalize_username
  before_validation :generate_unique_username, if: :new_record?
  before_create :set_first_user_as_admin

  # Class method for case-insensitive username lookup
  def self.find_by_username(username)
    return nil if username.blank?
    where("LOWER(username) = ?", username.to_s.strip.downcase).first
  end

  def full_name
    "#{firstname} #{lastname}"
  end

  private

  def normalize_username
    self.username = username&.strip&.downcase
  end

  def generate_unique_username
    return if username.present? && !username_from_names?

    base_username = "#{firstname}#{lastname&.first}".downcase.gsub(/[^a-z0-9]/, "")
    return unless base_username.present?

    # Start with the base username
    candidate = base_username
    counter = 1

    # Keep adding numbers until we find a unique username (case-insensitive check)
    while User.where("LOWER(username) = ?", candidate.downcase).where.not(id: id).exists?
      candidate = "#{base_username}#{counter}"
      counter += 1
    end

    self.username = candidate
  end

  def username_from_names?
    return false unless firstname.present? && lastname.present?
    base = "#{firstname}#{lastname.first}".downcase.gsub(/[^a-z0-9]/, "")
    username&.match?(/^#{Regexp.escape(base)}\d*$/)
  end

  def five_k_runs
    runs.five_k.order(:time)
  end

  def bronco_runs
    runs.bronco.order(:time)
  end

  private

  def set_first_user_as_admin
    self.admin = true if User.count == 0
  end
end
