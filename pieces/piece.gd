class_name Piece extends Node

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
