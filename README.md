# Bowling Game API

A Ruby on Rails API for managing and scoring ten-pin bowling games with proper API namespacing and JSON format.

## Setup

1. **Install dependencies:**
   ```sh
   bundle install
   ```
2. **Run database migrations:**
   ```sh
   rails db:migrate
   ```
3. **Start the server:**
   ```sh
   rails server
   ```

## API Endpoints

All endpoints are under the `/api` namespace and return JSON format by default.

### 1. Start a New Game
- **Endpoint:** `POST /api/games`
- **Response:**
  ```json
  {
    "game_id": 1,
    "message": "New bowling game created successfully"
  }
  ```

### 2. Submit a Roll
- **Endpoint:** `POST /api/games/:game_id/rolls`
- **Body:**
  ```json
  {
    "roll": {
      "pins": 7
    }
  }
  ```
- **Response:**
  ```json
  {
    "frame": 1,
    "roll": 1,
    "pins": 7,
    "message": "Roll recorded successfully"
  }
  ```
- **Error Response:**
  ```json
  {
    "error": "Pins must be an integer between 0 and 10",
    "received_value": 11
  }
  ```

### 3. Get Current Game Score
- **Endpoint:** `GET /api/games/:id/score`
- **Response:**
  ```json
  {
    "frame_scores": [8, 15, 25, 35, 45, 55, 65, 75, 85, 95],
    "total_score": 95
  }
  ```

### 4. Get Game Information
- **Endpoint:** `GET /api/games/:id`
- **Response:**
  ```json
  {
    "game_id": 1,
    "frames": [
      {"id": 1, "number": 1},
      {"id": 2, "number": 2}
    ],
    "total_rolls": 5
  }
  ```

## Example Usage

### Start a new game:
```bash
curl -X POST http://localhost:3000/api/games
```

### Submit a roll:
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"roll": {"pins": 8}}' \
  http://localhost:3000/api/games/1/rolls
```

### Get current score:
```bash
curl http://localhost:3000/api/games/1/score
```

### Get game info:
```bash
curl http://localhost:3000/api/games/1
```

## Bowling Rules Implementation

The API implements standard ten-pin bowling scoring:

- **Strike (X):** 10 points + next 2 rolls
- **Spare (/):** 10 points + next 1 roll  
- **Open frame:** Sum of both rolls
- **10th frame:** Up to 3 rolls if strike or spare

## Error Handling

The API provides clear error messages for:
- Invalid pin counts (0-10 only)
- Game not found
- Game already complete
- Invalid parameters

## API Features

- **JSON-only responses** - All endpoints return JSON format
- **Proper HTTP status codes** - 201 for creation, 200 for success, 422 for errors
- **RESTful design** - Follows REST conventions
- **Comprehensive error handling** - Clear error messages with context
- **API namespacing** - All endpoints under `/api` namespace
