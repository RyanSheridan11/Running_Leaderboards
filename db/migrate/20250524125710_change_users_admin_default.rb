class ChangeUsersAdminDefault < ActiveRecord::Migration[8.0]
  def change
    change_column_default :users, :admin, from: true, to: false
  end
end
