require Rails.root.join("app/services/score_calculator")
require Rails.root.join("app/services/game_state_service")
require Rails.root.join("app/services/roll_validator_service")

class RollService
  def initialize(game:, pins:)
    @game = game
    @pins = pins
    @frames = game.frames.order(:number).includes(:rolls)
  end

  def perform
    score_calculator = ScoreCalculator.new(@game, @frames)
    game_state_service = GameStateService.new(@game, @frames, score_calculator)

    return failure("Game is in an invalid state") unless game_state_service.valid_game_state?

    frame = game_state_service.find_available_frame
    return failure("Game is already complete") if frame.nil?

    roll_number = game_state_service.next_roll_number(frame)
    roll_validator = RollValidatorService.new(frame, roll_number, @pins)
    return failure(roll_validator.validation_errors.join(", ")) unless roll_validator.valid_roll?

    roll = frame.rolls.build(roll_number: roll_number, pins: @pins)
    if roll.save
      message = (roll.pins == BowlingRules::MAX_PINS && roll_number == 1) ? "Strike! Frame complete." : "Roll recorded successfully"
      success(roll: roll, frame: frame, roll_number: roll_number, message: message)
    else
      failure(roll.errors.full_messages.join(", "), roll.errors.messages)
    end
  end

  private

  def success(data)
    { success: true, **data }
  end

  def failure(error, validation_errors = {})
    {
      success: false,
      error: error,
      validation_errors: validation_errors
    }
  end
end
