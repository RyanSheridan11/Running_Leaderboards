class ReplaceUsernameWithEmail < ActiveRecord::Migration[8.0]
  def change
    # Add email field with unique constraint
    add_column :users, :email, :string
    add_index :users, :email, unique: true

    # Remove the old username-related indexes and column
    remove_index :users, name: "index_users_on_lower_username"
    remove_column :users, :username, :string
  end
end
