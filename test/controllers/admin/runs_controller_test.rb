require "test_helper"

class Admin::RunsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.create!(
      firstname: "Admin",
      lastname: "User",
      username: "admin_test",
      password: "password123",
      password_confirmation: "password123",
      admin: true
    )

    @regular_user = User.create!(
      firstname: "Regular",
      lastname: "User",
      username: "regular_test",
      password: "password123",
      password_confirmation: "password123"
    )

    @run = Run.create!(
      user: @regular_user,
      date: Date.current,
      time: 1800, # 30 minutes
      race_type: "5k"
    )
  end

  test "admin can access runs index" do
    log_in(@admin)
    get admin_runs_path
    assert_response :success
    assert_select "h1", "Admin Panel - All Runs"
  end

  test "admin can access edit form for any run" do
    log_in(@admin)
    get edit_admin_run_path(@run)
    assert_response :success
    assert_select "h1", "Edit Run - Admin Panel"
  end

  test "admin can update any run" do
    log_in(@admin)
    patch admin_run_path(@run), params: {
      run: {
        date: @run.date,
        race_type: @run.race_type,
        time: "25:00"
      }
    }
    assert_redirected_to admin_runs_path
    @run.reload
    assert_equal 1500, @run.time # 25 minutes
  end

  test "non-admin cannot access admin runs" do
    log_in(@regular_user)
    get admin_runs_path
    assert_redirected_to root_path
  end

  private

  def log_in(user)
    post login_path, params: { username: user.username, password: "password123" }
  end
end
