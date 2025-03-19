class_name PieceNodes extends Node2D

signal piece_node_selected(piece_node: PieceNode)

## Dictionary from int to PieceNode
var _piece_nodes: Dictionary
## Dictionary from Team to PieceNode
var _cached_king_positions: Dictionary = {}

func spawn_piece(piece: Piece, animate: bool = false) -> PieceNode:
	var piece_node := create_piece_node(piece)
	piece_node.gen_id()
	piece_node.name = "PN_%s_%s_%d" % [Piece.type_to_string(piece.type), piece.team, piece_node.id()]
	assert(!has_piece_node(piece_node.id()))
	add_child(piece_node)
	piece_node.selected.connect(_on_piece_node_selected.bind(piece_node))
	var target_position := (Vector2(piece.pos) - Vector2.ONE * Config.max_board_size * 0.5) * 16
	piece_node.position = target_position
	_piece_nodes[piece_node.id()] = piece_node

	if animate:
		piece_node.scale = Vector2.ONE * 0.8
		piece_node.modulate = Color.TRANSPARENT
		piece_node.position += Vector2(0, -10)
		var tw := piece_node.create_tween().set_parallel().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tw.tween_interval((piece.pos.x + piece.pos.y) * 0.03 + 0.1)
		tw.chain().tween_property(piece_node, "scale", Vector2.ONE, 0.2)
		tw.tween_property(piece_node, "modulate", Color.WHITE, 0.1)
		tw.tween_property(piece_node, "position", target_position, 0.2)

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
		var piece := piece_node.piece()
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

const piece_node_scene := preload("res://frontend/pieces/piece_node.tscn")

static func create_piece_node(piece: Piece) -> PieceNode:
	var piece_node := piece_node_scene.instantiate() as PieceNode
	piece_node.set_piece(piece)
	return piece_node
