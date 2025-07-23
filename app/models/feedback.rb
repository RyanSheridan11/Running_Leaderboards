class Feedback < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :content, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_event, ->(event) { where(event: event) }
end
