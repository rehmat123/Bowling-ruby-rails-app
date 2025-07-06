require Rails.root.join("app/lib/bowling_rules")

class ScoreCalculator
  def initialize(game, frames = nil, rolls = nil)
    @game = game
    @frames = frames || game.frames.order(:number).includes(:rolls)
    @rolls = rolls || @frames.flat_map { |f| f.rolls.order(:roll_number) }
  end

  # Returns a hash with frame-by-frame and total score
  def calculate_score
    frame_scores = []
    total = 0
    roll_index = 0

    BowlingRules::MAX_FRAMES.times do |frame_number|
      frame_score = calculate_frame_score(frame_number, roll_index)
      frame_scores << frame_score
      total += frame_score

      # Move roll index based on frame type
      if strike?(roll_index)
        roll_index += 1
      else
        roll_index += 2
      end
    end

    {
      frame_scores: frame_scores,
      total_score: total
    }
  end

  # Calculate score for a specific frame
  def calculate_frame_score(frame_number, roll_index)
    return 0 if roll_index >= @rolls.length

    if strike?(roll_index)
      calculate_strike_score(roll_index)
    elsif spare?(roll_index)
      calculate_spare_score(roll_index)
    else
      calculate_open_frame_score(roll_index)
    end
  end

  # Check if current roll is a strike
  def strike?(roll_index)
    return false if roll_index >= @rolls.length
    @rolls[roll_index].pins == BowlingRules::MAX_PINS
  end

  # Check if current two rolls make a spare
  def spare?(roll_index)
    return false if roll_index + 1 >= @rolls.length
    @rolls[roll_index].pins + @rolls[roll_index + 1].pins == BowlingRules::MAX_PINS
  end

  # Calculate score for a strike (10 + next two rolls)
  def calculate_strike_score(roll_index)
    score = BowlingRules::MAX_PINS

    # Add first bonus roll
    if roll_index + 1 < @rolls.length
      score += @rolls[roll_index + 1].pins
    end

    # Add second bonus roll
    if roll_index + 2 < @rolls.length
      score += @rolls[roll_index + 2].pins
    end

    score
  end

  # Calculate score for a spare (10 + next roll)
  def calculate_spare_score(roll_index)
    score = BowlingRules::MAX_PINS

    # Add bonus roll
    if roll_index + 2 < @rolls.length
      score += @rolls[roll_index + 2].pins
    end

    score
  end

  # Calculate score for an open frame (sum of two rolls)
  def calculate_open_frame_score(roll_index)
    score = @rolls[roll_index].pins

    if roll_index + 1 < @rolls.length
      score += @rolls[roll_index + 1].pins
    end

    score
  end

  # Get total number of rolls
  def total_rolls
    @rolls.length
  end

  # Check if game is complete
  def game_complete?
    return false if @frames.length != BowlingRules::MAX_FRAMES

    @frames.all? { |frame| frame_complete?(frame) }
  end

  # Check if a specific frame is complete
  def frame_complete?(frame)
    rolls = frame.rolls.order(:roll_number)

    if frame.number == BowlingRules::MAX_FRAMES
      complete_10th_frame?(rolls)
    else
      complete_regular_frame?(rolls)
    end
  end

  private

  def complete_regular_frame?(rolls)
    return false if rolls.empty?

    if rolls.first.pins == BowlingRules::MAX_PINS # Strike
      true
    elsif rolls.length >= BowlingRules::MAX_ROLLS_PER_FRAME # Two rolls
      true
    else
      false
    end
  end

  def complete_10th_frame?(rolls)
    return false if rolls.empty?

    if rolls.first.pins == BowlingRules::MAX_PINS # Strike
      rolls.length >= BowlingRules::MAX_ROLLS_TENTH_FRAME
    elsif rolls.length >= BowlingRules::MAX_ROLLS_PER_FRAME && rolls[0].pins + rolls[1].pins == BowlingRules::MAX_PINS # Spare
      rolls.length >= BowlingRules::MAX_ROLLS_TENTH_FRAME
    else # Open frame
      rolls.length >= BowlingRules::MAX_ROLLS_PER_FRAME
    end
  end
end
