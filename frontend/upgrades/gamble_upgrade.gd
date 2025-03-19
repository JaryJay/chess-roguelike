class_name GambleUpgrade extends Upgrade

class GamblePossibility:
	var remove_types: Array[String]
	var add_types: Array[String]
	var weight: float

	func _init(_remove_types: Array[String], _add_types: Array[String], _weight: float) -> void:
		remove_types = _remove_types
		add_types = _add_types
		weight = _weight

	func is_applicable(game_setup: GameSetup) -> bool:
		# Check if the types to remove are present in the game setup
		# and have enough copies
		var type_counts: Dictionary[Piece.Type, int] = {}
		for piece_type in game_setup.piece_types:
			if not type_counts.has(piece_type):
				type_counts[piece_type] = 0
			type_counts[piece_type] += 1
	
		for type in remove_types:
			var piece_type = Piece.STRING_TO_TYPE[type]
			if not type_counts.has(piece_type) or type_counts[piece_type] == 0:
				return false
			type_counts[piece_type] -= 1

		return true

var possibilities: Array[GamblePossibility]

func _init(_display_name: String, _description: String, _possibilities: Array[GamblePossibility]) -> void:
	super(_display_name, _description)
	possibilities = _possibilities

func is_applicable(game_setup: GameSetup) -> bool:
	# All possibilities must be applicable
	for possibility in possibilities:
		if not possibility.is_applicable(game_setup):
			return false
	return true

func apply(game_setup: GameSetup) -> void:
	# Choose a possibility at random
	var total_weight: float = 0.0
	for possibility in possibilities:
		total_weight += possibility.weight
	
	var random_value: float = randf_range(0.0, total_weight)
	# Choose a possibility based on the random value
	var chosen_possibility: GamblePossibility = null
	for possibility in possibilities:
		if random_value < possibility.weight:
			chosen_possibility = possibility
			break
		else:
			random_value -= possibility.weight

	# Apply the chosen possibility
	for type in chosen_possibility.remove_types:
		game_setup.piece_types.erase(Piece.STRING_TO_TYPE[type])
	for type in chosen_possibility.add_types:
		game_setup.piece_types.append(Piece.STRING_TO_TYPE[type])
