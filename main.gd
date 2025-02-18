extends Node2D

@onready var board: BoardNode = $BoardNode
@onready var game_over_label: Label = $CanvasLayer/GameOverScreen/Label
@onready var game_over_screen: Control = $CanvasLayer/GameOverScreen

func _enter_tree() -> void:
	Config.load_config()
	PieceRules.load_pieces()

func _ready() -> void:
	board.init_randomly()

func _on_board_node_game_over(game_result: Game.Result) -> void:
	if game_result == Game.Result.WIN:
		game_over_label.text = "You win!"
	elif game_result == Game.Result.LOSE:
		game_over_label.text = "You lose!"
	elif game_result == Game.Result.STALEMATE:
		game_over_label.text = "Stalemate!"
	game_over_screen.show()

func _on_restart_button_pressed() -> void:
	board.queue_free()
	for piece_node: PieceNode in get_tree().get_nodes_in_group("piece_nodes"):
		piece_node.remove_from_group("piece_nodes")
	for tile_node: TileNode in get_tree().get_nodes_in_group("tile_nodes"):
		tile_node.remove_from_group("tile_nodes")
	board = load("res://frontend/board/board_node.tscn").instantiate()
	add_child(board)
	board.game_over.connect(_on_board_node_game_over)
	board.init_randomly()
	game_over_screen.hide()
