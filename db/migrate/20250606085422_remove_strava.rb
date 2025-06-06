class RemoveStrava < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :strava_access_token
    remove_column :users, :strava_refresh_token
  end
end
