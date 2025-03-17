class_name Upgrade extends Resource

@export var display_name: String
@export var description: String

func _init(_display_name: String, _description: String) -> void:
	display_name = _display_name
	description = _description

func is_applicable(_game_setup: GameSetup) -> bool:
	return true

func apply(_game_setup: GameSetup) -> void:
	assert(false, "Not implemented")
