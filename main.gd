extends Node3D

@onready var board: Board = $Board

var selected_piece: Piece
var ai: = AI.new()

func _ready() -> void:
	board.generate_tiles()
	board.generate_pieces()

func _on_board_tile_selected(tile: Tile) -> void:
	if not board.state.current_turn == Team.s.ALLY_PLAYER:
		return
	
	assert(tile, "Tile cannot be null")
	assert(board.state.has_tile(tile.pos()), "Board must have this tile")
	
	var piece: = board.state.get_piece(tile.pos())

	if selected_piece:
		if not piece:
			# Check if valid
			if not selected_piece.get_available_squares(board.state).has(tile.pos()):
				unselect_previous_piece()
				return
			move_piece(Move.new(selected_piece, tile.pos()))
			do_enemy_turn()
		elif Team.hostile_to_each_other(piece.team(), selected_piece.team()):
			move_piece(Move.new(selected_piece, tile.pos()))
			do_enemy_turn()
		else:
			unselect_previous_piece() 
			select_piece(piece)
	else:
		if piece:
			if Team.is_ally(piece.team()):
				select_piece(piece)
		else:
			unselect_previous_piece()

func move_piece(move: Move) -> void:
	for square_pos: Vector2i in selected_piece.get_available_squares(board.state):
		board.state.get_tile(square_pos).set_show_dot(false)
	board.perform_move(move)
	
	board.state.current_turn = Team.s.ENEMY_AI_0

func do_enemy_turn() -> void:
	print("Doing enemy turn")
	var best_result: = ai.get_best_result(board.state, 1, -INF, INF, Team.s.ENEMY_AI_0)
	board.perform_move(best_result.move)
	print("Performed move, eval = %s" % best_result.evaluation)
	board.state.current_turn = Team.s.ALLY_PLAYER

func select_piece(piece: Piece) -> void:
	selected_piece = piece
	for square_pos: Vector2i in piece.get_available_squares(board.state):
		board.state.get_tile(square_pos).set_show_dot(true)

func unselect_previous_piece() -> void:
	if not selected_piece: return
	for square_pos: Vector2i in selected_piece.get_available_squares(board.state):
		board.state.get_tile(square_pos).set_show_dot(false)
	selected_piece = null
