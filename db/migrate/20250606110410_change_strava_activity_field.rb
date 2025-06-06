class ChangeStravaActivityField < ActiveRecord::Migration[8.0]
  def change
    remove_column :runs, :strava_activity_id
    add_column :runs, :source, :string
  end
end
