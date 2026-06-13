class_name BoardNode extends Node2D

signal game_over(game_result: Match.Result)

enum BoardNodeState {
	NOT_INITIALIZED,
	INITIALIZED,
}
enum InputState {
	NONE,
	CHOOSING_PROMOTION,
	DRAGGING,
}

const DRAG_THRESHOLD := 4.0

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
var premove_action: MoveAction = null
var _pointer_down: bool = false
var _pointer_start_pos: Vector2 = Vector2.ZERO
var _active_pointer_id: int = -1
var _is_dragging: bool = false
var _suppress_click_signals: bool = false
var _drag_piece_node: PieceNode = null
var _press_piece_node: PieceNode = null
var _pending_premove_execute: bool = false

func init_with_game_setup(game_setup: GameSetup) -> void:
	assert(Config.loaded, "Config not loaded!")
	if ai_vs_ai_mode:
		ai_thread1.init(ABSearchAIV4.new())
		ai_thread2.init(ABSearchAIV5.new())
		init_randomly()
		return

	ai_thread2.init(ABSearchAIV5.new(game_setup.difficulty.eval_randomness))
	_reset_board_state()
	
	# Generate board with tiles and pieces
	if game_setup.classic_mode:
		b = TilesGenerator.generate_classic_board()
		b = PiecesGenerator.populate_classic_board(b)
	else:
		var min_tiles := maxi(20, floori(game_setup.piece_types.size() * 2.25))
		b = TilesGenerator.generate_board_with_tiles(min_tiles)
		b = PiecesGenerator.populate_board_with_player_types(b, game_setup.piece_types, game_setup.enemy_credits)
	
	_create_board_ui()
	state = BoardNodeState.INITIALIZED

	# Trigger AI's first move
	if ai_vs_ai_mode:
		_trigger_ai_move()

func init_randomly() -> void:
	assert(is_node_ready(), "BoardNode is not added to the tree")
	_reset_board_state()
	
	# Generate board with tiles and pieces
	b = TilesGenerator.generate_board_with_tiles(20)
	b = PiecesGenerator.populate_board(b, 1150)  # Use existing credit amount
	
	_create_board_ui()
	state = BoardNodeState.INITIALIZED

	# Trigger AI's first move
	if ai_vs_ai_mode:
		_trigger_ai_move()

