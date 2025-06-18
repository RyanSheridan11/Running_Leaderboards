class AddUserTypeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :user_type, :string, default: "player", null: false
    add_index :users, :user_type
  end
end
