class PlaysController < ApplicationController
  before_action :require_login, only: [ :new, :create ]
  before_action :get_play, only: [ :show ]

  def index
    @events = Event.order(:start_date)
    if params[:event_id].present?
      @selected_event = Event.find_by(id: params[:event_id])
      @top_plays = Play.approved.where(event: @selected_event).top_rated.limit(10)
    else
      @top_plays = Play.approved.top_rated.limit(10)
    end
  end

  def new
    @play = current_user.plays.build
    @events = Event.order(:start_date)
  end

  def create
    @play = current_user.plays.build(play_params)

    if @play.save
      redirect_to root_path, notice: "Play submitted successfully! It will be reviewed by an admin."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @play = Play.find(params[:id])
  end

  private

  def get_play
    @play = Play.find(params[:id])
  end

  def play_params
    params.require(:play).permit(:title, :description, :video_url, :event_id)
  end
end
