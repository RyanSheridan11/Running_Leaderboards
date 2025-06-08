class RaceDeadline < ApplicationRecord
  validates :race_type, presence: true, inclusion: { in: %w[5k bronco] }
  validates :due_date, presence: true
  validates :start_date, presence: true

  scope :active, -> { where(active: true) }
  scope :for_race_type, ->(type) { where(race_type: type) }

  def overdue?
    due_date < Date.current
  end

  def days_remaining
    (due_date - Date.current).to_i
  end

  def users_with_submissions
    User.joins(:runs).where(runs: { race_type: race_type, date: start_date..due_date }).distinct
  end

  def users_without_submissions
    User.where.not(id: users_with_submissions.pluck(:id))
  end
end
