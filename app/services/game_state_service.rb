class GameStateService
  def initialize(game, frames = nil)
    @game = game
    @frames = frames || game.frames.order(:number).includes(:rolls)
  end

  # Check if the game is in a valid state
  def valid_game_state?
    @frames.length == 10 && @frames.all? { |f| f.number <= 10 }
  end

  # Find the first frame that can accept a roll
  def find_available_frame
    @frames.detect { |frame| can_roll_in_frame?(frame) }
  end

  # Check if a roll can be made in a specific frame
  def can_roll_in_frame?(frame)
    rolls = frame.rolls.order(:roll_number)
    
    if frame.number == 10
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

  # Check if a specific frame is complete
  def frame_complete?(frame)
    rolls = frame.rolls.order(:roll_number)
    
    if frame.number == 10
      frame_complete_10th?(rolls)
    else
      frame_complete_regular?(rolls)
    end
  end

  # Get total number of rolls in the game
  def total_rolls
    @frames.sum { |frame| frame.rolls.count }
  end

  # Get game information
  def game_info
    {
      game_id: @game.id,
      total_frames: @frames.length,
      total_rolls: total_rolls,
      is_complete: game_complete?,
      frames: @frames.map { |frame| frame_info(frame) }
    }
  end

  private

  def frame_complete_regular?(rolls)
    return false if rolls.empty?
    
    if rolls.first.pins == 10 # Strike
      true
    elsif rolls.length >= 2 # Two rolls
      true
    else
      false
    end
  end

  def frame_complete_10th?(rolls)
    return false if rolls.empty?
    
    if rolls.first.pins == 10 # Strike
      rolls.length >= 3
    elsif rolls.length >= 2 && rolls[0].pins + rolls[1].pins == 10 # Spare
      rolls.length >= 3
    else # Open frame
      rolls.length >= 2
    end
  end

  def frame_info(frame)
    rolls = frame.rolls.order(:roll_number)
    {
      number: frame.number,
      rolls: rolls.map { |roll| { roll_number: roll.roll_number, pins: roll.pins } },
      is_complete: frame_complete?(frame)
    }
  end
end 