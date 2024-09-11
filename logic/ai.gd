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
		var max_eval: = -INF
		for move: Move in s.get_legal_moves():
			var eval: = get_best_result(s., depth - 1, alpha, beta, Team.s.ENEMY_AI_0)
			max_eval = max(max_eval, eval)
			alpha = max(alpha, eval)
			if beta <= alpha:
				break  # beta cut-off
		return max_eval
	else:
		var min_eval: = +infinity
		for move: Move in s.get_legal_moves():
			var eval: = get_best_result(child, depth - 1, alpha, beta, Team.s.ALLY_PLAYER)
			min_eval = min(min_eval, eval)
			beta = min(beta, eval)
			if beta <= alpha:
				break  # alpha cut-off
		return min_eval


func evaluate(board_state: BoardState) -> float:
	var pieces: = board_state.pieces.values() as Array[Piece]
	return pieces.size()
