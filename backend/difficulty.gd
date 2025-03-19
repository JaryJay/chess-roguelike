class_name Difficulty

var name: String
var display_name: String
var description: String
var eval_randomness: float
var default_depth: int
var enemy_credits: int
var enemy_credit_increment: int

func _init(
	_name: String,
	_display_name: String,
	_description: String,
	_eval_randomness: float,
	_default_depth: int,
	_enemy_credits: int,
	_enemy_credit_increment: int
) -> void:
	name = _name
	display_name = _display_name
	description = _description
	eval_randomness = _eval_randomness
	default_depth = _default_depth
	enemy_credits = _enemy_credits
	enemy_credit_increment = _enemy_credit_increment

func _to_string() -> String:
	return "Difficulty(%s, %s, %s, %f, %d)" % [name, display_name, description, eval_randomness, default_depth]


