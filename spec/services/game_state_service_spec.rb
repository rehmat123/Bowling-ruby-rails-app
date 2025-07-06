require 'rails_helper'

RSpec.describe GameStateService, type: :service do
  let(:game) {
    game = Game.create!
    # Create 10 frames for the game
    10.times do |i|
      game.frames.create!(number: i + 1)
    end
    game
  }
  let(:service) { GameStateService.new(game, game.frames.order(:number).includes(:rolls)) }

  describe '#initialize' do
    it 'initializes with a game' do
      expect(service).to be_a(GameStateService)
    end

    it 'loads frames with rolls included' do
      expect(service.send(:instance_variable_get, :@frames).first.association(:rolls).loaded?).to be true
    end
  end

  describe '#valid_game_state?' do
    context 'with valid game state' do
      it 'returns true for game with exactly 10 frames' do
        expect(service.valid_game_state?).to be true
      end
    end

    context 'with invalid game state' do
      it 'returns false when game has fewer than 10 frames' do
        game.frames.last.destroy
        expect(service.valid_game_state?).to be false
      end

      it 'returns false when game has more than 10 frames' do
        # Create an extra frame by bypassing validation
        extra_frame = game.frames.build(number: 11)
        extra_frame.save!(validate: false)
        expect(service.valid_game_state?).to be false
      end

      it 'returns false when any frame has number greater than 10' do
        # Update frame number by bypassing validation
        game.frames.first.update_column(:number, 11)
        expect(service.valid_game_state?).to be false
      end
    end
  end

  describe '#find_available_frame' do
    context 'with empty game' do
      it 'returns the first frame' do
        expect(service.find_available_frame).to eq(game.frames.first)
      end
    end

    context 'with some rolls' do
      it 'returns the first incomplete frame' do
        # Add a strike to first frame
        game.frames.first.rolls.create!(roll_number: 1, pins: 10)

        expect(service.find_available_frame).to eq(game.frames.second)
      end

      it 'returns the frame that needs a second roll' do
        # Add first roll to first frame
        game.frames.first.rolls.create!(roll_number: 1, pins: 5)

        expect(service.find_available_frame).to eq(game.frames.first)
      end
    end

    context 'with complete game' do
      it 'returns nil when all frames are complete' do
        # Complete all frames with strikes
        10.times do |i|
          frame = game.frames.find_by(number: i + 1)
          if i < 9
            frame.rolls.create!(roll_number: 1, pins: 10)
          else
            # 10th frame with 3 strikes
            frame.rolls.create!(roll_number: 1, pins: 10)
            frame.rolls.create!(roll_number: 2, pins: 10)
            frame.rolls.create!(roll_number: 3, pins: 10)
          end
        end

        expect(service.find_available_frame).to be_nil
      end
    end
  end

  describe '#can_roll_in_frame?' do
    context 'regular frames (1-9)' do
      let(:frame) { game.frames.first }

      it 'returns true for empty frame' do
        expect(service.can_roll_in_frame?(frame)).to be true
      end

      it 'returns true after first roll (non-strike)' do
        frame.rolls.create!(roll_number: 1, pins: 5)
        expect(service.can_roll_in_frame?(frame)).to be true
      end

      it 'returns false after strike' do
        frame.rolls.create!(roll_number: 1, pins: 10)
        expect(service.can_roll_in_frame?(frame)).to be false
      end

      it 'returns false after two rolls' do
        frame.rolls.create!(roll_number: 1, pins: 5)
        frame.rolls.create!(roll_number: 2, pins: 3)
        expect(service.can_roll_in_frame?(frame)).to be false
      end
    end

    context '10th frame' do
      let(:frame) { game.frames.last }

      it 'returns true for empty frame' do
        expect(service.can_roll_in_frame?(frame)).to be true
      end

      it 'returns true after first roll (non-strike)' do
        frame.rolls.create!(roll_number: 1, pins: 5)
        expect(service.can_roll_in_frame?(frame)).to be true
      end

      it 'returns true after strike' do
        frame.rolls.create!(roll_number: 1, pins: 10)
        expect(service.can_roll_in_frame?(frame)).to be true
      end

      it 'returns true after strike and second roll' do
        frame.rolls.create!(roll_number: 1, pins: 10)
        frame.rolls.create!(roll_number: 2, pins: 5)
        expect(service.can_roll_in_frame?(frame)).to be true
      end

      it 'returns false after strike and two bonus rolls' do
        frame.rolls.create!(roll_number: 1, pins: 10)
        frame.rolls.create!(roll_number: 2, pins: 10)
        frame.rolls.create!(roll_number: 3, pins: 10)
        expect(service.can_roll_in_frame?(frame)).to be false
      end

      it 'returns true after spare' do
        frame.rolls.create!(roll_number: 1, pins: 5)
        frame.rolls.create!(roll_number: 2, pins: 5)
        expect(service.can_roll_in_frame?(frame)).to be true
      end

      it 'returns false after spare and bonus roll' do
        frame.rolls.create!(roll_number: 1, pins: 5)
        frame.rolls.create!(roll_number: 2, pins: 5)
        frame.rolls.create!(roll_number: 3, pins: 5)
        expect(service.can_roll_in_frame?(frame)).to be false
      end

      it 'returns false after open frame' do
        frame.rolls.create!(roll_number: 1, pins: 5)
        frame.rolls.create!(roll_number: 2, pins: 3)
        expect(service.can_roll_in_frame?(frame)).to be false
      end
    end
  end

  describe '#next_roll_number' do
    it 'returns 1 for empty frame' do
      frame = game.frames.first
      expect(service.next_roll_number(frame)).to eq(1)
    end

    it 'returns 2 after first roll' do
      frame = game.frames.first
      frame.rolls.create!(roll_number: 1, pins: 5)
      expect(service.next_roll_number(frame)).to eq(2)
    end

    it 'returns 3 after two rolls' do
      frame = game.frames.first
      frame.rolls.create!(roll_number: 1, pins: 5)
      frame.rolls.create!(roll_number: 2, pins: 3)
      expect(service.next_roll_number(frame)).to eq(3)
    end
  end

  describe '#game_complete?' do
    context 'with incomplete game' do
      it 'returns false for empty game' do
        expect(service.game_complete?).to be false
      end

      it 'returns false with some frames incomplete' do
        # Complete first 5 frames with strikes
        5.times do |i|
          game.frames.find_by(number: i + 1).rolls.create!(roll_number: 1, pins: 10)
        end
        expect(service.game_complete?).to be false
      end
    end

    context 'with complete game' do
      it 'returns true when all frames are complete' do
        # Complete all frames with strikes
        10.times do |i|
          frame = game.frames.find_by(number: i + 1)
          if i < 9
            frame.rolls.create!(roll_number: 1, pins: 10)
          else
            # 10th frame with 3 strikes
            frame.rolls.create!(roll_number: 1, pins: 10)
            frame.rolls.create!(roll_number: 2, pins: 10)
            frame.rolls.create!(roll_number: 3, pins: 10)
          end
        end

        expect(service.game_complete?).to be true
      end

      it 'returns true with mixed frame types' do
        # Complete frames with different patterns
        game.frames.each_with_index do |frame, i|
          if i < 9
            if i % 2 == 0
              frame.rolls.create!(roll_number: 1, pins: 10) # Strike
            else
              frame.rolls.create!(roll_number: 1, pins: 5)
              frame.rolls.create!(roll_number: 2, pins: 5) # Spare
            end
          else
            # 10th frame
            frame.rolls.create!(roll_number: 1, pins: 10)
            frame.rolls.create!(roll_number: 2, pins: 10)
            frame.rolls.create!(roll_number: 3, pins: 10)
          end
        end

        expect(service.game_complete?).to be true
      end
    end
  end

  describe '#frame_complete?' do
    context 'regular frames (1-9)' do
      let(:frame) { game.frames.first }

      it 'returns false for empty frame' do
        expect(service.frame_complete?(frame)).to be false
      end

      it 'returns false after first roll (non-strike)' do
        frame.rolls.create!(roll_number: 1, pins: 5)
        expect(service.frame_complete?(frame)).to be false
      end

      it 'returns true after strike' do
        frame.rolls.create!(roll_number: 1, pins: 10)
        expect(service.frame_complete?(frame)).to be true
      end

      it 'returns true after two rolls' do
        frame.rolls.create!(roll_number: 1, pins: 5)
        frame.rolls.create!(roll_number: 2, pins: 3)
        expect(service.frame_complete?(frame)).to be true
      end
    end

    context '10th frame' do
      let(:frame) { game.frames.last }

      it 'returns false for empty frame' do
        expect(service.frame_complete?(frame)).to be false
      end

      it 'returns false after first roll (non-strike)' do
        frame.rolls.create!(roll_number: 1, pins: 5)
        expect(service.frame_complete?(frame)).to be false
      end

      it 'returns false after strike' do
        frame.rolls.create!(roll_number: 1, pins: 10)
        expect(service.frame_complete?(frame)).to be false
      end

      it 'returns false after strike and second roll' do
        frame.rolls.create!(roll_number: 1, pins: 10)
        frame.rolls.create!(roll_number: 2, pins: 5)
        expect(service.frame_complete?(frame)).to be false
      end

      it 'returns true after strike and two bonus rolls' do
        frame.rolls.create!(roll_number: 1, pins: 10)
        frame.rolls.create!(roll_number: 2, pins: 10)
        frame.rolls.create!(roll_number: 3, pins: 10)
        expect(service.frame_complete?(frame)).to be true
      end

      it 'returns false after spare' do
        frame.rolls.create!(roll_number: 1, pins: 5)
        frame.rolls.create!(roll_number: 2, pins: 5)
        expect(service.frame_complete?(frame)).to be false
      end

      it 'returns true after spare and bonus roll' do
        frame.rolls.create!(roll_number: 1, pins: 5)
        frame.rolls.create!(roll_number: 2, pins: 5)
        frame.rolls.create!(roll_number: 3, pins: 5)
        expect(service.frame_complete?(frame)).to be true
      end

      it 'returns true after open frame' do
        frame.rolls.create!(roll_number: 1, pins: 5)
        frame.rolls.create!(roll_number: 2, pins: 3)
        expect(service.frame_complete?(frame)).to be true
      end
    end
  end

  describe '#total_rolls' do
    it 'returns 0 for empty game' do
      expect(service.total_rolls).to eq(0)
    end

    it 'returns correct count with some rolls' do
      game.frames.first.rolls.create!(roll_number: 1, pins: 10)
      game.frames.second.rolls.create!(roll_number: 1, pins: 5)
      game.frames.second.rolls.create!(roll_number: 2, pins: 3)

      expect(service.total_rolls).to eq(3)
    end

    it 'returns correct count for complete game' do
      # Perfect game: 12 strikes
      10.times do |i|
        frame = game.frames.find_by(number: i + 1)
        if i < 9
          frame.rolls.create!(roll_number: 1, pins: 10)
        else
          frame.rolls.create!(roll_number: 1, pins: 10)
          frame.rolls.create!(roll_number: 2, pins: 10)
          frame.rolls.create!(roll_number: 3, pins: 10)
        end
      end

      expect(service.total_rolls).to eq(12)
    end
  end

  describe '#game_info' do
    it 'returns correct structure for empty game' do
      info = service.game_info

      expect(info).to include(
        game_id: game.id,
        total_frames: 10,
        total_rolls: 0,
        is_complete: false
      )
      expect(info[:frames].length).to eq(10)
    end

    it 'returns correct structure with some rolls' do
      game.frames.first.rolls.create!(roll_number: 1, pins: 10)
      game.frames.second.rolls.create!(roll_number: 1, pins: 5)
      game.frames.second.rolls.create!(roll_number: 2, pins: 3)

      info = service.game_info

      expect(info[:total_rolls]).to eq(3)
      expect(info[:is_complete]).to be false
      expect(info[:frames].first[:rolls]).to eq([ { roll_number: 1, pins: 10 } ])
      expect(info[:frames].first[:is_complete]).to be true
      expect(info[:frames].second[:rolls]).to eq([
        { roll_number: 1, pins: 5 },
        { roll_number: 2, pins: 3 }
      ])
      expect(info[:frames].second[:is_complete]).to be true
    end

    it 'returns correct structure for complete game' do
      # Complete all frames with strikes
      10.times do |i|
        frame = game.frames.find_by(number: i + 1)
        if i < 9
          frame.rolls.create!(roll_number: 1, pins: 10)
        else
          frame.rolls.create!(roll_number: 1, pins: 10)
          frame.rolls.create!(roll_number: 2, pins: 10)
          frame.rolls.create!(roll_number: 3, pins: 10)
        end
      end

      info = service.game_info

      expect(info[:total_rolls]).to eq(12)
      expect(info[:is_complete]).to be true
      expect(info[:frames].all? { |f| f[:is_complete] }).to be true
    end
  end

  describe 'edge cases' do
    it 'handles game with invalid state gracefully' do
      game.frames.last.destroy # Remove 10th frame
      service = GameStateService.new(game, game.frames.order(:number).includes(:rolls))

      expect(service.valid_game_state?).to be false
      expect(service.game_complete?).to be false
    end

    it 'handles frames with out-of-order roll numbers' do
      frame = game.frames.first
      frame.rolls.create!(roll_number: 2, pins: 5)
      frame.rolls.create!(roll_number: 1, pins: 10)

      # Should still work correctly despite roll number order
      expect(service.can_roll_in_frame?(frame)).to be false
      expect(service.frame_complete?(frame)).to be true
    end
  end
end
