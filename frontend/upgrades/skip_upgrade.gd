class_name SkipUpgrade extends Upgrade

func _init() -> void:
	super("Skip", "Keep your current army as-is and move on.")

func is_applicable(_game_setup: GameSetup) -> bool:
	return true

func apply(_game_setup: GameSetup) -> void:
	pass

func preview_apply(piece_types: Array[Piece.Type]) -> Array[Piece.Type]:
	return piece_types.duplicate()
