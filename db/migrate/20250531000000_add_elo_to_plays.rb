class AddEloToPlays < ActiveRecord::Migration[8.0]
  def change
    drop_table :votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :play, null: false, foreign_key: true
      t.integer :ranking, null: false

      t.timestamps
      add_index :votes, [:user_id, :play_id], unique: true
      add_index :votes, [:user_id, :ranking]
    end
    add_column :plays, :elo, :integer, null: false, default: 1000
    remove_column :plays, :ranking
  end
end
