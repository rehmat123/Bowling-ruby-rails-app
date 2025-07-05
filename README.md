# Bowling Game API

A Ruby on Rails API for managing and scoring ten-pin bowling games.

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

### 1. Start a New Game
- **Endpoint:** `POST /games`
- **Response:**
  ```json
  { "game_id": 1 }
  ```

### 2. Submit a Roll
- **Endpoint:** `POST /games/:game_id/rolls`
- **Body:**
  ```json
  { "roll": { "pins": 7 } }
  ```
- **Response:**
  ```json
  { "frame": 1, "roll": 1, "pins": 7 }
  ```
- **Error Response:**
  ```json
  { "error": "Pins must be an integer between 0 and 10" }
  ```

### 3. Get Current Game Score
- **Endpoint:** `GET /games/:id/score`
- **Response:**
  ```json
  {
    "frame_scores": [7, 9, 10, ...],
    "total_score": 56
  }
  ```

### 4. Get Game Info
- **Endpoint:** `GET /games/:id`
- **Response:**
  ```json
  {
    "game_id": 1,
    "frames": [
      { "id": 1, "number": 1 },
      { "id": 2, "number": 2 },
      ...
    ]
  }
  ```

## Example Usage

#### Start a new game
```sh
curl -X POST http://localhost:3000/games
```

#### Submit a roll (e.g., 7 pins)
```sh
curl -X POST -H "Content-Type: application/json" -d '{"roll": {"pins": 7}}' http://localhost:3000/games/1/rolls
```

#### Get current score
```sh
curl http://localhost:3000/games/1/score
```

---

**Enjoy your bowling game API!**
