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
	test_obvious_recapture()
	test_react_to_forced_checkmate()
	test_lots_of_pieces()
	test_en_passant_capture()
	test_en_passant_enemy_side()
	test_en_passant_only_immediately()
	test_en_passant_no_double_push()
	
	get_tree().quit()

func test_mate_in_one() -> void:
	var b := create_board_from_grid("""
  .k..
  ....
  .K.R
  ....
""")
	b.team_to_move = Team.PLAYER
	var ai := _create_ai()
	var move := ai.get_move(b)
	
	assert(move.from == Vector2i(5,2)) # Rook from bottom
	assert(move.to == Vector2i(5,0)) # Rook to top, delivering mate
	print("Mate in one passed")

func test_obvious_queen_capture() -> void:
	var b := create_board_from_grid("""
  K...
  qR..
  ..k.
""")
	b.team_to_move = Team.PLAYER
	
	var ai := _create_ai()
	var move := ai.get_move(b)
	
	assert(move.from == Vector2i(3,1) or move.from == Vector2i(2,0))
	assert(move.to == Vector2i(2,1))
	assert(move.is_capture())
	print("Obvious queen capture passed")

func test_pawn_promotion_mate() -> void:
	# The spaces are intentional to test that the AI can handle different kinds of boards
	var b := create_board_from_grid("""




  .k..
  ...P.
  .K.
  ....
""")
	b.team_to_move = Team.PLAYER
	var ai := _create_ai()
	var move := ai.get_move(b)
	
	assert(move.from == Vector2i(5,5))  # Pawn
	assert(move.to == Vector2i(5,4))	# Promote pawn
	assert(move.promo_info == Piece.Type.QUEEN or move.promo_info == Piece.Type.ROOK)
	print("Pawn promotion mate passed")

func test_pawn_promotion_less_obvious() -> void:
	var b := create_board_from_grid("""




  ....
  .....
  kp.K
  ....
""")
	b.team_to_move = Team.ENEMY_AI
	
	var ai := _create_ai()
	var move := ai.get_move(b)

	assert(move.from == Vector2i(3,6), "Moved from %s instead of (3,6)" % move.from)
	assert(move.to == Vector2i(3,7), "Moved to %s instead of (3,7)" % move.to)
	assert(move.is_promotion(), "Did not promote")
	assert(move.promo_info == Piece.Type.QUEEN, "Promoted to %s instead of QUEEN" % Piece.type_to_string(move.promo_info))
	print("Pawn promotion less obvious passed")

func test_knight_fork() -> void:
	var b := create_board_from_grid("""

  K...
  R...
  N...
  .q.k
""")
	b.team_to_move = Team.PLAYER
	
	var ai := _create_ai()
	var move := ai.get_move(b)
	
	assert(move.from == Vector2i(2,3), "Moved from %s instead of (2,3)" % move.from)
	assert(move.to == Vector2i(4,2), "Moved to %s instead of (4,2)" % move.to)
	print("Knight fork passed")

func test_obvious_pawn_capture() -> void:
	var b := create_board_from_grid("""

  ..k.
  ....
  Kp..
  ....
""")
	b.team_to_move = Team.PLAYER
	
	var ai := _create_ai()
	var move := ai.get_move(b)

	assert(move.from == Vector2i(2,3))
	assert(move.is_capture())
	assert(move.to == Vector2i(3,3))
	print("Obvious pawn capture passed")

func test_obvious_recapture() -> void:
	var b := create_board_from_grid("""

  .kr..
  pppq.
  .n...
  NP.QP
  ..P.K
""")
	b.team_to_move = Team.PLAYER
	
	# Make player queen capture enemy queen
	b = b.perform_move(Move.new(Vector2i(5,4), Vector2i(5,2), Move.CAPTURE))
	
	var ai := _create_ai()
	var move := ai.get_move(b)
	
	assert(move.from == Vector2i(3,3), "Moved from %s instead of (3,3). Should have moved knight" % move.from)
	assert(move.is_capture())
	assert(move.to == Vector2i(5,2))
	print("Obvious recapture passed")

# Player has forced checkmate, AI should react to it without breaking, even though it knows it's going to lose
func test_react_to_forced_checkmate() -> void:
	var b := create_board_from_grid("""
  ....
 b...kq
 ..QR..
  .P.P.
   .PK
""")
	b.team_to_move = Team.PLAYER
	
	# Make player queen give a check
	b = b.perform_move(Move.new(Vector2i(3,2), Vector2i(2,1), Move.CHECK))
	assert(b.team_to_move == Team.ENEMY_AI)

	var ai := _create_ai()
	var ai_move1 := ai.get_move(b)
	assert(ai_move1 != null, "AI should have moved the first time")
	assert(ai_move1.from == Vector2i(5,1))
	assert(ai_move1.to == Vector2i(5,0))

	b = b.perform_move(ai_move1)
	assert(b.team_to_move == Team.PLAYER)

	b = b.perform_move(Move.new(Vector2i(2,1), Vector2i(3,0), Move.CHECK))
	assert(b.team_to_move == Team.ENEMY_AI)

	var ai_move2 := ai.get_move(b)
	assert(ai_move2 != null, "AI should have moved the second time")
	assert(ai_move2.from == Vector2i(5,0))
	assert(ai_move2.to == Vector2i(5,1))

	b = b.perform_move(ai_move2)
	assert(b.team_to_move == Team.PLAYER)

	b = b.perform_move(Move.new(Vector2i(3,0), Vector2i(4,0), Move.CHECK))
	assert(b.is_match_over())
	assert(b.get_match_result() == Match.Result.WIN)
	
	print("React to forced checkmate passed")

