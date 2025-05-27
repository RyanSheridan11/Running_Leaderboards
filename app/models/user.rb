class User < ApplicationRecord
  has_secure_password
  has_many :runs, dependent: :destroy
  has_many :plays, dependent: :destroy
  has_many :votes, dependent: :destroy
  validates :username, presence: true, uniqueness: true

  before_create :set_first_user_as_admin

  def five_k_runs
    runs.five_k.order(:time)
  end

  def bronco_runs
    runs.bronco.order(:time)
  end

  def voted_plays
    votes.includes(:play).map(&:play)
  end

  private

  def set_first_user_as_admin
    self.admin = true if User.count == 0
  end
end
