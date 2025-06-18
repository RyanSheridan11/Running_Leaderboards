class Admin::RunsController < ApplicationController
  before_action :require_login
  before_action :require_admin
  before_action :set_run, only: [ :edit, :update, :destroy ]

  def index
    @runs = Run.includes(:user).order(created_at: :desc)
    @runs = @runs.where(race_type: params[:race_type]) if params[:race_type].present?
    @runs = @runs.where(source: params[:source]) if params[:source].present?

    # Filter by user type
    if params[:user_type].present?
      @runs = @runs.joins(:user).where(users: { user_type: params[:user_type] })
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

    @run.assign_attributes(run_params)
    @run.time = time_in_seconds
    if @run.save
      redirect_to admin_runs_path, notice: "Run updated successfully!"
    else
      render :edit
    end
  end

  def destroy
    @run.destroy
    redirect_to admin_runs_path, notice: "Run deleted successfully."
  end

  private

  def set_run
    @run = Run.find(params[:id])
  end

  def run_params
    params.require(:run).permit(:date, :race_type)
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
end
