class_name BoardNode extends Node2D

signal game_over(game_result: Match.Result)

enum BoardNodeState {
	NOT_INITIALIZED,
	INITIALIZED,
}
enum InputState {
	NONE,
	CHOOSING_PROMOTION,
}

@export var ai_vs_ai_mode: bool

@onready var tile_nodes: TileNodes = $TileNodes
@onready var piece_nodes: PieceNodes = $PieceNodes
@onready var ai_thread1: AIThread = $AIThread1
@onready var ai_thread2: AIThread = $AIThread2
@onready var promotion_ui: PromotionUI = $CanvasLayer/PromotionUI
var b: Board
var player_team: Team = Team.PLAYER
var state: BoardNodeState = BoardNodeState.NOT_INITIALIZED
var input_state: InputState = InputState.NONE
var selected_piece_node: PieceNode = null
var temp_move_action: MoveAction = null

func _ready() -> void:
	assert(Config.loaded, "Config not loaded!")
	if ai_vs_ai_mode:
		ai_thread1.init(ABSearchAIV4.new())
	ai_thread2.init(ABSearchAIV4.new())

func init_with_game_setup(game_setup: GameSetup) -> void:
	assert(is_node_ready(), "BoardNode is not added to the tree")
	if state == BoardNodeState.INITIALIZED:
		state = BoardNodeState.NOT_INITIALIZED
		# Reset UI elements
		for piece_node: PieceNode in piece_nodes.get_all_piece_nodes():
			piece_node.queue_free()
		for tile_node: TileNode in tile_nodes.get_all_tile_nodes():
			tile_node.queue_free()
		# AI thread is stateless, so we don't need to reset it
		promotion_ui.hide()
		input_state = InputState.NONE
		selected_piece_node = null
		temp_move_action = null
	
	# Generate board with tiles and pieces
	b = TilesGenerator.generate_board_with_tiles()
	b = PiecesGenerator.populate_board_with_player_types(b, game_setup.faction.piece_types, 1150)
	
	# Create UI elements
	tile_nodes.create_tile_nodes(b.tile_map.get_all_tiles())
	var pieces := b.piece_map.get_all_pieces()
	for piece in pieces:
		var piece_node := piece_nodes.spawn_piece(piece)
		assert(b.piece_map.has_piece(piece_node.piece().pos))
		assert(b.piece_map.get_piece(piece_node.piece().pos) == piece_node.piece())
	
	assert(piece_nodes.get_all_piece_nodes().size() == pieces.size(), "Did not spawn all pieces")
	state = BoardNodeState.INITIALIZED

	# Trigger AI's first move
	if ai_vs_ai_mode:
		if b.team_to_move == Team.PLAYER:
			ai_thread1.process_board(b)
		else:
			ai_thread2.process_board(b)

func init_randomly() -> void:
	assert(is_node_ready(), "BoardNode is not added to the tree")
	if state == BoardNodeState.INITIALIZED:
		state = BoardNodeState.NOT_INITIALIZED
		# Reset UI elements
		for piece_node: PieceNode in piece_nodes.get_all_piece_nodes():
			piece_node.queue_free()
		for tile_node: TileNode in tile_nodes.get_all_tile_nodes():
			tile_node.queue_free()
		# AI thread is stateless, so we don't need to reset it
		promotion_ui.hide()
		input_state = InputState.NONE
		selected_piece_node = null
		temp_move_action = null
	
	# Generate board with tiles and pieces
	b = TilesGenerator.generate_board_with_tiles()
	b = PiecesGenerator.populate_board(b, 1150)  # Use existing credit amount
	
	# Create UI elements
	tile_nodes.create_tile_nodes(b.tile_map.get_all_tiles())
	var pieces := b.piece_map.get_all_pieces()
	for piece in pieces:
		var piece_node := piece_nodes.spawn_piece(piece)
		assert(b.piece_map.has_piece(piece_node.piece().pos))
		assert(b.piece_map.get_piece(piece_node.piece().pos) == piece_node.piece())
	
	assert(piece_nodes.get_all_piece_nodes().size() == pieces.size(), "Did not spawn all pieces")
	state = BoardNodeState.INITIALIZED

	# Trigger AI's first move
	if ai_vs_ai_mode:
		if b.team_to_move == Team.PLAYER:
			ai_thread1.process_board(b)
		else:
			ai_thread2.process_board(b)

