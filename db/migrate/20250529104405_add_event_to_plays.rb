class AddEventToPlays < ActiveRecord::Migration[8.0]
  def change
    add_reference :plays, :event, null: false, default: 1, foreign_key: true
  end
end
