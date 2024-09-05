extends Node3D

@onready var board: Board = $Board

var selected_tile: Tile

func _ready() -> void:
	board.generate_tiles()
	board.generate_pieces()


func _on_board_tile_selected(tile: Tile) -> void:
	print("pressed tile @ %v" % tile.pos)
	
	assert(tile, "Tile cannot be null")
	assert(board.has_tile(tile.pos), "Board must have this tile")
	assert(board.get_piece(tile.pos), "Cannot select empty tile")
	
	var piece: = board.get_piece(tile.pos)
	for square_pos: Vector2i in piece.get_available_squares(board):
		board.get_tile(square_pos).set_show_dot(true)
	
