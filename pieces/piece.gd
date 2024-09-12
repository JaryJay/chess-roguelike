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

@export var type: Type
@export var black_sprite: Sprite2D
@export var white_sprite: Sprite2D

var _state: PieceState

func _ready() -> void:
	assert(black_sprite)
	assert(white_sprite)
	init_team_color()

func state() -> PieceState:
	return _state

func set_state(new_state: PieceState) -> void:
	_state = new_state

func init_team_color() -> void:
	if state().team.is_player():
		black_sprite.queue_free()
	elif state().team.is_enemy():
		white_sprite.queue_free()
	else:
		assert(false, "Unknown team %s" % state().team._key)
