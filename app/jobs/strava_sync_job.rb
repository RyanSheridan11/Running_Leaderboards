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
      strava_service = StravaService.new

      # Get recent activities from the club
      activities = strava_service.get_activities(per_page: 5)

      if activities.empty?
        Rails.logger.info "No activities found in the club"
        # Store empty activities data in cache
        store_sync_data([], 0, 0, 0)
        return
      end

      Rails.logger.info "Found #{activities.count} activities in club"

      # Track sync statistics
      processed_activities = []
      total_activities = activities.count
      processed_count = 0
      created_runs_count = 0

      activities.each do |activity|
        # Store activity data for dashboard display
        # Safely handle nil athlete names
        firstname = activity.dig("athlete", "firstname") || "Unknown"
        lastname = activity.dig("athlete", "lastname") || "User"

        activity_data = {
          athlete_name: "#{firstname} #{lastname}",
          name: activity["name"] || "Unnamed Activity",
          distance: activity["distance"] || 0,
          moving_time: activity["moving_time"] || 0,
          type: activity["type"] || "Unknown",
          sport_type: activity["sport_type"] || "Unknown",
          start_date: activity["start_date"],
          is_5k: StravaService.is_5k_run?(activity),
          processed: false,
          created_run: false
        }

        if StravaService.is_5k_run?(activity)
          processed_count += 1
          activity_data[:processed] = true

          if process_activity(activity)
            created_runs_count += 1
            activity_data[:created_run] = true
          end
        end

        processed_activities << activity_data
      end

      # Store sync data in Rails cache for dashboard display
      store_sync_data(processed_activities, total_activities, processed_count, created_runs_count)

    rescue StandardError => e
      Rails.logger.error "Error syncing club activities: #{e.message}"

      # Categorize the error for better dashboard display
      error_type = case e.message
      when /authentication failed|401 Unauthorized/i
        "authentication_error"
      when /access forbidden|403 Forbidden/i
        "permission_error"
      when /rate limit|429 Too Many Requests/i
        "rate_limit_error"
      else
        "general_error"
      end

      # Store error data in cache with error type
      store_sync_data([], 0, 0, 0, e.message, error_type)
    end
  end

  def process_activity(activity)
    # Find user by athlete name (you'll need to implement this matching logic)
    user = find_user_by_athlete(activity["athlete"])
    unless user
      firstname = activity.dig("athlete", "firstname") || "Unknown"
      lastname = activity.dig("athlete", "lastname") || "User"
      Rails.logger.warn "No user found for athlete: #{firstname} #{lastname}"
      return false
    end

    # Parse activity data
    begin
      activity_date = activity["start_date"] ? Date.parse(activity["start_date"]) : Date.today
    rescue ArgumentError
      Rails.logger.warn "Invalid date format for activity: #{activity["start_date"]}"
      activity_date = Date.today
    end
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
      return false
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
      true
    else
      Rails.logger.error "Failed to save run for user #{user.username}: #{run.errors.full_messages}"
      false
    end
  end

  def find_user_by_athlete(athlete)
    return nil unless athlete&.dig("firstname") && athlete&.dig("lastname")

    strava_firstname = athlete["firstname"].to_s.strip.downcase
    strava_lastname = athlete["lastname"].to_s.strip.downcase

    # Skip if we don't have both names
    return nil if strava_firstname.empty? || strava_lastname.empty?

    # Try to find by stored strava_athlete_id first
    if athlete["id"]
      user = User.find_by(strava_athlete_id: athlete["id"].to_s)
      return user if user
    end

    # Method 1: Check if strava firstname + lastname matches our strava_username field
    strava_full_name = "#{strava_firstname} #{strava_lastname}"
    user = User.where("LOWER(strava_username) = ?", strava_full_name.downcase).first
    return user if user

    # Method 2: Check if our user's firstname + first letter of lastname matches strava firstname + first letter of lastname
    # Safely get the first character of lastname
    lastname_first_char = strava_lastname.present? ? strava_lastname[0].downcase : ""
    strava_short_name = "#{strava_firstname.downcase}#{lastname_first_char}"

    # Find users where firstname + first letter of lastname matches (SQLite compatible)
    User.where("LOWER(firstname) || LOWER(SUBSTR(lastname, 1, 1)) = ?", strava_short_name).first
  end

  def store_sync_data(activities, total_count, processed_count, created_count, error_message = nil, error_type = nil)
    sync_data = {
      activities: activities,
      total_activities: total_count,
      processed_activities: processed_count,
      created_runs: created_count,
      sync_time: Time.current,
      error: error_message,
      error_type: error_type
    }

    Rails.cache.write("last_strava_sync_data", sync_data, expires_in: 7.days)
    Rails.logger.info "Stored sync data: #{total_count} total, #{processed_count} processed, #{created_count} created"
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


