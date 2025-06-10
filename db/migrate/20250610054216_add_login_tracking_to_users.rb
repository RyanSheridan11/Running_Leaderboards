class AddLoginTrackingToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_login_at, :datetime
    add_column :users, :login_count, :integer, default: 0, null: false
  end
end
