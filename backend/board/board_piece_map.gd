class_name BoardPieceMap

var _pieces: Array[Array] = []
var _cached_king_positions: Dictionary = {}

func _init() -> void:
	_pieces.resize(Config.max_board_size)
	for y: int in _pieces.size():
		_pieces[y] = []
		_pieces[y].resize(Config.max_board_size)

func get_piece(pos: Vector2i) -> Piece:
	assert(has_piece(pos), "No piece at %.v" % pos)
	return _pieces[pos.y][pos.x]

func remove_piece(pos: Vector2i) -> void:
	assert(has_piece(pos), "No piece at %.v" % pos)
	_pieces[pos.y][pos.x] = null

func put_piece(pos: Vector2i, piece: Piece) -> void:
	assert(!has_piece(pos), "Piece already at %.v" % pos)
	_pieces[pos.y][pos.x] = piece

func has_piece(pos: Vector2i) -> bool:
	return _pieces[pos.y][pos.x] != null

func get_king(team: Team) -> Piece:
	# TODO: implement caching
	# if _cached_king_positions.has(team):
	# 	return _cached_king_positions[team]
	
	for y: int in _pieces.size():
		for x: int in _pieces[y].size():
			if !has_piece(Vector2i(x, y)): continue
			var piece: = get_piece(Vector2i(x, y))
			if piece.type == Piece.Type.KING and piece.team == team:
				_cached_king_positions[team] = piece
	
	return _cached_king_positions[team]

func get_all_pieces() -> Array[Piece]:
	var all_pieces: Array[Piece] = []
	
	for y: int in _pieces.size():
		for x: int in _pieces[y].size():
			var pos: = Vector2i(x, y)
			if has_piece(pos):
				all_pieces.append(get_piece(pos))
	
	return all_pieces

func duplicate() -> BoardPieceMap:
	var new_piece_map: = BoardPieceMap.new()
	
	for y: int in _pieces.size():
		for x: int in _pieces[y].size():
			new_piece_map._pieces[y][x] = _pieces[y][x]
	for key: Team in _cached_king_positions:
		new_piece_map._cached_king_positions[key] = _cached_king_positions[key]
	
	return new_piece_map
