class Frame < ApplicationRecord
  belongs_to :game
  has_many :rolls, dependent: :destroy

  validates :number, presence: true, inclusion: { in: 1..10 }
  validates :number, uniqueness: { scope: :game_id }
end
