class AddStartDateToRaceDeadlines < ActiveRecord::Migration[8.0]
  def change
    add_column :race_deadlines, :start_date, :date
  end
end
