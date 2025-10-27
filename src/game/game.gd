extends Node

enum GridState {
	EMPTY = 0,
	TAKEN = 1,
	FOOD = 2,
}


const GameConstants = preload("res://src/game/game_constants.gd")
const Snake = preload("res://src/game/snake.gd")
const Food = preload("res://src/game/food.gd")

var _speed: float = 0.2
var _snake: Snake
var _food: Food
var _step_timer: Timer
var _grid: Array[Array] = []
var _score: int = 0

func _ready() -> void:
	_start_game()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("turn_up"):
		_snake.turn(GameConstants.Direction.UP)
	if event.is_action_pressed("turn_right"):
		_snake.turn(GameConstants.Direction.RIGHT)
	if event.is_action_pressed("turn_down"):
		_snake.turn(GameConstants.Direction.DOWN)
	if event.is_action_pressed("turn_left"):
		_snake.turn(GameConstants.Direction.LEFT)


## Create an empty grid
func _create_grid(rows: int, columns: int) -> void:
	_grid = []
	_grid.resize(rows)
	for row: Array in _grid:
		row.resize(columns)
		row.fill(GridState.EMPTY)


func _start_game() -> void:
	_score = 0

	# Calculate grid size to viewport and create it
	var rect: Rect2 = get_viewport().get_visible_rect()
	var rows: int = floori(rect.size.y / GameConstants.CELL_SIZE)
	var columns: int = floori(rect.size.x / GameConstants.CELL_SIZE)
	_create_grid(rows, columns)

	# Create the snake
	if _snake != null:
		_snake.queue_free()

	_snake = Snake.new()
	_snake.starting_position = Vector2i(int(columns / 2.0), int(rows / 2.0))
	_snake.moved.connect(_on_snake_moved)
	add_child(_snake)

	# Create food
	_create_food()

	# Create the step timer
	if _step_timer != null:
		_step_timer.queue_free()

	_step_timer = Timer.new()
	_step_timer.wait_time = _speed
	_step_timer.autostart = true
	_step_timer.one_shot = false
	_step_timer.timeout.connect(_game_step)
	add_child(_step_timer)


func _game_step() -> void:
	if _snake != null:
		_snake.move_step()


func _are_all_slots_taken() -> bool:
	for row: Array in _grid:
		for cell: GridState in row:
			if cell == GridState.EMPTY:
				return false

	return true


func _create_food() -> void:
	if _food != null:
		_food.queue_free()

	if _are_all_slots_taken():
		print("You win!")
		_step_timer.stop()
		return

	# Get random empty cell
	var is_empty_cell_found: bool = false
	while not is_empty_cell_found:
		var y: int = randi() % _grid.size()
		var x: int = randi() % _grid[y].size()
		if _grid[y][x] == GridState.EMPTY:
			is_empty_cell_found = true
			_food = Food.new()
			_food.position = Vector2(x * GameConstants.CELL_SIZE, y * GameConstants.CELL_SIZE)
			add_child(_food)
			_grid[y][x] = GridState.FOOD


func _is_moving_to_death(cell_position: Vector2i) -> bool:
	var y: int = cell_position.y
	var x: int = cell_position.x

	# Death if out of bounds
	if y < 0 or y >= _grid.size():
		return true
	var row: Array = _grid[y]
	if x < 0 or x >= row.size():
		return true

	if row[x] == GridState.TAKEN:
		return true

	return false


func _is_moving_to_food(cell_position: Vector2i) -> bool:
	if _is_moving_to_death(cell_position):
		return false

	return _grid[cell_position.y][cell_position.x] == GridState.FOOD


func _on_snake_moved(segments: Array[Vector2i], previous_tail: Vector2i) -> void:
	var head: Vector2i = segments[0]
	var tail: Vector2i = previous_tail

	# Check for death
	if _is_moving_to_death(head):
		print("Game Over!")
		_step_timer.stop()
		return

	# Check for food and update the tail position if not eating
	if _is_moving_to_food(head):
		_snake.grow()
		_score += 1
		_create_food()
	else:
		_grid[tail.y][tail.x] = GridState.EMPTY

	# Update the head position
	_grid[head.y][head.x] = GridState.TAKEN
