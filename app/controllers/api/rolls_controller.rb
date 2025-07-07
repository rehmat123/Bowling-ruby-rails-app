require Rails.root.join("app/schemas/roll_schema")
require Rails.root.join("app/services/roll_service")

module Api
  class RollsController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    before_action :set_default_format

    def create
      result = RollSchema.call(params.to_unsafe_h)
      unless result.success?
        render json: { errors: result.errors.to_h }, status: :unprocessable_entity
        return
      end

      game = Game.find(params[:game_id])
      pins = result[:roll][:pins]

      service_result = RollService.new(game: game, pins: pins).perform

      if service_result[:success]
        render json: {
          frame: service_result[:frame].number,
          roll: service_result[:roll_number],
          pins: service_result[:roll].pins,
          message: service_result[:message]
        }, status: :created
      else
        render json: {
          error: service_result[:error],
          validation_errors: service_result[:validation_errors],
          received_data: { pins: pins }
        }, status: :unprocessable_entity
      end
    end

    private

    def not_found
      render json: { error: "Game not found" }, status: :not_found
    end

    def set_default_format
      request.format = :json
    end
  end
end
