require "test_helper"

class StravaDistanceTest < ActiveSupport::TestCase
  setup do
    @user = users(:ryan)
  end

  test "run can store strava_distance" do
    run = Run.new(
      user: @user,
      date: Date.current,
      time: 1500, # 25:00
      race_type: "5k",
      source: "strava",
      strava_distance: 5000.0
    )

    assert run.save
    assert_equal 5000.0, run.strava_distance
  end

  test "strava_distance is optional for manual runs" do
    run = Run.new(
      user: @user,
      date: Date.current,
      time: 1500,
      race_type: "5k",
      source: "manual"
    )

    assert run.save
    assert_nil run.strava_distance
  end

  test "duplicate detection considers distance for strava runs" do
    # Create an existing Strava run
    existing_run = Run.create!(
      user: @user,
      date: Date.current,
      time: 1500, # 25:00
      race_type: "5k",
      source: "strava",
      strava_distance: 5000.0
    )

    # Test duplicate detection logic (similar to what's in StravaSyncJob)
    activity_time = 1502 # 25:02 (within 3 seconds)
    activity_distance = 5050.0 # 5050m (within 100m)

    duplicate_run = @user.runs.where(race_type: "5k").find do |run|
      time_match = (run.time - activity_time).abs <= 3

      if run.from_strava? && run.strava_distance.present?
        distance_match = (run.strava_distance - activity_distance).abs <= 100
        time_match && distance_match
      else
        time_match
      end
    end

    assert_not_nil duplicate_run
    assert_equal existing_run, duplicate_run
  end

  test "duplicate detection allows different distances for strava runs" do
    # Create an existing Strava run
    existing_run = Run.create!(
      user: @user,
      date: Date.current,
      time: 1500, # 25:00
      race_type: "5k",
      source: "strava",
      strava_distance: 5000.0
    )

    # Test with different distance (more than 100m difference)
    activity_time = 1502 # 25:02 (within 3 seconds)
    activity_distance = 5200.0 # 5200m (more than 100m difference)

    duplicate_run = @user.runs.where(race_type: "5k").find do |run|
      time_match = (run.time - activity_time).abs <= 3

      if run.from_strava? && run.strava_distance.present?
        distance_match = (run.strava_distance - activity_distance).abs <= 100
        time_match && distance_match
      else
        time_match
      end
    end

    assert_nil duplicate_run # Should not find a duplicate due to distance difference
  end

  test "duplicate detection still works for manual runs without distance" do
    # Create an existing manual run
    existing_run = Run.create!(
      user: @user,
      date: Date.current,
      time: 1500, # 25:00
      race_type: "5k",
      source: "manual"
    )

    # Test duplicate detection (only time-based for manual runs)
    activity_time = 1502 # 25:02 (within 3 seconds)
    activity_distance = 5000.0

    duplicate_run = @user.runs.where(race_type: "5k").find do |run|
      time_match = (run.time - activity_time).abs <= 3

      if run.from_strava? && run.strava_distance.present?
        distance_match = (run.strava_distance - activity_distance).abs <= 100
        time_match && distance_match
      else
        time_match
      end
    end

    assert_not_nil duplicate_run
    assert_equal existing_run, duplicate_run
  end
end
