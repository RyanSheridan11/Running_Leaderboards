class ChangeDefaultPlayToAccepted < ActiveRecord::Migration[8.0]
  def change
    change_column_default :plays, :status, from: 'pending', to: 'approved'
  end
end
