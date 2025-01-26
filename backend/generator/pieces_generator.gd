class_name PiecesGenerator

const QUEEN_COST: = 900
const ROOK_COST: = 500
const BISHOP_COST: = 300
const KNIGHT_COST: = 280
const PAWN_COST: = 100

const COSTS: = {
	Piece.Type.QUEEN: 900,
	Piece.Type.ROOK: 500,
	Piece.Type.BISHOP: 300,
	Piece.Type.KNIGHT: 290,
	Piece.Type.PAWN: 100,
}

static func generate_armies(credits: int, b: Board) -> Array[Piece]:
	# Generate armies for both teams
	var enemy_army: = generate_army(credits, b, Team.ENEMY_AI)
	var player_army: = generate_army(credits, b, Team.PLAYER)

	var board_copy: = b.duplicate()
	
	for piece: Piece in enemy_army + player_army:
		assert(not b.piece_map.has_piece(piece.pos))
		assert(b.tile_map.has_tile(piece.pos))
		
		board_copy.piece_map.put_piece(piece.pos, piece)
	if board_copy.is_team_in_check(Team.ENEMY_AI):
		# If enemy king is in check, add a pawn in front of it
		var king: Piece = enemy_army[0]
		assert(king.type == Piece.Type.KING)
		var pawn: Piece = Piece.new(Piece.Type.PAWN, Team.ENEMY_AI, king.pos + Vector2i.UP)
		print("Adding pawn in front of king")
		enemy_army.insert(0, pawn)

	return enemy_army + player_army

static func generate_army(credits: int, b: Board, team: Team) -> Array[Piece]:
	var army: Array[Piece] = []
	
	# Placeholder position
	army.append(Piece.new(Piece.Type.KING, team, Vector2i(0, 0)))
	
	# Generate pieces
	while credits > 0:
		var piece_type: = generate_piece_type(credits)
		if piece_type == Piece.Type.UNSET: break
		
		credits -= COSTS[piece_type]
		army.append(Piece.new(piece_type, team, Vector2i(0, 0)))
	
	# Arrange pieces
	var army_size: = army.size()
	assert(b.tile_map.num_tiles() >= army_size, "Board does not have enough tiles")
	# Get first x tiles, where x is army size
	var tiles: = b.tile_map.get_all_tiles()
	tiles.shuffle()
	tiles.sort_custom(sort_tiles_by_y)
	var first_few_tiles: = tiles.slice(0, army_size) if team.is_enemy() else tiles.slice(-army_size)
	for i: int in army_size:
		army[i].pos = first_few_tiles[i]
	
	return army

static func generate_piece_type(credits: int) -> Piece.Type:
	if credits < COSTS[Piece.Type.PAWN]: return Piece.Type.UNSET
	
	var affordable_types: Array[Piece.Type] = []
	for type: Piece.Type in COSTS.keys():
		if COSTS[type] <= credits: affordable_types.append(type)
	
	assert(affordable_types.size() >= 1)
	
	return affordable_types.pick_random()

static func sort_tiles_by_y(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y
