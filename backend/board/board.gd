class_name Board

var tile_map: BoardTileMap
var piece_map: BoardPieceMap
var team_to_move: Team

# The following fields are not included in the hash
var turn_number: int = 1
## Dictionary from int to int. Maps position hashes to the repetition count
var position_counts: Dictionary = {}
var is_threefold_repetition: bool = false

func _init() -> void:
	tile_map = BoardTileMap.new()
	piece_map = BoardPieceMap.new()
	team_to_move = Team.PLAYER
	position_counts[self.hash()] = 1

func get_available_moves() -> Array[Move]:
	var all_moves: Array[Move] = []
	for piece: Piece in piece_map.get_all_pieces():
		if piece.team != team_to_move: continue
		all_moves.append_array(get_available_moves_from(piece.pos))
	return all_moves

func has_available_moves_from(from: Vector2i) -> bool:
	assert(piece_map.has_piece(from), "Must be a piece there")
	var piece: = piece_map.get_piece(from)
	var moves: = piece.get_available_moves(self)
	for move: Move in moves:
		var filtered_moves: = filter_out_illegal_moves_and_tag_check_moves([move])
		if !filtered_moves.is_empty():
			return true
	return false

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
	next_board.turn_number = turn_number + 1
	
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
	
	# If the move is a capture, promotion, or pawn move, then the board
	# is changed "permanently" so we don't have to store all the previous
	# board positions.
	if !move.is_capture() and !move.is_promotion() and piece_to_move.type != Piece.Type.PAWN:
		next_board.position_counts = position_counts.duplicate()
	var pos_hash = next_board.hash()
	var new_count = next_board.position_counts.get(pos_hash, 0) + 1
	next_board.position_counts[pos_hash] = new_count
	# Set threefold repetition flag if count reaches 3
	if new_count >= 3:
		next_board.is_threefold_repetition = true
	
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
	# Check for threefold repetition first
	if is_threefold_repetition:
		return true
	
	var pieces: = piece_map.get_all_pieces()
	
	# Check for insufficient material
	if _is_insufficient_material(pieces):
		return true
	
	# Check for any valid moves, return early if we find one
	# This is equivalent to checking if get_available_moves().is_empty()
	for piece: Piece in pieces:
		if piece.team != team_to_move:
			continue
		if has_available_moves_from(piece.pos):
			return false
			
	return true

func _is_insufficient_material(pieces: Array[Piece]) -> bool:
	# Filter out kings first since we know there are exactly two
	var non_king_pieces := pieces.filter(func(p): return p.type != Piece.Type.KING)
	
	# King vs King
	if non_king_pieces.is_empty():
		return true
	
	# If there are more than 2 non-king pieces, there must be sufficient material
	if non_king_pieces.size() > 2:
		return false
	
	# King + Bishop vs King or King + Knight vs King
	if non_king_pieces.size() == 1:
		var piece_type = non_king_pieces[0].type
		return piece_type == Piece.Type.BISHOP or piece_type == Piece.Type.KNIGHT
	
	# Split remaining pieces by team
	var white_pieces: = non_king_pieces.filter(func(p): return p.team == Team.PLAYER)
	var black_pieces: = non_king_pieces.filter(func(p): return p.team == Team.ENEMY_AI)
	
	# King + Bishop vs King + Bishop (same colored squares)
	if non_king_pieces.size() == 2:
		if white_pieces.size() == 1 and black_pieces.size() == 1:
			var white_piece = white_pieces[0]
			var black_piece = black_pieces[0]
			if white_piece.type == Piece.Type.BISHOP and black_piece.type == Piece.Type.BISHOP:
				# Check if bishops are on same colored squares
				# In chess, squares are same color if (x + y) % 2 is the same
				var white_square_color = (white_piece.pos.x + white_piece.pos.y) % 2
				var black_square_color = (black_piece.pos.x + black_piece.pos.y) % 2
				return white_square_color == black_square_color
	
	return false

func get_game_result() -> Match.Result:
	assert(is_match_over(), "Match is not over")
	
	# Check for threefold repetition first
	if is_threefold_repetition:
		return Match.Result.DRAW_THREEFOLD_REPETITION
	
	# Check for insufficient material
	if _is_insufficient_material(piece_map.get_all_pieces()):
		return Match.Result.DRAW_INSUFFICIENT_MATERIAL
	
	# Then check for other conditions
	if is_team_in_check(team_to_move):
		if team_to_move == Team.PLAYER:
			return Match.Result.LOSE
		else:
			return Match.Result.WIN
	else:
		return Match.Result.DRAW_STALEMATE

func duplicate() -> Board:
	var new_board: = Board.new()
	# In the future, tile_map can change. For now, it's safe to pass the same
	# instance
	new_board.tile_map = tile_map
	new_board.piece_map = piece_map.duplicate()
	new_board.team_to_move = team_to_move
	new_board.turn_number = turn_number
	new_board.position_counts = position_counts.duplicate()
	new_board.is_threefold_repetition = is_threefold_repetition
	return new_board

func hash() -> int:
	var ctx: = HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	
	# Add team to move
	ctx.update(PackedByteArray([team_to_move.hash()]))
	
	var pieces: = piece_map.get_all_pieces()
	for piece: Piece in pieces:
		var piece_data := PackedByteArray([
			piece.pos.x,
			piece.pos.y,
			piece.type,
			piece.team.hash(),
			piece.info,
		])
		ctx.update(piece_data)
	
	# Get the hash as bytes
	var hash_bytes: = ctx.finish()
	
	# Convert first 4 bytes to integer
	return hash_bytes.decode_s32(0)