# [ { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Morning Run", "distance": 5010.4, "moving_time": 1344, "elapsed_time": 1344, "total_elevation_gain": 0.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Benjamin", "lastname": "C." }, "name": "Late, cold and rainy", "distance": 3023.9, "moving_time": 723, "elapsed_time": 729, "total_elevation_gain": 6.7, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Morning Run", "distance": 3042.0, "moving_time": 846, "elapsed_time": 874, "total_elevation_gain": 29.7, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Harris", "lastname": "C." }, "name": "Forgot the ffing dog last time so had to go again", "distance": 2446.8, "moving_time": 621, "elapsed_time": 627, "total_elevation_gain": 0.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Harris", "lastname": "C." }, "name": "Run", "distance": 3051.9, "moving_time": 712, "elapsed_time": 718, "total_elevation_gain": 4.7, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Andy", "lastname": "H." }, "name": "Night Run", "distance": 6131.1, "moving_time": 1892, "elapsed_time": 2071, "total_elevation_gain": 44.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Benjamin", "lastname": "C." }, "name": "Woke up late, had to walk the dog", "distance": 2343.4, "moving_time": 507, "elapsed_time": 592, "total_elevation_gain": 17.5, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Morning Run", "distance": 3078.9, "moving_time": 887, "elapsed_time": 957, "total_elevation_gain": 29.5, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Finlay", "lastname": "A." }, "name": "Evening Run", "distance": 4492.8, "moving_time": 1899, "elapsed_time": 6042, "total_elevation_gain": 8.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Andy", "lastname": "H." }, "name": "Afternoon Run", "distance": 5030.0, "moving_time": 1625, "elapsed_time": 1752, "total_elevation_gain": 41.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Ryan", "lastname": "S." }, "name": "Belmont trig", "distance": 11256.1, "moving_time": 4904, "elapsed_time": 5367, "total_elevation_gain": 556.0, "type": "Run", "sport_type": "Run", "workout_type": null }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Morning Run", "distance": 5520.8, "moving_time": 1862, "elapsed_time": 2224, "total_elevation_gain": 38.8, "type": "Run", "sport_type": "Run", "workout_type": null }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Andy", "lastname": "H." }, "name": "Night Run", "distance": 6161.4, "moving_time": 1996, "elapsed_time": 1996, "total_elevation_gain": 41.9, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "River", "lastname": "R." }, "name": "post-gym run with Luke. 3.4/10. absence of joy.", "distance": 5016.5, "moving_time": 1414, "elapsed_time": 1584, "total_elevation_gain": 37.8, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Ryan", "lastname": "S." }, "name": "Park Run", "distance": 5100.4, "moving_time": 1374, "elapsed_time": 1374, "total_elevation_gain": 14.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Morning Run", "distance": 4942.7, "moving_time": 1378, "elapsed_time": 1381, "total_elevation_gain": 0.0, "type": "Run", "sport_type": "Run", "workout_type": null }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Run to the run", "distance": 2055.1, "moving_time": 713, "elapsed_time": 734, "total_elevation_gain": 0.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Benjamin", "lastname": "C." }, "name": "Legs were fine, fitness was what got me", "distance": 3070.5, "moving_time": 733, "elapsed_time": 738, "total_elevation_gain": 7.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "River", "lastname": "R." }, "name": "Afternoon Run", "distance": 6372.5, "moving_time": 1823, "elapsed_time": 2019, "total_elevation_gain": 48.9, "type": "Run", "sport_type": "Run", "workout_type": null }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Evening Run w Kerryn", "distance": 2533.7, "moving_time": 1022, "elapsed_time": 1143, "total_elevation_gain": 20.8, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Josh", "lastname": "J." }, "name": "Evening 5k", "distance": 5011.2, "moving_time": 1384, "elapsed_time": 1384, "total_elevation_gain": 3.9, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Benjamin", "lastname": "C." }, "name": "Windy and my headphones died :(", "distance": 2100.2, "moving_time": 494, "elapsed_time": 499, "total_elevation_gain": 4.8, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Finlay", "lastname": "A." }, "name": "Morning Run", "distance": 9921.5, "moving_time": 3031, "elapsed_time": 4064, "total_elevation_gain": 136.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Andy", "lastname": "H." }, "name": "Afternoon Run", "distance": 5591.3, "moving_time": 1711, "elapsed_time": 1820, "total_elevation_gain": 38.8, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Rian", "lastname": "C." }, "name": "6km w knee recovery", "distance": 6028.2, "moving_time": 2184, "elapsed_time": 2255, "total_elevation_gain": 4.2, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Lower Hutt Park Run", "distance": 5000.0, "moving_time": 1353, "elapsed_time": 1353, "total_elevation_gain": 16.2, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Ryan", "lastname": "S." }, "name": "Hutt park run", "distance": 5002.0, "moving_time": 1364, "elapsed_time": 1364, "total_elevation_gain": 37.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Benjamin", "lastname": "C." }, "name": "First 5k since getting shin splints", "distance": 5041.8, "moving_time": 1323, "elapsed_time": 1329, "total_elevation_gain": 10.3, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Finlay", "lastname": "A." }, "name": "Afternoon Run", "distance": 8008.2, "moving_time": 2799, "elapsed_time": 3015, "total_elevation_gain": 85.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "River", "lastname": "R." }, "name": "Afternoon Run", "distance": 8008.2, "moving_time": 2799, "elapsed_time": 3015, "total_elevation_gain": 85.0, "type": "Run", "sport_type": "Run", "workout_type": null }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Andy", "lastname": "H." }, "name": "Night Run", "distance": 6190.6, "moving_time": 1987, "elapsed_time": 1990, "total_elevation_gain": 44.1, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Finlay", "lastname": "A." }, "name": "Afternoon Run", "distance": 9100.0, "moving_time": 2793, "elapsed_time": 2793, "total_elevation_gain": 0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Flu game run", "distance": 5003.5, "moving_time": 1418, "elapsed_time": 1422, "total_elevation_gain": 0.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Ryan", "lastname": "S." }, "name": "Park run", "distance": 5069.7, "moving_time": 1431, "elapsed_time": 1431, "total_elevation_gain": 16.0, "type": "Run", "sport_type": "Run", "workout_type": null }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Andy", "lastname": "H." }, "name": "Night Run", "distance": 6263.2, "moving_time": 1998, "elapsed_time": 2001, "total_elevation_gain": 44.2, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Finlay", "lastname": "A." }, "name": "Afternoon Run", "distance": 5391.0, "moving_time": 1808, "elapsed_time": 1820, "total_elevation_gain": 9.0, "type": "Run", "sport_type": "Run", "workout_type": null }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Ryan", "lastname": "S." }, "name": "After Work Rogaine on the home turf!", "distance": 15855.3, "moving_time": 7587, "elapsed_time": 10579, "total_elevation_gain": 764.0, "type": "Run", "sport_type": "TrailRun", "workout_type": null }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Ryan", "lastname": "S." }, "name": "Park Run", "distance": 5131.0, "moving_time": 1496, "elapsed_time": 1503, "total_elevation_gain": 7.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Run in the park", "distance": 5018.7, "moving_time": 1354, "elapsed_time": 1354, "total_elevation_gain": 0.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Park run with joe!", "distance": 5024.3, "moving_time": 1393, "elapsed_time": 1411, "total_elevation_gain": 0.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Finlay", "lastname": "A." }, "name": "Evening Run", "distance": 5997.5, "moving_time": 1993, "elapsed_time": 2135, "total_elevation_gain": 62.0, "type": "Run", "sport_type": "Run", "workout_type": null }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Park run!", "distance": 5139.6, "moving_time": 1402, "elapsed_time": 1429, "total_elevation_gain": 0.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Park run!", "distance": 5139.6, "moving_time": 1337, "elapsed_time": 1341, "total_elevation_gain": 0.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Spooky Pukawa run", "distance": 1512.6, "moving_time": 358, "elapsed_time": 358, "total_elevation_gain": 2.3, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Park run!!", "distance": 5001.1, "moving_time": 1446, "elapsed_time": 1446, "total_elevation_gain": 0.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "
# resource_state": 2, "athlete": { "
# resource_state": 2, "firstname": "Ryan", "lastname": "S." }, "name": "Park run!", "distance": 5172.6, "moving_time": 1490, "elapsed_time": 1494, "total_elevation_gain": 4.0, "type": "Run", "sport_type": "Run", "workout_type": 0 }, { "resource_state": 2, "athlete": { "resource_state": 2, "firstname": "Nick", "lastname": "B." }, "name": "Morning Run", "distance": 2012.1, "moving_time": 494, "elapsed_time": 494, "total_elevation_gain": 18.0, "type": "Run", "sport_type": "Run", "workout_type": 3 } ]
