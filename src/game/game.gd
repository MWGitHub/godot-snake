extends Node

enum GridState {
	EMPTY = 0,
	TAKEN = 1,
	FOOD = 2,
}

const GameConstants = preload("res://src/game/game_constants.gd")
const Snake = preload("res://src/game/snake.gd")
const Food = preload("res://src/game/food.gd")

const MAX_SPEED: float = 2.0
const MIN_SPEED: float = 0.01
const SPEED_STEP: float = 0.01

## Starting speed for the snake in seconds per step
@export_range(MIN_SPEED, MAX_SPEED, SPEED_STEP, "suffix:s") var starting_speed: float = 1.0
## Fastest speed for the snake in seconds per step
@export_range(MIN_SPEED, MAX_SPEED, SPEED_STEP, "suffix:s") var fastest_speed: float = 0.1

var _snake: Snake
var _food: Food
var _step_timer: Timer
var _grid: Array[Array] = []
var _score: int = 0
var _is_game_over: bool = false

@onready var _game_layer: Node = $GameLayer
@onready var _score_label: Label = $ScoreLabel
@onready var _end_screen: Control = $EndScreen
@onready var _game_end_score_label: Label = $EndScreen/VBoxContainer/GameEndScoreLabel


func _ready() -> void:
	if fastest_speed > starting_speed:
		push_warning("fastest_speed cannot be greater than starting_speed!")
		fastest_speed = starting_speed

	_start_game()


func _unhandled_input(event: InputEvent) -> void:
	if _is_game_over:
		return

	var has_turned: bool = false
	if event.is_action_pressed("turn_up"):
		has_turned = _snake.turn(GameConstants.Direction.UP)
	elif event.is_action_pressed("turn_right"):
		has_turned = _snake.turn(GameConstants.Direction.RIGHT)
	elif event.is_action_pressed("turn_down"):
		has_turned = _snake.turn(GameConstants.Direction.DOWN)
	elif event.is_action_pressed("turn_left"):
		has_turned = _snake.turn(GameConstants.Direction.LEFT)

	# Move after turning and reset timer for snappier movement
	if has_turned:
		_step_timer.stop()
		_step_timer.timeout.emit()
		_step_timer.start()


## Create an empty grid
func _create_grid(rows: int, columns: int) -> void:
	_grid = []
	_grid.resize(rows)
	for row: Array in _grid:
		row.resize(columns)
		row.fill(GridState.EMPTY)


func _start_game() -> void:
	_is_game_over = false
	_end_screen.visible = false

	_score = 0
	_update_score()

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
	_game_layer.add_child(_snake)

	# Create food
	_create_food()

	# Create the step timer
	if _step_timer != null:
		_step_timer.queue_free()

	_step_timer = Timer.new()
	_step_timer.wait_time = starting_speed
	_step_timer.autostart = true
	_step_timer.one_shot = false
	_step_timer.timeout.connect(_game_step)
	add_child(_step_timer)


func _game_step() -> void:
	if _snake != null:
		_snake.move_step()


func _end_game() -> void:
	_step_timer.stop()
	_is_game_over = true
	_end_screen.visible = true
	_game_end_score_label.text = "Score: %d" % _score


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
		_end_game()
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


func _increase_speed() -> void:
	# Max score is total cells subtracted by the initial snake length
	var max_score: int = _grid.size() * _grid[0].size() - 1
	var speed: float = starting_speed - (starting_speed - fastest_speed) * _score / max_score
	_step_timer.wait_time = clampf(speed, fastest_speed, starting_speed)

func _on_snake_moved(segments: Array[Vector2i], previous_tail: Vector2i) -> void:
	var head: Vector2i = segments[0]
	var tail: Vector2i = previous_tail

	# Check for death
	if _is_moving_to_death(head):
		_end_game()
		return

	# Check for food and update the tail position if not eating
	if _is_moving_to_food(head):
		_snake.grow()
		_increase_speed()
		_score += 50
		_update_score()
		_create_food()
	else:
		_grid[tail.y][tail.x] = GridState.EMPTY

	# Update the head position
	_grid[head.y][head.x] = GridState.TAKEN


func _update_score() -> void:
	_score_label.text = "Score: %d" % _score


func _on_restart_button_pressed() -> void:
	_start_game()
