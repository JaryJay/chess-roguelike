class_name Main extends Node2D

@onready var version_label: Label = $UI/Control/VersionLabel

func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version")
	version_label.text = "v%s" % version
	Config.load_config()
	PieceRules.load_pieces()
	Upgrades.load_upgrades()

func _on_new_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://frontend/ui/game_creation.tscn")

func _on_classic_game_button_pressed() -> void:
	var game: Game = load("res://frontend/game.tscn").instantiate()
	get_tree().root.add_child(game)
	var setup := GameSetup.new()
	setup.difficulty = Config.difficulties[-1]
	setup.classic_mode = true
	game.init_with_game_setup(setup)
	queue_free()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

