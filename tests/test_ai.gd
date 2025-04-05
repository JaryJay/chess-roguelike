class_name TestAI extends Node

@export var wait_before_running: = true

func _ready() -> void:
	if wait_before_running:
		var timer: Timer = Timer.new()
		timer.wait_time = 1.0
		timer.timeout.connect(run_tests)
		add_child(timer)
		timer.start()
	else:
		run_tests()

func run_tests() -> void:
	Config.load_config()
	PieceRules.load_pieces()

	test_mate_in_one()
	test_obvious_queen_capture()
	test_pawn_promotion_mate()
	test_pawn_promotion_less_obvious()
	test_knight_fork()
	test_obvious_pawn_capture()
	
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
	b.piece_map.put_piece(Vector2i(3,2), Piece.new(Piece.Type.KING, Team.ENEMY_AI))  # Black king top left
	b.piece_map.put_piece(Vector2i(3,4), Piece.new(Piece.Type.KING, Team.PLAYER))	# White king bottom left
	b.piece_map.put_piece(Vector2i(5,4), Piece.new(Piece.Type.ROOK, Team.PLAYER))	# White rook bottom right
	
	var ai := _create_ai()
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
	b.piece_map.put_piece(Vector2i(2,2), Piece.new(Piece.Type.KING, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(4,4), Piece.new(Piece.Type.KING, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(2,3), Piece.new(Piece.Type.QUEEN, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(3,3), Piece.new(Piece.Type.ROOK, Team.PLAYER))
	
	var ai := _create_ai()
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
	
	b.piece_map.put_piece(Vector2i(5,5), Piece.new(Piece.Type.PAWN, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(3,6), Piece.new(Piece.Type.KING, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(3,4), Piece.new(Piece.Type.KING, Team.ENEMY_AI))

	var ai := _create_ai()
	var move := ai.get_move(b)
	
	assert(move.from == Vector2i(5,5))  # Pawn from bottom left
	assert(move.to == Vector2i(5,4))	# Pawn to top left, promoting
	assert(move.promo_info == Piece.Type.QUEEN or move.promo_info == Piece.Type.ROOK)
	print("Pawn promotion mate passed")

func test_pawn_promotion_less_obvious() -> void:
	var b := Board.new()
	b.team_to_move = Team.ENEMY_AI
	b.tile_map.set_tiles([
		Vector2i(2,4), Vector2i(3,4), Vector2i(4,4), Vector2i(5,4),  # Bottom row
		Vector2i(2,5), Vector2i(3,5), Vector2i(4,5), Vector2i(5,5),  # Row 2
		Vector2i(2,6), Vector2i(3,6), Vector2i(4,6), Vector2i(5,6),  # Row 3
		Vector2i(2,7), Vector2i(3,7), Vector2i(4,7), Vector2i(5,7),  # Top row (promotion rank)
	])

	b.piece_map.put_piece(Vector2i(3,6), Piece.new(Piece.Type.PAWN, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(2,6), Piece.new(Piece.Type.KING, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(4,6), Piece.new(Piece.Type.KING, Team.PLAYER))

	var ai := _create_ai()
	var move := ai.get_move(b)

	assert(move.from == Vector2i(3,6), "Moved from %s instead of (3,6)" % move.from)
	assert(move.to == Vector2i(3,7), "Moved to %s instead of (3,7)" % move.to)
	assert(move.is_promotion(), "Did not promote")
	assert(move.promo_info == Piece.Type.QUEEN, "Promoted to %s instead of QUEEN" % Piece.type_to_string(move.promo_info))
	print("Pawn promotion less obvious passed")

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
	b.piece_map.put_piece(Vector2i(2,2), Piece.new(Piece.Type.KING, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(2,3), Piece.new(Piece.Type.ROOK, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(2,4), Piece.new(Piece.Type.KNIGHT, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(5,5), Piece.new(Piece.Type.KING, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(3,5), Piece.new(Piece.Type.QUEEN, Team.ENEMY_AI))
	
	var ai := _create_ai()
	var move := ai.get_move(b)
	
	assert(move.from == Vector2i(2,4))  # Knight from current position
	assert(move.to == Vector2i(4,3))    # Knight to forking square
	print("Knight fork passed")

func test_obvious_pawn_capture() -> void:
	var b := Board.new()
	b.team_to_move = Team.PLAYER
	b.tile_map.set_tiles([
		Vector2i(2,2), Vector2i(3,2), Vector2i(4,2), Vector2i(5,2),
		Vector2i(2,3), Vector2i(3,3), Vector2i(4,3), Vector2i(5,3),
		Vector2i(2,4), Vector2i(3,4), Vector2i(4,4), Vector2i(5,4),
		Vector2i(2,5), Vector2i(3,5), Vector2i(4,5), Vector2i(5,5),
	])
	
	b.piece_map.put_piece(Vector2i(2,4), Piece.new(Piece.Type.KING, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(4,2), Piece.new(Piece.Type.KING, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(3,4), Piece.new(Piece.Type.PAWN, Team.ENEMY_AI))

	var ai := _create_ai()
	var move := ai.get_move(b)

	assert(move.from == Vector2i(2,4))
	assert(move.is_capture())
	assert(move.to == Vector2i(3,4))
	print("Obvious pawn capture passed")

func _create_ai() -> AbstractAI:
	return ABSearchAIV4.new()
