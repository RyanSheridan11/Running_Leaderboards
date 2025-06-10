require "test_helper"

class LoginTrackingTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:ryan)
    @user.update!(admin: true, password: "password")
  end

  test "should track login when user logs in successfully" do
    assert_nil @user.last_login_at
    assert_equal 0, @user.login_count

    post "/login", params: { email: @user.email, password: "password" }

    @user.reload
    assert_not_nil @user.last_login_at
    assert_equal 1, @user.login_count
    assert_redirected_to root_path
  end

  test "should increment login count on subsequent logins" do
    @user.track_login!
    initial_count = @user.login_count

    post "/login", params: { email: @user.email, password: "password" }

    @user.reload
    assert_equal initial_count + 1, @user.login_count
  end

  test "should track login when setting up password" do
    user_without_password = User.create!(
      email: "newuser@example.com",
      firstname: "New",
      lastname: "User"
    )

    # Start password setup process
    post "/login", params: { email: user_without_password.email, password: "" }
    assert_redirected_to setup_password_path

    # Complete password setup
    post "/password", params: {
      password: "newpassword",
      password_confirmation: "newpassword"
    }

    user_without_password.reload
    assert_not_nil user_without_password.last_login_at
    assert_equal 1, user_without_password.login_count
    assert_redirected_to root_path
  end

  test "login status method returns correct status" do
    # Never logged in
    user = User.new
    assert_equal "Never logged in", user.login_status

    # Recent login
    user.last_login_at = 30.minutes.ago
    assert_equal "Active today", user.login_status

    # Old login
    user.last_login_at = 2.months.ago
    assert_match(/Inactive/, user.login_status)
  end

  test "admin dashboard shows login tracking data" do
    # Create some test data
    @user.track_login!

    post "/login", params: { email: @user.email, password: "password" }
    get admin_dashboard_path

    assert_response :success
    assert_select "h3", "🔐 Recent Logins"
    assert_select "h3", "🔑 Password Setup Status"
  end
end
