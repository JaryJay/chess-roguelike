class_name ABSearchAIV2 extends AbstractAI

func get_move(board: Board) -> Move:
	var depth: = 3
	if board.piece_map.get_all_pieces().size() <= 5:
		depth = 4
	elif board.piece_map.get_team_pieces(Team.PLAYER).size() <= 2 or \
		board.piece_map.get_team_pieces(Team.ENEMY_AI).size() <= 3:
		depth = 4
	var result: = _get_best_result(board, depth, -INF, INF)  # 3 is a good depth for reasonable performance
	print("V2 Best result is %s" % str(result))
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
			eval += calculate_piece_worth(piece, board)
		else:
			eval -= calculate_piece_worth(piece, board)
	
	# Small logarithmic penalty for taking longer
	eval += log(float(board.turn_number + 1)) * 0.02
	
	return eval

func sort_moves_by_strength_desc(moves: Array[Move], board: Board) -> void:
	if moves.size() == 1:
		return
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
	
	var enemy_pieces: = board.piece_map.get_team_pieces(opposing_team)
	var only_king_left: = enemy_pieces.size() == 1
	
	# If it's a capture, add the value of the captured piece
	if move.is_capture():
		var captured_piece: = board.piece_map.get_piece(move.to)
		strength += 2.0 + 2.0 * calculate_piece_worth(captured_piece, board)
	if move.is_promotion() and move.promo_info == Piece.Type.QUEEN:
		# Should almost always be a good idea
		strength += 20.0

	# Simulate the move
	var next_board: = board.perform_move(move, true)
	
	# Check if it's checkmate
	if next_board.is_match_over() and next_board.is_team_in_check(opposing_team):
		return INF
	
	# Add bonus for putting opponent in check
	if next_board.is_team_in_check(opposing_team):
		strength += 3.0
	
	# Add small bonus for moving a piece a long distance
	strength += 0.02 * move.to.distance_to(move.from)

	# Add bonus for moving pawns
	if piece.type == Piece.Type.PAWN:
		if move.to - move.from == Vector2i(0, 2):
			strength += 3.0
		else:
			strength += 2.0
	
	if piece.type == Piece.Type.KING and only_king_left:
		var enemy_king: Piece = enemy_pieces[0]
		var distance: = piece.pos.distance_to(enemy_king.pos)
		strength += maxf(4.0 - distance, 0.0) * 0.05
	
	# Finally, add a small randomness to the move strength
	strength += randf_range(-0.05, 0.05)
	
	return strength

func calculate_piece_worth(piece: Piece, board: Board) -> float:
	var base_worth: = piece.get_worth()
	var worth: = base_worth

	var opposing_team: Team = Team.ENEMY_AI if piece.team == Team.PLAYER else Team.PLAYER
	var enemy_pieces: = board.piece_map.get_team_pieces(opposing_team)
	var only_king_left: = enemy_pieces.size() == 1

	if piece.type == Piece.Type.PAWN:
		# Check if there's an enemy piece blocking the pawn's path
		var is_blocked: = false
		var distance_from_end: = 0
		var forward_dir: Vector2i = piece._get_pawn_facing_direction()
		var forward_pos: Vector2i = piece.pos + forward_dir
		while board.tile_map.has_tile(forward_pos):
			if board.piece_map.has_piece(forward_pos) and board.piece_map.get_piece(forward_pos).team.is_hostile_to(piece.team):
				is_blocked = true
				break
			forward_pos += forward_dir
			distance_from_end += 1
		# Add positional bonus (less if blocked)
		var position_multiplier := 0.1 if is_blocked else 0.3
		var end_game_multiplier: = 2.0 if only_king_left else 1.0
		var position_bonus: = distance_from_end * position_multiplier * end_game_multiplier
		worth += position_bonus
	
	# Add king proximity bonus in king-only endgame
	if only_king_left:
		assert(enemy_pieces[0].type == Piece.Type.KING)
		var enemy_king: Piece = enemy_pieces[0]
		var distance: = piece.pos.distance_to(enemy_king.pos)
		# Add bonus for being closer to enemy king (max 2.0 when adjacent)
		var proximity_bonus: float
		if piece.type == Piece.Type.KING:
			proximity_bonus = maxf(8 - distance, 0) * 0.08
		else:
			proximity_bonus = maxf(8 - distance, 0) * 0.01
		worth += proximity_bonus
	
	return worth

class Result extends Resource:
	var evaluation: float
	var move: Move
	
	func _init(_evaluation: float, _move: Move) -> void:
		evaluation = _evaluation
		move = _move
	
	func _to_string() -> String:
		return "Move %s, Eval %.3f" % [move, evaluation]
