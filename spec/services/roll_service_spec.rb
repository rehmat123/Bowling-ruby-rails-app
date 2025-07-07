require 'rails_helper'

describe RollService, type: :service do
  let(:game) do
    g = Game.create!
    10.times { |i| g.frames.create!(number: i + 1) }
    g
  end

  describe '#perform' do
    context 'with valid input' do
      it 'creates a roll in the first frame' do
        service = RollService.new(game: game, pins: 5)
        result = service.perform
        expect(result[:success]).to be true
        expect(result[:roll].pins).to eq(5)
        expect(result[:frame].number).to eq(1)
        expect(result[:roll_number]).to eq(1)
      end

      it 'creates a strike with correct message' do
        service = RollService.new(game: game, pins: 10)
        result = service.perform
        expect(result[:success]).to be true
        expect(result[:message]).to eq("Strike! Frame complete.")
      end

      it 'creates a spare with correct message' do
        game.frames.first.rolls.create!(roll_number: 1, pins: 5)
        service = RollService.new(game: game, pins: 5)
        result = service.perform
        expect(result[:success]).to be true
        expect(result[:roll].pins).to eq(5)
        expect(result[:frame].number).to eq(1)
        expect(result[:roll_number]).to eq(2)
      end
    end

    context 'with invalid input' do
      it 'rejects negative pins' do
        service = RollService.new(game: game, pins: -1)
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error]).to include("Pins must be between 0")
      end

      it 'rejects pins greater than 10' do
        service = RollService.new(game: game, pins: 11)
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error]).to include("Pins must be between 0")
      end

      it 'rejects second roll that exceeds frame total' do
        game.frames.first.rolls.create!(roll_number: 1, pins: 7)
        service = RollService.new(game: game, pins: 5)
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error]).to include("Second roll cannot exceed")
      end
    end
  end
end
