require Rails.root.join('app/schemas/game_schema')
require Rails.root.join('app/services/score_calculator')
require Rails.root.join('app/services/game_state_service')

module Api
  class GamesController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    
    # Force JSON format for all responses
    before_action :set_default_format

    def create
      game = Game.create!
      
      # Create 10 frames for the game
      10.times do |i|
        game.frames.create!(number: i + 1)
      end
      
      render json: {
        game_id: game.id,
        message: 'New bowling game created successfully'
      }, status: :created
    end

    def show
      game = Game.find(params[:id])
      game_state_service = GameStateService.new(game)
      
      unless game_state_service.valid_game_state?
        render json: { error: 'Game is in an invalid state' }, status: :unprocessable_entity
        return
      end
      
      render json: game_state_service.game_info, status: :ok
    end

    def score
      game = Game.find(params[:id])
      score_calculator = ScoreCalculator.new(game)
      
      render json: {
        total_score: score_calculator.calculate_score[:total_score],
        frame_scores: score_calculator.calculate_score[:frame_scores]
      }, status: :ok
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