class PlaysController < ApplicationController
  before_action :require_login, only: [:new, :create]
  before_action :set_play, only: [:show]

  def index
    @top_plays = Play.approved.top_rated.limit(10)
  end

  def new
    @play = current_user.plays.build
  end

  def create
    @play = current_user.plays.build(play_params)

    if @play.save
      redirect_to plays_path, notice: 'Play submitted successfully! It will be reviewed by an admin.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @play = Play.find(params[:id])
  end

  private

  def set_play
    @play = Play.find(params[:id])
  end

  def play_params
    params.require(:play).permit(:title, :description, :video_url)
  end

  def require_login
    unless logged_in?
      redirect_to login_path, alert: 'Please log in to submit a play.'
    end
  end
end
