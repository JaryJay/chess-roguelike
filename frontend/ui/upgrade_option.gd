class_name UpgradeOption extends AspectRatioContainer

signal chosen(upgrade: Upgrade)
signal hovered(upgrade: Upgrade)
signal unhovered()

@export var upgrade: Upgrade

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered_option)
	mouse_exited.connect(_on_mouse_exited_option)

func init(_upgrade: Upgrade) -> void:
	assert(is_node_ready(), "UpgradeOption must be ready before initializing")
	upgrade = _upgrade
	%NameLabel.text = upgrade.display_name
	%DescriptionLabel.text = upgrade.description

func _on_mouse_entered_option() -> void:
	hovered.emit(upgrade)

func _on_mouse_exited_option() -> void:
	unhovered.emit()

func _on_choose_button_pressed() -> void:
	chosen.emit(upgrade)
