class_name PiecesGenerator

const PIECE_TYPES: = [
	Piece.Type.QUEEN,
	Piece.Type.ROOK,
	Piece.Type.BISHOP,
	Piece.Type.KNIGHT,
	Piece.Type.PAWN,
]

static func generate_army(credits: int, b: Board, team: Team) -> Array[Piece]:
	var army: Array[Piece] = []
	
	# Placeholder position
	army.append(Piece.new(Piece.Type.KING, team, Vector2i(0, 0)))
	
	# Generate pieces
	while credits > 0:
		var piece_type: = generate_piece_type(credits)
		if piece_type == Piece.Type.UNSET: break
		
		credits -= PieceRules.get_rule(piece_type).credit_cost
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
	if credits < PieceRules.get_rule(Piece.Type.PAWN).credit_cost: return Piece.Type.UNSET
	
	var affordable_types: Array[Piece.Type] = []
	for type: Piece.Type in PIECE_TYPES:
		if PieceRules.get_rule(type).credit_cost <= credits:
			affordable_types.append(type)
	
	assert(affordable_types.size() >= 1)
	
	return affordable_types.pick_random()

static func sort_tiles_by_y(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y
