class_name Difficulty

var name: String
var display_name: String
var description: String
var eval_randomness: float
var default_depth: int

func _init(_name: String, _display_name: String, _description: String, _eval_randomness: float, _default_depth: int) -> void:
	self.name = _name
	self.display_name = _display_name
	self.description = _description
	self.eval_randomness = _eval_randomness
	self.default_depth = _default_depth

func _to_string() -> String:
	return "Difficulty(%s, %s, %s, %f, %d)" % [name, display_name, description, eval_randomness, default_depth]


