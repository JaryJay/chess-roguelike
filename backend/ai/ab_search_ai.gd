class_name ABSearchAI extends AbstractAI

class Result extends Resource:
	var evaluation: float
	var move: Move
	
	func _init(_evaluation: float, _move: Move) -> void:
		evaluation = _evaluation
		move = _move
	
	func _to_string() -> String:
		return "Move %s, Eval %.1f" % [move, evaluation]

func get_move(board: Board) -> Move:
	var result: = _get_best_result(board, 2, -INF, INF)  # 3 is a good depth for reasonable performance
	print("Best result is %s" % str(result))
	return result.move

func _get_best_result(board: Board, depth: int, alpha: float, beta: float) -> Result:
	if depth == 0 or board.is_match_over():
		return Result.new(evaluate(board), null)
	
	var moves: = board.get_available_moves()
	if moves.is_empty():
		return Result.new(-INF if board.team_to_move == Team.PLAYER else INF, null)
	
	sort_moves_by_strength_desc(moves, board)
	moves = moves.slice(0, Config.ai.max_moves_to_consider)  # Only consider the top moves
	
	if board.team_to_move == Team.PLAYER:
		var best_result: = Result.new(-INF, null)
		for move in moves:
			var next_board: = board.perform_move(move)
			var result: = _get_best_result(next_board, depth - 1, alpha, beta)
			if result.evaluation >= best_result.evaluation:
				best_result = Result.new(result.evaluation, move)
				alpha = result.evaluation
			if beta <= alpha:
				break  # beta cut-off
		return best_result
	else:
		var worst_result: = Result.new(INF, null)
		for move in moves:
			var next_board: = board.perform_move(move)
			var result: = _get_best_result(next_board, depth - 1, alpha, beta)
			if result.evaluation <= worst_result.evaluation:
				worst_result = Result.new(result.evaluation, move)
				beta = result.evaluation
			if beta <= alpha:
				break  # alpha cut-off
		return worst_result

func evaluate(board: Board) -> float:
	# Check for checkmate/stalemate
	if board.is_match_over():
		if board.is_team_in_check(board.team_to_move):
			return -INF if board.team_to_move == Team.PLAYER else INF
		return 0  # Stalemate
	
	# Sum up piece values
	var eval: = 0.0
	for piece in board.piece_map.get_all_pieces():
		if piece.team == Team.PLAYER:
			eval += piece.get_worth()
		else:
			eval -= piece.get_worth()
	
	return eval

func sort_moves_by_strength_desc(moves: Array[Move], board: Board) -> void:
	var move_strength_cache: Dictionary = {}
	moves.sort_custom(func(m1: Move, m2: Move) -> bool:
		if not move_strength_cache.has(m1):
			move_strength_cache[m1] = estimate_move_strength(m1, board)
		if not move_strength_cache.has(m2):
			move_strength_cache[m2] = estimate_move_strength(m2, board)
		return move_strength_cache[m1] > move_strength_cache[m2]
	)

func estimate_move_strength(move: Move, board: Board) -> float:
	var strength: = 0.0
	
	# Get the piece making the move
	var piece: = board.piece_map.get_piece(move.from)
	var opposing_team: Team = Team.ENEMY_AI if piece.team == Team.PLAYER else Team.PLAYER
	
	# If it's a capture, add the value of the captured piece
	if move.is_capture():
		var captured_piece: = board.piece_map.get_piece(move.to)
		strength += captured_piece.get_worth()
	
	# Simulate the move
	var next_board: = board.perform_move(move, true)
	
	# Check if it's checkmate
	if next_board.is_match_over() and next_board.is_team_in_check(opposing_team):
		return INF
	
	# Add bonus for putting opponent in check
	if next_board.is_team_in_check(opposing_team):
		strength += 1.0
	
	# Add small bonus for moving a piece a long distance
	strength += 0.05 * move.to.distance_to(move.from)

	# Add bonus for moving pawns
	if piece.type == Piece.Type.PAWN:
		strength += 2.0
	
	return strength
