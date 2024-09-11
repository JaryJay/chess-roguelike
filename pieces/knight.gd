class_name Knight extends Piece

const DIRECTIONS: = [
	Vector2i(2, 1),
	Vector2i(1, 2),
	Vector2i(-1, 2),
	Vector2i(-2, 1),
	Vector2i(-2, -1),
	Vector2i(-1, -2),
	Vector2i(1, -2),
	Vector2i(2, -1),
]

func get_available_squares(s: BoardState) -> Array[Vector2i]:
	var available_squares: Array[Vector2i] = []

	for dir: Vector2i in DIRECTIONS:
		var currently_checking: = pos() + dir
		if not s.has_tile(currently_checking): continue
		var piece: = s.get_piece(currently_checking)

		if not piece or Team.hostile_to_each_other(piece.team(), team()):
			available_squares.append(currently_checking)

	return available_squares

func get_worth() -> float:
	return 2.9
