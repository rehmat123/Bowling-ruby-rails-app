require Rails.root.join("app/lib/bowling_rules")

class RollValidatorService
  def initialize(frame, roll_number, pins)
    @frame = frame
    @roll_number = roll_number
    @pins = pins
    @existing_rolls = frame.rolls.order(:roll_number)
  end

  # Validate if the roll is allowed
  def valid_roll?
    valid_pins? && valid_roll_number? && valid_frame_rules?
  end

  # Get validation errors
  def validation_errors
    errors = []

    unless valid_pins?
      errors << "Pins must be between 0 and #{BowlingRules::MAX_PINS}"
    end

    unless valid_roll_number?
      max_rolls = @frame.number == BowlingRules::MAX_FRAMES ? BowlingRules::MAX_ROLLS_TENTH_FRAME : BowlingRules::MAX_ROLLS_PER_FRAME
      errors << "Roll number must be between 1 and #{max_rolls}"
    end

    unless valid_frame_rules?
      errors << frame_rule_error_message
    end

    errors
  end

  private

  def valid_pins?
    @pins.is_a?(Integer) && @pins >= 0 && @pins <= BowlingRules::MAX_PINS
  end

  def valid_roll_number?
    max_rolls = @frame.number == BowlingRules::MAX_FRAMES ? BowlingRules::MAX_ROLLS_TENTH_FRAME : BowlingRules::MAX_ROLLS_PER_FRAME
    @roll_number.is_a?(Integer) && @roll_number >= 1 && @roll_number <= max_rolls
  end

  def valid_frame_rules?
    if @frame.number < BowlingRules::MAX_FRAMES
      valid_regular_frame_rules?
    else
      valid_10th_frame_rules?
    end
  end

  def valid_regular_frame_rules?
    case @roll_number
    when 1
      true # First roll always allowed
    when 2
      valid_second_roll_regular_frame?
    when 3
      false # Third roll not allowed in regular frames
    else
      false
    end
  end

  def valid_10th_frame_rules?
    case @roll_number
    when 1
      true # First roll always allowed
    when 2
      true # Second roll always allowed in 10th frame
    when 3
      valid_third_roll_10th_frame?
    else
      false
    end
  end

  def valid_second_roll_regular_frame?
    return false if @existing_rolls.empty?

    first_roll = @existing_rolls.first
    return false if first_roll.pins == BowlingRules::MAX_PINS # Can't have second roll after strike

    # Check if second roll would exceed 10 pins
    total_pins = first_roll.pins + @pins
    total_pins <= BowlingRules::MAX_PINS
  end

  def valid_third_roll_10th_frame?
    return false if @existing_rolls.length < 2

    first_roll = @existing_rolls[0]
    second_roll = @existing_rolls[1]

    # Third roll only allowed if first roll was strike or first two rolls were spare
    first_roll.pins == BowlingRules::MAX_PINS || (first_roll.pins + second_roll.pins == BowlingRules::MAX_PINS)
  end

  def frame_rule_error_message
    if @frame.number < BowlingRules::MAX_FRAMES
      regular_frame_error_message
    else
      tenth_frame_error_message
    end
  end

  def regular_frame_error_message
    case @roll_number
    when 2
      if @existing_rolls.any? && @existing_rolls.first.pins == BowlingRules::MAX_PINS
        "Second roll not allowed after strike in regular frames"
      else
        first_roll_pins = @existing_rolls.first&.pins || 0
        max_allowed = BowlingRules::MAX_PINS - first_roll_pins
        "Second roll cannot exceed #{max_allowed} pins"
      end
    when 3
      "Third roll not allowed in regular frames"
    else
      "Invalid roll number"
    end
  end

  def tenth_frame_error_message
    case @roll_number
    when 3
      if @existing_rolls.length < 2
        "Third roll requires two previous rolls"
      else
        first_roll = @existing_rolls[0]
        second_roll = @existing_rolls[1]

        if first_roll.pins == BowlingRules::MAX_PINS
          "Third roll allowed after strike"
        elsif first_roll.pins + second_roll.pins == BowlingRules::MAX_PINS
          "Third roll allowed after spare"
        else
          "Third roll not allowed in open frame"
        end
      end
    else
      "Invalid roll number for 10th frame"
    end
  end
end
