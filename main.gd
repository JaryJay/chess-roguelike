extends Node3D

@onready var board: Board = $Board

var selected_piece: Piece

func _ready() -> void:
	board.generate_tiles()
	board.generate_pieces()

func _on_board_tile_selected(tile: Tile) -> void:
	print("pressed tile @ %v" % tile.pos)

	assert(tile, "Tile cannot be null")
	assert(board.has_tile(tile.pos), "Board must have this tile")
	#assert(board.get_piece(tile.pos), "Cannot select tile without piece")

	#unselect_previous_piece()

	var piece: = board.get_piece(tile.pos)

	if selected_piece:
		if not piece:
			# Check if valid
			if not selected_piece.get_available_squares(board).has(tile.pos):
				unselect_previous_piece()
				return
			for square_pos: Vector2i in selected_piece.get_available_squares(board):
				board.get_tile(square_pos).set_show_dot(false)
			board.move_piece(selected_piece, tile.pos)
			for square_pos: Vector2i in selected_piece.get_available_squares(board):
				board.get_tile(square_pos).set_show_dot(true)
		elif Team.hostile_to_each_other(piece.team(), selected_piece.team()):
			for square_pos: Vector2i in selected_piece.get_available_squares(board):
				board.get_tile(square_pos).set_show_dot(false)
			board.move_piece(selected_piece, tile.pos)
			for square_pos: Vector2i in selected_piece.get_available_squares(board):
				board.get_tile(square_pos).set_show_dot(true)
		else:
			unselect_previous_piece()
			select_piece(piece)
	else:
		if piece:
			if Team.is_ally(piece.team()):
				select_piece(piece)
		else:
			unselect_previous_piece()

func select_piece(piece: Piece) -> void:
	selected_piece = piece
	for square_pos: Vector2i in piece.get_available_squares(board):
		board.get_tile(square_pos).set_show_dot(true)

func unselect_previous_piece() -> void:
	if not selected_piece: return

	for square_pos: Vector2i in selected_piece.get_available_squares(board):
		board.get_tile(square_pos).set_show_dot(false)
