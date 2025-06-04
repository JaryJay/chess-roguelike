class_name ABSearchAIV5 extends AbstractAI

var deterministic: bool

func _init(_deterministic: bool = false) -> void:
	deterministic = _deterministic

func get_move(board: Board) -> Move:
	var depth := 3
	if board.piece_map.get_all_pieces().size() <= 4:
		depth = 4
	
	var result := _get_best_result(board, depth, -INF, INF)
	return result.move

func _get_best_result(board: Board, depth: int, alpha: float, beta: float) -> Result:
	if depth == 0 or board.is_match_over():
		return Result.new(evaluate(board), null)
	
	var moves := board.get_available_moves()
	
	assert(!moves.is_empty(), "No moves found for board %s, but is_match_over() is %s" % [board.to_string(), board.is_match_over()])
	
	sort_moves_by_strength_desc(moves, board)
	
	moves = moves.slice(0, Config.ai.max_moves_to_consider)
	
	if board.team_to_move == Team.PLAYER:
		var best_result: Result = null
		for move in moves:
			var next_board := board.perform_move(move)
			
			var result := _get_best_result(next_board, depth - 1, alpha, beta)
			
			if !best_result:
				best_result = Result.new(result.evaluation, move)
			elif result.evaluation > best_result.evaluation:
				best_result = Result.new(result.evaluation, move)
			if best_result.evaluation >= beta:
				break
			alpha = best_result.evaluation
		return best_result
	else:
		var worst_result: Result = null
		for move in moves:
			var next_board := board.perform_move(move)
			
			var result := _get_best_result(next_board, depth - 1, alpha, beta)
			
			if !worst_result:
				worst_result = Result.new(result.evaluation, move)
			elif result.evaluation < worst_result.evaluation:
				worst_result = Result.new(result.evaluation, move)
			if worst_result.evaluation <= alpha:
				break
			beta = worst_result.evaluation
		return worst_result

func evaluate(board: Board) -> float:
	if board.is_match_over():
		var match_result: Match.Result = board.get_match_result()
		assert(match_result != Match.Result.IN_PROGRESS)
		if match_result == Match.Result.DRAW_INSUFFICIENT_MATERIAL:
			return 0
		if match_result == Match.Result.DRAW_THREEFOLD_REPETITION:
			return 0
		if match_result == Match.Result.DRAW_STALEMATE:
			return 0
		if match_result == Match.Result.WIN:
			return INF
		if match_result == Match.Result.LOSE:
			return -INF
		assert(false, "Unexpected match result %s" % match_result)
	
	var eval := 0.0
	for piece in board.piece_map.get_all_pieces():
		if piece.team == Team.PLAYER:
			eval += calculate_piece_worth(piece, board)
		else:
			eval -= calculate_piece_worth(piece, board)
	
	eval += calculate_king_mobility_penalty(board, Team.ENEMY_AI)
	eval -= calculate_king_mobility_penalty(board, Team.PLAYER)
	
	# Penalize long sequences of moves that achieve the same outcome as a short sequence
	eval *= 100.0 / float(board.turn_number + 100)

	return eval

func sort_moves_by_strength_desc(moves: Array[Move], board: Board) -> void:
	if moves.size() == 1:
		return
	var move_strength_cache := {}
	moves.sort_custom(func(m1: Move, m2: Move) -> bool:
		if not move_strength_cache.has(m1):
			move_strength_cache[m1] = estimate_move_strength(m1, board)
		if not move_strength_cache.has(m2):
			move_strength_cache[m2] = estimate_move_strength(m2, board)
		return move_strength_cache[m1] > move_strength_cache[m2]
	)

func estimate_move_strength(move: Move, board: Board) -> float:
	var strength := 0.0
	
	var piece := board.piece_map.get_piece(move.from)
	var opposing_team: Team = Team.ENEMY_AI if piece.team == Team.PLAYER else Team.PLAYER
	var enemy_pieces := board.piece_map.get_team_pieces(opposing_team)
	var only_king_left := enemy_pieces.size() == 1
	
	# Capture estimation
	if move.is_capture():
		var captured_piece := board.piece_map.get_piece(move.to)
		strength += 2.0 + 2.0 * calculate_piece_worth(captured_piece, board)
		
		# Check if this is a recapture
		if board.previous_boards.size() >= 2:
			var prev_board := board.previous_boards[1]
			if prev_board.piece_map.has_piece(move.to):
				var prev_piece := prev_board.piece_map.get_piece(move.to)
				if prev_piece.team == piece.team:
					# This is a recapture - the piece we're capturing just captured one of our pieces
					strength += 5.5
	
	# Promotion estimation
	if move.is_promotion() and move.promo_info == Piece.Type.QUEEN:
		strength += 20.0
	
	if move.is_check():
		strength += 4.0

	# Pawn movement estimation
	if enemy_pieces.size() < 4 and piece.type == Piece.Type.PAWN:
		if absi(move.to.y - move.from.y) == 2:
			strength += 3.0
		else:
			strength += 2.0

	# King endgame estimation
	if piece.type == Piece.Type.KING and only_king_left:
		var enemy_king: Piece = enemy_pieces[0]
		var old_distance := piece.pos.distance_to(enemy_king.pos)
		var new_distance := move.to.distance_to(enemy_king.pos)
		strength += maxf(old_distance - new_distance, 0.0) * 1
	
	if !deterministic:
		strength += randf_range(-0.05, 0.05)
	
	return strength

