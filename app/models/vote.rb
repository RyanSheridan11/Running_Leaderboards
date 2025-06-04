class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :play


  validates :user_id, uniqueness: { scope: :play_id,
            message: "can only vote once per play" }

  after_save :update_play_score
  after_destroy :update_play_score

  private

end
