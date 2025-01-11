class_name MatchPieceMap

var _pieces: Array[Array]

func get_piece(pos: Vector2i) -> Piece:
	return _pieces[pos.y][pos.x]

func has_piece(pos: Vector2i) -> bool:
	return _pieces[pos.y][pos.x] != null
