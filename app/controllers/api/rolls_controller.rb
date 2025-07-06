require Rails.root.join('app/schemas/roll_schema')
require Rails.root.join('app/schemas/game_schema')
require Rails.root.join('app/services/game_state_service')
require Rails.root.join('app/services/roll_validator_service')

module Api
  class RollsController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    
    # Force JSON format for all responses
    before_action :set_default_format

    def create
      # Use dry-schema validation
      result = RollSchema.call(params.to_unsafe_h)
      
      unless result.success?
        render json: { errors: result.errors.to_h }, status: :unprocessable_entity
        return
      end
      
      game = Game.find(params[:game_id])
      frames = game.frames.order(:number).includes(:rolls)
      game_state_service = GameStateService.new(game, frames)
      
      # Check if game is in valid state
      unless game_state_service.valid_game_state?
        render json: { error: 'Game is in an invalid state (not exactly 10 frames, or frame > 10 exists)' }, status: :unprocessable_entity
        return
      end

      # Find the first frame that can accept a roll
      frame = game_state_service.find_available_frame
      
      if frame.nil?
        render json: { 
          error: 'Game is already complete',
          game_id: game.id
        }, status: :unprocessable_entity
        return
      end
      
      roll_number = game_state_service.next_roll_number(frame)
      pins = result[:roll][:pins]
      
      # Validate the roll using the service
      roll_validator = RollValidatorService.new(frame, roll_number, pins)
      
      unless roll_validator.valid_roll?
        render json: { 
          error: roll_validator.validation_errors.join(', '),
          received_data: { pins: pins, frame: frame.number, roll: roll_number }
        }, status: :unprocessable_entity
        return
      end
      
      # Create the roll
      roll = frame.rolls.build(roll_number: roll_number, pins: pins)
      
      if roll.save
        response_data = { 
          frame: frame.number, 
          roll: roll_number, 
          pins: roll.pins,
          message: roll.pins == 10 && roll_number == 1 ? "Strike! Frame complete." : "Roll recorded successfully"
        }
        
        render json: response_data, status: :created
      else
        render json: { 
          error: roll.errors.full_messages.join(', '),
          validation_errors: roll.errors.messages,
          received_data: { pins: pins, frame: frame.number, roll: roll_number }
        }, status: :unprocessable_entity
      end
    end

    private

    def not_found
      render json: { error: 'Game not found' }, status: :not_found
    end

    def set_default_format
      request.format = :json
    end
  end
end 