extends Node2D

@onready var num_factions: int = Config.factions.size()
@onready var faction_slider: Node2D = $FactionSlider
@onready var difficulties_container: Control = %DifficultiesContainer
@onready var initial_slider_pos: Vector2 = faction_slider.position
@onready var faction_name_label: Label = %FactionNameLabel
@onready var flavour_text_label: RichTextLabel = %FlavourTextLabel
@onready var pieces_preview: PiecesPreview = %PiecesPreview

var faction_idx: int
var difficulty_idx: int
var game_setup: GameSetup = GameSetup.new()

func _ready() -> void:
	# The elements in the scene are merely placeholders. We free all of them,
	# then instantiate everything in the factions/ui folder
	for child in faction_slider.get_children():
		child.queue_free()
		faction_slider.remove_child(child)
	for i in Config.factions.size():
		var faction: Faction = Config.factions[i]
		var path: = "res://frontend/ui/factions/%s.tscn" % faction.name
		if not ResourceLoader.exists(path): continue
		var faction_node: Node2D = load(path).instantiate()
		faction_node.position = Vector2(i * 650, 0)
		faction_node.name = faction.name
		faction_slider.add_child(faction_node)
	# Then do the same thing for difficulties
	for child in difficulties_container.get_children():
		child.queue_free()
		difficulties_container.remove_child(child)
	var difficulty_button_group: = ButtonGroup.new()
	for i in Config.difficulties.size():
		var difficulty: Difficulty = Config.difficulties[i]
		var path: = "res://frontend/ui/difficulties/%s.tscn" % difficulty.name
		if not ResourceLoader.exists(path): continue
		var difficulty_button: Button = load(path).instantiate()
		difficulties_container.add_child(difficulty_button)
		difficulty_button.name = difficulty.name
		difficulty_button.button_group = difficulty_button_group
	difficulty_button_group.pressed.connect(_on_difficulty_button_pressed)
	
	_load_config_or_default()
	
	flavour_text_label.self_modulate = Color.TRANSPARENT
	faction_name_label.self_modulate = Color.TRANSPARENT
	faction_name_label.text = Config.factions[faction_idx].display_name
	flavour_text_label.text = "[i]%s[/i]" % Config.factions[faction_idx].description
	var tw := create_tween().set_parallel(true)
	tw.tween_property(flavour_text_label, "self_modulate", Color.WHITE, 0.3)
	tw.tween_property(faction_name_label, "self_modulate", Color.WHITE, 0.3)
	
	_on_faction_changed(true)

func _load_config_or_default() -> void:
	var config := ConfigFile.new()
	var err := config.load("user://settings.cfg")
	if err != OK:
		# Default behaviour
		difficulty_idx = 0
		_set_difficulty(Config.difficulties[0])
		(difficulties_container.get_child(0) as Button).button_pressed = true
		faction_idx = 0
		return
	var diff_name: String = config.get_value("settings", "difficulty", "novice")
	var diff_idx := Config.difficulties.find_custom(func(d): return d.name == diff_name)
	if diff_idx == -1: # If not found
		diff_idx = 0
	difficulty_idx = diff_idx
	(difficulties_container.get_child(diff_idx) as Button).button_pressed = true
	_set_difficulty(Config.difficulties[diff_idx])
	
	var fac_name: String = config.get_value("settings", "faction", "monarchy")
	var fac_idx := Config.factions.find_custom(func(f): return f.name == fac_name)
	if fac_idx == -1: # If not found
		fac_idx = 0
	faction_idx = fac_idx
	game_setup.faction = Config.factions[fac_idx]

func _save_config() -> void:
	var config = ConfigFile.new()
	config.set_value("settings", "difficulty", game_setup.difficulty.name)
	config.set_value("settings", "faction", game_setup.faction.name)
	config.save("user://settings.cfg")

func _update_army_preview() -> void:
	pieces_preview.set_piece_types(Config.factions[faction_idx].piece_types)

func _on_faction_changed(instant: bool = false) -> void:
	# Shift the slider to the selected faction
	var faction_node: Node2D = faction_slider.get_child(faction_idx)
	var slider_target_pos := -faction_node.position + initial_slider_pos
	
	if not instant:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(faction_slider, "position", slider_target_pos, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	else:
		faction_slider.position = slider_target_pos
	
	# Fade in the flavour text and faction name
	var tw2 := create_tween()
	tw2.tween_property(flavour_text_label, "self_modulate", Color.TRANSPARENT, 0.15)
	tw2.parallel().tween_property(faction_name_label, "self_modulate", Color.TRANSPARENT, 0.15)
	tw2.tween_callback(func():
		flavour_text_label.text = "[i]%s[/i]" % Config.factions[faction_idx].description
		faction_name_label.text = Config.factions[faction_idx].display_name
	)
	tw2.tween_property(flavour_text_label, "self_modulate", Color.WHITE, 0.15)
	tw2.parallel().tween_property(faction_name_label, "self_modulate", Color.WHITE, 0.15)

	_update_army_preview()

func _on_right_button_pressed() -> void:
	faction_idx = (faction_idx + 1) % num_factions
	_on_faction_changed()

func _on_left_button_pressed() -> void:
	faction_idx = (faction_idx - 1) % num_factions
	_on_faction_changed()

func _on_start_button_pressed() -> void:
	game_setup.faction = Config.factions[faction_idx]
	game_setup.piece_types.append_array(game_setup.faction.piece_types)
	game_setup.enemy_credits = game_setup.difficulty.enemy_credits
	
	_save_config()

	var game: Game = load("res://frontend/game.tscn").instantiate()
	get_tree().root.add_child(game)
	game.init_with_game_setup(game_setup)
	queue_free()

func _set_difficulty(difficulty: Difficulty) -> void:
	game_setup.difficulty = difficulty
	%DifficultyNameLabel.text = difficulty.display_name
	%DifficultyDescriptionLabel.text = difficulty.description

func _on_difficulty_button_pressed(button: Button) -> void:
	var i := button.get_index()
	difficulty_idx = i
	_set_difficulty(Config.difficulties[i])
