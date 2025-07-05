class GamesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def create
    game = Game.create!
    # Create 10 frames for the game
    (1..10).each { |n| game.frames.create!(number: n) }
    render json: { game_id: game.id }, status: :created
  end

  def show
    game = Game.find(params[:id])
    render json: { game_id: game.id, frames: game.frames.order(:number).as_json(only: [:id, :number]) }
  end

  def score
    game = Game.find(params[:id])
    render json: game.score_breakdown
  end

  private

  def not_found
    render json: { error: 'Game not found' }, status: :not_found
  end
end
