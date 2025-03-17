class_name BasicUpgrade extends Upgrade

@export var remove_types: Array[String]
@export var add_types: Array[String]

func _init(_display_name: String, _description: String, _remove_types: Array[String], _add_types: Array[String]) -> void:
	super(_display_name, _description)
	remove_types = _remove_types
	add_types = _add_types

func is_applicable(game_setup: GameSetup) -> bool:
	# Check if the types to remove are present in the game setup
	# and have enough copies
	var type_counts: Dictionary[Piece.Type, int] = {}
	for piece_type in game_setup.faction.piece_types:
		if not type_counts.has(piece_type):
			type_counts[piece_type] = 0
		type_counts[piece_type] += 1
	
	for type in remove_types:
		var piece_type = Piece.STRING_TO_TYPE[type]
		if not type_counts.has(piece_type) or type_counts[piece_type] == 0:
			return false
		type_counts[piece_type] -= 1

	return true

func apply(game_setup: GameSetup) -> void:
	# Remove the types to remove
	for type in remove_types:
		game_setup.faction.piece_types.erase(Piece.STRING_TO_TYPE[type])

	# Add the types to add
	for type in add_types:
		game_setup.faction.piece_types.append(Piece.STRING_TO_TYPE[type])

