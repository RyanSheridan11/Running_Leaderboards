class CreatePlays < ActiveRecord::Migration[8.0]
  def change
    create_table :plays do |t|
      t.string :title, null: false
      t.text :description
      t.string :video_url
      t.references :user, null: false, foreign_key: true
      t.integer :score, default: 0
      t.string :status, default: 'pending'

      t.timestamps
    end

    add_index :plays, :score
    add_index :plays, :status
    add_index :plays, :created_at
  end
end
