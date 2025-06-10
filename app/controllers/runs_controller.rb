class RunsController < ApplicationController
  before_action :require_login, only: [ :new, :create, :edit, :update, :destroy ]
  before_action :set_run, only: [ :edit, :update, :destroy ]
  before_action :check_owner, only: [ :edit, :update, :destroy ]
  before_action :get_play_pair, only: [ :index, :create_vote ]

  def index
    @five_k_runs = Run.five_k.includes(:user).order(:time)
    @bronco_runs = Run.bronco.includes(:user).order(:time)
    # Only each user's personal best (first ordered by time), limit to top 10
    @unique_5k_runs = @five_k_runs.uniq(&:user_id).first(10)
    # Only each user's personal best for bronco, limit to top 10
    @unique_bronco_runs = @bronco_runs.uniq(&:user_id).first(10)
    @top_plays = Play.approved.top_rated.limit(10)
    @current_deadlines = RaceDeadline.active.where("start_date <= ? AND due_date >= ?", Date.current, Date.current)
    @events = Event.order(:start_date)
    if params[:event_id].present?
      @selected_event = Event.find_by(id: params[:event_id])
      @top_plays = Play.approved.where(event: @selected_event).top_rated.limit(10)
    else
      @top_plays = Play.approved.top_rated.limit(10)
    end
  end

  def new
    @run = Run.new
  end

  def create
    if current_user&.admin? && params[:run][:user_id].present?
      user = User.find(params[:run][:user_id])
      @run = user.runs.build(run_params.except(:user_id))
    else
      @run = current_user.runs.build(run_params)
    end

    race_type = params[:run][:race_type] || "5k"
    time_in_seconds = convert_time_to_seconds(params[:run][:time], race_type)
    @run.source = "manual"
    if params[:run][:time].present?
      case time_in_seconds
      when nil
        format_example = race_type == "bronco" ? "5:30" : "25:30"
        @run.errors.add(:time, "must be in #{race_type == 'bronco' ? 'm:ss' : 'mm:ss'} format (e.g. #{format_example})")
        render :new and return
      when :invalid_minutes
        @run.errors.add(:time, "minutes must be less than 60")
        render :new and return
      when :invalid_seconds
        @run.errors.add(:time, "seconds must be less than 60")
        render :new and return
      end
    end

    @run.time = time_in_seconds
    if @run.save
      redirect_to root_path, notice: "Run added!"
    else
      render :new
    end
  end

  def create_vote
    # Record single head-to-head vote
    selected_id = params[:selected_play_id]
    if selected_id.present?
      chosen = Play.find(params[:selected_play_id])
      other  = (@play_pair - [ chosen ]).first

      changes = chosen.update_elo_against(other)

      redirect_to runs_path, notice: changes
    else
      redirect_to runs_path, alert: changes
    end
  end

  def edit
  end

  def update
    race_type = params[:run][:race_type] || @run.race_type
    time_in_seconds = convert_time_to_seconds(params[:run][:time], race_type)

    if params[:run][:time].present?
      case time_in_seconds
      when nil
        format_example = race_type == "bronco" ? "5:30" : "25:30"
        @run.errors.add(:time, "must be in #{race_type == 'bronco' ? 'm:ss' : 'mm:ss'} format (e.g. #{format_example})")
        render :edit and return
      when :invalid_minutes
        @run.errors.add(:time, "minutes must be less than 60")
        render :edit and return
      when :invalid_seconds
        @run.errors.add(:time, "seconds must be less than 60")
        render :edit and return
      end
    end

    # Handle user assignment for admins
    if current_user&.admin? && params[:run][:user_id].present? && params[:run][:user_id] != @run.user_id.to_s
      new_user = User.find(params[:run][:user_id])
      @run.user = new_user
    end

    @run.assign_attributes(run_params.except(:user_id))
    @run.time = time_in_seconds
    if @run.save
      redirect_to root_path, notice: "Run updated!"
    else
      render :edit
    end
  end

  def destroy
    @run.destroy
    redirect_to root_path, notice: "Run deleted!"
  end

  # GET /bronco_tutorials
  def bronco_tutorials
  end

  private

  def set_run
    @run = Run.find(params[:id])
  end

  def check_owner
    unless @run.user == current_user || current_user&.admin?
      redirect_to root_path, alert: "You can only edit your own runs."
    end
  end

  def run_params
    if current_user&.admin?
      params.require(:run).permit(:date, :race_type, :user_id, :strava_distance)
    else
      params.require(:run).permit(:date, :race_type)
    end
  end

  def convert_time_to_seconds(time_string, race_type = "5k")
    return nil unless time_string.present?

    # For bronco (1.2k), accept m:ss format; for 5k, accept mm:ss format
    if race_type == "bronco"
      if time_string.match(/\A(\d{1,2}):(\d{2})\z/)
        minutes = $1.to_i
        seconds = $2.to_i

        if minutes >= 60
          :invalid_minutes
        elsif seconds >= 60
          :invalid_seconds
        else
          (minutes * 60) + seconds
        end
      else
        nil
      end
    else
      if time_string.match(/\A(\d+):(\d{2})\z/)
        minutes = $1.to_i
        seconds = $2.to_i

        if minutes >= 60
          :invalid_minutes
        elsif seconds >= 60
          :invalid_seconds
        else
          (minutes * 60) + seconds
        end
      else
        nil
      end
    end
  end
  def get_play_pair
    base_scope = Play.approved.includes(:user)
    if action_name == "index"
      @selected_event_id = params[:event_id]
      base_scope = base_scope.where(event_id: @selected_event_id) if @selected_event_id.present?
      @play_pair = base_scope.order(Arel.sql("RANDOM()")).limit(2)
    else
      # pull the same IDs back from the form for update
      ids = params.require(:play_ids).split(",").map(&:to_i)
      @play_pair = Play.find(ids)
    end
  end
end
