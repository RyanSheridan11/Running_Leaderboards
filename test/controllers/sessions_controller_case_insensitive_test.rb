require "test_helper"

class SessionsControllerCaseInsensitiveTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "testuser@example.com",
      firstname: "Test",
      lastname: "User",
      password: "password123"
    )
  end

  test "should login with lowercase email" do
    post login_path, params: { email: "testuser@example.com", password: "password123" }
    assert_redirected_to root_path
    assert_equal @user.id, session[:user_id]
  end

  test "should login with uppercase email" do
    post login_path, params: { email: "TESTUSER@EXAMPLE.COM", password: "password123" }
    assert_redirected_to root_path
    assert_equal @user.id, session[:user_id]
  end

  test "should login with mixed case email" do
    post login_path, params: { email: "TestUser@Example.Com", password: "password123" }
    assert_redirected_to root_path
    assert_equal @user.id, session[:user_id]
  end

  test "should login with random case email" do
    post login_path, params: { email: "tEsTuSeR@eXaMpLe.CoM", password: "password123" }
    assert_redirected_to root_path
    assert_equal @user.id, session[:user_id]
  end

  test "should fail login with wrong password regardless of email case" do
    post login_path, params: { email: "TESTUSER@EXAMPLE.COM", password: "wrongpassword" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_match(/wrong password/i, response.body)
  end

  test "should fail login with non-existent email" do
    post login_path, params: { email: "nonexistent@example.com", password: "password123" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_match(/user does not exist/i, response.body)
  end
end
