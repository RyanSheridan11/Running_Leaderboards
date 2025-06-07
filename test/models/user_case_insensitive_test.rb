require "test_helper"

class UserCaseInsensitiveTest < ActiveSupport::TestCase
  test "find_by_username should be case insensitive" do
    user = User.create!(
      username: "testuser",
      firstname: "Test",
      lastname: "User",
      password: "password"
    )

    # Test various case combinations
    assert_equal user, User.find_by_username("testuser")
    assert_equal user, User.find_by_username("TESTUSER")
    assert_equal user, User.find_by_username("TestUser")
    assert_equal user, User.find_by_username("tEsTuSeR")

    # Test with nil and empty string
    assert_nil User.find_by_username(nil)
    assert_nil User.find_by_username("")
    assert_nil User.find_by_username("   ")
  end

  test "username should be normalized to lowercase on save" do
    user = User.new(
      username: "TestUser",
      firstname: "Test",
      lastname: "User",
      password: "password"
    )

    user.save!
    assert_equal "testuser", user.username
  end

  test "username uniqueness should be case insensitive" do
    User.create!(
      username: "testuser",
      firstname: "Test",
      lastname: "User",
      password: "password"
    )

    duplicate_user = User.new(
      username: "TESTUSER",
      firstname: "Another",
      lastname: "User",
      password: "password"
    )

    assert_not duplicate_user.valid?
    assert duplicate_user.errors[:username].any?
  end

  test "generate_unique_username should be case insensitive" do
    # Create a user with auto-generated username
    existing_user = User.create!(
      firstname: "John",
      lastname: "Doe",
      password: "password"
    )

    assert_equal "johnd", existing_user.username

    # Try to create another user with same name pattern
    new_user = User.new(
      firstname: "John",
      lastname: "Doe",
      password: "password"
    )

    new_user.save!
    assert_equal "johnd1", new_user.username

    # Test that it would also avoid "JOHND" (case insensitive check)
    another_user = User.new(
      username: "JOHND2",  # This should be normalized to johnd2
      firstname: "Jane",
      lastname: "Smith",
      password: "password"
    )

    another_user.save!
    assert_equal "johnd2", another_user.username
  end
end
