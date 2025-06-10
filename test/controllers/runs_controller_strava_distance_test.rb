require "test_helper"

class RunsControllerStravaDistanceTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:ryan)
    @regular_user = users(:alice)
    @admin_user.update!(admin: true)
    @regular_user.update!(admin: false)
  end

  test "admin can create run with strava_distance" do
    post "/login", params: { email: @admin_user.email, password: "password" }

    assert_difference("Run.count") do
      post runs_path, params: {
        run: {
          user_id: @regular_user.id,
          race_type: "5k",
          date: Date.current,
          time: "25:30",
          strava_distance: 5000.0
        }
      }
    end

    run = Run.last
    assert_equal @regular_user, run.user
    assert_equal 5000.0, run.strava_distance
    assert_redirected_to root_path
  end

  test "admin can edit run and update strava_distance" do
    run = Run.create!(
      user: @regular_user,
      date: Date.current,
      time: 1500,
      race_type: "5k",
      source: "strava",
      strava_distance: 5000.0
    )

    post "/login", params: { email: @admin_user.email, password: "password" }

    patch run_path(run), params: {
      run: {
        user_id: run.user_id,
        race_type: run.race_type,
        date: run.date,
        time: "24:00",
        strava_distance: 5100.0
      }
    }

    run.reload
    assert_equal 5100.0, run.strava_distance
    assert_redirected_to root_path
  end

  test "regular user cannot set strava_distance" do
    post "/login", params: { email: @regular_user.email, password: "password" }

    assert_difference("Run.count") do
      post runs_path, params: {
        run: {
          race_type: "5k",
          date: Date.current,
          time: "25:30",
          strava_distance: 5000.0  # This should be ignored
        }
      }
    end

    run = Run.last
    assert_equal @regular_user, run.user
    assert_nil run.strava_distance  # Should be nil since regular user can't set it
  end
end
