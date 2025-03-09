extends Node2D

@onready var num_factions: int = Config.factions.size()
@onready var faction_slider: Node2D = $FactionSlider
@onready var initial_slider_pos: Vector2 = faction_slider.position

var current_faction_idx: int = 0

func _move_slider() -> void:
	var faction_node: Node2D = faction_slider.get_child(current_faction_idx)
	var slider_target_pos: = -faction_node.position + initial_slider_pos
	var tw: = faction_slider.create_tween()
	tw.tween_property(faction_slider, "position", slider_target_pos, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_right_button_pressed() -> void:
	current_faction_idx = (current_faction_idx + 1) % num_factions
	_move_slider()

func _on_left_button_pressed() -> void:
	current_faction_idx = (current_faction_idx - 1) % num_factions
	_move_slider()

func _on_start_button_pressed() -> void:
	var game: Game = load("res://frontend/game.tscn").instantiate()
	get_tree().root.add_child(game)
	queue_free()
