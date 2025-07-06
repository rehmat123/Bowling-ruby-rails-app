require 'rails_helper'

RSpec.describe ScoreCalculator, type: :service do
  let(:game) {
    game = Game.create!
    10.times { |i| game.frames.create!(number: i + 1) }
    game
  }
  let(:service) { ScoreCalculator.new(game) }

  def add_rolls(rolls_by_frame)
    game.frames.each_with_index do |frame, i|
      (rolls_by_frame[i] || []).each_with_index do |pins, j|
        frame.rolls.create!(roll_number: j + 1, pins: pins)
      end
    end
  end

  describe '#calculate_score' do
    it 'returns 0 for a new game' do
      expect(service.calculate_score).to eq({ frame_scores: [ 0 ]*10, total_score: 0 })
    end

    it 'scores a perfect game' do
      # 12 strikes
      add_rolls(Array.new(9) { [ 10 ] } + [ [ 10, 10, 10 ] ])
      expect(service.calculate_score[:total_score]).to eq(300)
      expect(service.calculate_score[:frame_scores]).to eq([ 30 ]*10)
    end

    it 'scores a gutter game' do
      add_rolls(Array.new(10) { [ 0, 0 ] })
      expect(service.calculate_score[:total_score]).to eq(0)
      expect(service.calculate_score[:frame_scores]).to eq([ 0 ]*10)
    end

    it 'scores a game with all spares (5,5 + 5)' do
      add_rolls(Array.new(9) { [ 5, 5 ] } + [ [ 5, 5, 5 ] ])
      expect(service.calculate_score[:total_score]).to eq(150)
      expect(service.calculate_score[:frame_scores]).to eq([ 15 ]*10)
    end

    it 'scores a mixed game (strike, spare, open)' do
      add_rolls([
        [ 10 ],      # strike
        [ 5, 5 ],     # spare
        [ 3, 4 ],     # open
        [ 10 ],      # strike
        [ 10 ],      # strike
        [ 2, 8 ],     # spare
        [ 0, 0 ],     # open
        [ 10 ],      # strike
        [ 1, 9 ],     # spare
        [ 10, 10, 10 ] # 10th frame
      ])
      result = service.calculate_score
      expect(result[:frame_scores].length).to eq(10)
      expect(result[:total_score]).to be > 0
    end
  end

  describe '#strike?' do
    it 'returns true for a strike' do
      add_rolls([ [ 10 ] ] + Array.new(9) { [ 0, 0 ] })
      expect(service.strike?(0)).to be true
    end
    it 'returns false for non-strike' do
      add_rolls([ [ 5, 5 ] ] + Array.new(9) { [ 0, 0 ] })
      expect(service.strike?(0)).to be false
    end
  end

  describe '#spare?' do
    it 'returns true for a spare' do
      add_rolls([ [ 5, 5 ] ] + Array.new(9) { [ 0, 0 ] })
      expect(service.spare?(0)).to be true
    end
    it 'returns false for non-spare' do
      add_rolls([ [ 3, 4 ] ] + Array.new(9) { [ 0, 0 ] })
      expect(service.spare?(0)).to be false
    end
  end

  describe '#total_rolls' do
    it 'returns correct number of rolls' do
      add_rolls([ [ 10 ], [ 5, 5 ], [ 3, 4 ], [ 10 ], [ 10 ], [ 2, 8 ], [ 0, 0 ], [ 10 ], [ 1, 9 ], [ 10, 10, 10 ] ])
      expect(service.total_rolls).to eq(17)
    end
  end

  describe '#game_complete?' do
    it 'returns false for incomplete game' do
      add_rolls([ [ 10 ], [ 5, 5 ] ])
      expect(service.game_complete?).to be false
    end
    it 'returns true for complete game' do
      add_rolls(Array.new(9) { [ 10 ] } + [ [ 10, 10, 10 ] ])
      expect(service.game_complete?).to be true
    end
  end

  describe '#frame_complete?' do
    it 'returns true for complete regular frame (strike)' do
      frame = game.frames.first
      frame.rolls.create!(roll_number: 1, pins: 10)
      expect(service.frame_complete?(frame)).to be true
    end
    it 'returns true for complete regular frame (two rolls)' do
      frame = game.frames.first
      frame.rolls.create!(roll_number: 1, pins: 5)
      frame.rolls.create!(roll_number: 2, pins: 4)
      expect(service.frame_complete?(frame)).to be true
    end
    it 'returns false for incomplete regular frame' do
      frame = game.frames.first
      frame.rolls.create!(roll_number: 1, pins: 5)
      expect(service.frame_complete?(frame)).to be false
    end
    it 'returns true for complete 10th frame (strike + 2 bonus)' do
      frame = game.frames.last
      frame.rolls.create!(roll_number: 1, pins: 10)
      frame.rolls.create!(roll_number: 2, pins: 10)
      frame.rolls.create!(roll_number: 3, pins: 10)
      expect(service.frame_complete?(frame)).to be true
    end
    it 'returns true for complete 10th frame (spare + 1 bonus)' do
      frame = game.frames.last
      frame.rolls.create!(roll_number: 1, pins: 5)
      frame.rolls.create!(roll_number: 2, pins: 5)
      frame.rolls.create!(roll_number: 3, pins: 10)
      expect(service.frame_complete?(frame)).to be true
    end
    it 'returns true for complete 10th frame (open)' do
      frame = game.frames.last
      frame.rolls.create!(roll_number: 1, pins: 3)
      frame.rolls.create!(roll_number: 2, pins: 4)
      expect(service.frame_complete?(frame)).to be true
    end
    it 'returns false for incomplete 10th frame' do
      frame = game.frames.last
      frame.rolls.create!(roll_number: 1, pins: 10)
      frame.rolls.create!(roll_number: 2, pins: 10)
      expect(service.frame_complete?(frame)).to be false
    end
  end
end
