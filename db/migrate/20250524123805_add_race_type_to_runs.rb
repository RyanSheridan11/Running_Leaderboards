class AddRaceTypeToRuns < ActiveRecord::Migration[8.0]
  def change
    add_column :runs, :race_type, :string, default: "5k", null: false
  end
end
