class RemoveScoreFromPlays < ActiveRecord::Migration[8.0]
  def change
    remove_column :plays, :score
  end
end
