class_name AI

class Result extends Resource:
	var evaluation: float
	var move: Move
	
	func _init(_evaluation: float, _move: Move) -> void:
		evaluation = _evaluation
		move = _move
	
	func _to_string() -> String:
		return "Move %s, Eval %.1f" % [move, evaluation]

func get_best_result(s: BoardState, depth: int, alpha: float, beta: float) -> Result:
	if depth == 0 or s.is_end_state():
		return Result.new(evaluate(s), null)
	if s.current_turn == Team.PLAYER:
		var best_result: = Result.new(-INF, null)
		var legal_moves: = s.get_legal_moves()
		sort_moves_by_strength_desc(legal_moves, s)
		for move: Move in legal_moves:
			#print("%s: player move from %v to %v" % [depth, move.from, move.to])
			var new_board_state: = s.simulate_move(move)
			var result: = get_best_result(new_board_state, depth - 1, alpha, beta)
			#print("%s: eval if player move from %v to %v: %s" % [depth, move.from, move.to, result.evaluation])
			if result.evaluation >= best_result.evaluation:
				best_result = Result.new(result.evaluation, move)
				alpha = result.evaluation
			if beta <= alpha:
				print("Beta cut-off at d=%s, a=%s, b=%s" % [depth - 1, alpha, beta])
				break  # beta cut-off
		return best_result
	else:
		var worst_result: = Result.new(INF, null)
		var legal_moves: = s.get_legal_moves()
		sort_moves_by_strength_desc(legal_moves, s)
		for move: Move in legal_moves:
			#print("%s: ai move from %v to %v" % [depth, move.from, move.to])
			var new_board_state: = s.simulate_move(move)
			var result: = get_best_result(new_board_state, depth - 1, alpha, beta)
			#print("%s: eval if ai move from %v to %v: %s" % [depth, move.from, move.to, result.evaluation])
			if result.evaluation <= worst_result.evaluation:
				worst_result = Result.new(result.evaluation, move)
				beta = result.evaluation
			if beta <= alpha:
				print("Alpha cut-off at d=%s, a=%s, b=%s" % [depth - 1, alpha, beta])
				break  # alpha cut-off
		return worst_result

func evaluate(board_state: BoardState) -> float:
	# Player pieces: positive
	# Enemy pieces: negative
	var piece_states: = board_state.piece_states.values()
	
	if not board_state.is_king_alive(Team.PLAYER):
		return -INF
	if not board_state.is_king_alive(Team.ENEMY_AI):
		return INF
	
	var eval: = 0.0
	for piece_state: PieceState in piece_states:
		assert(piece_state.team)
		
		if piece_state.team.is_player():
			eval += piece_state.get_worth()
		else:
			eval -= piece_state.get_worth()
	
	return eval

func sort_moves_by_strength_desc(moves: Array[Move], board_state: BoardState) -> void:
	var move_strength_cache: Dictionary = {} # Map from move to float
	moves.sort_custom(func(m1: Move, m2: Move) -> bool:
		if not move_strength_cache.has(m1):
			move_strength_cache[m1] = estimate_move_strength(m1, board_state)
		if not move_strength_cache.has(m2):
			move_strength_cache[m2] = estimate_move_strength(m2, board_state)
		return move_strength_cache[m1] < move_strength_cache[m2]
	)

## Used as a heuristic to prioritize certain moves in get_best_result
func estimate_move_strength(move: Move, board_state: BoardState) -> float:
	var strength: = 0.0
	
	var piece_state: = board_state.get_piece_state(move.from)
	var opposing_team: Team = Team.ENEMY_AI if piece_state.team.is_player() else Team.PLAYER
	
	# If it's a capture, get the worth of the piece captured
	if board_state.has_piece(move.to):
		var captured_piece_value: = board_state.get_piece_state(move.to).get_worth()
		strength += captured_piece_value
	
	var next_state: = board_state.simulate_move(move)
	
	assert(next_state.is_king_alive(piece_state.team), "You can't make a move when your king is dead")
	if not next_state.is_king_alive(opposing_team):
		return INF
	
	# Instant loss
	if next_state.is_king_in_check(piece_state.team):
		return -INF
	
	if next_state.is_king_in_check(opposing_team):
		strength += 10
	
	return strength
