class RunsController < ApplicationController
  before_action :require_login, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_run, only: [:edit, :update, :destroy]
  before_action :check_owner, only: [:edit, :update, :destroy]

  def index
    @runs = Run.includes(:user).order(:time)
  end

  def new
    @run = Run.new
  end

  def create
    @run = current_user.runs.build(run_params)
    time_in_seconds = convert_time_to_seconds(params[:run][:time])

    if params[:run][:time].present?
      case time_in_seconds
      when nil
        @run.errors.add(:time, "must be in mm:ss format (e.g. 25:30)")
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

  def edit
  end

  def update
    time_in_seconds = convert_time_to_seconds(params[:run][:time])

    if params[:run][:time].present?
      case time_in_seconds
      when nil
        @run.errors.add(:time, "must be in mm:ss format (e.g. 25:30)")
        render :edit and return
      when :invalid_minutes
        @run.errors.add(:time, "minutes must be less than 60")
        render :edit and return
      when :invalid_seconds
        @run.errors.add(:time, "seconds must be less than 60")
        render :edit and return
      end
    end

    @run.assign_attributes(run_params)
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

  private

  def set_run
    @run = Run.find(params[:id])
  end

  def check_owner
    unless @run.user == current_user
      redirect_to root_path, alert: "You can only edit your own runs."
    end
  end

  def run_params
    params.require(:run).permit(:date)
  end

  def convert_time_to_seconds(time_string)
    return nil unless time_string.present?

    if time_string.match(/\A(\d+):(\d{2})\z/)
      minutes = $1.to_i
      seconds = $2.to_i

      # Validate that minutes and seconds are within valid ranges
      if minutes >= 60
        return :invalid_minutes
      elsif seconds >= 60
        return :invalid_seconds
      else
        (minutes * 60) + seconds
      end
    else
      nil
    end
  end
end
