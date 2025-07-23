class Event < ApplicationRecord
  has_many :feedbacks, dependent: :destroy
end
