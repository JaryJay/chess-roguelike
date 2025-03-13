class_name PiecesGenerator

## Only the types that can be generated
## Note that the king is not included here
const PIECE_TYPES := [
	Piece.Type.QUEEN,
	Piece.Type.ROOK,
	Piece.Type.BISHOP,
	Piece.Type.KNIGHT,
	Piece.Type.PAWN,
]

static func arrange_piece_positions(board: Board, pieces: Array[Piece], team: Team) -> void:
	var army_size := pieces.size()
	assert(board.tile_map.num_tiles() >= army_size, "Board does not have enough tiles")
	# Get first x tiles, where x is army size
	var tiles := board.tile_map.get_all_tiles()
	tiles.shuffle()
	tiles.sort_custom(sort_tiles_by_y)
	var first_few_tiles := tiles.slice(0, army_size) if team.is_enemy() else tiles.slice(-army_size)
	for i: int in army_size:
		pieces[i].pos = first_few_tiles[i]

static func generate_army_randomly(credits: int, b: Board, team: Team) -> Array[Piece]:
	var army: Array[Piece] = []
	
	# Placeholder position
	army.append(Piece.new(Piece.Type.KING, team, Vector2i(0, 0)))
	
	# Generate pieces
	var remaining_credits := credits
	while remaining_credits > 0:
		var piece_type := generate_piece_type(remaining_credits)
		if piece_type == Piece.Type.UNSET: break
		
		remaining_credits -= PieceRules.get_rule(piece_type).credit_cost
		army.append(Piece.new(piece_type, team, Vector2i(0, 0)))
	
	arrange_piece_positions(b, army, team)
	
	return army

static func generate_army_with_types(piece_types: Array[Piece.Type],b: Board, team: Team) -> Array[Piece]:
	var army: Array[Piece] = []
	
	# Placeholder position
	army.append(Piece.new(Piece.Type.KING, team, Vector2i(0, 0)))
	for piece_type in piece_types:
		army.append(Piece.new(piece_type, team, Vector2i(0, 0)))
	
	arrange_piece_positions(b, army, team)
	
	return army

static func generate_piece_type(credits: int) -> Piece.Type:
	if credits < PieceRules.get_rule(Piece.Type.PAWN).credit_cost: return Piece.Type.UNSET
	
	var affordable_types: Array[Piece.Type] = []
	for type: Piece.Type in PIECE_TYPES:
		assert(PieceRules.get_rule(type) != null)
		assert(PieceRules.get_rule(type).credit_cost > 0)
		if PieceRules.get_rule(type).credit_cost <= credits:
			affordable_types.append(type)
	
	assert(affordable_types.size() >= 1)
	
	return affordable_types.pick_random()

static func sort_tiles_by_y(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y

static func populate_board(board: Board, credits: int, retries: int = 100) -> Board:
	for retry in retries:
		var new_board := board.duplicate()
		new_board.piece_map = BoardPieceMap.new()
		
		# Generate both armies
		var player_army := generate_army_randomly(credits, new_board, Team.PLAYER)
		var enemy_army := generate_army_randomly(credits, new_board, Team.ENEMY_AI)
		var pieces := player_army + enemy_army
		var num_pieces := pieces.size()
		
		if num_pieces >= new_board.tile_map.num_tiles():
			print("There are more pieces than tiles, retrying")
			continue
		
		# Place all pieces
		for piece in pieces:
			assert(not new_board.piece_map.has_piece(piece.pos))
			assert(new_board.tile_map.has_tile(piece.pos))
			new_board.piece_map.put_piece(piece.pos, piece)
			
		if !new_board.is_team_in_check(Team.PLAYER) and !new_board.is_team_in_check(Team.ENEMY_AI):
			return new_board
	
	push_error("Failed to generate valid board after %d attempts" % retries)
	return board

static func populate_board_with_player_types(board: Board, player_types: Array[Piece.Type], credits: int, retries: int = 100) -> Board:
	for retry in retries:
		var new_board := board.duplicate()
		new_board.piece_map = BoardPieceMap.new()
		
		# Generate both armies
		var player_army := generate_army_with_types(player_types, new_board, Team.PLAYER)
		var enemy_army := generate_army_randomly(credits, new_board, Team.ENEMY_AI)
		var pieces := player_army + enemy_army
		var num_pieces := pieces.size()
		
		if num_pieces >= new_board.tile_map.num_tiles():
			print("There are more pieces than tiles, retrying")
			continue
		
		# Place all pieces
		for piece in pieces:
			assert(not new_board.piece_map.has_piece(piece.pos))
			assert(new_board.tile_map.has_tile(piece.pos))
			new_board.piece_map.put_piece(piece.pos, piece)

		if !new_board.is_team_in_check(Team.PLAYER) and !new_board.is_team_in_check(Team.ENEMY_AI):
			return new_board
	
	push_error("Failed to generate valid board after %d attempts" % retries)
	return board
