class CreateRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :runs do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date
      t.integer :time

      t.timestamps
    end
  end
end
