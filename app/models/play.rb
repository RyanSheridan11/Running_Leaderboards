class Play < ApplicationRecord
  belongs_to :user
  has_many :votes, dependent: :destroy

  validates :title, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }
  validates :video_url, format: {
    with: /\A(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.+\z/i,
    message: "must be a valid YouTube URL"
  }, allow_blank: true
  validates :status, inclusion: { in: %w[pending approved rejected] }

  scope :approved, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }
  scope :top_rated, -> { approved.order(score: :desc) }

  def calculate_score!
    total_score = votes.sum do |vote|
      # Higher ranking (lower number) = more points
      # 1st place = 10 points, 2nd = 9 points, etc.
      [11 - vote.ranking, 1].max
    end
    update!(score: total_score)
  end

  def youtube_embed_url
    return nil if video_url.blank?

    video_id = youtube_video_id
    "https://www.youtube.com/embed/#{video_id}" if video_id
  end

  def youtube_video_id
    return nil if video_url.blank?

    if video_url.include?('youtube.com/watch?v=')
      video_url.split('v=')[1]&.split('&')[0]
    elsif video_url.include?('youtu.be/')
      video_url.split('youtu.be/')[1]&.split('?')[0]
    end
  end
end
