require "test_helper"

class RunsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.create!(
      firstname: "Admin",
      lastname: "User",
      email: "admin_main@test.com",
      password: "password123",
      password_confirmation: "password123",
      admin: true
    )

    @regular_user = User.create!(
      firstname: "Regular",
      lastname: "User",
      email: "regular_main@test.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @other_user = User.create!(
      firstname: "Other",
      lastname: "User",
      email: "other_main@test.com",
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

  test "should get index" do
    get runs_index_url
    assert_response :success
  end

  test "should get new when logged in" do
    log_in(@regular_user)
    get new_run_path
    assert_response :success
  end

  test "regular user can edit own run" do
    log_in(@regular_user)
    get edit_run_path(@run)
    assert_response :success
  end

  test "regular user cannot edit other user's run" do
    log_in(@other_user)
    get edit_run_path(@run)
    assert_redirected_to root_path
  end

  test "admin can edit any user's run" do
    log_in(@admin)
    get edit_run_path(@run)
    assert_response :success
  end

  test "admin can update any user's run" do
    log_in(@admin)
    patch run_path(@run), params: {
      run: {
        date: @run.date,
        race_type: @run.race_type,
        time: "28:00"
      }
    }
    assert_redirected_to root_path
    @run.reload
    assert_equal 1680, @run.time # 28 minutes
  end

  private

  def log_in(user)
    post login_path, params: { email: user.email, password: "password123" }
  end
end
