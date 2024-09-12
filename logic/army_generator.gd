class_name ArmyGenerator

const king_scene: = preload("res://pieces/king.tscn")
const queen_scene: = preload("res://pieces/queen.tscn")
const rook_scene: = preload("res://pieces/rook.tscn")
const bishop_scene: = preload("res://pieces/bishop.tscn")
const knight_scene: = preload("res://pieces/knight.tscn")
const pawn_scene: = preload("res://pieces/pawn.tscn")

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

const SCENES: = {
	Piece.Type.QUEEN: queen_scene,
	Piece.Type.ROOK: rook_scene,
	Piece.Type.BISHOP: bishop_scene,
	Piece.Type.KNIGHT: knight_scene,
	Piece.Type.PAWN: pawn_scene,
}

static func generate_army(credits: int, state: BoardState, team: Team) -> Array[Piece]:
	var army: Array[Piece] = []
	
	army.append(king_scene.instantiate())
	
	# Generate pieces
	while credits > 0:
		var piece_type: = generate_piece_type(credits)
		if piece_type == Piece.Type.UNSET: break
		
		credits -= COSTS[piece_type]
		army.append(SCENES[piece_type].instantiate())
	
	# Arrange pieces
	var army_size: = army.size()
	assert(state.tiles.size() >= army_size, "Board does not have enough tiles")
	# Get first x tiles, where x is army size
	var tiles: = state.tiles.values()
	tiles.shuffle()
	tiles.sort_custom(sort_tiles_by_y)
	var first_few_tiles: = tiles.slice(0, army_size) if team.is_enemy() else tiles.slice(-army_size)
	for i: int in army_size:
		var piece_state: = PieceState.new(first_few_tiles[i].pos(), army[i].type, team)
		army[i].set_state(piece_state)
	
	return army

static func generate_piece_type(credits: int) -> Piece.Type:
	if credits < COSTS[Piece.Type.PAWN]: return Piece.Type.UNSET
	
	var affordable_types: Array[Piece.Type] = []
	for type: Piece.Type in COSTS.keys():
		if COSTS[type] <= credits: affordable_types.append(type)
	
	assert(affordable_types.size() >= 1)
	
	return affordable_types.pick_random()

static func sort_tiles_by_y(a: Tile, b: Tile) -> bool:
	return a.pos().y < b.pos().y
