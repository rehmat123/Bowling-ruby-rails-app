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
    
    10.times do |frame_number|
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
    @rolls[roll_index].pins == 10
  end

  # Check if current two rolls make a spare
  def spare?(roll_index)
    return false if roll_index + 1 >= @rolls.length
    @rolls[roll_index].pins + @rolls[roll_index + 1].pins == 10
  end

  # Calculate score for a strike (10 + next two rolls)
  def calculate_strike_score(roll_index)
    score = 10
    
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
    score = 10
    
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
    return false if @frames.length != 10
    
    @frames.all? { |frame| frame_complete?(frame) }
  end

  # Check if a specific frame is complete
  def frame_complete?(frame)
    rolls = frame.rolls.order(:roll_number)
    
    if frame.number == 10
      complete_10th_frame?(rolls)
    else
      complete_regular_frame?(rolls)
    end
  end

  private

  def complete_regular_frame?(rolls)
    return false if rolls.empty?
    
    if rolls.first.pins == 10 # Strike
      true
    elsif rolls.length >= 2 # Two rolls
      true
    else
      false
    end
  end

  def complete_10th_frame?(rolls)
    return false if rolls.empty?
    
    if rolls.first.pins == 10 # Strike
      rolls.length >= 3
    elsif rolls.length >= 2 && rolls[0].pins + rolls[1].pins == 10 # Spare
      rolls.length >= 3
    else # Open frame
      rolls.length >= 2
    end
  end
end 