class CreateRaceDeadlines < ActiveRecord::Migration[8.0]
  def change
    create_table :race_deadlines do |t|
      t.string :race_type, null: false
      t.date :due_date, null: false
      t.text :description
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    
    add_index :race_deadlines, [:race_type, :active]
  end
end
