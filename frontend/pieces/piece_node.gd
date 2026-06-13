class_name PieceNode extends Node2D

signal selected

@onready var visual_pivot: Node2D = $VisualPivot
@onready var piece_sprite_2d: PieceSprite2D = $VisualPivot/PieceSprite2D

var _initialized := false
var _id: int
var _piece: Piece

var is_hovered: bool = false
var is_selected: bool = false
var _is_moving: bool = false
var _is_dragging: bool = false
var _drag_z_index: int = 0
var _saved_scale: Vector2 = Vector2.ONE
var _feedback_tween: Tween = null

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

func move_to(target_position: Vector2, is_promotion: bool = false) -> void:
	if _is_dragging:
		end_drag(false)
	_is_moving = true
	_stop_feedback_tween()
	reset_visual_pivot()

	if is_promotion:
		var promotion_particles: Node2D = preload("res://frontend/vfx/promotion_particles.tscn").instantiate()
		promotion_particles.local_coords = true
		add_child(promotion_particles)
		promotion_particles.position = Vector2(0, 5)

	var tween := create_tween()
	tween.tween_property(self, "position", target_position + Vector2(0, -2), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_callback(func():
		var dust_particles: Node2D = preload("res://frontend/vfx/dust_particles.tscn").instantiate()
		dust_particles.local_coords = true
		add_child(dust_particles)
		dust_particles.position = Vector2(0, 8)
	)
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

func _stop_feedback_tween() -> void:
	if _feedback_tween:
		_feedback_tween.kill()
		_feedback_tween = null

func reset_visual_pivot() -> void:
	_stop_feedback_tween()
	visual_pivot.position = Vector2.ZERO
	visual_pivot.rotation = 0.0
	if not _is_dragging:
		visual_pivot.scale = Vector2.ONE

func set_hovered(new_hovered: bool) -> void:
	is_hovered = new_hovered
	if is_hovered and !_is_moving and !_is_dragging:
		_stop_feedback_tween()
		_feedback_tween = create_tween()
		_feedback_tween.tween_property(visual_pivot, "position", Vector2(0, -1), 0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	elif !is_hovered and !_is_moving and !_is_dragging:
		_stop_feedback_tween()
		_feedback_tween = create_tween()
		_feedback_tween.tween_property(visual_pivot, "position", Vector2.ZERO, 0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)

func set_selected(new_selected: bool) -> void:
	is_selected = new_selected
	if is_selected and !_is_moving and !_is_dragging:
		_stop_feedback_tween()
		_feedback_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
		_feedback_tween.set_ease(Tween.EASE_OUT)
		_feedback_tween.tween_property(visual_pivot, "position", Vector2(0, -2), 0.05)
		_feedback_tween.tween_property(visual_pivot, "rotation", randf_range(-0.05, 0.05), 0.05)
		_feedback_tween.tween_property(visual_pivot, "scale", Vector2.ONE * 1.1, 0.05)
		_feedback_tween.set_ease(Tween.EASE_IN)
		_feedback_tween.chain().tween_property(visual_pivot, "position", Vector2.ZERO, 0.05)
		_feedback_tween.tween_property(visual_pivot, "rotation", 0.0, 0.05)
		_feedback_tween.tween_property(visual_pivot, "scale", Vector2.ONE, 0.05)

		var particles: OneShotParticles = load("res://frontend/vfx/select_particles.tscn").instantiate()
		particles.position = position + Vector2(0, 6)
		get_tree().root.add_child(particles)
	elif !new_selected and !_is_moving and !_is_dragging:
		reset_visual_pivot()

func calculate_target_position() -> Vector2:
	return (Vector2(_piece.pos) - Vector2.ONE * Config.max_board_size * 0.5) * 16

func is_moving() -> bool:
	return _is_moving

func is_dragging() -> bool:
	return _is_dragging

func begin_drag() -> void:
	_is_dragging = true
	_stop_feedback_tween()
	reset_visual_pivot()
	_drag_z_index = z_index
	z_index = 100
	_saved_scale = visual_pivot.scale
	visual_pivot.scale = Vector2.ONE * 1.15

func update_drag_position(local_pos: Vector2) -> void:
	position = local_pos

func end_drag(restore: bool) -> void:
	_is_dragging = false
	z_index = _drag_z_index
	visual_pivot.scale = _saved_scale
	if restore:
		position = calculate_target_position()

func snap_to_position(world_position: Vector2) -> void:
	if _is_dragging:
		end_drag(false)
	_stop_feedback_tween()
	reset_visual_pivot()
	position = world_position

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
