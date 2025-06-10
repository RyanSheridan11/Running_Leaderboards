require "test_helper"

class StravaSyncJobDistanceTest < ActiveJob::TestCase
  setup do
    @user = users(:ryan)
    @job = StravaSyncJob.new
  end

  test "process_activity stores strava_distance" do
    # Mock activity data from Strava API
    activity = {
      "athlete" => {
        "firstname" => @user.firstname,
        "lastname" => @user.lastname
      },
      "start_date" => "2025-06-10T10:00:00Z",
      "moving_time" => 1500, # 25:00 in seconds
      "distance" => 5000.0,
      "type" => "Run",
      "sport_type" => "Run"
    }

    # Stub the find_user_by_athlete method to return our test user
    @job.stub(:find_user_by_athlete, @user) do
      result = @job.send(:process_activity, activity)

      assert result, "Activity should be processed successfully"

      # Check that the run was created with strava_distance
      run = @user.runs.last
      assert_not_nil run
      assert_equal "strava", run.source
      assert_equal 5000.0, run.strava_distance
      assert_equal 1500, run.time
    end
  end

  test "duplicate detection works with distance for strava runs" do
    # Create an existing Strava run
    existing_run = Run.create!(
      user: @user,
      date: Date.parse("2025-06-10"),
      time: 1500,
      race_type: "5k",
      source: "strava",
      strava_distance: 5000.0
    )

    # Mock a similar activity (same time, similar distance)
    activity = {
      "athlete" => {
        "firstname" => @user.firstname,
        "lastname" => @user.lastname
      },
      "start_date" => "2025-06-10T10:00:00Z",
      "moving_time" => 1501, # 25:01 (within 3 seconds)
      "distance" => 5050.0, # 5050m (within 100m)
      "type" => "Run",
      "sport_type" => "Run"
    }

    initial_run_count = @user.runs.count

    @job.stub(:find_user_by_athlete, @user) do
      result = @job.send(:process_activity, activity)

      assert_not result, "Activity should be skipped as duplicate"
      assert_equal initial_run_count, @user.runs.count, "No new run should be created"
    end
  end

  test "different distance allows new run creation" do
    # Create an existing Strava run
    existing_run = Run.create!(
      user: @user,
      date: Date.parse("2025-06-10"),
      time: 1500,
      race_type: "5k",
      source: "strava",
      strava_distance: 5000.0
    )

    # Mock a different activity (same time, but different distance)
    activity = {
      "athlete" => {
        "firstname" => @user.firstname,
        "lastname" => @user.lastname
      },
      "start_date" => "2025-06-10T11:00:00Z",
      "moving_time" => 1501, # 25:01 (within 3 seconds)
      "distance" => 5200.0, # 5200m (more than 100m difference)
      "type" => "Run",
      "sport_type" => "Run"
    }

    initial_run_count = @user.runs.count

    @job.stub(:find_user_by_athlete, @user) do
      result = @job.send(:process_activity, activity)

      assert result, "Activity should be processed as new run"
      assert_equal initial_run_count + 1, @user.runs.count, "New run should be created"

      new_run = @user.runs.last
      assert_equal 5200.0, new_run.strava_distance
    end
  end
end