func _on_piece_node_selected(piece_node: PieceNode) -> void:
	if ai_vs_ai_mode: return
		
	if b.team_to_move == player_team and selected_piece_node:
		assert(selected_piece_node.piece().team == player_team)
		if _can_capture(piece_node):
			var move_action: MoveAction
			if b.tile_map.is_promotion_tile(piece_node.piece().pos, player_team) and selected_piece_node.piece().type == Piece.Type.PAWN:
				temp_move_action = MoveAction.new(selected_piece_node.id(), piece_node.piece().pos, Move.CAPTURE, Piece.Type.UNSET, piece_node.id())
				input_state = InputState.CHOOSING_PROMOTION
				promotion_ui.show()
			else:
				move_action = MoveAction.new(selected_piece_node.id(), piece_node.piece().pos, Move.CAPTURE, Piece.Type.UNSET, piece_node.id())
				perform_move_action(move_action)
				end_player_turn()
			return
	
	if _can_select(piece_node):
		promotion_ui.hide()
		_select_piece_node(piece_node)
	else:
		_select_piece_node(null)

func _on_tile_node_selected(tile_node: TileNode) -> void:
	if ai_vs_ai_mode: return
		
	if b.team_to_move == player_team and selected_piece_node:
		assert(selected_piece_node.piece().team == player_team)
		if _can_move_to(tile_node):
			var move_action: MoveAction
			if b.tile_map.is_promotion_tile(tile_node.pos(), player_team) and selected_piece_node.piece().type == Piece.Type.PAWN:
				temp_move_action = MoveAction.new(selected_piece_node.id(), tile_node.pos(), 0, Piece.Type.UNSET)
				input_state = InputState.CHOOSING_PROMOTION
				promotion_ui.show()
			else:
				move_action = MoveAction.new(selected_piece_node.id(), tile_node.pos())
				perform_move_action(move_action)
				end_player_turn()
			return
	
	promotion_ui.hide()
	_select_piece_node(null)

func _on_promotion_ui_promotion_chosen(promotion_type: Piece.Type) -> void:
	if ai_vs_ai_mode: return
		
	assert(temp_move_action)
	assert(input_state == InputState.CHOOSING_PROMOTION)
	assert(selected_piece_node)
	assert(b.team_to_move == player_team)
	temp_move_action.promo_info = promotion_type
	input_state = InputState.NONE
	perform_move_action(temp_move_action)
	promotion_ui.hide()
	temp_move_action = null
	end_player_turn()

func _select_piece_node(piece_node: PieceNode) -> void:
	if selected_piece_node:
		selected_piece_node.set_selected(false)
	selected_piece_node = piece_node
	if piece_node:
		var available_moves := b.get_available_moves_from(piece_node.piece().pos)
		var tiles_to_highlight: Array[Vector2i] = []
		for move: Move in available_moves:
			tiles_to_highlight.append(move.to)
		tile_nodes.highlight_tiles(tiles_to_highlight)
		piece_node.set_selected(true)
	else:
		tile_nodes.highlight_tiles([])

func end_player_turn() -> void:
	if b.is_match_over():
		game_over.emit(b.get_game_result())
		return
	ai_thread2.process_board(b)

func end_ai_turn() -> void:
	if b.is_match_over():
		game_over.emit(b.get_game_result())
		return
	
	if ai_vs_ai_mode:
		# Trigger next AI's move
		if b.team_to_move == Team.PLAYER:
			ai_thread1.process_board(b)
		else:
			ai_thread2.process_board(b)

func _on_ai_thread_move_found(move: Move) -> void:
	# Create move action
	var from := move.from
	var to := move.to
	var piece_id := piece_nodes.get_piece_node_by_pos(from).id()
	var captured_piece_id := 0
	if move.is_capture():
		captured_piece_id = piece_nodes.get_piece_node_by_pos(to).id()
	var move_action: MoveAction = MoveAction.new(piece_id, to, move.info, move.promo_info, captured_piece_id)
	perform_move_action(move_action)
	end_ai_turn()

#region utils

func _can_select(piece_node: PieceNode) -> bool:
	return b.team_to_move == player_team and piece_node.piece().team == player_team

func _can_capture(piece_node: PieceNode) -> bool:
	var available_moves := b.get_available_moves_from(selected_piece_node.piece().pos)
	for move: Move in available_moves:
		if move.is_capture() and move.to == piece_node.piece().pos:
			return true
		assert(move.to != piece_node.piece().pos, "you shouldn't be able to move here without a capture flag")
	return false

func _can_move_to(tile_node: TileNode) -> bool:
	var available_moves := b.get_available_moves_from(selected_piece_node.piece().pos)
	for move: Move in available_moves:
		if move.to == tile_node.pos():
			return true
	return false

#endregion

func perform_move_action(move_action: MoveAction) -> void:
	assert(move_action)
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
		var new_piece := b.piece_map.get_piece(move_action.to)
		# Note: this is the position of the sprite, not the coordinates of the piece
		var old_piece_position := piece_node.position
		# Free old piece node
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

func start_ai_vs_ai() -> void:
	ai_vs_ai_mode = true
	ai_thread1.process_board(b)

func stop_ai_vs_ai() -> void:
	ai_vs_ai_mode = false
