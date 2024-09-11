class_name BoardState

var tiles: Dictionary
var pieces: Dictionary
var current_turn: Team.s = Team.s.ALLY_PLAYER

func is_end_state() -> bool:
	return false

func simulate_move(move: Move) -> BoardState:
	var new_state: = BoardState.new()
	new_state.tiles = tiles.duplicate()
	new_state.pieces = pieces.duplicate()
	new_state.current_turn = Team.s.ALLY_PLAYER if current_turn == Team.s.ENEMY_AI_0 else Team.s.ENEMY_AI_0
	
	assert(new_state.get_piece(move.piece.pos()) == move.piece)
	assert(move.piece.get_available_squares(self).has(move.new_pos))
	
	# If is a capture, delete piece that gets captured
	if new_state.has_piece(move.new_pos):
		assert(Team.hostile_to_each_other(new_state.get_piece(move.new_pos).team(), move.piece.team()))
		new_state.pieces.erase(move.new_pos)
	
	new_state.pieces.erase(move.piece.pos())
	new_state.pieces[move.new_pos] = move.piece
	
	return new_state

func get_legal_moves() -> Array[Move]:
	var moves: Array[Move] = []
	for piece: Piece in pieces.values():
		if piece.team() != current_turn: continue
		
		for available_square: Vector2i in piece.get_available_squares(self):
			moves.append(Move.new(piece, available_square))
	return moves

func get_tile(pos: Vector2i) -> Tile:
	return tiles[pos] as Tile

func has_tile(pos: Vector2i) -> bool:
	return tiles.has(pos)

func has_piece(pos: Vector2i) -> bool:
	return pieces.has(pos)

func get_piece(pos: Vector2i) -> Piece:
	return pieces.get(pos)
