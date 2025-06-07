class MakeUsernamesCaseInsensitive < ActiveRecord::Migration[8.0]
  def up
    # Normalize existing usernames to lowercase
    execute "UPDATE users SET username = LOWER(username)"

    # Add a unique index on lowercase username for case-insensitive uniqueness
    add_index :users, "LOWER(username)", unique: true, name: "index_users_on_lower_username"
  end

  def down
    # Remove the case-insensitive index
    remove_index :users, name: "index_users_on_lower_username"
  end
end
