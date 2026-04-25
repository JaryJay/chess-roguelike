class_name Game extends Node2D

## Number of wins needed to complete a run.
const RUN_TARGET_WINS: int = 5

@onready var board: BoardNode = $BoardNode
@onready var game_over_label: Label = $GameOverLayer/Rect/H/Label
@onready var game_over_rect: Control = $GameOverLayer/Rect
@onready var settings_rect: Control = $SettingsLayer/Rect
@onready var upgrade_select_ui: UpgradeSelectUI = $UpgradeSelectUI
@onready var win_counter_label: Label = $UILayer/WinCounterLabel
@onready var thinking_label: Label = $UILayer/ThinkingLabel
@onready var continue_button: Button = %ContinueButton

var audio_manager: AudioManager = null

var game_setup: GameSetup
var saved_game_result: Match.Result

var wins_this_run: int = 0
var _run_complete: bool = false

func init_with_game_setup(_game_setup: GameSetup) -> void:
	self.game_setup = _game_setup
	# Create AudioManager if it doesn't exist yet
	if audio_manager == null:
		audio_manager = AudioManager.new()
		audio_manager.name = "AudioManager"
		add_child(audio_manager)
	_connect_board_signals()
	board.init_with_game_setup(_game_setup)
	_update_win_counter_label()

func init_randomly() -> void:
	board.init_randomly()

func _connect_board_signals() -> void:
	if not board.game_over.is_connected(_on_board_node_game_over):
		board.game_over.connect(_on_board_node_game_over)
	if not board.thinking_changed.is_connected(_on_board_thinking_changed):
		board.thinking_changed.connect(_on_board_thinking_changed)
	if not board.sound_event.is_connected(_on_board_sound_event):
		board.sound_event.connect(_on_board_sound_event)

func _update_win_counter_label() -> void:
	if is_instance_valid(win_counter_label):
		win_counter_label.text = "Wins: %d / %d" % [wins_this_run, RUN_TARGET_WINS]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_settings"):
		if settings_rect.visible:
			_close_settings()
		else:
			_open_settings()
		get_viewport().set_input_as_handled()

func _on_board_thinking_changed(is_thinking: bool) -> void:
	if is_instance_valid(thinking_label):
		thinking_label.visible = is_thinking

func _on_board_sound_event(event_name: String) -> void:
	if is_instance_valid(audio_manager):
		audio_manager.on_sound_event(event_name)

func _on_board_node_game_over(game_result: Match.Result) -> void:
	saved_game_result = game_result
	_run_complete = false

	if game_result == Match.Result.WIN:
		wins_this_run += 1
		_update_win_counter_label()
		if wins_this_run >= RUN_TARGET_WINS:
			_run_complete = true
			game_over_label.text = "Run Complete! 🎉\n%d wins!" % wins_this_run
			continue_button.text = "Back to Menu"
		elif wins_this_run == 1:
			game_over_label.text = "You win!\n1 win this run"
		else:
			game_over_label.text = "You win!\n%d wins this run" % wins_this_run
	elif game_result == Match.Result.LOSE:
		game_over_label.text = "You lose!\n%d win%s this run" % [wins_this_run, "" if wins_this_run == 1 else "s"]
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
	continue_button.text = "Continue"

	# Run complete — return to game creation
	if _run_complete:
		get_tree().change_scene_to_file("res://frontend/ui/game_creation.tscn")
		queue_free()
		return

	match saved_game_result:
		Match.Result.WIN:
			# Apply enemy credit increment, capped at max_enemy_credits (0 means no cap)
			game_setup.enemy_credits += game_setup.difficulty.enemy_credit_increment
			var cap := game_setup.difficulty.max_enemy_credits
			if cap > 0:
				game_setup.enemy_credits = mini(game_setup.enemy_credits, cap)
			upgrade_select_ui.show()
			upgrade_select_ui.generate_upgrades(game_setup)
		Match.Result.LOSE:
			get_tree().change_scene_to_file("res://frontend/ui/game_creation.tscn")
			queue_free()
		_: # Draw
			# Enemy gets stronger, but you don't get an upgrade
			game_setup.enemy_credits += game_setup.difficulty.enemy_credit_increment
			var cap := game_setup.difficulty.max_enemy_credits
			if cap > 0:
				game_setup.enemy_credits = mini(game_setup.enemy_credits, cap)
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
	_connect_board_signals()
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

