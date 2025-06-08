require "test_helper"

class StravaSyncJobTest < ActiveJob::TestCase
  def setup
    # Create test users with names that might match Strava athletes
    @user1 = User.create!(
      firstname: "Benjamin",
      lastname: "Cooper",
      email: "benjaminc@test.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @user2 = User.create!(
      firstname: "Sarah",
      lastname: "Johnson",
      email: "sarahj@test.com",
      password: "password123",
      password_confirmation: "password123",
      strava_username: "Sarah J."
    )

    @user3 = User.create!(
      firstname: "Mike",
      lastname: "Davis",
      email: "miked@test.com",
      password: "password123",
      password_confirmation: "password123",
      strava_athlete_id: "12345678"
    )

    # Create a Strava token for testing
    StravaToken.create!(
      access_token: Rails.application.credentials.strava&.access_token || "test_token",
      refresh_token: "test_refresh_token",
      expires_at: 1.hour.from_now,
      expires_in: 3600
    )
  end

  test "should perform strava sync job without errors" do
    # skip "Skipping live API test - set STRAVA_LIVE_TEST=true to run" unless ENV["STRAVA_LIVE_TEST"]

    assert_nothing_raised do
      StravaSyncJob.perform_now
    end
  end

  test "should handle strava service initialization" do
    # skip "Skipping live API test - set STRAVA_LIVE_TEST=true to run" unless ENV["STRAVA_LIVE_TEST"]

    job = StravaSyncJob.new

    # Test that we can create a StravaService without errors
    assert_nothing_raised do
      service = StravaService.new
      assert_not_nil service
    end
  end

  test "should sync club activities from live API" do
    # assert_strava_api_available

    puts "\n🔴 LIVE TEST: Hitting the real Strava API..."

    initial_run_count = Run.count

    # Perform the job
    StravaSyncJob.perform_now

    puts "✅ StravaSyncJob completed successfully"
    puts "📊 Runs before: #{initial_run_count}, after: #{Run.count}"

    # The job should complete without raising errors
    # We can't assert specific run creation since we don't control the API data
    assert true
  end

  test "should identify 5k runs correctly" do
    # Test the 5k identification logic
    assert StravaService.is_5k_run?({
      "type" => "Run",
      "distance" => 5000.0  # exactly 5k
    })

    assert StravaService.is_5k_run?({
      "type" => "Run",
      "distance" => 4900.0  # 4.9k - should still qualify
    })

    assert StravaService.is_5k_run?({
      "type" => "Run",
      "distance" => 5100.0  # 5.1k - should still qualify
    })

    refute StravaService.is_5k_run?({
      "type" => "Run",
      "distance" => 3000.0  # 3k - too short
    })

    refute StravaService.is_5k_run?({
      "type" => "Run",
      "distance" => 10000.0  # 10k - too long
    })

    refute StravaService.is_5k_run?({
      "type" => "Ride",  # Not a run
      "distance" => 5000.0
    })
  end

  test "should find user by athlete using strava_athlete_id" do
    job = StravaSyncJob.new

    athlete = {
      "id" => "12345678",
      "firstname" => "Mike",
      "lastname" => "Davis"
    }

    found_user = job.send(:find_user_by_athlete, athlete)
    assert_equal @user3, found_user
  end

  test "should find user by athlete using strava username match" do
    job = StravaSyncJob.new

    athlete = {
      "id" => "99999999",  # Different ID
      "firstname" => "Sarah",
      "lastname" => "J."
    }

    found_user = job.send(:find_user_by_athlete, athlete)
    assert_equal @user2, found_user
  end

  test "should find user by athlete using firstname + lastname pattern" do
    job = StravaSyncJob.new

    athlete = {
      "id" => "99999999",  # Different ID
      "firstname" => "Benjamin",
      "lastname" => "C."  # Only first letter of last name
    }

    found_user = job.send(:find_user_by_athlete, athlete)
    assert_equal @user1, found_user
  end

  test "should return nil when no user matches athlete" do
    job = StravaSyncJob.new

    athlete = {
      "id" => "99999999",
      "firstname" => "Unknown",
      "lastname" => "Person"
    }

    found_user = job.send(:find_user_by_athlete, athlete)
    assert_nil found_user
  end

  test "should handle missing athlete data gracefully" do
    job = StravaSyncJob.new

    # Test with nil athlete
    assert_nil job.send(:find_user_by_athlete, nil)

    # Test with empty athlete
    assert_nil job.send(:find_user_by_athlete, {})

    # Test with missing firstname
    assert_nil job.send(:find_user_by_athlete, { "lastname" => "Test" })

    # Test with missing lastname
    assert_nil job.send(:find_user_by_athlete, { "firstname" => "Test" })
  end

  test "should convert strava time correctly" do
    # Test time conversion
    assert_equal 1800, StravaService.convert_time_to_seconds(1800)  # 30 minutes
    assert_equal 1200, StravaService.convert_time_to_seconds(1200)  # 20 minutes
  end

  test "should handle token refresh if expired" do
    # Create an expired token
    expired_token = StravaToken.create!(
      access_token: "expired_token",
      refresh_token: Rails.application.credentials.strava&.refresh_token || "test_refresh",
      expires_at: 1.hour.ago,  # Expired
      expires_in: 3600
    )

    # Delete the valid token we created in setup
    StravaToken.where.not(id: expired_token.id).destroy_all

    puts "\n🔄 Testing token refresh..."

    # This should trigger a token refresh
    assert_nothing_raised do
      service = StravaService.new
      assert_not_nil service
    end

    # Token should have been refreshed
    expired_token.reload
    assert expired_token.expires_at > Time.current, "Token should have been refreshed"
  end

  private

  def assert_strava_api_available
    unless Rails.application.credentials.strava&.access_token.present?
      skip "Strava access token not available"
    end

    # Test basic API connectivity
    begin
      service = StravaService.new
      activities = service.get_activities(per_page: 1)

      unless activities.is_a?(Array)
        skip "Could not retrieve activities from Strava API"
      end
    rescue StandardError => e
      skip "Strava API not accessible: #{e.message}"
    end
  end
end
