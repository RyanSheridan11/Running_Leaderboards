class CreateStravaTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :strava_tokens do |t|
      t.string :access_token
      t.string :refresh_token
      t.datetime :expires_at
      t.integer :expires_in

      t.timestamps
    end
  end
end
