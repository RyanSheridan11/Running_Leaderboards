class AddStravaDistanceToRuns < ActiveRecord::Migration[8.0]
  def change
    add_column :runs, :strava_distance, :float, comment: "Distance in meters from Strava API for better duplicate detection"
  end
end
