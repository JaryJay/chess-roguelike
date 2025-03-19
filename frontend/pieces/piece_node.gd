class_name PieceNode extends Node2D

signal selected

@onready var piece_sprite_2d: PieceSprite2D = $PieceSprite2D

var _initialized := false
var _id: int
var _piece: Piece

var is_hovered: bool = false
var is_selected: bool = false
var _is_moving: bool = false

func _ready() -> void:
	init_team_sprites()
	add_to_group("piece_nodes")

func piece() -> Piece:
	return _piece

func set_piece(new_piece: Piece) -> void:
	if _initialized:
		assert(_piece)
		assert(_piece.type == new_piece.type, "%s != %s" % [_piece.type, new_piece.type])
	_piece = new_piece

func move_to(target_position: Vector2) -> void:
	_is_moving = true
	var tween := create_tween()
	tween.tween_property(self, "position", target_position + Vector2(0, -2), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "position", target_position, 0.05).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_callback(func(): _is_moving = false)

func init_team_sprites() -> void:
	assert(_initialized)
	assert(_piece)

	var white_texture_path := "res://frontend/pieces/textures/%s_white.tres" % Piece.TYPE_TO_STRING[_piece.type]
	var black_texture_path := "res://frontend/pieces/textures/%s_black.tres" % Piece.TYPE_TO_STRING[_piece.type]
	var white_texture: Texture2D = load(white_texture_path)
	var black_texture: Texture2D = load(black_texture_path)
	piece_sprite_2d.white_texture = white_texture
	piece_sprite_2d.black_texture = black_texture

	if piece().team.is_player():
		piece_sprite_2d.color = PieceSprite2D.PieceColor.WHITE
	elif piece().team.is_enemy():
		piece_sprite_2d.color = PieceSprite2D.PieceColor.BLACK
	else:
		assert(false, "Unknown team %s" % piece().team._key)

#region input handling

# This only works for mouse_and_keyboard
func _unhandled_input(event: InputEvent) -> void:
	if Settings.INPUT_MODE != "mouse_and_keyboard": return

	if event.is_action_pressed("primary") && is_hovered:
		selected.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_released("primary"):
		is_selected = false

# This only works for touch
func _on_button_pressed() -> void:
	if Settings.INPUT_MODE != "touch": return
	selected.emit()
	get_viewport().set_input_as_handled()

func _on_area_2d_mouse_entered() -> void:
	if Settings.INPUT_MODE != "mouse_and_keyboard": return
	set_hovered(true)

func _on_area_2d_mouse_exited() -> void:
	if Settings.INPUT_MODE != "mouse_and_keyboard": return
	set_hovered(false)

func set_hovered(new_hovered: bool) -> void:
	is_hovered = new_hovered
	if is_hovered and !_is_moving:
		var tw := create_tween()
		tw.tween_property(self, "position", Vector2(0, -1), 0.05).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	elif !is_hovered and !_is_moving:
		var tw := create_tween()
		tw.tween_property(self, "position", Vector2(0, 1), 0.05).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)

func set_selected(new_selected: bool) -> void:
	is_selected = new_selected
	if is_selected and !_is_moving:
		var tw := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
		tw.set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position", Vector2(0, -2), 0.05).as_relative()
		tw.tween_property(self, "rotation", randf_range(-0.05, 0.05), 0.05)
		tw.tween_property(self, "scale", Vector2.ONE * 1.1, 0.05)
		tw.set_ease(Tween.EASE_IN)
		tw.chain().tween_property(self, "position", calculate_target_position(), 0.05)
		tw.tween_property(self, "rotation", 0.0, 0.05)
		tw.tween_property(self, "scale", Vector2.ONE, 0.05)

func calculate_target_position() -> Vector2:
	return (Vector2(_piece.pos) - Vector2.ONE * Config.max_board_size * 0.5) * 16

#endregion

# Generating ids
static var _next_id := 1
func gen_id() -> void:
	assert(!_initialized)
	_id = _next_id
	_next_id += 1
	_initialized = true

func id() -> int:
	assert(_initialized)
	return _id

func set_id(new_id: int) -> void:
	assert(!_initialized)
	assert(_id == 0)
	_id = new_id
	_initialized = true
