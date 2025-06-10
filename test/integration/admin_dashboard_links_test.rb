require "test_helper"

class AdminDashboardLinksTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:ryan)
    @admin_user.update!(admin: true)
  end

  test "stat card links navigate to correct admin pages" do
    post "/login", params: { email: @admin_user.email, password: "password" }

    # Visit admin dashboard
    get admin_dashboard_path
    assert_response :success

    # Test users stat card link
    assert_select "a[href='#{admin_users_path}']"

    # Test total runs stat card link
    assert_select "a[href='#{admin_runs_path}']"

    # Test strava runs stat card link
    assert_select "a[href='#{admin_runs_path(source: "strava")}']"

    # Test manual runs stat card link
    assert_select "a[href='#{admin_runs_path(source: "manual")}']"

    # Test plays stat card link
    assert_select "a[href='#{admin_plays_path}']"

    # Test deadlines stat card link
    assert_select "a[href='#{admin_race_deadlines_path}']"
  end

  test "clicking stat cards navigates to correct filtered views" do
    post "/login", params: { email: @admin_user.email, password: "password" }

    # Test navigation to strava runs
    get admin_runs_path(source: "strava")
    assert_response :success

    # Test navigation to manual runs
    get admin_runs_path(source: "manual")
    assert_response :success

    # Test navigation to users
    get admin_users_path
    assert_response :success

    # Test navigation to plays
    get admin_plays_path
    assert_response :success

    # Test navigation to race deadlines
    get admin_race_deadlines_path
    assert_response :success
  end

  test "admin runs controller filters by source correctly" do
    # Create test runs
    strava_run = Run.create!(
      user: @admin_user,
      date: Date.current,
      time: 1500,
      race_type: "5k",
      source: "strava"
    )

    manual_run = Run.create!(
      user: @admin_user,
      date: Date.current,
      time: 1600,
      race_type: "5k",
      source: "manual"
    )

    post "/login", params: { email: @admin_user.email, password: "password" }

    # Test strava filter
    get admin_runs_path(source: "strava")
    assert_response :success
    assert_includes assigns(:runs), strava_run
    assert_not_includes assigns(:runs), manual_run

    # Test manual filter
    get admin_runs_path(source: "manual")
    assert_response :success
    assert_includes assigns(:runs), manual_run
    assert_not_includes assigns(:runs), strava_run

    # Test no filter shows all
    get admin_runs_path
    assert_response :success
    assert_includes assigns(:runs), strava_run
    assert_includes assigns(:runs), manual_run
  end
end
