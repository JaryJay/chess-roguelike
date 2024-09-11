class_name Pawn extends Piece

const DIAGONALS: = [Vector2i(1, -1), Vector2i(1, -1)]

func get_available_squares(s: BoardState) -> Array[Vector2i]:
	var available_squares: Array[Vector2i] = []
	
	var forwards: = pos() + Vector2i(0, -1)
	if s.has_tile(forwards) and not s.has_piece(forwards):
		available_squares.append(forwards)
	for diagonal: Vector2i in DIAGONALS:
		var square: = pos() + diagonal
		if s.has_tile(square) and s.has_piece(square) and Team.hostile_to_each_other(s.get_piece(square).team(), team()):
			available_squares.append(square)
	
	return available_squares
