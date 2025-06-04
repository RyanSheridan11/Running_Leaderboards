class Play < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :title, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }
  validates :video_url, format: {
    with: /\A(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.+\z/i,
    message: "must be a valid YouTube URL"
  }, allow_blank: true
  validates :status, inclusion: { in: %w[pending approved rejected] }

  scope :approved, -> { where(status: "approved") }
  scope :pending, -> { where(status: "pending") }
  scope :top_rated, -> { where(status: "approved").order(elo: :desc) }

  def youtube_embed_url
    return nil if video_url.blank?

    video_id = youtube_video_id
    "https://www.youtube.com/embed/#{video_id}" if video_id
  end

  def youtube_video_id
    return nil if video_url.blank?

    if video_url.include?('youtube.com/watch?v=') # rubocop:disable Style/StringLiterals
      video_url.split("v=")[1]&.split("&")[0]
    elsif video_url.include?("youtu.be/")
      video_url.split("youtu.be/")[1]&.split("?")[0]
    end
  end

  # Update Elo ratings after a head-to-head match
  # winner: this play; loser: opponent play; k: rating adjustment factor
  def update_elo_against(loser, k: 50)
    winner_elo = self.elo
    loser_elo = loser.elo

    match = Elos::Match.new(k: k)
    match.add_player(rating: loser_elo)
    match.add_player(rating: winner_elo, winner: true)

    new_loser_elo, new_winner_elo = match.updated_ratings
    Play.transaction do
      update!(elo: new_winner_elo)
      loser.update!(elo: new_loser_elo)
    end
    "Updating Elo ratings: #{loser_elo} -> #{new_loser_elo}, #{winner_elo} -> #{new_winner_elo}"
  end
end
