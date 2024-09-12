class_name BoardState

var tiles: Dictionary
var pieces: Dictionary # Map from 
var current_turn: Team = Team.PLAYER

func is_end_state() -> bool:
	return false

func simulate_move(move: Move) -> BoardState:
	var new_state: = BoardState.new()
	new_state.tiles = tiles.duplicate()
	new_state.pieces = pieces.duplicate()
	new_state.current_turn = current_turn
	
	assert(new_state.has_piece(move.piece.pos()))
	assert(new_state.get_piece(move.piece.pos()) == move.piece)
	assert(move.piece.get_available_squares(self).has(move.to))
	
	# If is a capture, delete piece that gets captured
	if new_state.has_piece(move.to):
		assert(new_state.get_piece(move.to).team().is_hostile_to(move.piece.team()))
		new_state.pieces.erase(move.to)
	
	new_state.pieces.erase(move.piece.pos())
	new_state.pieces[move.to] = move.piece
	
	new_state.current_turn = Team.PLAYER if current_turn == Team.ENEMY_AI else Team.ENEMY_AI
	
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
