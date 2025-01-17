class_name PieceNodes extends Node2D

signal piece_node_selected(piece_node: PieceNode)

## Dictionary from int to PieceNode
var _piece_nodes: Dictionary
## Dictionary from Team to PieceNode
var _cached_king_positions: Dictionary = {}

func spawn_piece(piece: Piece) -> PieceNode:
	var piece_node: = create_piece_node(piece)
	piece_node.gen_id()
	assert(!has_piece_node(piece_node.id()))
	add_child(piece_node)
	piece_node.mouse_selected.connect(_on_piece_node_selected.bind(piece_node))
	piece_node.position = piece.pos * 16
	_piece_nodes[piece_node.id()] = piece_node
	return piece_node

func get_piece_node(id: int) -> PieceNode:
	assert(has_piece_node(id))
	assert(!_piece_nodes[id].is_queued_for_deletion())
	return _piece_nodes[id]

func get_piece_node_by_pos(pos: Vector2i) -> PieceNode:
	for piece_node: PieceNode in _piece_nodes.values():
		if piece_node.piece().pos == pos:
			return piece_node
	return null

func free_piece_node(id: int) -> void:
	assert(has_piece_node(id))
	get_piece_node(id).queue_free()
	_piece_nodes.erase(id)
	# We may want to spawn some particles here

func has_piece_node(id: int) -> bool:
	return _piece_nodes.has(id)

func get_king_node(team: Team) -> PieceNode:
	if _cached_king_positions.has(team):
		assert(_cached_king_positions[team].piece().type == Piece.Type.KING)
		return _cached_king_positions[team]
	
	for piece_node: PieceNode in _piece_nodes.values():
		var piece: = piece_node.piece()
		if piece.type == Piece.Type.KING and piece.team == team:
			_cached_king_positions[team] = piece
	
	return _cached_king_positions[team]

func get_all_piece_nodes() -> Array[PieceNode]:
	# assert(_piece_nodes.size() == get_tree().get_nodes_in_group("piece_nodes").size(),
	# 	"_piece_nodes.size(): %s, nodes in group: %s" % [_piece_nodes.size(), get_tree().get_nodes_in_group("piece_nodes").size()])
	var piece_nodes: Array[PieceNode] = []
	piece_nodes.append_array(get_tree().get_nodes_in_group("piece_nodes"))
	return piece_nodes

func _on_piece_node_selected(piece_node: PieceNode) -> void:
	piece_node_selected.emit(piece_node)


const king_scene: = preload("res://frontend/pieces/king_node.tscn")
const queen_scene: = preload("res://frontend/pieces/queen_node.tscn")
const rook_scene: = preload("res://frontend/pieces/rook_node.tscn")
const bishop_scene: = preload("res://frontend/pieces/bishop_node.tscn")
const knight_scene: = preload("res://frontend/pieces/knight_node.tscn")
const pawn_scene: = preload("res://frontend/pieces/pawn_node.tscn")


const SCENES: = {
	Piece.Type.KING: king_scene,
	Piece.Type.QUEEN: queen_scene,
	Piece.Type.ROOK: rook_scene,
	Piece.Type.BISHOP: bishop_scene,
	Piece.Type.KNIGHT: knight_scene,
	Piece.Type.PAWN: pawn_scene,
}

static func create_piece_node(piece: Piece) -> PieceNode:
	var scene: PackedScene = SCENES[piece.type]
	var piece_node: = scene.instantiate() as PieceNode
	piece_node.set_piece(piece)
	return piece_node
