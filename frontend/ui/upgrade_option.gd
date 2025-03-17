class_name UpgradeOption extends AspectRatioContainer

signal chosen(upgrade: Upgrade)

@export var upgrade: Upgrade

func init(_upgrade: Upgrade) -> void:
	assert(is_node_ready(), "UpgradeOption must be ready before initializing")
	upgrade = _upgrade
	%NameLabel.text = upgrade.display_name
	%DescriptionLabel.text = upgrade.description

func _on_choose_button_pressed() -> void:
	chosen.emit(upgrade)