func test_lots_of_pieces() -> void:
	var b := create_board_from_grid("""
  r.q
.n.p..k
r......
..PPPQP
P..P.P.
PPRN..P
  PKPP
""")
	b.team_to_move = Team.ENEMY_AI

	var ai := _create_ai()
	var move := ai.get_move(b)
	
	# Basically we just want to make sure the AI doesn't sacrifice random pieces for no reason
	assert(!move.is_capture(), "There are no safe pieces to capture")
	print("Test lots of pieces passed")

func _find_move(moves: Array[Move], to: Vector2i) -> Move:
	for move: Move in moves:
		if move.to == to:
			return move
	return null

# Player pawn captures an enemy pawn that just advanced two squares.
func test_en_passant_capture() -> void:
	var b := create_board_from_grid("""
.......k
...p....
........
....P...
........
........
........
K.......
""")
	b.team_to_move = Team.ENEMY_AI

	# Enemy pawn double-pushes to land beside the player pawn.
	b = b.perform_move(Move.new(Vector2i(3,1), Vector2i(3,3)))
	assert(b.team_to_move == Team.PLAYER)

	var moves := b.get_available_moves_from(Vector2i(4,3))
	var ep := _find_move(moves, Vector2i(3,2))
	assert(ep != null, "En passant move to (3,2) should be available")
	assert(ep.is_en_passant(), "Move should be flagged en passant")
	assert(ep.is_capture(), "En passant should also be a capture")

	b = b.perform_move(ep)
	assert(b.piece_map.has_piece(Vector2i(3,2)), "Player pawn should land on (3,2)")
	assert(b.piece_map.get_piece(Vector2i(3,2)).team == Team.PLAYER)
	assert(!b.piece_map.has_piece(Vector2i(3,3)), "Captured enemy pawn should be removed from (3,3)")
	assert(!b.piece_map.has_piece(Vector2i(4,3)), "Capturing pawn should have left (4,3)")
	print("En passant capture passed")

# The AI/enemy side can also capture en passant.
func test_en_passant_enemy_side() -> void:
	var b := create_board_from_grid("""
.......k
........
........
........
...p....
........
....P...
K.......
""")
	b.team_to_move = Team.PLAYER

	# Player pawn double-pushes to land beside the enemy pawn.
	b = b.perform_move(Move.new(Vector2i(4,6), Vector2i(4,4)))
	assert(b.team_to_move == Team.ENEMY_AI)

	var moves := b.get_available_moves_from(Vector2i(3,4))
	var ep := _find_move(moves, Vector2i(4,5))
	assert(ep != null, "Enemy en passant move to (4,5) should be available")
	assert(ep.is_en_passant(), "Move should be flagged en passant")

	b = b.perform_move(ep)
	assert(b.piece_map.has_piece(Vector2i(4,5)), "Enemy pawn should land on (4,5)")
	assert(b.piece_map.get_piece(Vector2i(4,5)).team == Team.ENEMY_AI)
	assert(!b.piece_map.has_piece(Vector2i(4,4)), "Captured player pawn should be removed from (4,4)")
	print("En passant enemy side passed")

# En passant is only legal on the move immediately after the double push.
func test_en_passant_only_immediately() -> void:
	var b := create_board_from_grid("""
.......k
...p....
........
....P...
........
........
........
K.......
""")
	b.team_to_move = Team.ENEMY_AI

	# Enemy double-pushes beside the player pawn.
	b = b.perform_move(Move.new(Vector2i(3,1), Vector2i(3,3)))
	# Player makes an unrelated move (king shuffle) instead of capturing.
	b = b.perform_move(Move.new(Vector2i(0,7), Vector2i(0,6)))
	# Enemy makes an unrelated move.
	b = b.perform_move(Move.new(Vector2i(7,0), Vector2i(7,1)))
	assert(b.team_to_move == Team.PLAYER)

	var moves := b.get_available_moves_from(Vector2i(4,3))
	var ep := _find_move(moves, Vector2i(3,2))
	assert(ep == null, "En passant should no longer be available after intervening moves")
	print("En passant only-immediately passed")

# A pawn that arrived via single steps cannot be captured en passant.
func test_en_passant_no_double_push() -> void:
	var b := create_board_from_grid("""
.......k
........
........
...pP...
........
........
........
K.......
""")
	# Enemy pawn is already adjacent; the last move was unrelated, not a double push.
	b.team_to_move = Team.ENEMY_AI
	b = b.perform_move(Move.new(Vector2i(7,0), Vector2i(7,1)))
	assert(b.team_to_move == Team.PLAYER)

	var moves := b.get_available_moves_from(Vector2i(4,3))
	var ep := _find_move(moves, Vector2i(3,2))
	assert(ep == null, "En passant must not be available without a fresh double push")
	print("En passant no-double-push passed")

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
	if grid_str.begins_with("\n"):
		grid_str = grid_str.substr(1)

	var b := Board.new()
	b.team_to_move = Team.PLAYER

	# Split into lines
	var lines := grid_str.split("\n")
	
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
