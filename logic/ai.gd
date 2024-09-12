class_name AI

class Result:
	var evaluation: float
	var move: Move
	
	func _init(_evaluation: float, _move: Move) -> void:
		evaluation = _evaluation
		move = _move

func get_best_result(s: BoardState, depth: int, alpha: float, beta: float) -> Result:
	if depth == 0 or s.is_end_state():
		return Result.new(evaluate(s), null)
	if s.current_turn == Team.PLAYER:
		var best_result: = Result.new(-INF, null)
		for move: Move in s.get_legal_moves():
			#print("%s: player move from %v to %v" % [depth, move.from, move.to])
			var new_board_state: = s.simulate_move(move)
			var result: = get_best_result(new_board_state, depth - 1, alpha, beta)
			#print("%s: eval if player move from %v to %v: %s" % [depth, move.from, move.to, result.evaluation])
			if result.evaluation >= best_result.evaluation:
				best_result = Result.new(result.evaluation, move)
				alpha = result.evaluation
			if beta <= alpha:
				break  # beta cut-off
		return best_result
	else:
		var worst_result: = Result.new(INF, null)
		for move: Move in s.get_legal_moves():
			#print("%s: ai move from %v to %v" % [depth, move.from, move.to])
			var new_board_state: = s.simulate_move(move)
			var result: = get_best_result(new_board_state, depth - 1, alpha, beta)
			#print("%s: eval if ai move from %v to %v: %s" % [depth, move.from, move.to, result.evaluation])
			if result.evaluation <= worst_result.evaluation:
				worst_result = Result.new(result.evaluation, move)
				beta = result.evaluation
			if beta <= alpha:
				break  # alpha cut-off
		return worst_result


func evaluate(board_state: BoardState) -> float:
	# Player pieces: positive
	# Enemy pieces: negative
	var piece_states: = board_state.piece_states.values()
	
	var eval: = 0.0
	for piece_state: PieceState in piece_states:
		assert(piece_state.team)
		
		if piece_state.team.is_player():
			eval += piece_state.get_worth()
		else:
			eval -= piece_state.get_worth()
	
	return eval
