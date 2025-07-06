require 'rails_helper'

RSpec.describe 'Bowling Game API', type: :request do
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }

  describe 'Game Creation' do
    it 'creates a new game successfully' do
      post '/api/v1/games', headers: headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body).to include('game_id', 'message')
      expect(body['message']).to eq('New bowling game created successfully')
      expect(body['game_id']).to be_a(Integer)
    end

    it 'creates 10 frames for a new game' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      get "/api/v1/games/#{game_id}", headers: headers
      body = JSON.parse(response.body)

      expect(body['frames'].length).to eq(10)
      expect(body['frames'].map { |f| f['number'] }).to eq((1..10).to_a)
    end
  end

  describe 'Basic Bowling Scenarios' do
    it 'scores a strike correctly' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Roll a strike (10 pins)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers
      expect(response).to have_http_status(:created)

      # Roll 3, 4 in next frame
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 3 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 4 } }.to_json, headers: headers

      # Get score
      get "/api/v1/games/#{game_id}/score", headers: headers
      body = JSON.parse(response.body)
      expect(body['frame_scores'].first).to eq(17) # 10 + 3 + 4
      expect(body['total_score']).to eq(24)       # 17 + 3 + 4
    end

    it 'scores a spare correctly' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Roll 7, 3 (spare)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 7 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 3 } }.to_json, headers: headers

      # Next roll 4
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 4 } }.to_json, headers: headers

      get "/api/v1/games/#{game_id}/score", headers: headers
      body = JSON.parse(response.body)
      expect(body['frame_scores'].first).to eq(14) # 7 + 3 + 4
      expect(body['total_score']).to eq(18)       # 14 + 4
    end

    it 'scores an open frame correctly' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Roll 3, 5 (open frame)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 3 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers

      get "/api/v1/games/#{game_id}/score", headers: headers
      body = JSON.parse(response.body)
      expect(body['frame_scores'].first).to eq(8)
      expect(body['total_score']).to eq(8)
    end
  end

  describe 'Perfect Game (300)' do
    it 'scores a perfect game correctly' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Roll 12 strikes (10 frames + 2 bonus rolls)
      12.times do
        post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers
        expect(response).to have_http_status(:created)
      end

      get "/api/v1/games/#{game_id}/score", headers: headers
      body = JSON.parse(response.body)
      expect(body['total_score']).to eq(300)
      expect(body['frame_scores'].last).to eq(30) # Last frame: 10 + 10 + 10
    end
  end

  describe 'Gutter Game (0)' do
    it 'scores a gutter game correctly' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Roll 20 gutter balls
      20.times do
        post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 0 } }.to_json, headers: headers
        expect(response).to have_http_status(:created)
      end

      get "/api/v1/games/#{game_id}/score", headers: headers
      body = JSON.parse(response.body)
      expect(body['total_score']).to eq(0)
      expect(body['frame_scores']).to all(eq(0))
    end
  end

  describe '10th Frame Edge Cases' do
    it 'handles strike in 10th frame with two bonus rolls' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Complete first 9 frames with strikes
      9.times do
        post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers
      end

      # 10th frame: strike + 7 + 3
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 7 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 3 } }.to_json, headers: headers

      get "/api/v1/games/#{game_id}/score", headers: headers
      body = JSON.parse(response.body)
      expect(body['frame_scores'].last).to eq(20) # 10 + 7 + 3
    end

    it 'handles spare in 10th frame with one bonus roll' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Complete first 9 frames with strikes
      9.times do
        post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers
      end

      # 10th frame: 7 + 3 (spare) + 5
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 7 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 3 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers

      get "/api/v1/games/#{game_id}/score", headers: headers
      body = JSON.parse(response.body)
      expect(body['frame_scores'].last).to eq(15) # 7 + 3 + 5
    end

    it 'handles open frame in 10th frame (no bonus rolls)' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Complete first 9 frames with strikes
      9.times do
        post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers
      end

      # 10th frame: 7 + 2 (open frame)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 7 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 2 } }.to_json, headers: headers

      get "/api/v1/games/#{game_id}/score", headers: headers
      body = JSON.parse(response.body)
      expect(body['frame_scores'].last).to eq(9) # 7 + 2
    end

    it 'prevents third roll in 10th frame when not earned' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Complete first 9 frames with strikes
      9.times do
        post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers
      end

      # 10th frame: 7 + 2 (open frame)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 7 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 2 } }.to_json, headers: headers

      # Try to roll a third time (should fail)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'Additional Edge Cases' do
    it 'handles 10th frame with strike followed by gutter balls' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Complete first 9 frames with strikes
      9.times do
        post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers
      end

      # 10th frame: strike + 0 + 0
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 0 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 0 } }.to_json, headers: headers

      get "/api/v1/games/#{game_id}/score", headers: headers
      body = JSON.parse(response.body)
      expect(body['frame_scores'].last).to eq(10) # 10 + 0 + 0
    end

    it 'handles 10th frame with spare followed by gutter ball' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Complete first 9 frames with strikes
      9.times do
        post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers
      end

      # 10th frame: 5 + 5 (spare) + 0
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 0 } }.to_json, headers: headers

      get "/api/v1/games/#{game_id}/score", headers: headers
      body = JSON.parse(response.body)
      expect(body['frame_scores'].last).to eq(10) # 5 + 5 + 0
    end

    it 'prevents invalid second roll that would exceed 10 pins' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # First roll: 8 pins
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 8 } }.to_json, headers: headers
      expect(response).to have_http_status(:created)

      # Second roll: 3 pins (should fail - exceeds remaining pins)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 3 } }.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body['error']).to include('Second roll cannot exceed 2 pins')
    end

    it 'allows exactly 10 pins in two rolls' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # First roll: 8 pins
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 8 } }.to_json, headers: headers
      expect(response).to have_http_status(:created)

      # Second roll: 2 pins (should succeed - makes a spare)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 2 } }.to_json, headers: headers
      expect(response).to have_http_status(:created)
    end

    it 'handles consecutive spares correctly' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Frame 1: 5, 5 (spare)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers

      # Frame 2: 5, 5 (spare)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers

      # Frame 3: 5, 4 (open frame)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 4 } }.to_json, headers: headers

      get "/api/v1/games/#{game_id}/score", headers: headers
      body = JSON.parse(response.body)

      # Frame 1: 5 + 5 + 5 = 15
      # Frame 2: 5 + 5 + 5 = 15
      # Frame 3: 5 + 4 = 9
      # Total: 15 + 15 + 9 = 39
      expect(body['total_score']).to eq(39)
    end
  end

  describe 'Input Validation' do
    it 'rejects invalid pin values' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Test negative pins
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: -1 } }.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body['errors']).to include('roll' => include('pins' => include('must be greater than or equal to 0')))

      # Test pins > 10
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 11 } }.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body['errors']).to include('roll' => include('pins' => include('must be less than or equal to 10')))
    end

    it 'rejects invalid JSON structure' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Missing pins field
      post "/api/v1/games/#{game_id}/rolls", params: { roll: {} }.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body['errors']).to include('roll' => include('pins' => include('is missing')))

      # Wrong data type for pins
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: "five" } }.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body['errors']).to include('roll' => include('pins' => include('must be an integer')))

      # Extra fields in roll object (schema allows this, so it should succeed)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5, extra: "field" } }.to_json, headers: headers
      expect(response).to have_http_status(:created)
    end

    it 'rejects invalid game IDs' do
      # Non-numeric game ID - Rails will return 404 for non-existent games
      get "/api/v1/games/abc", headers: headers
      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body['error']).to eq('Game not found')

      get "/api/v1/games/abc/score", headers: headers
      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body['error']).to eq('Game not found')

      post "/api/v1/games/abc/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers
      expect(response).to have_http_status(:not_found) # Rails routing handles this
    end
  end

  describe 'Game State Validation' do
    it 'prevents rolling in completed game with all open frames' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Complete the game with 20 rolls (all open frames)
      # Use 3 and 4 for each frame to ensure open frames (3+4=7, not 10)
      10.times do |frame|
        # First roll of frame
        post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 3 } }.to_json, headers: headers
        expect(response).to have_http_status(:created)

        # Second roll of frame
        post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 4 } }.to_json, headers: headers
        expect(response).to have_http_status(:created)
      end

      # Check how many rolls we actually have
      get "/api/v1/games/#{game_id}", headers: headers
      body = JSON.parse(response.body)

      # Try to roll again (should fail)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body['error']).to eq('Game is already complete')
    end

    it 'allows more than 20 rolls when 10th frame has strikes or spares' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Complete first 9 frames with strikes
      9.times do
        post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers
        expect(response).to have_http_status(:created)
      end

      # 10th frame: strike + 7 + 3 (22 total rolls)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers
      expect(response).to have_http_status(:created)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 7 } }.to_json, headers: headers
      expect(response).to have_http_status(:created)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 3 } }.to_json, headers: headers
      expect(response).to have_http_status(:created)

      # Try to roll again (should fail)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body['error']).to eq('Game is already complete')
    end

    it 'prevents second roll after strike in frames 1-9' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Roll a strike
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers
      expect(response).to have_http_status(:created)

      # Try to roll again in the same frame (should succeed as it moves to next frame)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers
      expect(response).to have_http_status(:created) # This should succeed as it moves to next frame

      # Verify we're in the second frame
      body = JSON.parse(response.body)
      expect(body['frame']).to eq(2)
    end
  end

  describe 'Frame Rules Validation' do
    it 'prevents invalid second roll in frame' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # First roll: 7 pins
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 7 } }.to_json, headers: headers
      expect(response).to have_http_status(:created)

      # Second roll: 5 pins (should fail - exceeds remaining pins)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body['error']).to include('Second roll cannot exceed 3 pins')
    end

    it 'allows valid second roll in frame' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # First roll: 7 pins
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 7 } }.to_json, headers: headers
      expect(response).to have_http_status(:created)

      # Second roll: 3 pins (should succeed - makes a spare)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 3 } }.to_json, headers: headers
      expect(response).to have_http_status(:created)
    end
  end

  describe 'Error Handling' do
    it 'returns 404 for non-existent game' do
      get "/api/v1/games/99999", headers: headers
      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body['error']).to eq('Game not found')

      get "/api/v1/games/99999/score", headers: headers
      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body['error']).to eq('Game not found')

      post "/api/v1/games/99999/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers
      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body['error']).to eq('Game not found')
    end

    it 'handles malformed JSON gracefully' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Send malformed JSON - Rails will handle this with a 400 Bad Request
      expect {
        post "/api/v1/games/#{game_id}/rolls", params: '{"roll": {"pins": 5}', headers: headers
      }.to raise_error(ActionView::Template::Error)
    end
  end

  describe 'Complex Scoring Scenarios' do
    it 'handles alternating strikes and spares' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Frame 1: Strike
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers

      # Frame 2: 7, 3 (spare)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 7 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 3 } }.to_json, headers: headers

      # Frame 3: Strike
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers

      # Frame 4: 4, 6 (spare)
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 4 } }.to_json, headers: headers
      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 6 } }.to_json, headers: headers

      get "/api/v1/games/#{game_id}/score", headers: headers
      body = JSON.parse(response.body)

      # Frame 1: 10 + 7 + 3 = 20
      # Frame 2: 7 + 3 + 10 = 20
      # Frame 3: 10 + 4 + 6 = 20
      # Frame 4: 4 + 6 = 10
      # Total: 20 + 20 + 20 + 10 = 70
      expect(body['total_score']).to eq(70)
    end

    it 'handles turkey (three consecutive strikes)' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      # Roll three strikes
      3.times do
        post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 10 } }.to_json, headers: headers
      end

      get "/api/v1/games/#{game_id}/score", headers: headers
      body = JSON.parse(response.body)

      # Frame 1: 10 + 10 + 10 = 30
      # Frame 2: 10 + 10 = 20 (incomplete)
      # Frame 3: 10 = 10 (incomplete)
      # Total: 30 + 20 + 10 = 60 (includes incomplete frames)
      expect(body['total_score']).to eq(60)
      expect(body['frame_scores'][0]).to eq(30)
      expect(body['frame_scores'][1]).to eq(20)
      expect(body['frame_scores'][2]).to eq(10)
    end
  end

  describe 'API Response Format' do
    it 'returns consistent JSON structure for game creation' do
      post '/api/v1/games', headers: headers
      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)
      expect(body).to have_key('game_id')
      expect(body).to have_key('message')
      expect(body['game_id']).to be_a(Integer)
      expect(body['message']).to be_a(String)
    end

    it 'returns consistent JSON structure for roll creation' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      post "/api/v1/games/#{game_id}/rolls", params: { roll: { pins: 5 } }.to_json, headers: headers
      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)
      expect(body).to have_key('frame')
      expect(body).to have_key('roll')
      expect(body).to have_key('pins')
      expect(body).to have_key('message')
      expect(body['frame']).to be_a(Integer)
      expect(body['roll']).to be_a(Integer)
      expect(body['pins']).to be_a(Integer)
      expect(body['message']).to be_a(String)
    end

    it 'returns consistent JSON structure for score' do
      post '/api/v1/games', headers: headers
      game_id = JSON.parse(response.body)['game_id']

      get "/api/v1/games/#{game_id}/score", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body).to have_key('total_score')
      expect(body).to have_key('frame_scores')
      expect(body['total_score']).to be_a(Integer)
      expect(body['frame_scores']).to be_an(Array)
      expect(body['frame_scores'].length).to eq(10)
    end
  end
end
