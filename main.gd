class_name Main extends Node2D

func _on_new_game_button_pressed() -> void:
	var game: Node = load("res://frontend/game.tscn").instantiate()
	get_tree().root.add_child(game)
	queue_free()

func _on_exit_button_pressed() -> void:
	get_tree().quit()
