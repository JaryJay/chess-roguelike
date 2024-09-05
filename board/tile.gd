class_name Tile extends Node3D

const white_tile_material: = preload("res://materials/white_tile_material.tres")
const black_tile_material: = preload("res://materials/black_tile_material.tres")

var pos: Vector2i

@onready var tile: MeshInstance3D = $TileModel/Tile

func init(_pos: Vector2i) -> void:
	pos = _pos
	if (pos.x + pos.y) % 2 == 0:
		tile.material_override = black_tile_material
	else:
		tile.material_override = white_tile_material
