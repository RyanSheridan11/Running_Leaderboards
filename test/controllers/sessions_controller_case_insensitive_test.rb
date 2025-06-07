require "test_helper"

class SessionsControllerCaseInsensitiveTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      username: "testuser",
      firstname: "Test",
      lastname: "User",
      password: "password123"
    )
  end

  test "should login with lowercase username" do
    post login_path, params: { username: "testuser", password: "password123" }
    assert_redirected_to root_path
    assert_equal @user.id, session[:user_id]
  end

  test "should login with uppercase username" do
    post login_path, params: { username: "TESTUSER", password: "password123" }
    assert_redirected_to root_path
    assert_equal @user.id, session[:user_id]
  end

  test "should login with mixed case username" do
    post login_path, params: { username: "TestUser", password: "password123" }
    assert_redirected_to root_path
    assert_equal @user.id, session[:user_id]
  end

  test "should login with random case username" do
    post login_path, params: { username: "tEsTuSeR", password: "password123" }
    assert_redirected_to root_path
    assert_equal @user.id, session[:user_id]
  end

  test "should fail login with wrong password regardless of username case" do
    post login_path, params: { username: "TESTUSER", password: "wrongpassword" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_match /wrong password/i, response.body
  end

  test "should fail login with non-existent username" do
    post login_path, params: { username: "nonexistent", password: "password123" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_match /user does not exist/i, response.body
  end
end
