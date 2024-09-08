class_name Pawn extends Piece

const DIAGONALS: = [Vector2i(1, -1), Vector2i(1, -1)]

func get_available_squares(board: Board) -> Array[Vector2i]:
	var available_squares: Array[Vector2i] = []
	
	var forwards: = pos() + Vector2i(0, -1)
	if board.has_tile(forwards) and not board.has_piece(forwards):
		available_squares.append(forwards)
	for diagonal: Vector2i in DIAGONALS:
		var square: = pos() + diagonal
		if board.has_tile(square) and board.has_piece(square) and Team.hostile_to_each_other(board.get_piece(square).team(), team()):
			available_squares.append(square)
	
	return available_squares
