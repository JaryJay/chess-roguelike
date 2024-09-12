class_name Piece extends Node2D

enum Type {
	UNSET,
	KING,
	QUEEN,
	ROOK,
	BISHOP,
	KNIGHT,
	PAWN,
}

@export var black_sprite: Sprite2D
@export var white_sprite: Sprite2D
var _pos: Vector2i
var _team: Team

func _ready() -> void:
	assert(black_sprite)
	assert(white_sprite)
	set_team(team())

func get_available_squares(_s: BoardState) -> Array[Vector2i]:
	printerr("get_available_squares not implemented")
	return []

func get_worth() -> float:
	printerr("get_worth not implemented")
	return 0

func pos() -> Vector2i:
	return _pos

func set_pos(new_pos: Vector2i) -> void:
	_pos = new_pos

func team() -> Team:
	return _team

func set_team(new_team: Team) -> void:
	_team = new_team
	
	if not is_node_ready(): return
	
	if team().is_player():
		black_sprite.queue_free()
	elif team().is_enemy():
		white_sprite.queue_free()
	else:
		assert(false, "Unknown team %s" % team()._key)
