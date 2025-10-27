extends Node2D


## Signal emitted when the snake moves with the first element being the head.
signal moved(segments: Array[Vector2i], previous_tail: Vector2i)


const GameConstants = preload("res://src/game/game_constants.gd")

const Direction = GameConstants.Direction

@export var starting_position: Vector2i = Vector2i(0, 0)
@export var starting_direction: Direction = Direction.UP

# Opposite directions to prevent moving towards
var _opposite_direction: Dictionary[Direction, Direction] = {
	Direction.UP: Direction.DOWN,
	Direction.RIGHT: Direction.LEFT,
	Direction.DOWN: Direction.UP,
	Direction.LEFT: Direction.RIGHT,
}
var _prev_tail: Vector2i = Vector2i(-1, -1)

@onready var _segments: Array[Vector2i] = [starting_position]
@onready var _direction: Direction = starting_direction
@onready var _next_direction: Direction = starting_direction

func _init() -> void:
	pass


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	for segment: Vector2i in _segments:
		var rect: Rect2 = Rect2()
		rect.position = Vector2(segment.x * GameConstants.CELL_SIZE, segment.y * GameConstants.CELL_SIZE)
		rect.size = Vector2(GameConstants.CELL_SIZE, GameConstants.CELL_SIZE)
		draw_rect(rect, Color.DARK_OLIVE_GREEN)


func move_step() -> void:
	_direction = _next_direction
	var next_position: Vector2i = _segments[0]
	match _direction:
		Direction.UP:
			next_position += Vector2i(0, -1)
		Direction.RIGHT:
			next_position += Vector2i(1, 0)
		Direction.DOWN:
			next_position += Vector2i(0, 1)
		Direction.LEFT:
			next_position += Vector2i(-1, 0)

	_segments.push_front(next_position)
	_prev_tail = _segments.pop_back()
	moved.emit(_segments, _prev_tail)
	queue_redraw()


## Turn to the given direction as long as it isn't the opposite.
func turn(direction: Direction) -> void:
	# Check if going in the opposite direction
	if _direction == _opposite_direction[direction]:
		return

	_next_direction = direction


func grow() -> void:
	_segments.push_back(_prev_tail)
	queue_redraw()
