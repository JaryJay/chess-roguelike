class_name BasicUpgrade extends Upgrade

@export var types_to_remove: Array[String]
@export var types_to_add: Array[String]

func is_applicable(game_setup: GameSetup) -> bool:
	# Check if the types to remove are present in the game setup
	# and have enough copies
	var type_counts: Dictionary[Piece.Type, int] = {}
	for piece_type in game_setup.faction.piece_types:
		if not type_counts.has(piece_type):
			type_counts[piece_type] = 0
		type_counts[piece_type] += 1
	
	for type in types_to_remove:
		var piece_type = Piece.STRING_TO_TYPE[type]
		if not type_counts.has(piece_type) or type_counts[piece_type] == 0:
			return false
		type_counts[piece_type] -= 1

	return true

func apply(game_setup: GameSetup) -> void:
	# Remove the types to remove
	for type in types_to_remove:
		game_setup.faction.piece_types.erase(Piece.STRING_TO_TYPE[type])

	# Add the types to add
	for type in types_to_add:
		game_setup.faction.piece_types.append(Piece.STRING_TO_TYPE[type])

