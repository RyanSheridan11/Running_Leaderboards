class Admin::DashboardController < ApplicationController
  before_action :require_login
  before_action :require_admin

  def index
    # Get counts for dashboard overview
    @total_users = User.count
    @total_runs = Run.count
    @total_strava_runs = Run.where(source: "strava").count
    @total_manual_runs = Run.where(source: "manual").count
    @pending_plays = Play.where(status: "pending").count
    @active_deadlines = RaceDeadline.active.count

    # Get recent activity
    @recent_runs = Run.includes(:user).order(created_at: :desc).limit(10)
    @recent_users = User.order(created_at: :desc).limit(5)

    # Strava sync status (we'll track this in session or cache)
    @last_sync_status = session[:last_strava_sync_status] || "Not run yet"
    @last_sync_time = begin
      session[:last_strava_sync_time] ? Time.parse(session[:last_strava_sync_time]) : nil
    rescue ArgumentError
      nil
    end
    @last_sync_result = session[:last_strava_sync_result]

    # Get last Strava sync activity data from cache
    @sync_data = Rails.cache.read("last_strava_sync_data")
  end

  def trigger_strava_sync
    begin
      # Start the sync job
      StravaSyncJob.perform_now

      # Get the sync data from cache to provide detailed feedback
      sync_data = Rails.cache.read("last_strava_sync_data")

      if sync_data && !sync_data[:error]
        result_message = "Found #{sync_data[:total_activities]} activities, processed #{sync_data[:processed_activities]} eligible 5k runs, created #{sync_data[:created_runs]} new runs"
      else
        result_message = sync_data && sync_data[:error] ? "Error: #{sync_data[:error]}" : "Sync completed"
      end

      # Track sync result
      session[:last_strava_sync_status] = "Completed successfully"
      session[:last_strava_sync_time] = Time.current.to_s
      session[:last_strava_sync_result] = result_message

      redirect_to admin_dashboard_path, notice: "Strava sync completed successfully! #{result_message}"
    rescue => e
      # Track sync error
      session[:last_strava_sync_status] = "Failed"
      session[:last_strava_sync_time] = Time.current.to_s
      session[:last_strava_sync_result] = "Error: #{e.message}"

      redirect_to admin_dashboard_path, alert: "Strava sync failed: #{e.message}"
    end
  end
end
