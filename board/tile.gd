class_name Tile extends Node2D

signal mouse_selected

var _pos: Vector2i
var hovered: bool = false
var pressed: bool = false
var selected: bool = false
#var show_dot: bool = false

@onready var square: Polygon2D = $Square

@onready var dot: Sprite2D = $Dot

func init(new_pos: Vector2i) -> void:
	_pos = new_pos
	if (_pos.x + _pos.y) % 2 == 0:
		square.color = Color("c7c5c3")
	else:
		square.color = Color("2f3350")
	$Label.text = "%s,%s" % [new_pos.x, new_pos.y]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("primary") && hovered:
		mouse_selected.emit()
	elif event.is_action_released("primary"):
		pressed = false

func _on_area_2d_mouse_entered() -> void:
	set_hovered(true)

func _on_area_2d_mouse_exited() -> void:
	set_hovered(false)

func pos() -> Vector2i:
	return _pos

func set_hovered(new_hovered: bool) -> void:
	hovered = new_hovered

func set_selected(new_selected: bool) -> void:
	selected = new_selected

func set_show_dot(new_val: bool) -> void:
	dot.visible = new_val
