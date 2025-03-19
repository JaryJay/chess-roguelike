class_name Config

const PATH_TO_CONFIG: String = "res://config.json"

class AIConfig:
	var max_moves_to_consider: int

static var max_board_size: int
static var tile_generation_threshold: float
static var tile_generation_noise_scale: float
static var ai: AIConfig = AIConfig.new()
static var factions: Array[Faction] = []
static var difficulties: Array[Difficulty] = []

static var loaded: bool = false

static func load_config() -> void:
	assert(!loaded, "Config already loaded!")
	
	var file := FileAccess.open(PATH_TO_CONFIG, FileAccess.READ)
	if file == null:
		push_error("Failed to open config.json")
		return
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	json.parse(json_text)

	var config := json.data as Dictionary
	
	max_board_size = config["max_board_size"]
	assert(max_board_size > 0, "Max board size must be a positive integer")
	tile_generation_threshold = config["tile_generation_threshold"]
	tile_generation_noise_scale = config["tile_generation_noise_scale"]
	ai.max_moves_to_consider = config["ai"]["max_moves_to_consider"]

	for faction: Dictionary in config["factions"]:
		var piece_types: Array[Piece.Type] = []
		for piece_type: String in faction["piece_types"]:
			piece_types.append(Piece.STRING_TO_TYPE[piece_type])
		factions.append(Faction.new(faction["name"], faction["display_name"], faction["description"], piece_types))

	for difficulty: Dictionary in config["difficulties"]:
		difficulties.append(Difficulty.new(
			difficulty["name"],
			difficulty["display_name"],
			difficulty["description"],
			difficulty["eval_randomness"],
			difficulty["default_depth"],
			difficulty["enemy_credits"],
			difficulty["enemy_credit_increment"],
		))

	loaded = true
	print("Config loaded")
