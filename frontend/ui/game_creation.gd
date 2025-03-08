extends Node2D

enum Faction {
	MONARCHY,
	SHARPSHOOTERS,
	MILITARY,
	THE_SQUAD,
}
static var num_factions: int = Faction.size()

var current_faction: Faction = Faction.MONARCHY

@onready var faction_slider: Node2D = $FactionSlider
@onready var initial_slider_pos: Vector2 = faction_slider.position

func _move_slider() -> void:
	var faction_node: Node2D = faction_slider.get_child(current_faction)
	var slider_target_pos: = -faction_node.position + initial_slider_pos
	var tw: = faction_slider.create_tween()
	tw.tween_property(faction_slider, "position", slider_target_pos, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_right_button_pressed() -> void:
	current_faction = (current_faction + 1) % num_factions as Faction
	_move_slider()

func _on_left_button_pressed() -> void:
	current_faction = (current_faction - 1) % num_factions as Faction
	_move_slider()

func _on_start_button_pressed() -> void:
	var game: Game = load("res://frontend/game.tscn").instantiate()
	get_tree().root.add_child(game)
	queue_free()
