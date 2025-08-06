class_name GameSetup

# Starting conditions

var classic_mode: bool = false

var faction: Faction = null
var difficulty: Difficulty = null

## Excluding king
var piece_types: Array[Piece.Type] = []
var enemy_credits: int = 0

# func create_starter_faction_pieces() -> void:
	
func _to_string() -> String:
	var piece_types_str: String = ""
	for piece_type in piece_types:
		piece_types_str += Piece.TYPE_TO_STRING[piece_type] + ", "
	if piece_types_str.length() >= 2:
		piece_types_str = piece_types_str.left(piece_types_str.length() - 2)
	return "GameSetup(piece_types: %s, enemy_credits: %d)" % [piece_types_str, enemy_credits]

