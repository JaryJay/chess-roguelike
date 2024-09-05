class_name Tile extends Node3D

signal mouse_selected

const white_tile_material: = preload("res://materials/white_tile_material.tres")
const black_tile_material: = preload("res://materials/black_tile_material.tres")

var pos: Vector2i
var hovered: bool = false
var pressed: bool = false
var selected: bool = false
#var show_dot: bool = false

@onready var tile: MeshInstance3D = $TileModel/Tile
@onready var dot: Sprite3D = $Dot

func init(_pos: Vector2i) -> void:
	pos = _pos
	if (pos.x + pos.y) % 2 == 0:
		tile.material_override = black_tile_material
	else:
		tile.material_override = white_tile_material

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("primary") && hovered:
		mouse_selected.emit()
	elif event.is_action_released("primary"):
		pressed = false

func _on_area_3d_mouse_entered() -> void:
	set_hovered(true)

func _on_area_3d_mouse_exited() -> void:
	set_hovered(false)

func set_hovered(new_hovered: bool) -> void:
	hovered = new_hovered

func set_selected(new_selected: bool) -> void:
	selected = new_selected

func set_show_dot(new_val: bool) -> void:
	dot.visible = new_val
