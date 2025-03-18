class_name Game extends Node2D

@onready var board: BoardNode = $BoardNode
@onready var game_over_label: Label = $GameOverLayer/Rect/H/Label
@onready var game_over_layer: CanvasLayer = $GameOverLayer
@onready var settings_layer: CanvasLayer = $SettingsLayer
@onready var upgrade_select_ui: UpgradeSelectUI = $UpgradeSelectUI

var game_setup: GameSetup
var saved_game_result: Match.Result

func init_with_game_setup(_game_setup: GameSetup) -> void:
	self.game_setup = _game_setup
	board.init_with_game_setup(_game_setup)

func init_randomly() -> void:
	board.init_randomly()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_settings"):
		settings_layer.visible = !settings_layer.visible
		get_viewport().set_input_as_handled()

func _on_board_node_game_over(game_result: Match.Result) -> void:
	saved_game_result = game_result
	if game_result == Match.Result.WIN:
		game_over_label.text = "You win!"
	elif game_result == Match.Result.LOSE:
		game_over_label.text = "You lose!"
	elif game_result == Match.Result.DRAW_STALEMATE:
		game_over_label.text = "Stalemate!"
	elif game_result == Match.Result.DRAW_INSUFFICIENT_MATERIAL:
		game_over_label.text = "Draw! Insufficient material"
	elif game_result == Match.Result.DRAW_THREEFOLD_REPETITION:
		game_over_label.text = "Draw! Threefold repetition"
	game_over_layer.show()

func _on_restart_button_pressed() -> void:
	board.queue_free()
	for piece_node: PieceNode in get_tree().get_nodes_in_group("piece_nodes"):
		piece_node.remove_from_group("piece_nodes")
	for tile_node: TileNode in get_tree().get_nodes_in_group("tile_nodes"):
		tile_node.remove_from_group("tile_nodes")
	game_over_layer.hide()
	settings_layer.hide()
	
	if saved_game_result == Match.Result.WIN:
		game_setup.enemy_credits += 100
		upgrade_select_ui.show()
		upgrade_select_ui.generate_upgrades(game_setup)
	else:
		get_tree().change_scene_to_file("res://frontend/ui/game_creation.tscn")
		queue_free()

func _on_upgrade_select_ui_upgrade_chosen(upgrade: Upgrade) -> void:
	upgrade.apply(game_setup)
	upgrade_select_ui.hide()
	recreate_board()

func recreate_board() -> void:
	board = load("res://frontend/board/board_node.tscn").instantiate()
	add_child(board)
	board.game_over.connect(_on_board_node_game_over)
	board.init_with_game_setup(game_setup)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	settings_layer.show()

func _on_back_button_pressed() -> void:
	settings_layer.hide()
