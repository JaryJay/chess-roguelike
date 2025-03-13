class_name Main extends Node2D

@onready var version_label: Label = $UI/Control/VersionLabel

func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version")
	version_label.text = "v%s" % version
	Config.load_config()
	PieceRules.load_pieces()

func _on_new_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://frontend/ui/game_creation.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()
