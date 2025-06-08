require "test_helper"

class UserCaseInsensitiveTest < ActiveSupport::TestCase
  test "find_by_email should be case insensitive" do
    user = User.create!(
      email: "testuser@example.com",
      firstname: "Test",
      lastname: "User",
      password: "password"
    )

    # Test various case combinations
    assert_equal user, User.find_by_email("testuser@example.com")
    assert_equal user, User.find_by_email("TESTUSER@EXAMPLE.COM")
    assert_equal user, User.find_by_email("TestUser@Example.Com")
    assert_equal user, User.find_by_email("tEsTuSeR@eXaMpLe.CoM")

    # Test with nil and empty string
    assert_nil User.find_by_email(nil)
    assert_nil User.find_by_email("")
    assert_nil User.find_by_email("   ")
  end

  test "email should be normalized to lowercase on save" do
    user = User.new(
      email: "TestUser@Example.Com",
      firstname: "Test",
      lastname: "User",
      password: "password"
    )

    user.save!
    assert_equal "testuser@example.com", user.email
  end

  test "email uniqueness should be case insensitive" do
    User.create!(
      email: "testuser@example.com",
      firstname: "Test",
      lastname: "User",
      password: "password"
    )

    duplicate_user = User.new(
      email: "TESTUSER@EXAMPLE.COM",
      firstname: "Another",
      lastname: "User",
      password: "password"
    )

    assert_not duplicate_user.valid?
    assert duplicate_user.errors[:email].any?
  end
end
