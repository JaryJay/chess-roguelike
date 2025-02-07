class_name PieceNode extends Node2D

signal mouse_selected

var _sprite_pivot: Node2D

var _initialized: = false
var _id: int
var _piece: Piece

var hovered: bool = false
var pressed: bool = false
var selected: bool = false
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

	var sprite_path: = "res://frontend/pieces/sprites/%s_sprites.tscn" % PieceRules.type_to_string[_piece.type]
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("primary") && hovered:
		mouse_selected.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_released("primary"):
		pressed = false

func _on_area_2d_mouse_entered() -> void:
	set_hovered(true)

func _on_area_2d_mouse_exited() -> void:
	set_hovered(false)

func set_hovered(new_hovered: bool) -> void:
	hovered = new_hovered
	if hovered and !_is_moving:
		var tween: = create_tween()
		tween.tween_property(self, "position", Vector2(0, -1), 0.05).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	elif !hovered and !_is_moving:
		var tween: = create_tween()
		tween.tween_property(self, "position", Vector2(0, 1), 0.05).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)

func set_selected(new_selected: bool) -> void:
	selected = new_selected
	if selected and !_is_moving:
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
