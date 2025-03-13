extends Node2D

@onready var num_factions: int = Config.factions.size()
@onready var faction_slider: Node2D = $FactionSlider
@onready var initial_slider_pos: Vector2 = faction_slider.position
@onready var faction_name_label: Label = %FactionNameLabel
@onready var flavour_text_label: RichTextLabel = %FlavourTextLabel
@onready var army_preview: Node2D = %ArmyPreview

var current_faction_idx: int = 0
var game_setup: GameSetup = GameSetup.new()

func _ready() -> void:
	for child in faction_slider.get_children():
		child.queue_free()

	for i in Config.factions.size():
		var faction: Faction = Config.factions[i]
		var faction_node: Node2D = load("res://frontend/factions/%s.tscn" % faction.name).instantiate()
		faction_node.position = Vector2(i * 650, 0)
		faction_node.name = faction.name
		faction_slider.add_child(faction_node)
	
	flavour_text_label.self_modulate = Color.TRANSPARENT
	faction_name_label.self_modulate = Color.TRANSPARENT
	faction_name_label.text = Config.factions[current_faction_idx].display_name
	flavour_text_label.text = "[i]%s[/i]" % Config.factions[current_faction_idx].description
	var tw: = create_tween().set_parallel(true)
	tw.tween_property(flavour_text_label, "self_modulate", Color.WHITE, 0.3)
	tw.tween_property(faction_name_label, "self_modulate", Color.WHITE, 0.3)

	game_setup.difficulty = Config.difficulties[0]
	_on_difficulty_changed()
	_update_army_preview()

func _update_army_preview() -> void:
	for child in army_preview.get_children():
		child.queue_free()
	for i in range(Config.factions[current_faction_idx].piece_types.size() - 1, -1, -1):
		var piece_type: Piece.Type = Config.factions[current_faction_idx].piece_types[i]
		var piece_node: Node2D = load("res://frontend/pieces/sprites/%s_sprites.tscn" % Piece.TYPE_TO_STRING[piece_type]).instantiate()
		piece_node.position = Vector2((i % 10) * 16, (i / 10) * 16)
		army_preview.add_child(piece_node)

func _on_faction_changed() -> void:
	# Shift the slider to the selected faction
	var faction_node: Node2D = faction_slider.get_child(current_faction_idx)
	var slider_target_pos: = -faction_node.position + initial_slider_pos
	var tw: = create_tween().set_parallel(true)
	tw.tween_property(faction_slider, "position", slider_target_pos, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Fade in the flavour text and faction name
	var tw2: = create_tween()
	tw2.tween_property(flavour_text_label, "self_modulate", Color.TRANSPARENT, 0.15)
	tw2.parallel().tween_property(faction_name_label, "self_modulate", Color.TRANSPARENT, 0.15)
	tw2.tween_callback(func():
		flavour_text_label.text = "[i]%s[/i]" % Config.factions[current_faction_idx].description
		faction_name_label.text = Config.factions[current_faction_idx].display_name
	)
	tw2.tween_property(flavour_text_label, "self_modulate", Color.WHITE, 0.15)
	tw2.parallel().tween_property(faction_name_label, "self_modulate", Color.WHITE, 0.15)

	_update_army_preview()

func _on_right_button_pressed() -> void:
	current_faction_idx = (current_faction_idx + 1) % num_factions
	_on_faction_changed()

func _on_left_button_pressed() -> void:
	current_faction_idx = (current_faction_idx - 1) % num_factions
	_on_faction_changed()

func _on_start_button_pressed() -> void:
	game_setup.faction = Config.factions[current_faction_idx]
	game_setup.difficulty = Config.difficulties[0]

	var game: Game = load("res://frontend/game.tscn").instantiate()
	get_tree().root.add_child(game)
	game.init_with_game_setup(game_setup)
	queue_free()

func _on_difficulty_changed() -> void:
	%DifficultyNameLabel.text = game_setup.difficulty.display_name
	%DifficultyDescriptionLabel.text = game_setup.difficulty.description

func _on_novice_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		game_setup.difficulty = Config.difficulties[0]
		%StandardButton.set_pressed_no_signal(false)
		_on_difficulty_changed()

func _on_standard_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		game_setup.difficulty = Config.difficulties[1]
		%NoviceButton.set_pressed_no_signal(false)
		_on_difficulty_changed()
