class Roll < ApplicationRecord
  belongs_to :frame
  
  # Validations
  validates :roll_number, presence: true,
                         numericality: { 
                           only_integer: true, 
                           greater_than: 0, 
                           less_than_or_equal_to: 3,
                           message: "must be an integer between 1 and 3"
                         }
  
  # Custom validation for frame rules
  validate :frame_rules
  
  private
  
  def frame_rules
    return unless frame && pins
    
    # For frames 1-9, second roll can't exceed remaining pins
    if frame.number < 10 && roll_number == 2
      first_roll = frame.rolls.where(roll_number: 1).first
      if first_roll && (first_roll.pins + pins) > 10
        errors.add(:pins, "cannot exceed #{10 - first_roll.pins} for second roll in frame #{frame.number}")
      end
    end
    
    # For frame 10, validate third roll conditions
    if frame.number == 10 && roll_number == 3
      first_roll = frame.rolls.where(roll_number: 1).first
      second_roll = frame.rolls.where(roll_number: 2).first
      
      if first_roll && second_roll
        # Third roll only allowed if first roll was strike or first two rolls were spare
        unless first_roll.pins == 10 || (first_roll.pins + second_roll.pins) == 10
          errors.add(:roll_number, "third roll not allowed in frame 10 unless strike or spare")
        end
      end
    end
  end
end
