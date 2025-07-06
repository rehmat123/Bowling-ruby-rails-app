class Game < ApplicationRecord
  has_many :frames, dependent: :destroy
end
