class_name Move

var piece: Piece
var to: Vector2i

func _init(_piece: Piece, _to: Vector2i) -> void:
	piece = _piece
	to = _to
