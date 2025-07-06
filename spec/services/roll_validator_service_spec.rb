require 'rails_helper'

RSpec.describe RollValidatorService, type: :service do
  let(:game) {
    game = Game.create!
    10.times { |i| game.frames.create!(number: i + 1) }
    game
  }
  let(:regular_frame) { game.frames.first }
  let(:tenth_frame) { game.frames.last }

  describe '#valid_roll?' do
    context 'regular frame' do
      it 'allows first roll with valid pins' do
        validator = RollValidatorService.new(regular_frame, 1, 5)
        expect(validator.valid_roll?).to be true
      end
      it 'disallows pins < 0' do
        validator = RollValidatorService.new(regular_frame, 1, -1)
        expect(validator.valid_roll?).to be false
      end
      it 'disallows pins > 10' do
        validator = RollValidatorService.new(regular_frame, 1, 11)
        expect(validator.valid_roll?).to be false
      end
      it 'disallows roll_number < 1' do
        validator = RollValidatorService.new(regular_frame, 0, 5)
        expect(validator.valid_roll?).to be false
      end
      it 'disallows roll_number > 3' do
        validator = RollValidatorService.new(regular_frame, 4, 5)
        expect(validator.valid_roll?).to be false
      end
      it 'allows second roll if first roll not strike and total pins <= 10' do
        regular_frame.rolls.create!(roll_number: 1, pins: 4)
        validator = RollValidatorService.new(regular_frame, 2, 6)
        expect(validator.valid_roll?).to be true
      end
      it 'disallows second roll if first roll is strike' do
        regular_frame.rolls.create!(roll_number: 1, pins: 10)
        validator = RollValidatorService.new(regular_frame, 2, 0)
        expect(validator.valid_roll?).to be false
      end
      it 'disallows second roll if total pins > 10' do
        regular_frame.rolls.create!(roll_number: 1, pins: 7)
        validator = RollValidatorService.new(regular_frame, 2, 5)
        expect(validator.valid_roll?).to be false
      end
      it 'disallows third roll in regular frame' do
        validator = RollValidatorService.new(regular_frame, 3, 5)
        expect(validator.valid_roll?).to be false
      end
    end

    context '10th frame' do
      it 'allows first and second rolls' do
        validator1 = RollValidatorService.new(tenth_frame, 1, 10)
        validator2 = RollValidatorService.new(tenth_frame, 2, 10)
        expect(validator1.valid_roll?).to be true
        expect(validator2.valid_roll?).to be true
      end
      it 'allows third roll after strike' do
        tenth_frame.rolls.create!(roll_number: 1, pins: 10)
        tenth_frame.rolls.create!(roll_number: 2, pins: 10)
        validator = RollValidatorService.new(tenth_frame, 3, 10)
        expect(validator.valid_roll?).to be true
      end
      it 'allows third roll after spare' do
        tenth_frame.rolls.create!(roll_number: 1, pins: 5)
        tenth_frame.rolls.create!(roll_number: 2, pins: 5)
        validator = RollValidatorService.new(tenth_frame, 3, 10)
        expect(validator.valid_roll?).to be true
      end
      it 'disallows third roll for open frame' do
        tenth_frame.rolls.create!(roll_number: 1, pins: 3)
        tenth_frame.rolls.create!(roll_number: 2, pins: 4)
        validator = RollValidatorService.new(tenth_frame, 3, 5)
        expect(validator.valid_roll?).to be false
      end
    end
  end

  describe '#validation_errors' do
    it 'returns error for pins out of range' do
      validator = RollValidatorService.new(regular_frame, 1, 11)
      expect(validator.validation_errors).to include("Pins must be between 0 and 10")
    end
    it 'returns error for roll_number out of range' do
      validator = RollValidatorService.new(regular_frame, 4, 5)
      expect(validator.validation_errors).to include("Roll number must be between 1 and 3")
    end
    it 'returns error for second roll after strike' do
      regular_frame.rolls.create!(roll_number: 1, pins: 10)
      validator = RollValidatorService.new(regular_frame, 2, 0)
      expect(validator.validation_errors).to include("Second roll not allowed after strike in regular frames")
    end
    it 'returns error for second roll exceeding 10 pins' do
      regular_frame.rolls.create!(roll_number: 1, pins: 7)
      validator = RollValidatorService.new(regular_frame, 2, 5)
      expect(validator.validation_errors.first).to match(/Second roll cannot exceed/)
    end
    it 'returns error for third roll in regular frame' do
      validator = RollValidatorService.new(regular_frame, 3, 5)
      expect(validator.validation_errors).to include("Third roll not allowed in regular frames")
    end
    it 'returns error for third roll in 10th frame without strike/spare' do
      tenth_frame.rolls.create!(roll_number: 1, pins: 3)
      tenth_frame.rolls.create!(roll_number: 2, pins: 4)
      validator = RollValidatorService.new(tenth_frame, 3, 5)
      expect(validator.validation_errors).to include("Third roll not allowed in open frame")
    end
    it 'returns no error for third roll in 10th frame with strike' do
      tenth_frame.rolls.create!(roll_number: 1, pins: 10)
      tenth_frame.rolls.create!(roll_number: 2, pins: 10)
      validator = RollValidatorService.new(tenth_frame, 3, 10)
      expect(validator.validation_errors).to eq([])
    end
    it 'returns no error for third roll in 10th frame with spare' do
      tenth_frame.rolls.create!(roll_number: 1, pins: 5)
      tenth_frame.rolls.create!(roll_number: 2, pins: 5)
      validator = RollValidatorService.new(tenth_frame, 3, 10)
      expect(validator.validation_errors).to eq([])
    end
  end
end
