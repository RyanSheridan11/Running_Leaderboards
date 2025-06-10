require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:ryan)  # Assuming ryan is an admin in fixtures
    @regular_user = users(:alice)  # Assuming alice is not an admin

    # Ensure proper admin status
    @admin_user.update!(admin: true)
    @regular_user.update!(admin: false)
  end

  test "should require admin access" do
    post "/login", params: { email: @regular_user.email, password: "password" }
    get admin_users_path
    assert_redirected_to root_path
  end

  test "admin should see users index" do
    post "/login", params: { email: @admin_user.email, password: "password" }
    get admin_users_path
    assert_response :success
    assert_select "h1", "Admin Panel - All Users"
  end

  test "admin should promote user to admin" do
    post "/login", params: { email: @admin_user.email, password: "password" }

    assert_not @regular_user.admin?

    patch promote_admin_admin_user_path(@regular_user)

    assert_redirected_to admin_users_path
    assert @regular_user.reload.admin?
    assert_match "promoted to admin", flash[:notice]
  end

  test "admin should demote user from admin" do
    post "/login", params: { email: @admin_user.email, password: "password" }

    # Make the regular user an admin first
    @regular_user.update!(admin: true)
    assert @regular_user.admin?

    patch demote_admin_admin_user_path(@regular_user)

    assert_redirected_to admin_users_path
    assert_not @regular_user.reload.admin?
    assert_match "demoted from admin", flash[:notice]
  end

  test "admin cannot demote themselves" do
    post "/login", params: { email: @admin_user.email, password: "password" }

    assert @admin_user.admin?

    patch demote_admin_admin_user_path(@admin_user)

    assert_redirected_to admin_users_path
    assert @admin_user.reload.admin?  # Should still be admin
    assert_match "cannot demote yourself", flash[:alert]
  end
end
