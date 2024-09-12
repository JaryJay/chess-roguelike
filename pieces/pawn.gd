class_name Pawn extends Piece

const DIAGONALS_PLAYER: = [Vector2i(1, -1), Vector2i(1, -1)]
const DIAGONALS_ENEMY: = [Vector2i(1, 1), Vector2i(1, 1)]

func get_available_squares(s: BoardState) -> Array[Vector2i]:
	var available_squares: Array[Vector2i] = []
	
	var forwards: = pos() + (Vector2i.UP if team().is_player() else Vector2i.DOWN)
	if s.has_tile(forwards) and not s.has_piece(forwards):
		available_squares.append(forwards)
	for diagonal: Vector2i in (DIAGONALS_PLAYER if team().is_player() else DIAGONALS_ENEMY):
		var square: = pos() + diagonal
		if s.has_tile(square) and s.has_piece(square) and s.get_piece(square).team().is_hostile_to(team()):
			available_squares.append(square)
	
	return available_squares

func get_worth() -> float:
	return 1
