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

# Helper function to create a rectangular grid of tiles
func create_tiles(top_left: Vector2i, bottom_right: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for x in range(top_left.x, bottom_right.x + 1):
		for y in range(top_left.y, bottom_right.y + 1):
			tiles.append(Vector2i(x, y))
	return tiles

func run_tests() -> void:
	Config.load_config()
	PieceRules.load_pieces()

	test_mate_in_one()
	test_obvious_queen_capture()
	test_pawn_promotion_mate()
	test_pawn_promotion_less_obvious()
	test_knight_fork()
	test_obvious_pawn_capture()
	test_obvious_recapture()
	test_react_to_forced_checkmate()
	
	get_tree().quit()

func test_mate_in_one() -> void:
	var b := Board.new()
	b.team_to_move = Team.PLAYER
	b.tile_map.set_tiles(create_tiles(Vector2i(2,2), Vector2i(5,4)))
	
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
	b.tile_map.set_tiles(create_tiles(Vector2i(2,2), Vector2i(5,5)))
	
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
	b.tile_map.set_tiles(create_tiles(Vector2i(2,4), Vector2i(5,7)))
	
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
	b.tile_map.set_tiles(create_tiles(Vector2i(2,4), Vector2i(5,7)))

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
	b.tile_map.set_tiles(create_tiles(Vector2i(2,2), Vector2i(5,5)))
	
	# Knight can fork enemy king and queen
	b.piece_map.put_piece(Vector2i(2,2), Piece.new(Piece.Type.KING, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(2,3), Piece.new(Piece.Type.ROOK, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(2,4), Piece.new(Piece.Type.KNIGHT, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(5,5), Piece.new(Piece.Type.KING, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(3,5), Piece.new(Piece.Type.QUEEN, Team.ENEMY_AI))
	
	var ai := _create_ai()
	var move := ai.get_move(b)
	
	assert(move.from == Vector2i(2,4), "Moved from %s instead of (2,4)" % move.from)
	assert(move.to == Vector2i(4,3), "Moved to %s instead of (4,3)" % move.to)
	print("Knight fork passed")

func test_obvious_pawn_capture() -> void:
	var b := Board.new()
	b.team_to_move = Team.PLAYER
	b.tile_map.set_tiles(create_tiles(Vector2i(2,2), Vector2i(5,5)))
	
	b.piece_map.put_piece(Vector2i(2,4), Piece.new(Piece.Type.KING, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(4,2), Piece.new(Piece.Type.KING, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(3,4), Piece.new(Piece.Type.PAWN, Team.ENEMY_AI))

	var ai := _create_ai()
	var move := ai.get_move(b)

	assert(move.from == Vector2i(2,4))
	assert(move.is_capture())
	assert(move.to == Vector2i(3,4))
	print("Obvious pawn capture passed")

func test_obvious_recapture() -> void:
	var b := Board.new()
	b.team_to_move = Team.PLAYER
	b.tile_map.set_tiles(create_tiles(Vector2i(2,2), Vector2i(6,6)))
	
	b.piece_map.put_piece(Vector2i(3,2), Piece.new(Piece.Type.KING, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(4,2), Piece.new(Piece.Type.ROOK, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(2,3), Piece.new(Piece.Type.PAWN, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(3,3), Piece.new(Piece.Type.PAWN, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(4,3), Piece.new(Piece.Type.PAWN, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(5,3), Piece.new(Piece.Type.QUEEN, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(3,4), Piece.new(Piece.Type.KNIGHT, Team.ENEMY_AI))
	
	b.piece_map.put_piece(Vector2i(2,5), Piece.new(Piece.Type.KNIGHT, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(3,5), Piece.new(Piece.Type.PAWN, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(5,5), Piece.new(Piece.Type.QUEEN, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(6,5), Piece.new(Piece.Type.PAWN, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(4,6), Piece.new(Piece.Type.PAWN, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(6,6), Piece.new(Piece.Type.KING, Team.PLAYER))

	# Make player queen capture enemy queen
	b = b.perform_move(Move.new(Vector2i(5,5), Vector2i(5,3), Move.CAPTURE))
	
	var ai := _create_ai()
	var move := ai.get_move(b)
	
	assert(move.from == Vector2i(3,4), "Moved from %s instead of (3,4). Should have moved knight" % move.from)
	assert(move.is_capture())
	assert(move.to == Vector2i(5,3))
	print("Obvious recapture passed")

# Player has forced checkmate, AI should react to it without breaking, even though it knows it's going to lose
# Board: (lowercase letters are enemy pieces, uppercase letters are player pieces)
#  ....
# b...kq
# ..QR..
#  .P.P.
#   .PK
func test_react_to_forced_checkmate() -> void:
	var b := Board.new()
	b.team_to_move = Team.PLAYER
	var tiles: Array[Vector2i] = create_tiles(Vector2i(1,0), Vector2i(4,3))
	tiles.append_array([Vector2i(0,1), Vector2i(0,2), Vector2i(2,4), Vector2i(3,4), Vector2i(4,4), Vector2i(5,1), Vector2i(5,2), Vector2i(5,3)])
	b.tile_map.set_tiles(tiles)
	
	b.piece_map.put_piece(Vector2i(0,1), Piece.new(Piece.Type.BISHOP, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(4,1), Piece.new(Piece.Type.KING, Team.ENEMY_AI))
	b.piece_map.put_piece(Vector2i(5,1), Piece.new(Piece.Type.QUEEN, Team.ENEMY_AI))

	b.piece_map.put_piece(Vector2i(2,2), Piece.new(Piece.Type.QUEEN, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(3,2), Piece.new(Piece.Type.ROOK, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(2,3), Piece.new(Piece.Type.PAWN, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(4,3), Piece.new(Piece.Type.PAWN, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(3,4), Piece.new(Piece.Type.PAWN, Team.PLAYER))
	b.piece_map.put_piece(Vector2i(4,4), Piece.new(Piece.Type.KING, Team.PLAYER))

	# Make player queen give a check
	b = b.perform_move(Move.new(Vector2i(2,2), Vector2i(1,1), Move.CHECK))
	assert(b.team_to_move == Team.ENEMY_AI)

	var ai := _create_ai()
	var ai_move1 := ai.get_move(b)
	assert(ai_move1 != null, "AI should have moved the first time")
	assert(ai_move1.from == Vector2i(4,1))
	assert(ai_move1.to == Vector2i(4,0))

	b = b.perform_move(ai_move1)
	assert(b.team_to_move == Team.PLAYER)

	b = b.perform_move(Move.new(Vector2i(1,1), Vector2i(2,0), Move.CHECK))
	assert(b.team_to_move == Team.ENEMY_AI)

	var ai_move2 := ai.get_move(b)
	assert(ai_move2 != null, "AI should have moved the second time")
	assert(ai_move2.from == Vector2i(4,0))
	assert(ai_move2.to == Vector2i(4,1))

	b = b.perform_move(ai_move2)
	assert(b.team_to_move == Team.PLAYER)

	b = b.perform_move(Move.new(Vector2i(2,0), Vector2i(3,1), Move.CHECK))
	assert(b.is_match_over())
	assert(b.get_match_result() == Match.Result.WIN)
	
	print("React to forced checkmate passed")

func _create_ai() -> AbstractAI:
	return ABSearchAIV5.new(true)

# Takes a string grid representation of a chess board and returns a Board object
# Example input:
#  ....
# b...kq
# ..QR..
#  .P.P.
#   .PK
# Where:
# - Uppercase letters are player pieces (K=King, Q=Queen, R=Rook, B=Bishop, N=Knight, P=Pawn)
# - Lowercase letters are enemy pieces
# - Dots (.) represent empty tiles
# - Spaces represent no tile at that position
func create_board_from_grid(grid_str: String) -> Board:
	var b := Board.new()
	b.team_to_move = Team.PLAYER
	
	# Split into lines and reverse to get bottom-up orientation
	var lines := grid_str.split("\n")
	lines.reverse()
	
	# First pass: collect all tile positions
	var tiles: Array[Vector2i] = []
	for y in range(lines.size()):
		var line := lines[y]
		for x in range(line.length()):
			var c := line[x]
			if c != " ":  # Skip spaces (no tile)
				tiles.append(Vector2i(x, y))
	
	# Set up the tile map first
	b.tile_map.set_tiles(tiles)
	
	# Second pass: place pieces
	for y in range(lines.size()):
		var line := lines[y]
		for x in range(line.length()):
			var c := line[x]
			var pos := Vector2i(x, y)
			var piece: Piece = null
			
			match c:
				"K": piece = Piece.new(Piece.Type.KING, Team.PLAYER)
				"Q": piece = Piece.new(Piece.Type.QUEEN, Team.PLAYER)
				"R": piece = Piece.new(Piece.Type.ROOK, Team.PLAYER)
				"B": piece = Piece.new(Piece.Type.BISHOP, Team.PLAYER)
				"N": piece = Piece.new(Piece.Type.KNIGHT, Team.PLAYER)
				"P": piece = Piece.new(Piece.Type.PAWN, Team.PLAYER)
				"k": piece = Piece.new(Piece.Type.KING, Team.ENEMY_AI)
				"q": piece = Piece.new(Piece.Type.QUEEN, Team.ENEMY_AI)
				"r": piece = Piece.new(Piece.Type.ROOK, Team.ENEMY_AI)
				"b": piece = Piece.new(Piece.Type.BISHOP, Team.ENEMY_AI)
				"n": piece = Piece.new(Piece.Type.KNIGHT, Team.ENEMY_AI)
				"p": piece = Piece.new(Piece.Type.PAWN, Team.ENEMY_AI)
				".", " ": continue
				_: assert(false, "Invalid character: %s" % c)
			
			if piece:
				b.piece_map.put_piece(pos, piece)
	
	return b
