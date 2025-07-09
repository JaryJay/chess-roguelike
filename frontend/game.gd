class_name Game extends Node2D

@onready var board: BoardNode = $BoardNode
@onready var game_over_label: Label = $GameOverLayer/Rect/H/Label
@onready var game_over_rect: Control = $GameOverLayer/Rect
@onready var settings_rect: Control = $SettingsLayer/Rect
@onready var upgrade_select_ui: UpgradeSelectUI = $UpgradeSelectUI

var game_setup: GameSetup
var saved_game_result: Match.Result

var wins_this_run: int = 0

func init_with_game_setup(_game_setup: GameSetup) -> void:
	self.game_setup = _game_setup
	board.init_with_game_setup(_game_setup)

func init_randomly() -> void:
	board.init_randomly()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_settings"):
		if settings_rect.visible:
			_close_settings()
		else:
			_open_settings()
		get_viewport().set_input_as_handled()

func _on_board_node_game_over(game_result: Match.Result) -> void:
	saved_game_result = game_result
	if game_result == Match.Result.WIN:
		wins_this_run += 1
		if wins_this_run == 1:
			game_over_label.text = "You win!\n1 win this run"
		else:
			game_over_label.text = "You win!\n%s wins this run" % wins_this_run
	elif game_result == Match.Result.LOSE:
		game_over_label.text = "You lose!"
	elif game_result == Match.Result.DRAW_STALEMATE:
		game_over_label.text = "Stalemate!"
	elif game_result == Match.Result.DRAW_INSUFFICIENT_MATERIAL:
		game_over_label.text = "Draw! Insufficient material"
	elif game_result == Match.Result.DRAW_THREEFOLD_REPETITION:
		game_over_label.text = "Draw! Threefold repetition"
	
	game_over_rect.show()
	game_over_rect.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_property(game_over_rect, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)

func _on_continue_button_pressed() -> void:
	board.queue_free()
	for piece_node: PieceNode in get_tree().get_nodes_in_group("piece_nodes"):
		piece_node.remove_from_group("piece_nodes")
	for tile_node: TileNode in get_tree().get_nodes_in_group("tile_nodes"):
		tile_node.remove_from_group("tile_nodes")
	game_over_rect.hide()
	settings_rect.hide()
	
	match saved_game_result:
		Match.Result.WIN:
			game_setup.enemy_credits += game_setup.difficulty.enemy_credit_increment
			upgrade_select_ui.show()
			upgrade_select_ui.generate_upgrades(game_setup)
		Match.Result.LOSE:
			get_tree().change_scene_to_file("res://frontend/ui/game_creation.tscn")
			queue_free()
		_: # Draw
			# Enemy gets stronger, but you don't get an upgrade
			game_setup.enemy_credits += game_setup.difficulty.enemy_credit_increment
			recreate_board()

func _on_concede_button_pressed() -> void:
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

func _open_settings() -> void:
	settings_rect.show()
	settings_rect.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(settings_rect, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)

func _close_settings() -> void:
	var tw := create_tween()
	tw.tween_property(settings_rect, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tw.tween_callback(settings_rect.hide)

func _on_settings_button_pressed() -> void:
	_open_settings()

func _on_back_button_pressed() -> void:
	_close_settings()
