class_name BoardEvaluationTest

static func test_1() -> void:
	var state: = BoardState.new()
	
	for y in 3: # 0 to 2
		for x in 4: # 0 to 3
			add_tile_to_board_state(Vector2i(x, y), state)
	
	add_piece_to_board_state(Vector2i(3, 2), Piece.Type.KING, Team.PLAYER, state)
	add_piece_to_board_state(Vector2i(1, 2), Piece.Type.ROOK, Team.PLAYER, state)
	add_piece_to_board_state(Vector2i(2, 0), Piece.Type.KNIGHT, Team.PLAYER, state)
	
	add_piece_to_board_state(Vector2i(0, 0), Piece.Type.KING, Team.ENEMY_AI, state)
	add_piece_to_board_state(Vector2i(1, 0), Piece.Type.ROOK, Team.ENEMY_AI, state)
	add_piece_to_board_state(Vector2i(0, 1), Piece.Type.BISHOP, Team.ENEMY_AI, state)
	
	state.current_turn = Team.ENEMY_AI
	
	var ai: = AI.new()
	assert(is_equal_approx(ai.evaluate(state), -0.2))
	
	# Rook captures knight
	state = state.simulate_move(Move.new(state.get_piece_state(Vector2i(1, 0)).id, Vector2i(1, 0), Vector2i(2, 0)))
	assert(is_equal_approx(ai.evaluate(state), -3.2))
	
	# Player king moves up
	state = state.simulate_move(Move.new(state.get_piece_state(Vector2i(3, 2)).id, Vector2i(3, 2), Vector2i(3, 1)))
	assert(is_equal_approx(ai.evaluate(state), -3.2))
	
	# Bishop captures rook
	state = state.simulate_move(Move.new(state.get_piece_state(Vector2i(0, 1)).id, Vector2i(0, 1), Vector2i(1, 2)))
	assert(is_equal_approx(ai.evaluate(state), -8.2))
	
	# King captures rook
	state = state.simulate_move(Move.new(state.get_piece_state(Vector2i(3, 1)).id, Vector2i(3, 1), Vector2i(2, 0)))
	assert(is_equal_approx(ai.evaluate(state), -3.2))
	
	print("Test 1 passed")

# Mate in two test
static func test_2() -> void:
	var state: = BoardState.new()
	
	for y in 4: # 0 to 3
		for x in 5: # 0 to 4
			add_tile_to_board_state(Vector2i(x, y), state)
	
	add_piece_to_board_state(Vector2i(4, 3), Piece.Type.KING, Team.PLAYER, state)
	add_piece_to_board_state(Vector2i(1, 3), Piece.Type.ROOK, Team.PLAYER, state)
	add_piece_to_board_state(Vector2i(3, 2), Piece.Type.PAWN, Team.PLAYER, state)
	add_piece_to_board_state(Vector2i(4, 2), Piece.Type.PAWN, Team.PLAYER, state)
	
	add_piece_to_board_state(Vector2i(0, 0), Piece.Type.KING, Team.ENEMY_AI, state)
	add_piece_to_board_state(Vector2i(2, 0), Piece.Type.ROOK, Team.ENEMY_AI, state)
	add_piece_to_board_state(Vector2i(2, 1), Piece.Type.QUEEN, Team.ENEMY_AI, state)
	
	state.current_turn = Team.ENEMY_AI
	
	var ai: = AI.new()
	var result0: = ai.get_best_result(state, 5)
	assert(result0.move.piece_id == state.get_piece_state(Vector2i(2, 1)).id)
	assert(result0.move.from == Vector2i(2, 1))
	assert(result0.move.to == Vector2i(2, 3))
	assert(result0.evaluation < -1000) # AI should know that it won
	
	state = state.simulate_move(result0.move)
	state = state.simulate_move(Move.new(state.get_piece_state(Vector2i(1, 3)).id, Vector2i(1, 3), Vector2i(2, 3)))
	
	var result1: = ai.get_best_result(state, 3)
	assert(result1.move.piece_id == state.get_piece_state(Vector2i(2, 0)).id)
	assert(result1.move.from == Vector2i(2, 0))
	assert(result1.move.to == Vector2i(2, 3))
	
	print("Test 2 passed")

static func add_tile_to_board_state(pos: Vector2i, state: BoardState) -> void:
	var tile: = TileNode.new()
	tile._pos = Vector2(pos.x, pos.y)
	state.tiles[pos] = tile

static func add_piece_to_board_state(pos: Vector2i, piece_type: Piece.Type, team: Team, state: BoardState) -> void:
	var piece_state: = PieceState.new(pos, piece_type, team)
	state.piece_states[pos] = piece_state
