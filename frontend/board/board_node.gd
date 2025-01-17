class_name BoardNode extends Node2D

enum BoardNodeState {
	NOT_INITIALIZED,
	INITIALIZED,
}
enum InputState {
	NONE,
	CHOOSING_PROMOTION,
}

var b: Board = Board.new()
@onready var tile_nodes: TileNodes = $TileNodes
@onready var piece_nodes: PieceNodes = $PieceNodes

var player_team: Team = Team.PLAYER
var state: BoardNodeState = BoardNodeState.NOT_INITIALIZED
var input_state: InputState = InputState.NONE
var selected_piece_node: PieceNode = null

var _cached_available_moves: Array[Move] = []

func init_randomly() -> void:
	assert(is_node_ready())
	assert(state == BoardNodeState.NOT_INITIALIZED)
	_generate_tiles()
	_generate_pieces()
	state = BoardNodeState.INITIALIZED

func _perform_move_action(move_action: MoveAction) -> void:
	if move_action.is_promotion():
		pass

func _on_piece_node_selected(piece_node: PieceNode) -> void:
	if b.team_to_move == player_team and selected_piece_node:
		assert(selected_piece_node.piece().team == player_team)
		if _can_capture(piece_node):
			var move_action: MoveAction
			if b.tile_map.is_promotion_tile(piece_node.piece().pos, player_team):
				input_state = InputState.CHOOSING_PROMOTION
				# TODO
				pass
			else:
				move_action = MoveAction.new(selected_piece_node.id(), piece_node.piece().pos, Move.CAPTURE, Piece.Type.UNSET, piece_node.id())
			# TODO
			return
	
	if _can_select(piece_node):
		_select_piece_node(piece_node)
	else:
		_select_piece_node(null)

func _on_tile_node_selected(tile_node: TileNode) -> void:
	if b.team_to_move == player_team and selected_piece_node:
		assert(selected_piece_node.piece().team == player_team)
		if _can_move_to(tile_node):
			var move_action: MoveAction
			if b.tile_map.is_promotion_tile(tile_node.pos(), player_team):
				# TODO
				pass
			else:
				move_action = MoveAction.new(selected_piece_node.id(), tile_node.pos())
			return
	_select_piece_node(null)

func _select_piece_node(piece_node: PieceNode) -> void:
	selected_piece_node = piece_node
	if piece_node:
		var available_moves: = b.get_available_moves_from(piece_node.piece().pos)
		var tiles_to_highlight: Array[Vector2i] = []
		for move: Move in available_moves:
			tiles_to_highlight.append(move.to)
		tile_nodes.highlight_tiles(tiles_to_highlight)
	else:
		tile_nodes.highlight_tiles([])

#region utils

func _can_select(piece_node: PieceNode) -> bool:
	return piece_node.piece().team == player_team

func _can_capture(piece_node: PieceNode) -> bool:
	var available_moves: = b.get_available_moves_from(selected_piece_node.piece().pos)
	for move: Move in available_moves:
		if move.is_capture() and move.to == piece_node.piece().pos:
			return true
		assert(move.to != piece_node.piece().pos, "you shouldn't be able to move here without a capture flag")
	return false

func _can_move_to(tile_node: TileNode) -> bool:
	var available_moves: = b.get_available_moves_from(selected_piece_node.piece().pos)
	for move: Move in available_moves:
		if move.to == tile_node.pos():
			return true
	return false

#endregion

func _generate_tiles() -> void:
	var tile_positions: = TilesGenerator.generate_tiles()
	b.tile_map.set_tiles(tile_positions)
	tile_nodes.create_tile_nodes(tile_positions)

func _generate_pieces() -> void:
	var enemy_army: = PiecesGenerator.generate_army(1000, b, Team.ENEMY_AI)
	var army: = PiecesGenerator.generate_army(1000, b, Team.PLAYER)
	var pieces: = enemy_army + army
	for piece: Piece in pieces:
		assert(not b.piece_map.has_piece(piece.pos))
		assert(b.tile_map.has_tile(piece.pos))
		
		b.piece_map.put_piece(piece.pos, piece)
		piece_nodes.spawn_piece(piece)
	
	for piece_node: PieceNode in piece_nodes.get_all_piece_nodes():
		assert(b.piece_map.has_piece(piece_node.piece().pos))
		assert(b.piece_map.get_piece(piece_node.piece().pos) == piece_node.piece())
