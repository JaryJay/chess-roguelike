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

func get_available_squares(board: Board) -> Array[Vector2i]:
	var available_squares: Array[Vector2i] = []
	
	for dir: Vector2i in DIRECTIONS:
		var currently_checking: = pos() + dir
		if not board.has_tile(currently_checking): continue
		var piece: = board.get_piece(currently_checking)
		
		if piece:
			if Team.hostile_to_each_other(piece.team(), team()):
				available_squares.append(currently_checking)
			continue
		
		available_squares.append(currently_checking)
	
	# Eliminate squares that would put king in check
	# TODO
	
	return available_squares
