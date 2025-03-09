class_name PieceRules

const PATH_TO_PIECES: = "res://pieces.json"

static var piece_type_to_rules: Dictionary[Piece.Type, PieceRule] = {}

# Loads and parses the pieces from the JSON file
static func load_pieces() -> void:
	var file: = FileAccess.open(PATH_TO_PIECES, FileAccess.READ)
	if file == null:
		push_error("Failed to open pieces.json")
		return
		
	var json_text: = file.get_as_text()
	file.close()
	
	var json: = JSON.new()
	var error: = json.parse(json_text)
	if error != OK:
		push_error("Failed to parse pieces.json")
		return
		
	var pieces = json.data as Dictionary

	for piece_type: String in pieces:
		var credit_cost: int = pieces[piece_type]["credit_cost"]
		var tags: Array[String] = []
		if pieces[piece_type].has("tags"):
			for tag: String in pieces[piece_type]["tags"]:
				tags.append(tag)
		var moves: Array[PieceMoveAbility] = []
		if pieces[piece_type].has("moves"):	
			for move in pieces[piece_type]["moves"]:
				var dir_array: Array = move["dir"]
				var dir: = Vector2i(dir_array[0], dir_array[1])
				moves.append(PieceMoveAbility.new(dir, move["dist"]))
		
		piece_type_to_rules[Piece.STRING_TO_TYPE[piece_type]] = PieceRule.new(tags, moves, credit_cost)

static func get_rule(piece_type: Piece.Type) -> PieceRule:
	return piece_type_to_rules[piece_type]
