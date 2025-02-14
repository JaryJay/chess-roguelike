class_name Board

var tile_map: BoardTileMap
var piece_map: BoardPieceMap
var team_to_move: Team

func _init() -> void:
	tile_map = BoardTileMap.new()
	piece_map = BoardPieceMap.new()
	team_to_move = Team.PLAYER

func get_available_moves() -> Array[Move]:
	var all_moves: Array[Move] = []
	for piece: Piece in piece_map.get_all_pieces():
		if piece.team != team_to_move: continue
		all_moves.append_array(get_available_moves_from(piece.pos))
	return all_moves

func get_available_moves_from(from: Vector2i) -> Array[Move]:
	assert(piece_map.has_piece(from), "Must be a piece there")
	var piece: = piece_map.get_piece(from)
	var moves: = piece.get_available_moves(self)
	moves = filter_out_illegal_moves_and_tag_check_moves(moves)
	return moves

func filter_out_illegal_moves_and_tag_check_moves(moves: Array[Move]) -> Array[Move]:
	# Filter out all illegal moves
	for i in range(moves.size() - 1, -1, -1):
		var move: = moves[i]
		#if move.is_castle():
			#var castle_dir: = (move.to - move.from) / (move.to - move.from).abs().x
		
		var next_board: = perform_move(move, true)
		if next_board.is_team_in_check(team_to_move):
			# This is an illegal move
			moves.remove_at(i)
			continue
		
		# If the move puts the other team in check, tag it
		if next_board.is_team_in_check(next_board.team_to_move):
			# This move is a check
			move.info = move.info | Move.CHECK
		
	
	# moves = moves.filter(
	# 	func(move: Move) -> bool:
	# 		var next_board: = perform_move(move)
	# 		return !next_board.is_team_in_check(team_to_move)
	# )
	
	# For castling moves specifically, we do some more checks:
	# TODO
	# moves = moves.filter(
	return moves


func perform_move(move: Move, allow_illegal: bool = false) -> Board:
	var current_team_to_move: = team_to_move
	
	assert(piece_map.has_piece(move.from), "No piece at %s" % move.from)
	var piece_to_move: = piece_map.get_piece(move.from)
	assert(piece_to_move.team == current_team_to_move, "You can't move someone else's piece")
	if move.is_capture():
		assert(piece_map.has_piece(move.to), "There must be a piece being captured")
	else:
		assert(!piece_map.has_piece(move.to), "There must not be a piece at the destination if it's not a capture")
	
	var next_board: = duplicate()
	next_board.team_to_move = Team.PLAYER if current_team_to_move == Team.ENEMY_AI else Team.ENEMY_AI
	
	next_board.piece_map.remove_piece(piece_to_move.pos)
	if move.is_capture():
		var captured_piece: = piece_map.get_piece(move.to)
		assert(captured_piece.team.is_hostile_to(current_team_to_move), "Cannot capture friendly pieces")
		next_board.piece_map.remove_piece(move.to)
	if move.is_promotion():
		var promo_type: Piece.Type = move.get_promotion_type()
		var new_piece: Piece = Piece.new(promo_type, current_team_to_move, move.to, 0)
		next_board.piece_map.put_piece(move.to, new_piece)
	else:
		var new_piece: = piece_to_move.duplicate()
		new_piece.pos = move.to
		if piece_to_move.type == Piece.Type.PAWN:
			new_piece.info = new_piece.info | Piece.MOVED
		next_board.piece_map.put_piece(move.to, new_piece)
	
	if !allow_illegal:
		assert(!next_board.is_team_in_check(current_team_to_move), "A move cannot put your own team in check")
	
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
	var available_moves: = get_available_moves()
	if available_moves.size() == 0:
		if is_team_in_check(team_to_move):
			print("checkmate")
		else:
			print("stalemate")
		return true
	# Check if the only pieces remaining are the kings
	if piece_map.get_all_pieces().filter(func(piece: Piece) -> bool: return piece.type != Piece.Type.KING).size() == 0:
		print("stalemate")
		return true
	# if is_team_in_check(team_to_move): # in this case, it's a checkmate
	# otherwise it's a stalemate
	return false

func duplicate() -> Board:
	var new_board: = Board.new()
	# In the future, tile_map can change. For now, it's safe to pass the same
	# instance
	new_board.tile_map = tile_map
	new_board.piece_map = piece_map.duplicate()
	new_board.team_to_move = team_to_move
	return new_board
