require Rails.root.join('app/schemas/roll_schema')
require Rails.root.join('app/schemas/game_schema')

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
      
      frame = game.frames.order(:number).detect do |f|
        can_roll_in_frame?(f)
      end
      
      if frame.nil?
        render json: { 
          error: 'Game is already complete',
          game_id: game.id
        }, status: :unprocessable_entity
        return
      end
      
      roll_number = frame.rolls.count + 1
      roll = frame.rolls.build(roll_number: roll_number, pins: result[:roll][:pins])
      
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
          received_data: { pins: result[:roll][:pins], frame: frame.number, roll: roll_number }
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

    # Determines if a roll can be made in this frame
    def can_roll_in_frame?(frame)
      rolls = frame.rolls.order(:roll_number)
      return false if rolls.count >= (frame.number == 10 ? 3 : 2)
      
      # For frame 10, check if it's complete
      if frame.number == 10
        return !frame_complete?(frame)
      end
      
      # For frames 1-9, check if frame is still open
      if rolls.count == 0
        return true # First roll always allowed
      elsif rolls.count == 1
        # Second roll only allowed if first roll wasn't a strike
        return rolls.first.pins < 10
      end
      
      false
    end

    # Determines if the 10th frame is complete
    def frame_complete?(frame)
      rolls = frame.rolls.order(:roll_number).pluck(:pins)
      return false if rolls.size < 2
      
      if rolls[0] == 10 || rolls[0] + rolls[1] == 10
        rolls.size >= 3
      else
        rolls.size >= 2
      end
    end
  end
end 