extends Node2D

@onready var board: Board = $Board

var selected_piece: Piece
var ai: = AI.new()

var ai_thread: Thread
var semaphore: Semaphore
var mutex: Mutex
var exit_thread: = false

var ai_move_queue: Array[Move] = []

func _ready() -> void:
	board.generate_tiles()
	board.generate_pieces()
	
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	ai_thread = Thread.new()
	ai_thread.start(ai_thread_func)

func _process(_delta: float) -> void:
	mutex.lock()
	if ai_move_queue.is_empty():
		mutex.unlock()
		return
	var move: Move = ai_move_queue.pop_front()
	assert(board.state.current_turn.is_enemy())
	mutex.unlock()
	
	board.perform_move(move)

func _on_board_tile_selected(tile: Tile) -> void:
	#if not board.state.current_turn.is_player():
		#return
	
	assert(tile, "Tile cannot be null")
	assert(board.state.has_tile(tile.pos()), "Board must have this tile")
	
	var piece: = board.get_piece(board.state.get_piece_state(tile.pos()).id) if board.state.has_piece(tile.pos()) else null

	if selected_piece:
		# Check if valid
		if not selected_piece.state().get_available_squares(board.state).has(tile.pos()):
			unselect_previous_piece()
			return
		if not piece:
			move_piece(Move.new(selected_piece.state().id, selected_piece.state().pos, tile.pos()))
			unselect_previous_piece() 
			do_enemy_turn()
		elif piece.state().team.is_hostile_to(selected_piece.state().team):
			move_piece(Move.new(selected_piece.state().id, selected_piece.state().pos, tile.pos()))
			unselect_previous_piece() 
			do_enemy_turn()
		else:
			unselect_previous_piece() 
			select_piece(piece)
	else:
		if piece:
			if piece.state().team.is_player():
				select_piece(piece)
		else:
			unselect_previous_piece()

func move_piece(move: Move) -> void:
	for square_pos: Vector2i in selected_piece.state().get_available_squares(board.state):
		board.state.get_tile(square_pos).set_show_dot(false)
	board.perform_move(move)

func do_enemy_turn() -> void:
	print("Doing enemy turn")
	assert(board.state.current_turn == Team.ENEMY_AI)
	semaphore.post()

func ai_thread_func() -> void:
	print("AI Thread started")
	while true:
		semaphore.wait()
		mutex.lock()
		var should_exit: = exit_thread
		var board_state: = board.state
		mutex.unlock()
		if should_exit:
			break
		
		print("AI thinking...")
		var start_time: = Time.get_ticks_msec()
		var best_result: = ai.get_best_result(board_state, 6)
		var end_time: = Time.get_ticks_msec()
		print("Found move after %s ms" % (end_time - start_time))
		print("Result: %s" % best_result)
		
		mutex.lock()
		ai_move_queue.append(best_result.move)
		mutex.unlock()

func select_piece(piece: Piece) -> void:
	selected_piece = piece
	for square_pos: Vector2i in piece.state().get_available_squares(board.state):
		board.state.get_tile(square_pos).set_show_dot(true)

func unselect_previous_piece() -> void:
	if not selected_piece: return
	for square_pos: Vector2i in selected_piece.state().get_available_squares(board.state):
		board.state.get_tile(square_pos).set_show_dot(false)
	selected_piece = null

func _exit_tree() -> void:
	mutex.lock()
	exit_thread = true # Protect with Mutex.
	mutex.unlock()

	# Unblock by posting.
	semaphore.post()

	# Wait until it exits.
	ai_thread.wait_to_finish()
