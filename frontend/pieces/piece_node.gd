class_name PieceNode extends Node2D

signal selected

var _sprite_pivot: Node2D

var _initialized: = false
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
	var tween: = create_tween()
	tween.tween_property(self, "position", target_position + Vector2(0, -2), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "position", target_position, 0.05).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_callback(func(): _is_moving = false)

func init_team_sprites() -> void:
	assert(_initialized)
	assert(_piece)

	# $SpritePivot is the placeholder sprite node, we can remove it
	$SpritePivot.queue_free()
	remove_child($SpritePivot)

	var sprite_path: = "res://frontend/pieces/sprites/%s_sprites.tscn" % Piece.TYPE_TO_STRING[_piece.type]
	_sprite_pivot = load(sprite_path).instantiate()
	_sprite_pivot.name = "SpritePivot"
	add_child(_sprite_pivot)

	if piece().team.is_player():
		# Hide black sprite
		_sprite_pivot.get_node("B").hide()
	elif piece().team.is_enemy():
		# Hide white sprite
		_sprite_pivot.get_node("W").hide()
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
		var tween: = create_tween()
		tween.tween_property(self, "position", Vector2(0, -1), 0.05).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	elif !is_hovered and !_is_moving:
		var tween: = create_tween()
		tween.tween_property(self, "position", Vector2(0, 1), 0.05).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)

func set_selected(new_selected: bool) -> void:
	is_selected = new_selected
	if is_selected and !_is_moving:
		var tween: = create_tween()
		tween.tween_property(self, "position", Vector2(0, -2), 0.05).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
		tween.tween_property(self, "position", Vector2(0, 2), 0.05).as_relative().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)

#endregion

# Generating ids
static var _next_id: = 1
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
