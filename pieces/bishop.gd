class_name Bishop extends Piece

const DIRECTIONS: = [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)]

func get_available_squares(s: BoardState) -> Array[Vector2i]:
	var available_squares: Array[Vector2i] = []

	for dir: Vector2i in DIRECTIONS:
		var currently_checking: = pos() + dir
		while true:
			if not s.has_tile(currently_checking): break
			var piece: = s.get_piece(currently_checking)

			if piece:
				if piece.team().is_hostile_to(team()):
					available_squares.append(currently_checking)
				break

			available_squares.append(currently_checking)
			currently_checking = currently_checking + dir
			continue

	return available_squares

func get_worth() -> float:
	return 3
