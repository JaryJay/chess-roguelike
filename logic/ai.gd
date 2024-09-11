class_name AI

class Result:
	var evaluation: float
	var move: Move
	
	func _init(_evaluation: float, _move: Move) -> void:
		evaluation = _evaluation
		move = _move

func get_best_result(s: BoardState, depth: int, alpha: float, beta: float, team: Team.s) -> Result:
	if depth == 0 or s.is_end_state():
		return Result.new(evaluate(s), null)
	if team == Team.s.ALLY_PLAYER:
		var best_result: = Result.new(-INF, null)
		for move: Move in s.get_legal_moves():
			var new_board_state: = s.simulate_move(move)
			var result: = get_best_result(new_board_state, depth - 1, alpha, beta, Team.s.ENEMY_AI_0)
			if result.evaluation >= best_result.evaluation:
				best_result = Result.new(result.evaluation, move)
				alpha = result.evaluation
			if beta <= alpha:
				break  # beta cut-off
		return best_result
	else:
		var worst_result: = Result.new(INF, null)
		for move: Move in s.get_legal_moves():
			var new_board_state: = s.simulate_move(move)
			var result: = get_best_result(new_board_state, depth - 1, alpha, beta, Team.s.ALLY_PLAYER)
			if result.evaluation <= worst_result.evaluation:
				worst_result = Result.new(result.evaluation, move)
				beta = result.evaluation
			if beta <= alpha:
				break  # alpha cut-off
		return worst_result


func evaluate(board_state: BoardState) -> float:
	# Player pieces: positive
	# Enemy pieces: negative
	var pieces: = board_state.pieces.values()
	
	var eval: = 0.0
	for piece: Piece in pieces:
		assert(piece.team() == Team.s.ALLY_PLAYER or piece.team() == Team.s.ENEMY_AI_0)
		
		if piece.team() == Team.s.ALLY_PLAYER:
			eval += piece.get_worth()
		else:
			eval -= piece.get_worth()
	
	return eval
