require "test_helper"

class UsersControllerSignupTest < ActionDispatch::IntegrationTest
  test "should display signup form" do
    get new_user_path
    assert_response :success
    assert_select "h1", "🏃 Sign Up"
    assert_select "form.signup-form"
  end

  test "should show validation errors on invalid signup" do
    post users_path, params: {
      user: {
        firstname: "",
        lastname: "",
        email: "invalid-email",
        password: "123", # Too short
        password_confirmation: "456" # Doesn't match
      }
    }

    assert_response :success
    assert_template :new

    # Check that error messages are displayed
    assert_select ".alert.alert-error"
    assert_select ".alert.alert-error h4", /error.*prevented/
    assert_select ".alert.alert-error ul li", minimum: 1
  end

  test "should show specific validation errors" do
    post users_path, params: {
      user: {
        firstname: "",
        lastname: "Test",
        email: "invalid-email",
        password: "123",
        password_confirmation: "456"
      }
    }

    assert_response :success
    assert_template :new

    # Check that specific error messages are displayed
    assert_select ".alert.alert-error ul li", text: /First.*can't be blank/i
    assert_select ".alert.alert-error ul li", text: /Email.*invalid/i
    assert_select ".alert.alert-error ul li", text: /Password.*too short/i
  end

  test "should create user with valid data" do
    assert_difference("User.count") do
      post users_path, params: {
        user: {
          firstname: "Test",
          lastname: "User",
          email: "test@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to root_path
    assert_equal "Account created!", flash[:notice]

    # Check that user is automatically logged in
    assert session[:user_id].present?
  end

  test "should preserve form data on validation error" do
    post users_path, params: {
      user: {
        firstname: "Test",
        lastname: "User",
        email: "invalid-email",
        password: "123",
        password_confirmation: "456"
      }
    }

    assert_response :success
    assert_template :new

    # Check that form fields retain their values
    assert_select "input#user_firstname[value='Test']"
    assert_select "input#user_lastname[value='User']"
    assert_select "input[name='user[email]'][value='invalid-email']"
  end

  test "should handle missing user parameters gracefully" do
    assert_raises(ActionController::BadRequest) do
      post users_path, params: { not_user: { email: "test@example.com" } }
    end
  end

  test "should handle duplicate email addresses" do
    # Create a user first
    User.create!(
      firstname: "Existing",
      lastname: "User",
      email: "duplicate@example.com",
      password: "password123"
    )

    # Try to create another user with the same email
    post users_path, params: {
      user: {
        firstname: "New",
        lastname: "User",
        email: "duplicate@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_response :unprocessable_entity
    assert_template :new
    assert_select ".alert.alert-error ul li", text: /Email.*already taken/i
  end

  test "should sanitize and normalize input parameters" do
    post users_path, params: {
      user: {
        firstname: "  test  ",
        lastname: "  user  ",
        email: "  TEST@EXAMPLE.COM  ",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_redirected_to root_path
    user = User.last
    assert_equal "Test", user.firstname
    assert_equal "User", user.lastname
    assert_equal "test@example.com", user.email
  end

  test "should return unprocessable_entity status on validation failure" do
    post users_path, params: {
      user: {
        firstname: "",
        lastname: "",
        email: "invalid-email",
        password: "123",
        password_confirmation: "456"
      }
    }

    assert_response :unprocessable_entity
    assert_template :new
  end
end
