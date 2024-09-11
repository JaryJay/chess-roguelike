class_name Move

var piece: Piece
var new_pos: Vector2i

func _init(_piece: Piece, _new_pos: Vector2i) -> void:
	piece = _piece
	new_pos = _new_pos
