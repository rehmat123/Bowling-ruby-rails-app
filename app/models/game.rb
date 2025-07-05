class Game < ApplicationRecord
  has_many :frames, dependent: :destroy

  # Returns a hash with frame-by-frame and total score
  def score_breakdown
    frames = self.frames.order(:number).includes(:rolls)
    rolls = frames.flat_map { |f| f.rolls.order(:roll_number).pluck(:pins) }
    frame_scores = []
    total = 0
    roll_index = 0
    10.times do |frame|
      if rolls[roll_index] == 10 # strike
        score = 10 + rolls[roll_index + 1].to_i + rolls[roll_index + 2].to_i
        frame_scores << score
        total += score
        roll_index += 1
      elsif rolls[roll_index].to_i + rolls[roll_index + 1].to_i == 10 # spare
        score = 10 + rolls[roll_index + 2].to_i
        frame_scores << score
        total += score
        roll_index += 2
      else
        score = rolls[roll_index].to_i + rolls[roll_index + 1].to_i
        frame_scores << score
        total += score
        roll_index += 2
      end
    end
    {
      frame_scores: frame_scores,
      total_score: frame_scores.sum
    }
  end
end
