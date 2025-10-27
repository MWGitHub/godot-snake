extends Node2D


const GameConstants = preload("res://src/game/game_constants.gd")


func _draw() -> void:
	var rect: Rect2 = Rect2()
	rect.size = Vector2(GameConstants.CELL_SIZE, GameConstants.CELL_SIZE)
	draw_rect(rect, Color.OLIVE)
