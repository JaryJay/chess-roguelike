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
		var piece_type_index: = generate_piece_type_index(credits)
		if piece_type_index == -1: break
		
		credits -= COSTS[piece_type_index]
		army.append(PIECES[piece_type_index].instantiate())
	
	# Arrange pieces
	var army_size: = army.size()
	assert(state.tiles.size() >= army_size, "Board does not have enough tiles")
	# Get first x tiles, where x is army size
	var tiles: = state.tiles.values()
	tiles.shuffle()
	tiles.sort_custom(sort_tiles_by_y)
	var first_few_tiles: = tiles.slice(0, army_size) if team.is_enemy() else tiles.slice(-army_size)
	for i: int in army_size:
		var piece_state: = PieceState.new(first_few_tiles[i].pos(), Piece.Type.)
		army[i].state().set_team(team)
		army[i].set_pos(first_few_tiles[i].pos())
	
	return army

static func generate_piece_type_index(credits: int) -> int:
	if credits < COSTS[-1]: return -1
	
	var affordable_indices: = []
	for i: int in COSTS.size():
		if COSTS[i] <= credits: affordable_indices.append(i)
	
	assert(affordable_indices.size() >= 1)
	
	return affordable_indices.pick_random()

static func sort_tiles_by_y(a: Tile, b: Tile) -> bool:
	return a.pos().y < b.pos().y
