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

    errors << "Pins must be between 0 and #{BowlingRules::MAX_PINS}" unless valid_pins?
    errors << "Roll number must be between 1 and #{max_rolls_allowed}" unless valid_roll_number?
    errors << frame_rule_error_message unless valid_frame_rules?

    errors
  end

  private

  def valid_pins?
    @pins.is_a?(Integer) && @pins.between?(0, BowlingRules::MAX_PINS)
  end

  def valid_roll_number?
    @roll_number.is_a?(Integer) && @roll_number.between?(1, max_rolls_allowed)
  end

  def max_rolls_allowed
    if @frame.number == BowlingRules::MAX_FRAMES
      BowlingRules::MAX_ROLLS_TENTH_FRAME
    else
      BowlingRules::MAX_ROLLS_PER_FRAME
    end
  end

  def valid_frame_rules?
    @frame.number < BowlingRules::MAX_FRAMES ? valid_regular_frame_rules? : valid_10th_frame_rules?
  end

  def valid_regular_frame_rules?
    case @roll_number
    when 1 then true
    when 2 then valid_second_roll_regular_frame?
    else false
    end
  end

  def valid_10th_frame_rules?
    case @roll_number
    when 1, 2 then true
    when 3 then valid_third_roll_10th_frame?
    else false
    end
  end

  def valid_second_roll_regular_frame?
    return false if @existing_rolls.empty?

    first_roll = @existing_rolls.first
    return false if first_roll.pins == BowlingRules::MAX_PINS

    total_pins = first_roll.pins + @pins
    total_pins <= BowlingRules::MAX_PINS
  end

  def valid_third_roll_10th_frame?
    return false if @existing_rolls.length < 2

    first, second = @existing_rolls[0], @existing_rolls[1]
    first.pins == BowlingRules::MAX_PINS || (first.pins + second.pins == BowlingRules::MAX_PINS)
  end

  def frame_rule_error_message
    @frame.number < BowlingRules::MAX_FRAMES ? regular_frame_error_message : tenth_frame_error_message
  end

  def regular_frame_error_message
    case @roll_number
    when 2
      if @existing_rolls.first&.pins == BowlingRules::MAX_PINS
        "Second roll not allowed after strike in regular frames"
      else
        max_allowed = BowlingRules::MAX_PINS - (@existing_rolls.first&.pins || 0)
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
        first, second = @existing_rolls[0], @existing_rolls[1]
        if first.pins == BowlingRules::MAX_PINS
          "Third roll allowed after strike"
        elsif first.pins + second.pins == BowlingRules::MAX_PINS
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
