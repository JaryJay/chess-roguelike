class_name MoveAction

var piece_id: int
var to: Vector2i
## If 0, then no piece is captured
var captured_piece_id: int = 0

## See Move
var info: int
var promo_info: Piece.Type

func _init(_piece_id: int, _to: Vector2i, _info := 0, _promo_info := Piece.Type.UNSET, _capt_id := 0):
	piece_id = _piece_id
	to = _to
	info = _info
	promo_info = _promo_info
	captured_piece_id = _capt_id

func is_check() -> bool:
	return info & Move.CHECK != 0

func is_capture() -> bool:
	return info & Move.CAPTURE != 0

func is_castle() -> bool:
	assert(
		!(info & Move.CASTLE_LEFT != 0 and info & Move.CASTLE_RIGHT != 0),
		"You can't castle in two directions at once"
	)
	return info & (Move.CASTLE_LEFT | Move.CASTLE_RIGHT) != 0

func is_promotion() -> bool:
	return promo_info != Piece.Type.UNSET

func get_promotion_type() -> Piece.Type:
	assert(is_promotion(), "Must be a promotion")
	return promo_info
