class_name EnemyArmyGenerator

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

const COSTS: = [QUEEN_COST, ROOK_COST, BISHOP_COST, KNIGHT_COST, PAWN_COST]
const PIECES: = [queen_scene, rook_scene, bishop_scene, knight_scene, pawn_scene]

func generate_enemy_army(credits: int, board: Board) -> Array[Piece]:
	var army: Array[Piece] = []
	
	army.append(king_scene.instantiate())
	
	# TODO
	
	return army

func generate_piece(credits: int) -> Piece:
	if credits < 100: return null
	
	# TODO
	
	return null
