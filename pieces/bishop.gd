class_name Bishop extends Piece

const DIRECTIONS: = [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)]

func get_available_squares(board: Board) -> Array[Vector2i]:
	var available_squares: Array[Vector2i] = []

	for dir: Vector2i in DIRECTIONS:
		var currently_checking: = pos() + dir
		while true:
			if not board.has_tile(currently_checking): break
			var piece: = board.get_piece(currently_checking)

			if piece:
				if Team.hostile_to_each_other(piece.team(), team()):
					available_squares.append(currently_checking)
				break

			available_squares.append(currently_checking)
			currently_checking = currently_checking + dir
			continue

	return available_squares
