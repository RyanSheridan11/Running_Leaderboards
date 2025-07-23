class CreateFeedback < ActiveRecord::Migration[8.0]
  def change
    create_table :feedbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.text :content
    end
  end
end
