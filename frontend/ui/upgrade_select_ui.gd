class_name UpgradeSelectUI extends CanvasLayer

signal upgrade_chosen(upgrade: Upgrade)

@onready var upgrades_container: HBoxContainer = $Control/H

func generate_upgrades(game_setup: GameSetup, num_upgrades: int = 3) -> void:
	assert(is_node_ready(), "UpgradeSelectUI must be ready before generating upgrades")
	for child: Node in upgrades_container.get_children():
		child.queue_free()
	
	# Generate num_upgrades random upgrades, ensuring that they are unique and also applicable to the game setup
	var applicable_upgrades: Array[Upgrade] = []
	for upgrade in Upgrades.upgrades:
		if upgrade.is_applicable(game_setup):
			applicable_upgrades.append(upgrade)
	# Hack to ensure that we have enough applicable upgrades
	while applicable_upgrades.size() < num_upgrades:
		applicable_upgrades.append(applicable_upgrades[randi() % applicable_upgrades.size()])
	
	applicable_upgrades.shuffle()
	var upgrades: Array[Upgrade] = applicable_upgrades.slice(0, num_upgrades)
	for upgrade in upgrades:
		var upgrade_ui: UpgradeOption = load("res://frontend/ui/upgrade_option.tscn").instantiate()
		upgrades_container.add_child(upgrade_ui)
		upgrade_ui.init(upgrade)
		upgrade_ui.chosen.connect(_on_upgrade_chosen.bind(upgrade))

func _on_upgrade_chosen(upgrade: Upgrade) -> void:
	upgrade_chosen.emit(upgrade)
