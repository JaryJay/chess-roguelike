class_name Config

class AIConfig:
	var max_moves_to_consider: int

static var max_board_size: int
static var tile_generation_threshold: float
static var tile_generation_noise_scale: float
static var ai: AIConfig

static func load_config() -> void:
	var file: = FileAccess.open("config.json", FileAccess.READ)
	if file == null:
		push_error("Failed to open config.json")
		return
	
	var json_text: = file.get_as_text()
	file.close()
	
	var json: = JSON.new()
	json.parse(json_text)

	var config: = json.data as Dictionary
	
	max_board_size = config["max_board_size"]
	tile_generation_threshold = config["tile_generation_threshold"]
	tile_generation_noise_scale = config["tile_generation_noise_scale"]
	ai.max_moves_to_consider = config["ai"]["max_moves_to_consider"]

