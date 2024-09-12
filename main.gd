extends Node2D

@onready var board: Board = $Board

var selected_piece: Piece
var ai: = AI.new()

func _ready() -> void:
	board.generate_tiles()
	board.generate_pieces()

func _on_board_tile_selected(tile: Tile) -> void:
	#if not board.state.current_turn.is_player():
		#return
	
	assert(tile, "Tile cannot be null")
	assert(board.state.has_tile(tile.pos()), "Board must have this tile")
	
	var piece: = board.get_piece(board.state.get_piece_state(tile.pos()).id) if board.state.has_piece(tile.pos()) else null

	if selected_piece:
		if not piece:
			# Check if valid
			if not selected_piece.state().get_available_squares(board.state).has(tile.pos()):
				unselect_previous_piece()
				return
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
	board.state.current_turn = Team.ENEMY_AI
	var best_result: = ai.get_best_result(board.state, 6, -INF, INF)
	board.perform_move(best_result.move)
	print("Performed move, eval = %s" % best_result.evaluation)
	board.state.current_turn = Team.PLAYER

func select_piece(piece: Piece) -> void:
	selected_piece = piece
	for square_pos: Vector2i in piece.state().get_available_squares(board.state):
		board.state.get_tile(square_pos).set_show_dot(true)

func unselect_previous_piece() -> void:
	if not selected_piece: return
	for square_pos: Vector2i in selected_piece.state().get_available_squares(board.state):
		board.state.get_tile(square_pos).set_show_dot(false)
	selected_piece = null
