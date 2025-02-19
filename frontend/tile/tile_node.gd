class_name TileNode extends Node2D

signal selected

var _pos: Vector2i
var is_hovered: bool = false
var is_pressed: bool = false
var is_selected: bool = false
#var show_dot: bool = false

@onready var square: Polygon2D = $Square

@onready var dot: Sprite2D = $Dot

func init(new_pos: Vector2i) -> void:
	_pos = new_pos
	if (_pos.x + _pos.y) % 2 == 0:
		square.color = Color("c7c5c3")
	else:
		square.color = Color("2f3350")
	name = "Tile_%v" % _pos
	$Label.text = "%s,%s" % [_pos.x, _pos.y]
	position = (Vector2(_pos) - Vector2.ONE * Config.max_board_size * 0.5) * 16

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
