extends Node2D

const FACTION_SPACING := 650.0
const SNAP_DURATION := 0.25
const MAX_DIM_DISTANCE := 2.0
const INDICATOR_INACTIVE_WIDTH := 24.0
const INDICATOR_ACTIVE_WIDTH := 32.0
const INDICATOR_INACTIVE_HEIGHT := 2.0
const INDICATOR_ACTIVE_HEIGHT := 5.0

@export_range(0.0, 1.0) var inactive_faction_brightness: float = 0.45

@onready var num_factions: int = Config.factions.size()
@onready var faction_slider: Node2D = $FactionSlider
@onready var difficulties_container: Control = %DifficultiesContainer
@onready var initial_slider_pos: Vector2 = faction_slider.position
@onready var faction_name_label: Label = %FactionNameLabel
@onready var flavour_text_label: RichTextLabel = %FlavourTextLabel
@onready var pieces_preview: PiecesPreview = %PiecesPreview
@onready var faction_indicator: HBoxContainer = %FactionIndicator

var faction_idx: int
var difficulty_idx: int
var game_setup: GameSetup = GameSetup.new()

var _swipe_dragging := false
var _swipe_start_pos := Vector2.ZERO
var _slider_pos_at_drag_start := Vector2.ZERO
var _indicator_bars: Array[ColorRect] = []

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
		faction_node.position = Vector2(i * FACTION_SPACING, 0)
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

	_build_faction_indicator()
	_load_config_or_default()
	
	flavour_text_label.self_modulate = Color.TRANSPARENT
	faction_name_label.self_modulate = Color.TRANSPARENT
	faction_name_label.text = Config.factions[faction_idx].display_name
	flavour_text_label.text = "[i]%s[/i]" % Config.factions[faction_idx].description
	var tw := create_tween().set_parallel(true)
	tw.tween_property(flavour_text_label, "self_modulate", Color.WHITE, 0.3)
	tw.tween_property(faction_name_label, "self_modulate", Color.WHITE, 0.3)
	
	_on_faction_changed(true)

func _process(_delta: float) -> void:
	_update_faction_visuals()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		faction_idx = (faction_idx - 1) % num_factions
		_on_faction_changed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		faction_idx = (faction_idx + 1) % num_factions
		_on_faction_changed()
		get_viewport().set_input_as_handled()

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

func _build_faction_indicator() -> void:
	for child in faction_indicator.get_children():
		child.queue_free()
	_indicator_bars.clear()
	for _i in num_factions:
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(INDICATOR_INACTIVE_WIDTH, INDICATOR_INACTIVE_HEIGHT)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.color = Color(0.15, 0.15, 0.15)
		faction_indicator.add_child(bar)
		_indicator_bars.append(bar)

func _get_fractional_faction_idx() -> float:
	return (initial_slider_pos.x - faction_slider.position.x) / FACTION_SPACING

func _update_faction_visuals() -> void:
	var fractional_idx := _get_fractional_faction_idx()

	for i in num_factions:
		var faction_node := faction_slider.get_child(i) as CanvasItem
		var distance := absf(i - fractional_idx)
		var dim_amount := clampf(distance / MAX_DIM_DISTANCE, 0.0, 1.0)
		var brightness := lerpf(1.0, inactive_faction_brightness, dim_amount)
		faction_node.modulate = Color(brightness, brightness, brightness, 1.0)

	_update_indicator_bars(fractional_idx)

func _update_indicator_bars(fractional_idx: float) -> void:
	const inactive_color := Color(0.15, 0.15, 0.15)
	const active_color := Color(0.75, 0.75, 0.75)

	for i in _indicator_bars.size():
		var bar := _indicator_bars[i]
		var activation := clampf(1.0 - absf(i - fractional_idx), 0.0, 1.0)
		bar.color = inactive_color.lerp(active_color, activation)
		bar.custom_minimum_size = Vector2(
			lerpf(INDICATOR_INACTIVE_WIDTH, INDICATOR_ACTIVE_WIDTH, activation),
			lerpf(INDICATOR_INACTIVE_HEIGHT, INDICATOR_ACTIVE_HEIGHT, activation),
		)

func _slider_pos_for_faction(idx: int) -> Vector2:
	var faction_node: Node2D = faction_slider.get_child(idx)
	return -faction_node.position + initial_slider_pos

func _clamp_slider_pos(pos: Vector2) -> Vector2:
	var min_x := _slider_pos_for_faction(num_factions - 1).x
	var max_x := _slider_pos_for_faction(0).x
	pos.x = clampf(pos.x, min_x, max_x)
	return pos

func _nearest_faction_idx_from_slider_pos(pos: Vector2) -> int:
	return clampi(roundi(_get_fractional_faction_idx_from_pos(pos)), 0, num_factions - 1)

func _get_fractional_faction_idx_from_pos(pos: Vector2) -> float:
	return (initial_slider_pos.x - pos.x) / FACTION_SPACING

func _snap_slider_to_faction(idx: int, instant: bool) -> void:
	var slider_target_pos := _slider_pos_for_faction(idx)
	if instant:
		faction_slider.position = slider_target_pos
		return
	var tw := create_tween()
	tw.tween_property(faction_slider, "position", slider_target_pos, SNAP_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _on_faction_changed(instant: bool = false) -> void:
	_snap_slider_to_faction(faction_idx, instant)
	
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

func _on_faction_swipe_area_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_swipe_dragging = true
			_swipe_start_pos = event.position
			_slider_pos_at_drag_start = faction_slider.position
		elif _swipe_dragging:
			_finish_faction_swipe()
	elif event is InputEventScreenDrag:
		if _swipe_dragging:
			var delta: Vector2 = event.position - _swipe_start_pos
			faction_slider.position = _clamp_slider_pos(_slider_pos_at_drag_start + Vector2(delta.x, 0))
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_swipe_dragging = true
				_swipe_start_pos = event.position
				_slider_pos_at_drag_start = faction_slider.position
			elif _swipe_dragging:
				_finish_faction_swipe()
	elif event is InputEventMouseMotion:
		if _swipe_dragging and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			var delta: Vector2 = event.position - _swipe_start_pos
			faction_slider.position = _clamp_slider_pos(_slider_pos_at_drag_start + Vector2(delta.x, 0))

func _finish_faction_swipe() -> void:
	var new_idx := _nearest_faction_idx_from_slider_pos(faction_slider.position)
	_swipe_dragging = false
	faction_idx = new_idx
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
