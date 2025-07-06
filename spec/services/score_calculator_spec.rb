require 'rails_helper'

RSpec.describe ScoreCalculator, type: :service do
  let(:game) { Game.create! }
  let(:score_calculator) { ScoreCalculator.new(game) }

  before do
    # Create 10 frames for the game
    10.times { |i| game.frames.create!(number: i + 1) }
  end

  describe '#calculate_score' do
    it 'returns 0 for empty game' do
      result = score_calculator.calculate_score
      expect(result[:total_score]).to eq(0)
      expect(result[:frame_scores]).to all(eq(0))
    end

    it 'calculates score for open frames' do
      frame1 = game.frames.find_by(number: 1)
      frame1.rolls.create!(roll_number: 1, pins: 3)
      frame1.rolls.create!(roll_number: 2, pins: 4)
      
      frame2 = game.frames.find_by(number: 2)
      frame2.rolls.create!(roll_number: 1, pins: 5)
      frame2.rolls.create!(roll_number: 2, pins: 2)
      
      result = score_calculator.calculate_score
      expect(result[:total_score]).to eq(14) # 3+4 + 5+2
      expect(result[:frame_scores][0]).to eq(7) # 3+4
      expect(result[:frame_scores][1]).to eq(7) # 5+2
    end

    it 'calculates score for strike' do
      frame1 = game.frames.find_by(number: 1)
      frame1.rolls.create!(roll_number: 1, pins: 10)
      
      frame2 = game.frames.find_by(number: 2)
      frame2.rolls.create!(roll_number: 1, pins: 3)
      frame2.rolls.create!(roll_number: 2, pins: 4)
      
      result = score_calculator.calculate_score
      expect(result[:total_score]).to eq(24) # 10+3+4 + 3+4
      expect(result[:frame_scores][0]).to eq(17) # 10+3+4
      expect(result[:frame_scores][1]).to eq(7) # 3+4
    end

    it 'calculates score for spare' do
      frame1 = game.frames.find_by(number: 1)
      frame1.rolls.create!(roll_number: 1, pins: 7)
      frame1.rolls.create!(roll_number: 2, pins: 3)
      
      frame2 = game.frames.find_by(number: 2)
      frame2.rolls.create!(roll_number: 1, pins: 5)
      frame2.rolls.create!(roll_number: 2, pins: 2)
      
      result = score_calculator.calculate_score
      expect(result[:total_score]).to eq(22) # 7+3+5 + 5+2
      expect(result[:frame_scores][0]).to eq(15) # 7+3+5
      expect(result[:frame_scores][1]).to eq(7) # 5+2
    end

    it 'calculates perfect game score' do
      # Create 12 strikes (10 frames + 2 bonus)
      game.frames.each do |frame|
        if frame.number <= 10
          frame.rolls.create!(roll_number: 1, pins: 10)
          if frame.number == 10
            frame.rolls.create!(roll_number: 2, pins: 10)
            frame.rolls.create!(roll_number: 3, pins: 10)
          end
        end
      end
      
      result = score_calculator.calculate_score
      expect(result[:total_score]).to eq(300)
      expect(result[:frame_scores].last).to eq(30) # Last frame: 10 + 10 + 10
    end

    it 'calculates gutter game score' do
      game.frames.each do |frame|
        frame.rolls.create!(roll_number: 1, pins: 0)
        frame.rolls.create!(roll_number: 2, pins: 0)
      end
      
      result = score_calculator.calculate_score
      expect(result[:total_score]).to eq(0)
      expect(result[:frame_scores]).to all(eq(0))
    end

    it 'handles incomplete game' do
      # Only complete first 3 frames
      game.frames.limit(3).each do |frame|
        frame.rolls.create!(roll_number: 1, pins: 3)
        frame.rolls.create!(roll_number: 2, pins: 4)
      end
      
      result = score_calculator.calculate_score
      expect(result[:total_score]).to eq(21) # 3+4 + 3+4 + 3+4
      expect(result[:frame_scores][0..2]).to all(eq(7))
      expect(result[:frame_scores][3..9]).to all(eq(0)) # Incomplete frames
    end
  end

  describe '#calculate_frame_score' do
    it 'calculates open frame score' do
      frame1 = game.frames.find_by(number: 1)
      frame1.rolls.create!(roll_number: 1, pins: 3)
      frame1.rolls.create!(roll_number: 2, pins: 4)
      
      score = score_calculator.calculate_frame_score(0, 0)
      expect(score).to eq(7)
    end

    it 'calculates strike score' do
      frame1 = game.frames.find_by(number: 1)
      frame1.rolls.create!(roll_number: 1, pins: 10)
      
      frame2 = game.frames.find_by(number: 2)
      frame2.rolls.create!(roll_number: 1, pins: 3)
      frame2.rolls.create!(roll_number: 2, pins: 4)
      
      score = score_calculator.calculate_frame_score(0, 0)
      expect(score).to eq(17) # 10 + 3 + 4
    end

    it 'calculates spare score' do
      frame1 = game.frames.find_by(number: 1)
      frame1.rolls.create!(roll_number: 1, pins: 7)
      frame1.rolls.create!(roll_number: 2, pins: 3)
      
      frame2 = game.frames.find_by(number: 2)
      frame2.rolls.create!(roll_number: 1, pins: 5)
      
      score = score_calculator.calculate_frame_score(0, 0)
      expect(score).to eq(15) # 7 + 3 + 5
    end
  end

  describe '#strike?' do
    it 'returns true for strike' do
      frame1 = game.frames.find_by(number: 1)
      frame1.rolls.create!(roll_number: 1, pins: 10)
      
      expect(score_calculator.strike?(0)).to be true
    end

    it 'returns false for non-strike' do
      frame1 = game.frames.find_by(number: 1)
      frame1.rolls.create!(roll_number: 1, pins: 9)
      
      expect(score_calculator.strike?(0)).to be false
    end

    it 'returns false for empty roll index' do
      expect(score_calculator.strike?(0)).to be false
    end
  end

  describe '#spare?' do
    it 'returns true for spare' do
      frame1 = game.frames.find_by(number: 1)
      frame1.rolls.create!(roll_number: 1, pins: 7)
      frame1.rolls.create!(roll_number: 2, pins: 3)
      
      expect(score_calculator.spare?(0)).to be true
    end

    it 'returns false for non-spare' do
      frame1 = game.frames.find_by(number: 1)
      frame1.rolls.create!(roll_number: 1, pins: 7)
      frame1.rolls.create!(roll_number: 2, pins: 2)
      
      expect(score_calculator.spare?(0)).to be false
    end

    it 'returns false for insufficient rolls' do
      frame1 = game.frames.find_by(number: 1)
      frame1.rolls.create!(roll_number: 1, pins: 7)
      
      expect(score_calculator.spare?(0)).to be false
    end
  end

  describe '#total_rolls' do
    it 'returns 0 for empty game' do
      expect(score_calculator.total_rolls).to eq(0)
    end

    it 'counts total rolls correctly' do
      frame1 = game.frames.find_by(number: 1)
      frame1.rolls.create!(roll_number: 1, pins: 10)
      
      frame2 = game.frames.find_by(number: 2)
      frame2.rolls.create!(roll_number: 1, pins: 3)
      frame2.rolls.create!(roll_number: 2, pins: 4)
      
      expect(score_calculator.total_rolls).to eq(3)
    end
  end

  describe '#game_complete?' do
    it 'returns false for empty game' do
      expect(score_calculator.game_complete?).to be false
    end

    it 'returns true for completed game with open frames' do
      game.frames.each do |frame|
        frame.rolls.create!(roll_number: 1, pins: 3)
        frame.rolls.create!(roll_number: 2, pins: 4)
      end
      
      expect(score_calculator.game_complete?).to be true
    end

    it 'returns true for completed game with strikes' do
      game.frames.each do |frame|
        frame.rolls.create!(roll_number: 1, pins: 10)
        if frame.number == 10
          frame.rolls.create!(roll_number: 2, pins: 10)
          frame.rolls.create!(roll_number: 3, pins: 10)
        end
      end
      
      expect(score_calculator.game_complete?).to be true
    end
  end

  describe 'dependency injection' do
    it 'accepts custom frames and rolls' do
      custom_frames = game.frames.limit(5)
      custom_rolls = []
      
      custom_frames.each do |frame|
        frame.rolls.create!(roll_number: 1, pins: 5)
        frame.rolls.create!(roll_number: 2, pins: 3)
        custom_rolls.concat(frame.rolls.to_a)
      end
      
      custom_calculator = ScoreCalculator.new(game, custom_frames, custom_rolls)
      result = custom_calculator.calculate_score
      
      expect(result[:total_score]).to eq(40) # 5 frames * 8 pins each
      expect(result[:frame_scores][0..4]).to all(eq(8))
      expect(result[:frame_scores][5..9]).to all(eq(0)) # Incomplete frames
    end
  end
end 