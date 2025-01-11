class_name Move

enum Promotion {
	PROMOTE_TO_QUEEN = 1,
	PROMOTE_TO_ROOK = 2,
	PROMOTE_TO_BISHOP = 4,
	PROMOTE_TO_KNIGHT = 8,
}

var from: Vector2i
var to: Vector2i
var is_check: bool
## Can represent different things based on what piece is being moved
var info: int

func _init(_from: Vector2i, _to: Vector2i, _info = 0) -> void:
	from = _from
	to = _to
	info = _info
