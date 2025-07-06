require Rails.root.join("app/lib/bowling_rules")

class GameStateService
  def initialize(game, frames, score_calculator)
    @game = game
    @frames = frames
    @score_calculator = score_calculator
  end

  # Check if the game is in a valid state
  def valid_game_state?
    @frames.length == BowlingRules::MAX_FRAMES && @frames.all? { |f| f.number <= BowlingRules::MAX_FRAMES }
  end

  # Find the first frame that can accept a roll
  def find_available_frame
    @frames.detect { |frame| can_roll_in_frame?(frame) }
  end

  # Check if a roll can be made in a specific frame
  def can_roll_in_frame?(frame)
    rolls = ordered_rolls_for(frame)

    if frame.number == BowlingRules::MAX_FRAMES
      !frame_complete_10th?(rolls)
    else
      !frame_complete_regular?(rolls)
    end
  end

  # Get the next roll number for a frame
  def next_roll_number(frame)
    frame.rolls.count + 1
  end

  # Check if game is complete
  def game_complete?
    return false unless valid_game_state?

    @frames.all? { |frame| frame_complete?(frame) }
  end

  def frame_complete?(frame)
    rolls = ordered_rolls_for(frame)
    frame.number == BowlingRules::MAX_FRAMES ? frame_complete_10th?(rolls) : frame_complete_regular?(rolls)
  end

  def ordered_rolls_for(frame)
    @ordered_rolls ||= {}
    @ordered_rolls[frame.id] ||= frame.rolls.sort_by(&:roll_number)
  end

  # Get total number of rolls in the game
  def total_rolls
    @frames.sum { |frame| frame.rolls.count }
  end

  # Get game information including scores
  def game_info
    score_data = @score_calculator.calculate_score
    
    {
      game_id: @game.id,
      total_frames: @frames.length,
      total_rolls: total_rolls,
      is_complete: game_complete?,
      total_score: score_data[:total_score],
      frame_scores: score_data[:frame_scores],
      frames: @frames.map { |frame| frame_info(frame) }
    }
  end

  private

  def frame_complete_regular?(rolls)
    return false if rolls.empty?

    if rolls.first.pins == BowlingRules::MAX_PINS # Strike
      true
    elsif rolls.length >= BowlingRules::MAX_ROLLS_PER_FRAME
      true
    else
      false
    end
  end

  def frame_complete_10th?(rolls)
    return false if rolls.empty?

    first = rolls[0]&.pins || 0
    second = rolls[1]&.pins || 0

    if first == BowlingRules::MAX_PINS || (first + second == BowlingRules::MAX_PINS)
      rolls.length >= BowlingRules::MAX_ROLLS_TENTH_FRAME
    else
      rolls.length >= BowlingRules::MAX_ROLLS_PER_FRAME
    end
  end

  def frame_info(frame)
    rolls = ordered_rolls_for(frame)
    {
      number: frame.number,
      rolls: rolls.map { |roll| { roll_number: roll.roll_number, pins: roll.pins } },
      is_complete: frame_complete?(frame)
    }
  end
end
