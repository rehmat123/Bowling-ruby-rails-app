class RollsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def create
    game = Game.find(params[:game_id])
    pins = roll_params[:pins]
    unless pins.is_a?(Integer) && pins.between?(0, 10)
      render json: { error: 'Pins must be an integer between 0 and 10' }, status: :unprocessable_entity
      return
    end
    frame = game.frames.order(:number).detect do |f|
      f.rolls.count < (f.number == 10 ? 3 : 2) && (f.number < 10 || !frame_complete?(f))
    end
    if frame.nil?
      render json: { error: 'Game is already complete' }, status: :unprocessable_entity
      return
    end
    roll_number = frame.rolls.count + 1
    frame.rolls.create!(roll_number: roll_number, pins: pins)
    render json: { frame: frame.number, roll: roll_number, pins: pins }, status: :created
  end

  private

  def roll_params
    params.require(:roll).permit(:pins)
    { pins: params[:roll][:pins].to_i }
  rescue
    { pins: nil }
  end

  def not_found
    render json: { error: 'Game not found' }, status: :not_found
  end

  # Determines if the 10th frame is complete
  def frame_complete?(frame)
    rolls = frame.rolls.order(:roll_number).pluck(:pins)
    return false if rolls.size < 2
    if rolls[0] == 10 || rolls[0].to_i + rolls[1].to_i == 10
      rolls.size == 3
    else
      rolls.size == 2
    end
  end
end
