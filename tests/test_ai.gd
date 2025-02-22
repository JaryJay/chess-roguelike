class_name TestAI extends Node

func _ready() -> void:
	Config.load_config()
	PieceRules.load_pieces()

	test_mate_in_one()
	test_obvious_queen_capture()
	test_pawn_promotion_mate()
	test_knight_fork()
	
	get_tree().quit()

func test_mate_in_one() -> void:
	var b := Board.new()
	b.team_to_move = Team.PLAYER
	b.tile_map.set_tiles([
		# 4x4 grid of squares
		Vector2i(2,2), Vector2i(3,2), Vector2i(4,2), Vector2i(5,2),
		Vector2i(2,3), Vector2i(3,3), Vector2i(4,3), Vector2i(5,3),
		Vector2i(2,4), Vector2i(3,4), Vector2i(4,4), Vector2i(5,4),
	])
	
	# Black king trapped at bottom, White rook delivers mate from top, protected by pawn
	b.piece_map.put_piece(Vector2i(3,2), Piece.new(Piece.Type.KING, Team.ENEMY_AI, Vector2i(3,2)))  # Black king top left
	b.piece_map.put_piece(Vector2i(3,4), Piece.new(Piece.Type.KING, Team.PLAYER, Vector2i(3,4)))	# White king bottom left
	b.piece_map.put_piece(Vector2i(5,4), Piece.new(Piece.Type.ROOK, Team.PLAYER, Vector2i(5,4)))	# White rook bottom right
	
	var ai := ABSearchAIV2.new()
	var move := ai.get_move(b)
	
	assert(move.from == Vector2i(5,4))  # Rook from bottom right
	assert(move.to == Vector2i(5,2))	# Rook to top right, delivering mate
	print("Mate in one passed")

func test_obvious_queen_capture() -> void:
	var b := Board.new()
	b.team_to_move = Team.PLAYER
	b.tile_map.set_tiles([
		Vector2i(2,2), Vector2i(3,2), Vector2i(4,2), Vector2i(5,2),
		Vector2i(2,3), Vector2i(3,3), Vector2i(4,3), Vector2i(5,3),
		Vector2i(2,4), Vector2i(3,4), Vector2i(4,4), Vector2i(5,4),
		Vector2i(2,5), Vector2i(3,5), Vector2i(4,5), Vector2i(5,5),
	])
	
	# Undefended queen can be captured by rook
	b.piece_map.put_piece(Vector2i(2,2), Piece.new(Piece.Type.KING, Team.PLAYER, Vector2i(2,2)))
	b.piece_map.put_piece(Vector2i(4,4), Piece.new(Piece.Type.KING, Team.ENEMY_AI, Vector2i(4,4)))
	b.piece_map.put_piece(Vector2i(2,3), Piece.new(Piece.Type.QUEEN, Team.ENEMY_AI, Vector2i(2,3)))
	b.piece_map.put_piece(Vector2i(3,3), Piece.new(Piece.Type.ROOK, Team.PLAYER, Vector2i(3,3)))
	
	var ai := ABSearchAIV2.new()
	var move := ai.get_move(b)
	
	assert(move.from == Vector2i(3,3) or move.from == Vector2i(2,2))
	assert(move.to == Vector2i(2,3))
	assert(move.is_capture())
	print("Obvious queen capture passed")

func test_pawn_promotion_mate() -> void:
	var b := Board.new()
	b.team_to_move = Team.PLAYER
	b.tile_map.set_tiles([
		Vector2i(2,4), Vector2i(3,4), Vector2i(4,4), Vector2i(5,4),  # Bottom row
		Vector2i(2,5), Vector2i(3,5), Vector2i(4,5), Vector2i(5,5),  # Row 2
		Vector2i(2,6), Vector2i(3,6), Vector2i(4,6), Vector2i(5,6),  # Row 3
		Vector2i(2,7), Vector2i(3,7), Vector2i(4,7), Vector2i(5,7),  # Top row (promotion rank)
	])
	
	b.piece_map.put_piece(Vector2i(5,5), Piece.new(Piece.Type.PAWN, Team.PLAYER, Vector2i(5,5)))
	b.piece_map.put_piece(Vector2i(4,5), Piece.new(Piece.Type.KING, Team.PLAYER, Vector2i(4,5)))
	b.piece_map.put_piece(Vector2i(2,6), Piece.new(Piece.Type.KING, Team.ENEMY_AI, Vector2i(2,6)))

	var ai := ABSearchAIV2.new()
	var move := ai.get_move(b)
	
	assert(move.from == Vector2i(5,5))  # Pawn from bottom left
	assert(move.to == Vector2i(5,4))	# Pawn to top left, promoting
	assert(move.promo_info == Piece.Type.QUEEN)  # Promotes to queen for mate
	print("Pawn promotion mate passed")

func test_knight_fork() -> void:
	var b := Board.new()
	b.team_to_move = Team.PLAYER
	b.tile_map.set_tiles([
		Vector2i(2,2), Vector2i(3,2), Vector2i(4,2), Vector2i(5,2),
		Vector2i(2,3), Vector2i(3,3), Vector2i(4,3), Vector2i(5,3),
		Vector2i(2,4), Vector2i(3,4), Vector2i(4,4), Vector2i(5,4),
		Vector2i(2,5), Vector2i(3,5), Vector2i(4,5), Vector2i(5,5),
	])
	
	# Knight can fork enemy king and queen
	b.piece_map.put_piece(Vector2i(2,2), Piece.new(Piece.Type.KING, Team.PLAYER, Vector2i(2,2)))
	b.piece_map.put_piece(Vector2i(2,3), Piece.new(Piece.Type.ROOK, Team.PLAYER, Vector2i(2,3)))
	b.piece_map.put_piece(Vector2i(2,4), Piece.new(Piece.Type.KNIGHT, Team.PLAYER, Vector2i(2,4)))
	b.piece_map.put_piece(Vector2i(5,5), Piece.new(Piece.Type.KING, Team.ENEMY_AI, Vector2i(5,5)))
	b.piece_map.put_piece(Vector2i(3,5), Piece.new(Piece.Type.QUEEN, Team.ENEMY_AI, Vector2i(3,5)))
	
	var ai := ABSearchAIV2.new()
	var move := ai.get_move(b)
	
	assert(move.from == Vector2i(2,4))  # Knight from current position
	assert(move.to == Vector2i(4,3))    # Knight to forking square
	print("Knight fork passed")
