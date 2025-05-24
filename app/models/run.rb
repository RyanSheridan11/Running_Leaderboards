class Run < ApplicationRecord
  belongs_to :user
  validates :date, presence: true
  validates :time, presence: true, numericality: { greater_than: 0 }
end
