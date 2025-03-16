class_name UpgradeOption extends AspectRatioContainer

signal chosen(upgrade: Upgrade)

@export var upgrade: Upgrade

func _on_choose_button_pressed() -> void:
	chosen.emit(upgrade)
