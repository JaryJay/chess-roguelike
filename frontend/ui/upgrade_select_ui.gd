class_name UpgradeSelectUI extends CanvasLayer

signal upgrade_chosen(upgrade: Upgrade)

@onready var upgrades_container: HBoxContainer = $Control/H
@onready var enemy_budget_label: Label = $Control/EnemyBudgetLabel

var _current_piece_types: Array[Piece.Type] = []
var _upgrade_options: Array[UpgradeOption] = []

func generate_upgrades(game_setup: GameSetup, num_upgrades: int = 3) -> void:
	assert(is_node_ready(), "UpgradeSelectUI must be ready before generating upgrades")

	_current_piece_types = game_setup.piece_types.duplicate()
	%PiecesPreview.set_piece_types(_current_piece_types)

	# Show the enemy's next budget
	enemy_budget_label.text = "Next enemy budget: %d credits" % game_setup.enemy_credits

	for child: Node in upgrades_container.get_children():
		child.queue_free()
	_upgrade_options.clear()

	# Pick applicable upgrades (no duplicates needed — Skip is always available)
	var applicable_upgrades: Array[Upgrade] = []
	for upgrade in Upgrades.upgrades:
		if upgrade.is_applicable(game_setup):
			applicable_upgrades.append(upgrade)
	applicable_upgrades.shuffle()
	var chosen_upgrades: Array[Upgrade] = applicable_upgrades.slice(0, mini(num_upgrades, applicable_upgrades.size()))

	# Always offer Skip as the last option
	chosen_upgrades.append(SkipUpgrade.new())

	for upgrade in chosen_upgrades:
		var upgrade_ui: UpgradeOption = load("res://frontend/ui/upgrade_option.tscn").instantiate()
		upgrades_container.add_child(upgrade_ui)
		upgrade_ui.init(upgrade)
		upgrade_ui.chosen.connect(_on_upgrade_chosen)
		upgrade_ui.hovered.connect(_on_upgrade_hovered)
		upgrade_ui.unhovered.connect(_on_upgrade_unhovered)
		_upgrade_options.append(upgrade_ui)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	# Keyboard shortcuts: press 1/2/3/4 to pick the corresponding upgrade card
	if event is InputEventKey and event.pressed and not event.echo:
		for i in _upgrade_options.size():
			if event.keycode == KEY_1 + i:
				_upgrade_options[i].chosen.emit(_upgrade_options[i].upgrade)
				get_viewport().set_input_as_handled()
				break

func _on_upgrade_hovered(upgrade: Upgrade) -> void:
	var preview_types := upgrade.preview_apply(_current_piece_types)
	%PiecesPreview.set_piece_types(preview_types)

func _on_upgrade_unhovered() -> void:
	%PiecesPreview.set_piece_types(_current_piece_types)

func _on_upgrade_chosen(upgrade: Upgrade) -> void:
	upgrade_chosen.emit(upgrade)
