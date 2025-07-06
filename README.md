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
- **Endpoint:** `POST /api/v1/games`
- **Response:**
  ```json
  {
    "game_id": 1,
    "message": "New bowling game created successfully"
  }
  ```

### 3. Submit a Roll
- **Endpoint:** `POST /api/v1/games/:game_id/rolls`
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

### 4. Get Current Game Score
- **Endpoint:** `GET /api/v1/games/:id/score`
- **Response:**
  ```json
  {
    "frame_scores": [8, 15, 25, 35, 45, 55, 65, 75, 85, 95],
    "total_score": 95
  }
  ```

### 5. Get Game Information
- **Endpoint:** `GET /api/v1/games/:id`
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
curl -X POST http://localhost:3000/api/v1/games
```

### Submit a roll:
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"roll": {"pins": 8}}' \
  http://localhost:3000/api/v1/games/1/rolls
```

### Get current score:
```bash
curl http://localhost:3000/api/v1/games/1/score
```

### Get game info:
```bash
curl http://localhost:3000/api/v1/games/1
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

## Schema Validation with dry-schema

The API uses **dry-schema** for enterprise-grade input validation, providing type safety and clear error messages.

### Schema Definitions

#### **Roll Schema** (`app/schemas/roll_schema.rb`)
```ruby
require 'dry-schema'

RollSchema = Dry::Schema.JSON do
  required(:roll).hash do
    required(:pins).value(:integer, gteq?: 0, lteq?: 10)
  end
end
```

**Validates:**
- ✅ `pins` field is required
- ✅ `pins` must be an integer
- ✅ `pins` must be between 0 and 10 (inclusive)
- ✅ Proper JSON structure with nested `roll` object

```

**Validates:**
- ✅ Game creation accepts empty request body
- ✅ Extensible for future game creation parameters

### Validation Process

1. **Request Validation**: All incoming requests are validated against schemas before processing
2. **Type Safety**: Ensures data types match expected formats
3. **Range Validation**: Enforces business rules (e.g., pins 0-10)
4. **Error Messages**: Returns structured error responses with details

### Error Response Format

**Invalid Input:**
```json
{
  "errors": {
    "roll": {
      "pins": ["must be an integer", "must be greater than or equal to 0"]
    }
  }
}
```

**Missing Required Field:**
```json
{
  "errors": {
    "roll": {
      "pins": ["is missing"]
    }
  }
}
```

**Wrong Data Type:**
```json
{
  "errors": {
    "roll": {
      "pins": ["must be an integer"]
    }
  }
}
```

### Validation Examples

#### **Valid Roll Request:**
```json
{
  "roll": {
    "pins": 7
  }
}
```
✅ **Result**: Request processed successfully

#### **Invalid Roll Requests:**
```json
{
  "roll": {
    "pins": 11
  }
}
```
❌ **Error**: `"must be less than or equal to 10"`

```json
{
  "roll": {
    "pins": -1
  }
}
```
❌ **Error**: `"must be greater than or equal to 0"`

```json
{
  "roll": {
    "pins": "five"
  }
}
```
❌ **Error**: `"must be an integer"`

```json
{
  "roll": {}
}
```
❌ **Error**: `"pins is missing"`

### Benefits of dry-schema

- **Type Safety**: Compile-time validation of data types
- **Performance**: Fast validation with minimal overhead
- **Maintainability**: Declarative schema definitions
- **Error Clarity**: Detailed, structured error messages
- **Extensibility**: Easy to add new validation rules
- **Enterprise Ready**: Production-grade validation library

### Schema Location

- `app/schemas/roll_schema.rb` - Roll submission validation
- `app/schemas/game_schema.rb` - Game creation validation

### Integration with Controllers

Schemas are automatically loaded and used in controllers:

```ruby
# Validation in RollsController
result = RollSchema.call(params.to_unsafe_h)

unless result.success?
  render json: { errors: result.errors.to_h }, status: :unprocessable_entity
  return
end
```

This ensures all business logic receives validated, type-safe data.

## Service Layer Architecture

All business logic is implemented in a dedicated service layer (not in models):

- **ScoreCalculator** (`app/services/score_calculator.rb`): Calculates frame-by-frame and total scores for a game, handling all strike, spare, and 10th frame rules.
- **GameStateService** (`app/services/game_state_service.rb`): Determines game state, frame completion, next roll number, and provides game info in a structured format with scores included.
- **RollValidatorService** (`app/services/roll_validator_service.rb`): Validates roll input, enforces bowling rules for each frame, and provides detailed error messages for invalid rolls.

