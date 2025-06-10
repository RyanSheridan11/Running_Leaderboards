require "test_helper"

class RunsControllerAdminTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:ryan)
    @regular_user = users(:alice)
    @admin_user.update!(admin: true)
    @regular_user.update!(admin: false)
  end

  test "admin can create run for another user" do
    post "/login", params: { email: @admin_user.email, password: "password" }

    assert_difference("Run.count") do
      post runs_path, params: {
        run: {
          user_id: @regular_user.id,
          race_type: "5k",
          date: Date.current,
          time: "25:30"
        }
      }
    end

    run = Run.last
    assert_equal @regular_user, run.user
    assert_equal "5k", run.race_type
    assert_redirected_to root_path
  end

  test "admin can edit run and change user" do
    run = runs(:alice_5k)
    post "/login", params: { email: @admin_user.email, password: "password" }

    patch run_path(run), params: {
      run: {
        user_id: @admin_user.id,
        race_type: run.race_type,
        date: run.date,
        time: "24:00"
      }
    }

    run.reload
    assert_equal @admin_user, run.user
    assert_redirected_to root_path
  end

  test "regular user cannot specify user_id" do
    post "/login", params: { email: @regular_user.email, password: "password" }

    assert_difference("Run.count") do
      post runs_path, params: {
        run: {
          user_id: @admin_user.id,  # This should be ignored
          race_type: "5k",
          date: Date.current,
          time: "25:30"
        }
      }
    end

    run = Run.last
    assert_equal @regular_user, run.user  # Should be the logged-in user, not admin
  end
end