func _input(event: InputEvent) -> void:
	if ai_vs_ai_mode or state != BoardNodeState.INITIALIZED:
		return
	if input_state == InputState.CHOOSING_PROMOTION:
		return
	
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.canceled and touch.index == _active_pointer_id:
			_handle_pointer_cancelled()
		else:
			_handle_pointer(touch.index, touch.position, touch.pressed)
	elif event is InputEventScreenDrag:
		if _pointer_down and event.index == _active_pointer_id:
			_handle_pointer_motion(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer(-1, event.position, event.pressed)
	elif event is InputEventMouseMotion and _pointer_down and _active_pointer_id == -1:
		_handle_pointer_motion(event.position)

func _handle_pointer(pointer_id: int, screen_pos: Vector2, pressed: bool) -> void:
	if pressed:
		if _pointer_down:
			return
		_pointer_down = true
		_active_pointer_id = pointer_id
		_pointer_start_pos = screen_pos
		_is_dragging = false
		
		var world_pos := _screen_to_world(screen_pos)
		_press_piece_node = _get_player_piece_at_world_pos(world_pos)
		if _press_piece_node and not _press_piece_node.is_moving() and selected_piece_node == null:
			if b.team_to_move == player_team or Settings.premoving_enabled:
				_select_piece_node(_press_piece_node)
	else:
		if not _pointer_down or pointer_id != _active_pointer_id:
			return
		
		if _is_dragging:
			var world_pos := _screen_to_world(screen_pos)
			_finish_drag(world_pos)
			get_viewport().set_input_as_handled()
		
		_pointer_down = false
		_active_pointer_id = -1
		_is_dragging = false
		_suppress_click_signals = false
		_press_piece_node = null
		
		if _pending_premove_execute:
			_pending_premove_execute = false
			_try_execute_premove()

func _handle_pointer_cancelled() -> void:
	_cancel_drag()
	_pointer_down = false
	_active_pointer_id = -1
	_is_dragging = false
	_suppress_click_signals = false
	_press_piece_node = null
	if _pending_premove_execute:
		_pending_premove_execute = false
		_try_execute_premove()

func _handle_pointer_motion(screen_pos: Vector2) -> void:
	if not _pointer_down:
		return
	
	var drag_piece := selected_piece_node
	if _press_piece_node and is_instance_valid(_press_piece_node) and not _press_piece_node.is_moving():
		drag_piece = _press_piece_node
	if not drag_piece or drag_piece.is_moving():
		return
	
	if not _is_dragging:
		if screen_pos.distance_to(_pointer_start_pos) < DRAG_THRESHOLD:
			return
		if drag_piece != selected_piece_node:
			_select_piece_node(drag_piece)
		if not selected_piece_node:
			return
		_start_drag()
	
	var world_pos := _screen_to_world(screen_pos)
	var local_pos := piece_nodes.to_local(world_pos)
	selected_piece_node.update_drag_position(local_pos)
	var board_pos := tile_nodes.world_pos_to_board_pos(world_pos)
	if tile_nodes.has_tile_node(board_pos):
		tile_nodes.set_drag_hover_tile(board_pos)
	else:
		tile_nodes.clear_drag_hover()
	get_viewport().set_input_as_handled()

func _start_drag() -> void:
	_is_dragging = true
	_suppress_click_signals = true
	input_state = InputState.DRAGGING
	_drag_piece_node = selected_piece_node
	selected_piece_node.begin_drag()

func _finish_drag(world_pos: Vector2) -> void:
	var dragged_piece := _drag_piece_node if _drag_piece_node else selected_piece_node
	if not dragged_piece:
		_abort_drag(true)
		return
	
	var target_pos := tile_nodes.world_pos_to_board_pos(world_pos)
	var target_piece_node: PieceNode = null
	if b.piece_map.has_piece(target_pos):
		target_piece_node = piece_nodes.get_piece_node_by_pos(target_pos)
	
	input_state = InputState.NONE
	tile_nodes.clear_drag_hover()
	_is_dragging = false
	_drag_piece_node = null
	
	if b.team_to_move != player_team and Settings.premoving_enabled and _can_premove_to(dragged_piece, target_pos):
		dragged_piece.end_drag(true)
		_set_premove(dragged_piece, target_pos)
	elif b.team_to_move == player_team:
		selected_piece_node = dragged_piece
		dragged_piece.end_drag(true)
		if not _attempt_move_to(target_pos, target_piece_node) and tile_nodes.has_tile_node(dragged_piece.piece().pos):
			tile_nodes.get_tile_node(dragged_piece.piece().pos).animate_flash(0.9, 0.2)
	else:
		dragged_piece.end_drag(true)
		if tile_nodes.has_tile_node(dragged_piece.piece().pos):
			tile_nodes.get_tile_node(dragged_piece.piece().pos).animate_flash(0.9, 0.2)

func _cancel_drag() -> void:
	_abort_drag(true)

func _abort_drag(restore_position: bool = true) -> void:
	if _drag_piece_node and is_instance_valid(_drag_piece_node) and _drag_piece_node.is_dragging():
		_drag_piece_node.end_drag(restore_position)
	_drag_piece_node = null
	_is_dragging = false
	if input_state == InputState.DRAGGING:
		input_state = InputState.NONE
	tile_nodes.clear_drag_hover()

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

func _get_player_piece_at_world_pos(world_pos: Vector2) -> PieceNode:
	var board_pos := tile_nodes.world_pos_to_board_pos(world_pos)
	if not b.piece_map.has_piece(board_pos):
		return null
	var piece := b.piece_map.get_piece(board_pos)
	if piece.team != player_team:
		return null
	return piece_nodes.get_piece_node_by_pos(board_pos)

func _on_piece_node_selected(piece_node: PieceNode) -> void:
	if _suppress_click_signals:
		return
	
	var tile_node: TileNode = tile_nodes.get_tile_node(piece_node.piece().pos)
	tile_node.animate_flash(1.1)
	if ai_vs_ai_mode:
		return
		
	if b.team_to_move == player_team and selected_piece_node:
		if _attempt_move_to(piece_node.piece().pos, piece_node):
			return
	
	if b.team_to_move != player_team and Settings.premoving_enabled and selected_piece_node:
		if piece_node != selected_piece_node and _can_premove_to(selected_piece_node, piece_node.piece().pos):
			_set_premove(selected_piece_node, piece_node.piece().pos)
			return
	
	if _can_select(piece_node):
		promotion_ui.hide()
		_select_piece_node(piece_node)
	else:
		_select_piece_node(null)

func _on_tile_node_selected(tile_node: TileNode) -> void:
	if _suppress_click_signals:
		return
	
	tile_node.animate_flash(1.1)
	if ai_vs_ai_mode:
		return
		
	if b.team_to_move == player_team and selected_piece_node:
		if _attempt_move_to(tile_node.pos()):
			return
	
	if b.team_to_move != player_team and Settings.premoving_enabled and selected_piece_node:
		if _can_premove_to(selected_piece_node, tile_node.pos()):
			_set_premove(selected_piece_node, tile_node.pos())
			return
	
	promotion_ui.hide()
	_select_piece_node(null)

func _on_promotion_ui_promotion_chosen(promotion_type: Piece.Type) -> void:
	if ai_vs_ai_mode:
		return
		
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
		if b.team_to_move != player_team and not Settings.premoving_enabled:
			selected_piece_node = null
			tile_nodes.highlight_tiles([])
			return
		var tiles_to_highlight: Array[Vector2i] = []
		if b.team_to_move == player_team:
			var available_moves := b.get_available_moves_from(piece_node.piece().pos)
			for move: Move in available_moves:
				tiles_to_highlight.append(move.to)
		else:
			tiles_to_highlight = _get_premove_targets(piece_node.piece().pos)
		tile_nodes.highlight_tiles(tiles_to_highlight)
		piece_node.set_selected(true)
	else:
		tile_nodes.highlight_tiles([])

func clear_premoves() -> void:
	_clear_premove()
	if b and b.team_to_move != player_team:
		_select_piece_node(null)

func end_player_turn() -> void:
	if b.is_match_over():
		_on_game_over(b.get_match_result())
		return
	ai_thread2.process_board(b)

func end_ai_turn() -> void:
	if b.is_match_over():
		_on_game_over(b.get_match_result())
		return

	if ai_vs_ai_mode:
		# Trigger next AI's move
		if b.team_to_move == Team.PLAYER:
			ai_thread1.process_board(b)
		else:
			ai_thread2.process_board(b)
		return
	
	if b.team_to_move == player_team:
		if _pointer_down or _is_dragging:
			_pending_premove_execute = true
		else:
			_try_execute_premove()

func _on_game_over(game_result: Match.Result) -> void:
	game_over.emit(game_result)
	if game_result == Match.Result.WIN or game_result == Match.Result.LOSE:
		var defeated_team: Team = b.team_to_move
		var defeated_king_node: PieceNode = piece_nodes.get_king_node(defeated_team)
		
		var particles: OneShotParticles = load("res://frontend/vfx/capture_particles.tscn").instantiate()
		particles.position = defeated_king_node.position
		get_tree().root.add_child(particles)

		for tile_node: TileNode in tile_nodes.get_all_tile_nodes():
			var distance := tile_node.pos().distance_to(defeated_king_node.piece().pos)
			tile_node.animate_flash(1.2, 0.4, distance * 0.10)
		
		GameCamera.get_instance().shake(0.5, 3)
	else:
		GameCamera.get_instance().shake(0.3, 2)


func _on_ai_thread_move_found(move: Move) -> void:
	var from := move.from
	var to := move.to
	var from_node := piece_nodes.get_piece_node_by_pos(from)
	if from_node == null:
		return
	var piece_id := from_node.id()
	var captured_piece_id := 0
	if move.is_capture():
		var captured_pos := to
		if move.is_en_passant():
			captured_pos = Vector2i(to.x, from.y)
		var captured_node := piece_nodes.get_piece_node_by_pos(captured_pos)
		if captured_node:
			captured_piece_id = captured_node.id()
	var move_action: MoveAction = MoveAction.new(piece_id, to, move.info, move.promo_info, captured_piece_id)
	perform_move_action(move_action)
	end_ai_turn()

#region utils

func _can_select(piece_node: PieceNode) -> bool:
	return piece_node.piece().team == player_team

func _can_capture(piece_node: PieceNode) -> bool:
	var available_moves := b.get_available_moves_from(selected_piece_node.piece().pos)
	for move: Move in available_moves:
		if move.is_capture() and move.to == piece_node.piece().pos:
			return true
		assert(move.to != piece_node.piece().pos, "you shouldn't be able to move here without a capture flag")
	return false

func _can_move_to_pos(target_pos: Vector2i) -> bool:
	var available_moves := b.get_available_moves_from(selected_piece_node.piece().pos)
	for move: Move in available_moves:
		if move.to == target_pos:
			return true
	return false

func _get_available_move_to(target: Vector2i) -> Move:
	var available_moves := b.get_available_moves_from(selected_piece_node.piece().pos)
	for move: Move in available_moves:
		if move.to == target:
			return move
	return null

func _get_castle_move_to(pos: Vector2i) -> Move:
	if not selected_piece_node:
		return null
	for move: Move in b.get_available_moves_from(selected_piece_node.piece().pos):
		if move.is_castle() and move.to == pos:
			return move
	return null

func _get_premove_targets(from: Vector2i) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	if not b.piece_map.has_piece(from):
		return targets
	var piece := b.piece_map.get_piece(from)
	if piece.team != player_team:
		return targets
	var seen: Dictionary = {}
	for move: Move in piece.get_available_moves(b):
		if not seen.has(move.to):
			targets.append(move.to)
			seen[move.to] = true
	for tile_node: TileNode in tile_nodes.get_all_tile_nodes():
		var target_pos := tile_node.pos()
		if seen.has(target_pos):
			continue
		if _is_premove_capture_target(piece, target_pos):
			targets.append(target_pos)
			seen[target_pos] = true
	return targets

func _is_premove_capture_target(piece: Piece, target_pos: Vector2i) -> bool:
	if not b.tile_map.has_tile(target_pos):
		return false
	if not piece.is_attacking_square(target_pos, b):
		return false
	if not b.piece_map.has_piece(target_pos):
		return true
	var occupant := b.piece_map.get_piece(target_pos)
	if occupant.team.is_hostile_to(piece.team):
		return true
	# Recapture premove: destination currently has a friendly piece (e.g. piece opponent is about to capture)
	return occupant.team == piece.team

func _can_premove_to(from_piece: PieceNode, target_pos: Vector2i) -> bool:
	for target: Vector2i in _get_premove_targets(from_piece.piece().pos):
		if target == target_pos:
			return true
	return false

func _build_premove_action(from_piece: PieceNode, target_pos: Vector2i) -> MoveAction:
	var piece := from_piece.piece()
	var from := piece.pos
	for move: Move in piece.get_available_moves(b):
		if move.to != target_pos:
			continue
		var captured_piece_id := 0
		if move.is_capture():
			var captured_pos := target_pos
			if move.is_en_passant():
				captured_pos = Vector2i(target_pos.x, from.y)
			if b.piece_map.has_piece(captured_pos):
				captured_piece_id = piece_nodes.get_piece_node_by_pos(captured_pos).id()
		return MoveAction.new(from_piece.id(), target_pos, move.info, Piece.Type.UNSET, captured_piece_id)
	if _is_premove_capture_target(piece, target_pos):
		var captured_piece_id := 0
		if b.piece_map.has_piece(target_pos):
			var occupant := b.piece_map.get_piece(target_pos)
			if occupant.team.is_hostile_to(piece.team):
				captured_piece_id = piece_nodes.get_piece_node_by_pos(target_pos).id()
		return MoveAction.new(from_piece.id(), target_pos, Move.CAPTURE, Piece.Type.UNSET, captured_piece_id)
	return null

func _set_premove(from_piece: PieceNode, target_pos: Vector2i) -> void:
	if not Settings.premoving_enabled:
		return
	var action := _build_premove_action(from_piece, target_pos)
	if action == null:
		return
	premove_action = action
	_show_premove_highlight(from_piece.piece().pos, target_pos)
	_select_piece_node(null)

func _show_premove_highlight(from: Vector2i, to: Vector2i) -> void:
	tile_nodes.highlight_premove_squares([from, to])

func _clear_premove() -> void:
	premove_action = null
	tile_nodes.clear_premove_highlight()

func _is_premove_still_valid() -> bool:
	if premove_action == null:
		return false
	if not piece_nodes.has_piece_node(premove_action.piece_id):
		return false
	var piece_node := piece_nodes.get_piece_node(premove_action.piece_id)
	if not b.piece_map.has_piece(piece_node.piece().pos):
		return false
	return b.piece_map.get_piece(piece_node.piece().pos).team == player_team

func _try_execute_premove() -> void:
	if not Settings.premoving_enabled:
		_clear_premove()
		return
	if not _is_premove_still_valid():
		_clear_premove()
		return
	if b.team_to_move != player_team:
		return
	
	var action := premove_action
	_clear_premove()
	
	var piece_node := piece_nodes.get_piece_node(action.piece_id)
	selected_piece_node = piece_node
	var target_piece_node: PieceNode = null
	if b.piece_map.has_piece(action.to):
		target_piece_node = piece_nodes.get_piece_node_by_pos(action.to)
	if not _attempt_move_to(action.to, target_piece_node):
		GameCamera.get_instance().shake(0.1, 1.0)

func _attempt_move_to(target_pos: Vector2i, target_piece_node: PieceNode = null) -> bool:
	if not selected_piece_node:
		return false
	if b.team_to_move != player_team:
		return false
	
	assert(selected_piece_node.piece().team == player_team)
	
	var castle_move := _get_castle_move_to(target_pos)
	if castle_move != null:
		var castle_action := MoveAction.new(selected_piece_node.id(), castle_move.to, castle_move.info)
		perform_move_action(castle_action)
		end_player_turn()
		return true
	
	if target_piece_node and _can_capture(target_piece_node):
		if b.tile_map.is_promotion_tile(target_piece_node.piece().pos, player_team) and selected_piece_node.piece().type == Piece.Type.PAWN:
			temp_move_action = MoveAction.new(selected_piece_node.id(), target_piece_node.piece().pos, Move.CAPTURE, Piece.Type.UNSET, target_piece_node.id())
			input_state = InputState.CHOOSING_PROMOTION
			promotion_ui.show()
			return true
		var capture_action := MoveAction.new(selected_piece_node.id(), target_piece_node.piece().pos, Move.CAPTURE, Piece.Type.UNSET, target_piece_node.id())
		perform_move_action(capture_action)
		end_player_turn()
		return true
	
	if not _can_move_to_pos(target_pos):
		return false
	
	var target_move := _get_available_move_to(target_pos)
	if b.tile_map.is_promotion_tile(target_pos, player_team) and selected_piece_node.piece().type == Piece.Type.PAWN:
		temp_move_action = MoveAction.new(selected_piece_node.id(), target_pos, 0, Piece.Type.UNSET)
		input_state = InputState.CHOOSING_PROMOTION
		promotion_ui.show()
		return true
	if target_move != null and target_move.is_en_passant():
		var captured_pos := Vector2i(target_pos.x, selected_piece_node.piece().pos.y)
		var captured_node := piece_nodes.get_piece_node_by_pos(captured_pos)
		if captured_node == null:
			return false
		var captured_piece_id := captured_node.id()
		var en_passant_action := MoveAction.new(selected_piece_node.id(), target_pos, target_move.info, Piece.Type.UNSET, captured_piece_id)
		perform_move_action(en_passant_action)
		end_player_turn()
		return true
	
	var move_info: int = target_move.info if target_move else 0
	if move_info & Move.CAPTURE:
		move_info = move_info & ~Move.CAPTURE
	var move_action := MoveAction.new(selected_piece_node.id(), target_pos, move_info)
	perform_move_action(move_action)
	end_player_turn()
	return true

#endregion

func _resolve_captured_piece_node(move_action: MoveAction, moving_piece_node: PieceNode) -> PieceNode:
	if move_action.captured_piece_id != 0 and piece_nodes.has_piece_node(move_action.captured_piece_id):
		return piece_nodes.get_piece_node(move_action.captured_piece_id)
	if not move_action.is_capture():
		return null
	var captured_pos := move_action.to
	if move_action.is_en_passant():
		captured_pos = Vector2i(move_action.to.x, moving_piece_node.piece().pos.y)
	if not b.piece_map.has_piece(captured_pos):
		return null
	return piece_nodes.get_piece_node_by_pos(captured_pos)

func perform_move_action(move_action: MoveAction) -> void:
	assert(move_action)
	assert(state == BoardNodeState.INITIALIZED)
	
	if _is_dragging or _drag_piece_node:
		_abort_drag(false)
	
	if not piece_nodes.has_piece_node(move_action.piece_id):
		_clear_premove()
		return
	
	var piece_node: PieceNode = piece_nodes.get_piece_node(move_action.piece_id)
	var prev_team_to_move := b.team_to_move
	var captured_piece_node: PieceNode = _resolve_captured_piece_node(move_action, piece_node)

	# For castling, capture the rook's node and destination before the board
	# state changes (the rook's original square becomes empty afterwards)
	var castle_rook_node: PieceNode = null
	var castle_rook_to := Vector2i.ZERO
	if move_action.is_castle():
		var king_from := piece_node.piece().pos
		var castle_dir := Vector2i.RIGHT if move_action.to.x > king_from.x else Vector2i.LEFT
		var rook_from := king_from + castle_dir
		while b.tile_map.has_tile(rook_from) and not b.piece_map.has_piece(rook_from):
			rook_from += castle_dir
		assert(b.piece_map.has_piece(rook_from), "Castling rook not found")
		castle_rook_node = piece_nodes.get_piece_node_by_pos(rook_from)
		castle_rook_to = king_from + castle_dir

	var move_info := move_action.info
	if move_action.is_capture() and captured_piece_node == null:
		move_info = move_info & ~Move.CAPTURE
		move_info = move_info & ~Move.EN_PASSANT

	# Update backend board state
	b = b.perform_move(Move.new(piece_node.piece().pos, move_action.to, move_info, move_action.promo_info))
	
	# Handle captures
	if captured_piece_node:
		var shake_intensity := minf(2.0, captured_piece_node.piece().get_worth() * 0.15)
		GameCamera.get_instance().shake(0.2, shake_intensity)
		var capture_particles: Node2D = preload("res://frontend/vfx/capture_particles.tscn").instantiate()
		add_child(capture_particles)
		capture_particles.position = captured_piece_node.position + Vector2(0, 5)
		if piece_nodes.has_piece_node(captured_piece_node.id()):
			piece_nodes.free_piece_node(captured_piece_node.id())
	elif move_action.is_check():
		GameCamera.get_instance().shake(0.2, 2.0)
	
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

		piece_node.move_to(tile_nodes.get_tile_node(move_action.to).position, true)
	else:
		# Update piece position in the UI
		piece_node.move_to(tile_nodes.get_tile_node(move_action.to).position)
	
	piece_node.set_piece(b.piece_map.get_piece(move_action.to))

	# Move the rook for castling. This must happen before the generic update
	# loop below, which would otherwise look up the rook at its now-empty
	# original square.
	if move_action.is_castle():
		assert(castle_rook_node)
		castle_rook_node.move_to(tile_nodes.get_tile_node(castle_rook_to).position)
		castle_rook_node.set_piece(b.piece_map.get_piece(castle_rook_to))
	
	# Animate target tile color
	var tile_node: TileNode = tile_nodes.get_tile_node(move_action.to)
	tile_node.animate_flash(1.2)
	
	# For each other piece node, set piece to be the new piece in the new board
	for p: PieceNode in piece_nodes.get_all_piece_nodes():
		if p != piece_node and !p.is_queued_for_deletion():
			p.set_piece(b.piece_map.get_piece(p.piece().pos))

	# Reset selection state if the move just now was made by the player
	if prev_team_to_move == player_team:
		_select_piece_node(null)
	else:
		# Otherwise, show available moves for the player's next turn
		if selected_piece_node:
			if selected_piece_node.piece() != b.piece_map.get_piece(selected_piece_node.piece().pos):
				# If the selected piece is no longer on the board
				selected_piece_node = null
			else: # Selected piece is still on the board
				var available_moves := b.get_available_moves_from(selected_piece_node.piece().pos)
				var tiles_to_highlight: Array[Vector2i] = []
				for move: Move in available_moves:
					tiles_to_highlight.append(move.to)
				tile_nodes.highlight_tiles(tiles_to_highlight)
	if input_state != InputState.CHOOSING_PROMOTION:
		input_state = InputState.NONE
	
	if not _is_premove_still_valid():
		_clear_premove()

func start_ai_vs_ai() -> void:
	ai_vs_ai_mode = true
	ai_thread1.process_board(b)

func stop_ai_vs_ai() -> void:
	ai_vs_ai_mode = false

#region helper functions

func _reset_board_state() -> void:
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
		premove_action = null
		_pointer_down = false
		_active_pointer_id = -1
		_is_dragging = false
		_drag_piece_node = null
		_press_piece_node = null
		_pending_premove_execute = false
		_suppress_click_signals = false
		tile_nodes.clear_premove_highlight()

func _create_board_ui() -> void:
	# Create UI elements
	tile_nodes.create_tile_nodes(b.tile_map.get_all_tiles())
	var pieces := b.piece_map.get_all_pieces()
	for piece in pieces:
		var piece_node := piece_nodes.spawn_piece(piece, true)
		assert(b.piece_map.has_piece(piece_node.piece().pos))
		assert(b.piece_map.get_piece(piece_node.piece().pos) == piece_node.piece())
	
	assert(piece_nodes.get_all_piece_nodes().size() == pieces.size(), "Did not spawn all pieces")

func _trigger_ai_move() -> void:
	if b.team_to_move == Team.PLAYER:
		ai_thread1.process_board(b)
	else:
		ai_thread2.process_board(b)

#endregion
