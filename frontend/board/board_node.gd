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
@onready var ai_thread: AIThread = $AIThread

var player_team: Team = Team.PLAYER
var state: BoardNodeState = BoardNodeState.NOT_INITIALIZED
var input_state: InputState = InputState.NONE
var selected_piece_node: PieceNode = null

func _ready() -> void:
	ai_thread.init(DumbAI.new())

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
			if b.tile_map.is_promotion_tile(piece_node.piece().pos, player_team) and selected_piece_node.piece().type == Piece.Type.PAWN:
				input_state = InputState.CHOOSING_PROMOTION
				assert(false, "Promotion not implemented")
				pass
			else:
				move_action = MoveAction.new(selected_piece_node.id(), piece_node.piece().pos, Move.CAPTURE, Piece.Type.UNSET, piece_node.id())
			perform_move_action(move_action)
			end_turn()
			return
	
	if _can_select(piece_node):
		_select_piece_node(piece_node)
	else:
		_select_piece_node(null)

func _on_tile_node_selected(tile_node: TileNode) -> void:
	print("tile_node selected %v" % tile_node.pos())
	if b.team_to_move == player_team and selected_piece_node:
		assert(selected_piece_node.piece().team == player_team)
		if _can_move_to(tile_node):
			print("can move to %v" % tile_node.pos())
			var move_action: MoveAction
			if b.tile_map.is_promotion_tile(tile_node.pos(), player_team) and selected_piece_node.piece().type == Piece.Type.PAWN:
				input_state = InputState.CHOOSING_PROMOTION
				assert(false, "Promotion not implemented")
				pass
			else:
				move_action = MoveAction.new(selected_piece_node.id(), tile_node.pos())
			perform_move_action(move_action)
			end_turn()
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

func end_turn() -> void:
	if b.is_match_over():
		return
	ai_thread.process_board(b)

func _on_ai_thread_move_found(move: Move) -> void:
	# Create move action
	var from: = move.from
	var to: = move.to
	var piece_id: = piece_nodes.get_piece_node_by_pos(from).id()
	var captured_piece_id: = 0
	if move.is_capture():
		captured_piece_id = piece_nodes.get_piece_node_by_pos(to).id()
	var move_action: MoveAction = MoveAction.new(piece_id, to, move.info, move.promo_info, captured_piece_id)
	perform_move_action(move_action)
	if b.is_match_over():
		return

#region utils

func _can_select(piece_node: PieceNode) -> bool:
	return b.team_to_move == player_team and piece_node.piece().team == player_team

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

func perform_move_action(move_action: MoveAction) -> void:
	assert(state == BoardNodeState.INITIALIZED)
	
	var piece_node: PieceNode = piece_nodes.get_piece_node(move_action.piece_id)
	
	# Update backend board state
	b = b.perform_move(Move.new(piece_node.piece().pos, move_action.to, move_action.info, move_action.promo_info))
	
	# Handle captures
	if move_action.is_capture():
		piece_nodes.free_piece_node(move_action.captured_piece_id)
	
	# Handle promotions
	if move_action.is_promotion():
		# Get the new piece
		var new_piece: = b.piece_map.get_piece(move_action.to)
		# Free old piece node
		var old_piece_position: = piece_node.position
		piece_nodes.free_piece_node(piece_node.id())
		# Spawn new piece node
		piece_node = piece_nodes.spawn_piece(new_piece)
		# put it back in the old position. It will be moved to the new position later
		piece_node.position = old_piece_position
	
	# Update piece position in the UI
	piece_node.move_to(tile_nodes.get_tile_node(move_action.to).position)
	piece_node.set_piece(b.piece_map.get_piece(move_action.to))
	
	# For each other piece node, set piece to be the new piece in the new board
	for p: PieceNode in piece_nodes.get_all_piece_nodes():
		if p != piece_node and !p.is_queued_for_deletion():
			p.set_piece(b.piece_map.get_piece(p.piece().pos))

	# Reset selection state
	_select_piece_node(null)
	input_state = InputState.NONE
