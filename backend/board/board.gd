class_name Board

var tile_map: BoardTileMap = BoardTileMap.new()
var piece_map: BoardPieceMap = BoardPieceMap.new()
var team_to_move: Team = Team.PLAYER

func get_available_moves() -> Array[Move]:
	var all_moves: Array[Move] = []
	for piece: Piece in piece_map.get_all_pieces():
		if piece.team != team_to_move: continue
		all_moves.append_array(piece.get_available_moves(self))
	return filter_out_illegal_moves(all_moves)

func get_available_moves_from(from: Vector2i) -> Array[Move]:
	assert(piece_map.has_piece(from), "Must be a piece there")
	var piece: = piece_map.get_piece(from)
	var moves: = piece.get_available_moves(self)
	return filter_out_illegal_moves(moves)

func filter_out_illegal_moves(moves: Array[Move]) -> Array[Move]:
	# Filter out all illegal moves
	for i in range(moves.size() - 1, -1, -1):
		var move: = moves[i]
		#if move.is_castle():
			#var castle_dir: = (move.to - move.from) / (move.to - move.from).abs().x
		
		var next_board: = perform_move(move)
		if next_board.is_team_in_check(team_to_move):
			# This is an illegal move
			moves.remove_at(i)
			continue
		if next_board.is_team_in_check(next_board.team_to_move):
			# This move is a check
			move.info = move.info | Move.CHECK
		
		
	moves = moves.filter(
		func(move: Move) -> bool:
			var next_board: = perform_move(move)
			return !next_board.is_team_in_check(next_board.team_to_move)
	)
	
	# For castling moves specifically, we do some more checks:
	# TODO
	# moves = moves.filter(
	return moves

func perform_move(move: Move) -> Board:
	var current_team_to_move: = team_to_move
	
	assert(piece_map.has_piece(move.from), "No piece at %s" % move.from)
	var piece_to_move: = piece_map.get_piece(move.from)
	assert(piece_to_move.team == current_team_to_move, "You can't move someone else's piece")
	assert(move.is_capture() == piece_map.has_piece(move.to), "It's a capture iff there is a piece")
	
	var next_board: = duplicate()
	next_board.team_to_move = Team.PLAYER if current_team_to_move == Team.ENEMY_AI else Team.ENEMY_AI
	
	next_board.piece_map.remove_piece(piece_to_move.pos)
	if move.is_capture():
		var captured_piece: = piece_map.get_piece(move.to)
		assert(captured_piece.team.is_hostile_to(current_team_to_move), "Cannot capture friendly pieces")
		next_board.piece_map.remove_piece(move.to)
	if move.is_promotion():
		var promo_type: Piece.Type = move.get_promotion_type()
		var new_piece: Piece = Piece.new(promo_type, current_team_to_move, move.to)
		next_board.piece_map.put_piece(move.to, new_piece)
	else:
		var new_piece: = piece_to_move.duplicate()
		new_piece.pos = move.to
		next_board.piece_map.put_piece(move.to, new_piece)
	
	#assert(!next_board.is_team_in_check(current_team_to_move), "A move cannot put your own team in check")
	
	return next_board

## Whether the king on that team is in check
## In a valid board state, is_team_in_check(team_to_move) should always be false
func is_team_in_check(team: Team) -> bool:
	var team_king: = piece_map.get_king(team)
	
	for piece: Piece in piece_map.get_all_pieces():
		if piece.team.is_friendly_to(team_king.team): continue
		
		if piece.is_attacking_square(team_king.pos, self):
			return true
	return false

func is_match_over() -> bool:
	var teams: Array[Team] = [Team.ENEMY_AI, Team.PLAYER]
	return false

func duplicate() -> Board:
	var new_board: = Board.new()
	# In the future, tile_map can change. For now, it's safe to pass the same
	# instance
	new_board.tile_map = tile_map
	new_board.piece_map = piece_map.duplicate()
	new_board.team_to_move = team_to_move
	return new_board
