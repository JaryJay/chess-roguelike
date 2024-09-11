class_name Team extends Resource

static var PLAYER = Team.new(15)
static var ENEMY_AI = Team.new(20)

var _key: int

func _init(key: int) -> void:
	_key = key

func is_player() -> bool:
	return self == PLAYER

func is_enemy() -> bool:
	return self == ENEMY_AI

func is_hostile_to(t: Team) -> bool:
	assert(t != null)
	return (is_player() and t.is_enemy()) or (is_enemy() && t.is_player())

func is_friendly_to(t: Team) -> bool:
	assert(t != null)
	return (is_player() and t.is_player()) or (is_enemy() and t.is_enemy())
