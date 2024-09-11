class_name King extends Piece

const DIRECTIONS: = [
	Vector2i(1, 0),
	Vector2i(1, 1),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
]

func get_available_squares(s: BoardState) -> Array[Vector2i]:
	var available_squares: Array[Vector2i] = []

	for dir: Vector2i in DIRECTIONS:
		var currently_checking: = pos() + dir
		if not s.has_tile(currently_checking): continue
		var piece: = s.get_piece(currently_checking)

		if piece:
			if piece.team().is_hostile_to(team()):
				available_squares.append(currently_checking)
			continue

		available_squares.append(currently_checking)

	# Eliminate squares that would put king in check
	# TODO

	return available_squares

func get_worth() -> float:
	# Effectively infinity
	return 99999999999
