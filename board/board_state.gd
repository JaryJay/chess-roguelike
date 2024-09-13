class_name BoardState

var tiles: Dictionary # Map from Vector2i to Tile
var piece_states: Dictionary # Map from Vector2i to PieceState
var current_turn: Team = Team.PLAYER

func is_end_state() -> bool:
	return not (is_king_alive(Team.PLAYER) and is_king_alive(Team.ENEMY_AI))

func simulate_move(move: Move) -> BoardState:
	var new_state: = duplicate()
	
	assert(new_state.has_piece(move.from))
	var piece_state: = new_state.get_piece_state(move.from)
	assert(piece_state != get_piece_state(move.from)) # Should not be equal by reference
	assert(piece_state.id == move.piece_id)
	assert(piece_state.get_available_squares(self).has(move.to))
	
	# If is a capture, delete piece that gets captured
	if new_state.has_piece(move.to):
		assert(new_state.get_piece_state(move.to).team.is_hostile_to(piece_state.team))
		new_state.piece_states.erase(move.to)
	
	new_state.piece_states.erase(piece_state.pos)
	new_state.piece_states[move.to] = piece_state
	piece_state.pos = move.to
	
	new_state.current_turn = Team.PLAYER if current_turn == Team.ENEMY_AI else Team.ENEMY_AI
	
	return new_state

func get_legal_moves() -> Array[Move]:
	var moves: Array[Move] = []
	for piece_state: PieceState in piece_states.values():
		if piece_state.team != current_turn: continue
		
		for available_square: Vector2i in piece_state.get_available_squares(self):
			moves.append(Move.new(piece_state.id, piece_state.pos, available_square))
	return moves

func is_king_alive(team: Team) -> bool:
	var is_friendly_king: = func(p: PieceState) -> bool:
		return p.type == Piece.Type.KING and p.team.is_friendly_to(team)
	return not piece_states.values().filter(is_friendly_king).is_empty()

func is_king_in_check(team: Team) -> bool:
	var is_friendly_king: = func(p: PieceState) -> bool:
		return p.type == Piece.Type.KING and p.team.is_friendly_to(team)
	var king: PieceState = piece_states.values().filter(is_friendly_king)[0]
	assert(king != null)
	
	for p: PieceState in piece_states.values():
		if p.team.is_friendly_to(team): continue
		if p.get_available_squares(self).has(king.pos): return true
	return false

func duplicate() -> BoardState:
	var board_state: = BoardState.new()
	for key: Vector2i in tiles:
		board_state.tiles[key] = tiles[key]
	for key: Vector2i in piece_states:
		board_state.piece_states[key] = get_piece_state(key).duplicate()
	board_state.current_turn = current_turn
	
	return board_state

func get_tile(pos: Vector2i) -> Tile:
	return tiles[pos] as Tile

func has_tile(pos: Vector2i) -> bool:
	return tiles.has(pos)

func has_piece(pos: Vector2i) -> bool:
	return piece_states.has(pos)

func get_piece_state(pos: Vector2i) -> PieceState:
	return piece_states.get(pos)