**Design Patterns:**
- **Dependency Injection**: Services use dependency injection for better testability and loose coupling (e.g., `GameStateService` accepts `ScoreCalculator` as a parameter)
- **Single Responsibility**: Each service has a focused responsibility
- **Shared Constants**: All bowling rules centralized in `BowlingRules` module

**Shared Constants:**
- **BowlingRules** (`app/lib/bowling_rules.rb`): Centralized module containing all bowling game constants (MAX_PINS, MAX_FRAMES, etc.) used across services for consistency and maintainability.

**Performance Optimizations:**
- Database queries are optimized with eager loading (`includes(:rolls)`)
- Query results are cached in variables to avoid repeated database calls
- Services share common data structures to minimize memory usage

Controllers are thin and delegate all business logic to these services.

## Testing

### Unit Tests

Comprehensive unit tests cover all service logic:

- `spec/services/score_calculator_spec.rb`
- `spec/services/game_state_service_spec.rb`
- `spec/services/roll_validator_service_spec.rb`

To run all service tests:
```sh
bundle exec rspec spec/services/
```

All business logic is tested, including:
- Scoring (strikes, spares, open frames, perfect/gutter games, 10th frame edge cases)
- Game state transitions and validation
- Roll validation and error messages

### End-to-End Tests

Complete API integration tests are located in `spec/requests/bowling_game_spec.rb` and cover:

#### **Game Creation & Setup**
- ✅ Creates new game with unique ID
- ✅ Automatically creates 10 frames for new game
- ✅ Returns proper JSON structure

#### **Basic Bowling Scenarios**
- ✅ **Strike scoring**: 10 + next 2 rolls
- ✅ **Spare scoring**: 10 + next 1 roll  
- ✅ **Open frame scoring**: Sum of both rolls

#### **Perfect Game (300 Points)**
- ✅ Scores 12 consecutive strikes correctly
- ✅ Handles 10th frame with 3 strikes
- ✅ Total score equals 300

#### **Gutter Game (0 Points)**
- ✅ Scores 20 consecutive gutter balls
- ✅ All frame scores equal 0
- ✅ Total score equals 0

#### **10th Frame Edge Cases**
- ✅ **Strike in 10th frame**: Allows 2 bonus rolls
- ✅ **Spare in 10th frame**: Allows 1 bonus roll
- ✅ **Open frame in 10th frame**: No bonus rolls
- ✅ **Prevents invalid third roll**: When not earned by strike/spare
- ✅ **Strike + gutter balls**: 10th frame with 10+0+0
- ✅ **Spare + gutter ball**: 10th frame with 5+5+0

#### **Input Validation**
- ✅ **Invalid pin values**: Rejects negative pins, pins > 10
- ✅ **Invalid JSON structure**: Missing fields, wrong data types
- ✅ **Invalid game IDs**: Non-existent games return 404
- ✅ **Malformed JSON**: Handles gracefully

#### **Game State Validation**
- ✅ **Prevents rolling in completed game**: All open frames (20 rolls)
- ✅ **Allows >20 rolls**: When 10th frame has strikes/spares (up to 22 rolls)
- ✅ **Prevents second roll after strike**: In frames 1-9 (moves to next frame)

#### **Frame Rules Validation**
- ✅ **Invalid second roll**: Prevents exceeding remaining pins
- ✅ **Valid second roll**: Allows exactly 10 pins in two rolls
- ✅ **Consecutive spares**: Scores correctly

#### **Complex Scoring Scenarios**
- ✅ **Alternating strikes and spares**: Complex scoring patterns
- ✅ **Turkey (3 consecutive strikes)**: Handles multiple strikes
- ✅ **Consecutive spares**: Proper bonus calculation

#### **Error Handling**
- ✅ **404 for non-existent games**: All endpoints
- ✅ **Malformed JSON**: Graceful error handling
- ✅ **Consistent error responses**: Proper HTTP status codes

#### **API Response Format**
- ✅ **Consistent JSON structure**: All endpoints
- ✅ **Proper data types**: Integers, strings, arrays
- ✅ **Expected field presence**: Required fields in all responses

To run all E2E tests:
```sh
bundle exec rspec spec/requests/
```

To run all tests:
```sh
bundle exec rspec
```

## Project Structure

- `app/models/` — Data models only (no business logic)
- `app/services/` — All scoring, validation, and state logic
- `spec/services/` — Unit tests for all service classes
- `spec/requests/` — End-to-end API integration tests
- `app/controllers/` — API endpoints, thin controllers

---

For any questions or contributions, please open an issue or pull request.
