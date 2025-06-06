class AddStravaActivityIdToRuns < ActiveRecord::Migration[8.0]
  def change
    add_column :runs, :strava_activity_id, :string
    add_index :runs, :strava_activity_id, unique: true
  end
end
