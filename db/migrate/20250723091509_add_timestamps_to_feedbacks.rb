class AddTimestampsToFeedbacks < ActiveRecord::Migration[8.0]
  def change
    add_timestamps :feedbacks, null: false, default: -> { 'CURRENT_TIMESTAMP' }
  end
end
