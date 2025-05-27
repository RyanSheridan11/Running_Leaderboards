class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :play

  validates :ranking, presence: true,
            inclusion: { in: 1..10, message: "must be between 1 and 10" }
  validates :user_id, uniqueness: { scope: :play_id,
            message: "can only vote once per play" }

  after_save :update_play_score
  after_destroy :update_play_score

  private

  def update_play_score
    play.calculate_score!
  end
end
