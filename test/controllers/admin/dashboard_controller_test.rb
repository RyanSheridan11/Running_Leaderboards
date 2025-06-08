require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.create!(
      firstname: "Admin",
      lastname: "User",
      email: "admin@test.com",
      password: "password123",
      password_confirmation: "password123",
      admin: true
    )

    @regular_user = User.create!(
      firstname: "Regular",
      lastname: "User",
      email: "user@test.com",
      password: "password123",
      password_confirmation: "password123"
    )

    # Create some test data
    @run1 = Run.create!(
      user: @regular_user,
      date: Date.current,
      time: 1800, # 30 minutes
      race_type: "5k",
      source: "strava"
    )

    @run2 = Run.create!(
      user: @admin,
      date: Date.current - 1.day,
      time: 300, # 5 minutes
      race_type: "bronco",
      source: "manual"
    )

    # Create an event for the play
    @event = Event.create!(
      name: "Test Event",
      start_date: Date.current - 1.week,
      end_date: Date.current + 1.week
    )

    @play = Play.create!(
      user: @regular_user,
      event: @event,
      title: "Test Play",
      description: "Test description",
      status: "pending"
    )

    @race_deadline = RaceDeadline.create!(
      race_type: "5k",
      start_date: Date.current - 1.week,
      due_date: Date.current + 1.week,
      description: "Test deadline",
      active: true
    )
  end

  test "should redirect to login when not logged in" do
    get admin_dashboard_path
    assert_redirected_to login_path
  end

  test "should redirect to root when not admin" do
    post login_path, params: { email: @regular_user.email, password: "password123" }
    get admin_dashboard_path
    assert_redirected_to root_path
    assert_equal "You must be an admin to access this section.", flash[:alert]
  end

  test "should show dashboard when admin" do
    post login_path, params: { email: @admin.email, password: "password123" }
    get admin_dashboard_path

    assert_response :success
    assert_select "h1", "🏃‍♂️ Running Leaderboard Admin Dashboard"

    # Check that stats are displayed
    assert_select ".stat-card"
    assert_match "2", response.body # Total users
    assert_match "2", response.body # Total runs
    assert_match "1", response.body # Strava runs
    assert_match "1", response.body # Manual runs
    assert_match "1", response.body # Pending plays
    assert_match "1", response.body # Active deadlines
  end

  test "should show management links" do
    post login_path, params: { email: @admin.email, password: "password123" }
    get admin_dashboard_path

    assert_response :success
    assert_select "a[href='#{admin_runs_path}']", "View Runs"
    assert_select "a[href='#{admin_users_path}']", "View Users"
    assert_select "a[href='#{admin_race_deadlines_path}']", "View Deadlines"
    assert_select "a[href='#{admin_plays_path}']", "View Plays"
  end

  test "should show strava sync section" do
    post login_path, params: { email: @admin.email, password: "password123" }
    get admin_dashboard_path

    assert_response :success
    assert_select "form[action='#{admin_dashboard_sync_path}']"
    assert_select "input[type='submit'][value='🔄 Run Strava Sync']"
  end

  test "should show recent activity" do
    post login_path, params: { email: @admin.email, password: "password123" }
    get admin_dashboard_path

    assert_response :success
    assert_select ".recent-activity"
    assert_match "Recent Runs", response.body
    assert_match "Recent Users", response.body
  end

  test "should handle strava sync trigger" do
    post login_path, params: { email: @admin.email, password: "password123" }

    # Store sample sync data in cache for testing
    Rails.cache.write("last_strava_sync_data", {
      activities: [],
      total_activities: 0,
      processed_activities: 0,
      created_runs: 0,
      sync_time: Time.current,
      error: nil
    })

    # Override StravaSyncJob.perform_now for this test
    StravaSyncJob.define_singleton_method(:perform_now) { true }

    post admin_dashboard_sync_path

    assert_redirected_to admin_dashboard_path
    assert_match "Strava sync completed successfully!", flash[:notice]
  end

  test "should handle strava sync errors" do
    post login_path, params: { email: @admin.email, password: "password123" }

    # Override StravaSyncJob.perform_now to raise an error for this test
    StravaSyncJob.define_singleton_method(:perform_now) { raise StandardError.new("API Error") }

    post admin_dashboard_sync_path

    assert_redirected_to admin_dashboard_path
    assert_equal "Strava sync failed: API Error", flash[:alert]
  end
end
