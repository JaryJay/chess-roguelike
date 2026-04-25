class_name TileNode extends Node2D

signal selected

var _pos: Vector2i
var is_hovered: bool = false
var is_pressed: bool = false
var is_selected: bool = false

@onready var square: Polygon2D = $Square

@onready var dot: Sprite2D = $Dot

var _base_square_color: Color
var _check_flash_tween: Tween = null

func init(new_pos: Vector2i) -> void:
	_pos = new_pos
	if (_pos.x + _pos.y) % 2 == 0:
		square.color = Color("c7c5c3")
	else:
		square.color = Color("2f3350")
	_base_square_color = square.color
	name = "Tile_%v" % _pos
	position = (Vector2(_pos) - Vector2.ONE * Config.max_board_size * 0.5) * 16

## Tints the tile square to indicate this is where the last move started or ended.
func set_last_move_highlight(val: bool) -> void:
	if val:
		square.color = _base_square_color.lerp(Color(1.0, 0.85, 0.2, 1.0), 0.45)
	else:
		square.color = _base_square_color

## Starts or stops a continuous red pulse on this tile (used to show check on the king's tile).
func set_check_flashing(val: bool) -> void:
	if _check_flash_tween:
		_check_flash_tween.kill()
		_check_flash_tween = null
	if val:
		_check_flash_tween = create_tween().set_loops()
		_check_flash_tween.tween_property(square, "color", Color(1.0, 0.15, 0.15, 1.0), 0.4).set_ease(Tween.EASE_IN_OUT)
		_check_flash_tween.tween_property(square, "color", _base_square_color, 0.4).set_ease(Tween.EASE_IN_OUT)
	else:
		square.color = _base_square_color

func animate_flash(intensity: float = 1.2, duration: float = 0.4, delay: float = 0.0) -> void:
	# Because darker squares are less visible, we need to make them flash brighter
	if (_pos.x + _pos.y) % 2 == 1:
		intensity *= 1.1
	
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(self, "modulate", Color(intensity, intensity, intensity, 1), duration * 0.5)
	tw.tween_property(self, "modulate", Color.WHITE, duration * 0.5)

# This only works for mouse_and_keyboard
func _unhandled_input(event: InputEvent) -> void:
	if Settings.INPUT_MODE != "mouse_and_keyboard": return
	
	if event.is_action_pressed("primary") && is_hovered:
		selected.emit()
	elif event.is_action_released("primary"):
		is_pressed = false

# This only works for touch
func _on_button_pressed() -> void:
	if Settings.INPUT_MODE != "touch": return
	selected.emit()
	get_viewport().set_input_as_handled()

func _on_area_2d_mouse_entered() -> void:
	set_hovered(true)

func _on_area_2d_mouse_exited() -> void:
	set_hovered(false)

func pos() -> Vector2i:
	return _pos

func set_hovered(new_hovered: bool) -> void:
	is_hovered = new_hovered

func set_selected(new_selected: bool) -> void:
	is_selected = new_selected

func set_show_dot(new_val: bool) -> void:
	dot.visible = new_val
