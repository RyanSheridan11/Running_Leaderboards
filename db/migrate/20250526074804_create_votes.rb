class CreateVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :play, null: false, foreign_key: true
      t.integer :ranking, null: false

      t.timestamps
    end

    add_index :votes, [:user_id, :play_id], unique: true
    add_index :votes, [:user_id, :ranking]
  end
end
