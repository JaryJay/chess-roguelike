class_name Move

const CHECK: = 2**1
const CAPTURE: = 2**2
const CASTLE_LEFT: = 2**3
const CASTLE_RIGHT: = 2**4

var from: Vector2i
var to: Vector2i
## Can represent different things based on what piece is being moved
var info: int
var promo_info: Piece.Type

func _init(_from: Vector2i, _to: Vector2i, _info: = 0, _promo_info: = Piece.Type.UNSET) -> void:
	from = _from
	to = _to
	info = _info
	promo_info = _promo_info

func is_check() -> bool:
	return info & CHECK != 0

func is_capture() -> bool:
	return info & CAPTURE != 0

func is_castle() -> bool:
	assert(
		!(info & CASTLE_LEFT != 0 and info & CASTLE_RIGHT != 0),
		"You can't castle in two directions at once"
	)
	return info & (CASTLE_LEFT | CASTLE_RIGHT) != 0

func is_promotion() -> bool:
	return promo_info != Piece.Type.UNSET

func get_promotion_type() -> Piece.Type:
	assert(is_promotion(), "Must be a promotion")
	return promo_info
