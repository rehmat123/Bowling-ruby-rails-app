module Api
  class GamesController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    
    # Force JSON format for all responses
    before_action :set_default_format

    def create
      # Use dry-schema validation (even though no params required)
      result = GameSchema.call(params.to_unsafe_h)
      
      unless result.success?
        render json: { error: "Invalid request parameters" }, status: :unprocessable_entity
        return
      end
      
      game = Game.create!
      # Create 10 frames for the game
      (1..10).each { |n| game.frames.create!(number: n) }
      
      render json: { 
        game_id: game.id,
        message: "New bowling game created successfully"
      }, status: :created
    end

    def show
      # Validate game ID format
      unless params[:id].to_s.match?(/^\d+$/)
        render json: { 
          error: "Game ID must be a positive integer",
          received_value: params[:id]
        }, status: :bad_request
        return
      end
      
      game = Game.find(params[:id])
      render json: { 
        game_id: game.id, 
        frames: game.frames.order(:number).as_json(only: [:id, :number]),
        total_rolls: game.frames.joins(:rolls).count
      }
    end

    def score
      # Validate game ID format
      unless params[:id].to_s.match?(/^\d+$/)
        render json: { 
          error: "Game ID must be a positive integer",
          received_value: params[:id]
        }, status: :bad_request
        return
      end
      
      game = Game.find(params[:id])
      score_data = game.score_breakdown
      
      render json: score_data
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