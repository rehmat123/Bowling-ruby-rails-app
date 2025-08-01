class Roll < ApplicationRecord
  belongs_to :frame

  validates :pins, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :roll_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
