class AddStravaToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :strava_access_token, :string
    add_column :users, :strava_refresh_token, :string
    add_column :users, :strava_athlete_id, :string

    add_index :users, :strava_athlete_id, unique: true
  end
end
