class_name PieceNode extends Node2D

signal mouse_selected

@export var type: Piece.Type
@export var black_sprite: Sprite2D
@export var white_sprite: Sprite2D

var _initialized: = false
var _id: int
var _piece: Piece

var hovered: bool = false
var pressed: bool = false
var selected: bool = false

func _ready() -> void:
	assert(black_sprite)
	assert(white_sprite)
	init_team_color()
	add_to_group("piece_nodes")

func piece() -> Piece:
	return _piece

func set_piece(new_piece: Piece) -> void:
	_piece = new_piece

func init_team_color() -> void:
	assert(_initialized)
	if piece().team.is_player():
		black_sprite.queue_free()
	elif piece().team.is_enemy():
		white_sprite.queue_free()
	else:
		assert(false, "Unknown team %s" % piece().team._key)

#region input handling

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("primary") && hovered:
		print("selected")
		mouse_selected.emit()
	elif event.is_action_released("primary"):
		pressed = false

func _on_area_2d_mouse_entered() -> void:
	set_hovered(true)

func _on_area_2d_mouse_exited() -> void:
	set_hovered(false)

func set_hovered(new_hovered: bool) -> void:
	hovered = new_hovered

func set_selected(new_selected: bool) -> void:
	selected = new_selected

#endregion

# Generating ids
static var _next_id: = 1
func gen_id() -> int:
	assert(!_initialized)
	var _id: = _next_id
	_next_id += 1
	_initialized = true
	return _id

func id() -> int:
	assert(_initialized)
	return _id

func set_id(new_id: int) -> void:
	assert(!_initialized)
	assert(_id == 0)
	_id = new_id
	_initialized = true
