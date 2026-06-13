class_name TileNode extends Node2D

signal selected

var _pos: Vector2i
var _base_square_color: Color
var _is_drag_hovered: bool = false
var _is_premove_highlighted: bool = false
var is_hovered: bool = false
var is_pressed: bool = false
var is_selected: bool = false
#var show_dot: bool = false

@onready var square: Polygon2D = $Square

@onready var dot: Sprite2D = $Dot

func init(new_pos: Vector2i) -> void:
	_pos = new_pos
	if (_pos.x + _pos.y) % 2 == 0:
		_base_square_color = Color("c7c5c3")
	else:
		_base_square_color = Color("2f3350")
	square.color = _base_square_color
	name = "Tile_%v" % _pos
	$Label.text = "%s,%s" % [_pos.x, _pos.y]
	position = (Vector2(_pos) - Vector2.ONE * Config.max_board_size * 0.5) * 16

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

func set_show_premove(new_val: bool) -> void:
	_is_premove_highlighted = new_val
	_apply_square_color()

func set_show_drag_hover(new_val: bool) -> void:
	_is_drag_hovered = new_val
	_apply_square_color()

func _apply_square_color() -> void:
	if _is_drag_hovered:
		square.color = _base_square_color.lerp(Color(0.9, 0.85, 0.4), 0.45)
	elif _is_premove_highlighted:
		square.color = _base_square_color.lerp(Color(0.4, 0.6, 0.9), 0.35)
	else:
		square.color = _base_square_color
