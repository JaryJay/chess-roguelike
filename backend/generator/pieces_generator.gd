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
	
	# Get all tiles and sort by y
	var tiles := board.tile_map.get_all_tiles()
	tiles.sort_custom(sort_tiles_by_y)
	
	# Determine back row(s) for the team
	var king: Piece = null
	for p in pieces:
		if p.type == Piece.Type.KING:
			king = p
			break
	assert(king != null, "Army must contain a king")
	
	var king_row_y: int
	var king_row_tiles: Array[Vector2i] = []
	
	if team.is_enemy():
		# Enemy: use the first row(s)
		king_row_y = tiles[0].y
		for t in tiles:
			if t.y == king_row_y:
				king_row_tiles.append(t)
	else:
		# Player: use the last row(s)
		king_row_y = tiles[-1].y
		for t in tiles:
			if t.y == king_row_y:
				king_row_tiles.append(t)
	
	assert(king_row_tiles.size() > 0, "No tiles found for king's back row")
	king.pos = king_row_tiles.pick_random()
	
	# Remove king's tile from available tiles
	var available_tiles := tiles.duplicate()
	available_tiles.erase(king.pos)
	
	# Arrange rest of pieces
	var non_king_pieces := pieces.filter(func(p: Piece): return p != king)
	var first_few_tiles := available_tiles.slice(0, non_king_pieces.size()) if team.is_enemy() else available_tiles.slice(-non_king_pieces.size())
	first_few_tiles.shuffle()
	for i: int in non_king_pieces.size():
		non_king_pieces[i].pos = first_few_tiles[i]

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

static func populate_classic_board(board: Board) -> Board:
	var new_board := board.duplicate()
	new_board.piece_map = BoardPieceMap.new()

	const back_row = [Piece.Type.ROOK, Piece.Type.KNIGHT, Piece.Type.BISHOP, Piece.Type.QUEEN, Piece.Type.KING, Piece.Type.BISHOP, Piece.Type.KNIGHT, Piece.Type.ROOK]

	# Player pieces
	for x in range(8):
		# back row
		var piece_type = back_row[x]
		var piece = Piece.new(piece_type, Team.PLAYER, Vector2i(x, 7))
		new_board.piece_map.put_piece(piece.pos, piece)
		# pawns
		piece_type = Piece.Type.PAWN
		piece = Piece.new(piece_type, Team.PLAYER, Vector2i(x, 6))
		new_board.piece_map.put_piece(piece.pos, piece)

	# Enemy pieces
	for x in range(8):
		# back row
		var piece_type = back_row[x]
		var piece = Piece.new(piece_type, Team.ENEMY_AI, Vector2i(x, 0))
		new_board.piece_map.put_piece(piece.pos, piece)
		# pawns
		piece_type = Piece.Type.PAWN
		piece = Piece.new(piece_type, Team.ENEMY_AI, Vector2i(x, 1))
		new_board.piece_map.put_piece(piece.pos, piece)

	return new_board

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
