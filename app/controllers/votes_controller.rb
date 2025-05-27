class VotesController < ApplicationController
  before_action :require_login

  def index
    @approved_plays = Play.approved.includes(:user, :votes)
    @user_votes = current_user.votes.includes(:play).index_by(&:play_id)
  end

  def update
    votes_data = params[:votes] || []

    ActiveRecord::Base.transaction do
      # Clear existing votes for this user
      current_user.votes.destroy_all

      # Create new votes based on rankings
      votes_data.each_with_index do |play_id, index|
        ranking = index + 1
        next if ranking > 10 # Only allow top 10 rankings

        play = Play.approved.find_by(id: play_id)
        next unless play

        current_user.votes.create!(
          play: play,
          ranking: ranking
        )
      end
    end

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Votes saved successfully!' } }
      format.html { redirect_to vote_path, notice: 'Your votes have been saved!' }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to vote_path, alert: 'Error saving votes. Please try again.' }
    end
  end

  private

  def require_login
    unless logged_in?
      redirect_to login_path, alert: 'Please log in to vote.'
    end
  end
end
