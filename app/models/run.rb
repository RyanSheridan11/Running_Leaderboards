class Run < ApplicationRecord
  belongs_to :user
  validates :date, presence: true
  validates :time, presence: true, numericality: { greater_than: 0 }
  validates :race_type, inclusion: { in: %w[5k bronco] }

  scope :five_k, -> { where(race_type: "5k") }
  scope :bronco, -> { where(race_type: "bronco") }
  scope :from_strava, -> { where(source: "strava") }
  scope :manual_entry, -> { where(souce: "manual") }

  def from_strava?
    source == "strava"
  end
end
