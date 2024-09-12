class_name Move

var piece_id: int
var from: Vector2i
var to: Vector2i

func _init(_piece_id: int, _from: Vector2i, _to: Vector2i) -> void:
	piece_id = _piece_id
	from = _from
	to = _to
