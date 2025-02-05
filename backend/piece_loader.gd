class_name PieceLoader

const PATH_TO_PIECES: = "res://pieces.json"

# Dictionary to store all piece definitions
static var pieces: = {}

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
		
	pieces = json.data as Dictionary
	print(pieces)
	
# Returns the piece definition for a given piece type
static func get_piece(piece_type: String) -> Dictionary:
	if pieces.has(piece_type):
		return pieces[piece_type]
	push_error("Piece type '%s' not found" % piece_type)
	return {}

# Returns all available piece types
static func get_piece_types() -> Array:
	return pieces.keys()

# Returns true if a piece has a specific tag
static func has_tag(piece_type: String, tag: String) -> bool:
	if not pieces.has(piece_type):
		return false
	if not pieces[piece_type].has("tags"):
		return false
	return tag in pieces[piece_type]["tags"]
