class StravaSyncJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info "Starting Strava sync job"

    sync_club_activities

    Rails.logger.info "Completed Strava sync job"
  end

  private

  def sync_club_activities
    Rails.logger.info "Syncing activities from Strava club"

    begin
      # Use the single access token from credentials

      strava_service = StravaService.new

      # Get recent activities from the club
      activities = strava_service.get_activities(per_page: 50)

      if activities.empty?
        Rails.logger.info "No activities found in the club"
        return
      end

      Rails.logger.info "Found #{activities.count} activities in club"

      activities.each do |activity|
        process_activity(activity) if StravaService.is_5k_run?(activity)
      end

    rescue => e
      Rails.logger.error "Error syncing club activities: #{e.message}"
    end
  end

  def process_activity(activity)
    # Find user by athlete name (you'll need to implement this matching logic)
    user = find_user_by_athlete(activity["athlete"])
    unless user
      Rails.logger.warn "No user found for athlete: #{activity["athlete"]["firstname"]} #{activity["athlete"]["lastname"]}"
      return
    end

    # Parse activity data
    activity_date = Date.parse(activity["start_date"]) || Date.today
    activity_time = StravaService.convert_time_to_seconds(activity["moving_time"])

    # Check for duplicate runs on the same day with similar time (within 30 seconds)
    # and distance (5k runs should be between 4.5k and 5.5k)
    existing_run = user.runs.where(
      date: activity_date,
      race_type: "5k"
    ).find do |run|
      # Check if times are within 30 seconds of each other
      (run.time - activity_time).abs <= 30
    end

    if existing_run
      Rails.logger.info "Skipping duplicate run for user #{user.username} on #{activity_date} - existing time: #{existing_run.time}s, new time: #{activity_time}s"
      return
    end

    # Convert Strava data to our format
    run_data = {
      user: user,
      date: activity_date,
      time: activity_time,
      race_type: "5k",
      source: "strava"
    }

    run = Run.new(run_data)

    if run.save
      Rails.logger.info "Created run for user #{user.username}: #{run.time}s on #{run.date}"
    else
      Rails.logger.error "Failed to save run for user #{user.username}: #{run.errors.full_messages}"
    end
  end

  def find_user_by_athlete(athlete)
    # This is where you'll implement the logic to match Strava athletes to your users
    # You could match by:
    # - First name + last name
    # - A stored strava_athlete_id if you have them
    # - Username if it matches

    # Try to find by stored strava_athlete_id first
    # user = User.find_by(:name =>  your_custom_name: athlete["id"].to_s) if athlete["id"]
    # return user if user

    # Fallback: try to match by username containing first name
    User.where("username ILIKE ?", "%#{athlete["firstname"]}%").first
  end
end

# {
#   "resource_state" => 2,
#   "athlete" => {
#     "resource_state" => 2,
#     "firstname" => "Benjamin",
#     "lastname" => "C."
#   },
#   "name" => "Late, cold and rainy",
#   "distance" => 3023.9,
#   "moving_time" => 723,
#   "elapsed_time" => 729,
#   "total_elevation_gain" => 6.7,
#   "type" => "Run",
#   "sport_type" => "Run",
#   "workout_type" => 0
# }
