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

## Returns what piece_types would look like after applying this upgrade.
## Does NOT modify game_setup.
func preview_apply(piece_types: Array[Piece.Type]) -> Array[Piece.Type]:
	return piece_types.duplicate()
