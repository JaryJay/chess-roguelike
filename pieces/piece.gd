class_name Piece extends Node

const black_material: = preload("res://materials/black_piece_material.tres")
const white_material: = preload("res://materials/white_piece_material.tres")

@export var mesh: MeshInstance3D
var _pos: Vector2i
var _team: Team.s

func get_available_squares(_board: Board) -> Array[Vector2i]:
	printerr("get_available_squares not implemented")
	return []

func pos() -> Vector2i:
	return _pos

func set_pos(new_pos: Vector2i) -> void:
	_pos = new_pos

func team() -> Team.s:
	return _team

func set_team(new_team: Team.s) -> void:
	_team = new_team
	assert(mesh)
	if new_team == Team.s.ALLY_PLAYER:
		mesh.material_override = white_material
	else:
		mesh.material_override = black_material