func calculate_piece_worth(piece: Piece, board: Board) -> float:
	var base_worth := piece.get_worth()
	var worth := base_worth

	var opposing_team: Team = Team.ENEMY_AI if piece.team == Team.PLAYER else Team.PLAYER
	var enemy_pieces := board.piece_map.get_team_pieces(opposing_team)
	var only_king_left := enemy_pieces.size() == 1

	if piece.type == Piece.Type.PAWN:
		var is_blocked := false
		var distance_from_end := 0
		var forward_dir: Vector2i = piece._get_pawn_facing_direction()
		var forward_pos: Vector2i = piece.pos + forward_dir
		while board.tile_map.has_tile(forward_pos):
			if board.piece_map.has_piece(forward_pos):
				is_blocked = true
				break
			forward_pos += forward_dir
			distance_from_end += 1
		var position_multiplier := 0.1 if is_blocked else 0.3
		var end_game_multiplier := 2.0 if only_king_left else 1.0
		var position_bonus := maxf(0, (8 - distance_from_end) * position_multiplier * end_game_multiplier)
		worth += position_bonus
	
	if only_king_left:
		assert(enemy_pieces[0].type == Piece.Type.KING)
		var enemy_king: Piece = enemy_pieces[0]
		var distance := piece.pos.distance_to(enemy_king.pos)
		var proximity_bonus: float
		if piece.type == Piece.Type.KING:
			proximity_bonus = maxf(8 - distance, 0) * 0.08
		else:
			proximity_bonus = maxf(8 - distance, 0) * 0.01
		worth += proximity_bonus
	
	var piece_existence_bonus := 0.05
	worth += piece_existence_bonus
	
	return worth

func calculate_king_mobility_penalty(board: Board, team: Team) -> float:
	var team_pieces := board.piece_map.get_team_pieces(team)
	if team_pieces.size() == 1 and team_pieces[0].type == Piece.Type.KING:
		var king := team_pieces[0]
		var moveable_squares := 0
		
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				
				var check_pos := king.pos + Vector2i(dx, dy)
				if board.tile_map.has_tile(check_pos) and \
				not board.piece_map.has_piece(check_pos):
					moveable_squares += 1
		
		return (8.0 - moveable_squares) * 0.08
	return 0.0

class Result extends RefCounted:
	var evaluation: float
	var move: Move
	
	func _init(_evaluation: float, _move: Move) -> void:
		evaluation = _evaluation
		move = _move
	
	func _to_string() -> String:
		return "%s, Eval %.3f" % [str(move), evaluation]

func _print_timing_info(timing: Dictionary) -> void:
	print("\nPerformance Breakdown:")
	print("- Get moves: %d ms" % timing["get_moves"])
	print("- Sort moves: %d ms" % timing["sort_moves"])
	print("- Move strength estimation:")
	print("  * Calls: %d" % timing["estimate_move_strength_calls"])
	print("  * Total time: %d ms" % timing["estimate_move_strength_time"])
	print("  * Average time: %.2f ms" % (float(timing["estimate_move_strength_time"]) / timing["estimate_move_strength_calls"] if timing["estimate_move_strength_calls"] > 0 else 0))
	print("  * Breakdown:")
	print("    - Capture eval: %d ms" % timing["estimate_capture_time"])
	print("    - Promotion eval: %d ms" % timing["estimate_promotion_time"])
	print("    - Check eval: %d ms" % timing["estimate_check_time"])
	print("    - Pawn eval: %d ms" % timing["estimate_pawn_time"])
	print("    - King eval: %d ms" % timing["estimate_king_time"])
	print("    - perform_move calls: %d" % timing["estimate_perform_move_calls"])
	print("    - perform_move time: %d ms" % timing["estimate_perform_move_time"])
	print("- Board.perform_move:")
	print("  * Calls: %d" % timing["perform_move_calls"])
	print("  * Total time: %d ms" % timing["perform_move_time"])
	print("  * Average time: %.2f ms" % (float(timing["perform_move_time"]) / timing["perform_move_calls"] if timing["perform_move_calls"] > 0 else 0))
	print("- Position evaluation:")
	print("  * Calls: %d" % timing["evaluate_calls"])
	print("  * Total time: %d ms" % timing["evaluate_time"])
	print("  * Average time: %.2f ms" % (float(timing["evaluate_time"]) / timing["evaluate_calls"] if timing["evaluate_calls"] > 0 else 0))
	print("- Piece worth calculation:")
	print("  * Calls: %d" % timing["calculate_piece_worth_calls"])
	print("  * Total time: %d ms" % timing["calculate_piece_worth_time"])
	print("  * Average time: %.2f ms" % (float(timing["calculate_piece_worth_time"]) / timing["calculate_piece_worth_calls"] if timing["calculate_piece_worth_calls"] > 0 else 0))
