class_name Team extends Node

## Team types
enum s {
	## Cannot perform abilities that hurt other units
	PACIFIST_AI = 0,
	
	## Will not intentionally hurt other units
	NEUTRAL_AI = 2,
	NEUTRAL_PLAYER = 5,
	
	## Always hostile towards enemies
	ALLY_AI = 10,
	ALLY_PLAYER = 15,
	
	## Always hostile towards allies
	ENEMY_AI = 20,
	ENEMY_PLAYER = 25,
	
	## Reserved for future
	SPECIAL_ENEMY_AI = 50,
	RESERVED = 100,
}

static func is_ai(team: s) -> bool:
	return team == s.NEUTRAL_AI or team == s.ALLY_AI or \
		team == s.ENEMY_AI or team == s.SPECIAL_ENEMY_AI

static func is_player(team: s) -> bool:
	return team == s.NEUTRAL_PLAYER or team == s.ALLY_PLAYER or \
		team == s.ENEMY_PLAYER

static func is_neutral(team: s) -> bool:
	return 2 <= team and team <= 9

static func is_ally(team: s) -> bool:
	return 10 <= team and team <= 19

static func is_enemy(team: s) -> bool:
	return 20 <= team and team <= 29

static func hostile_to_each_other(t1: s, t2: s) -> bool:
	return (is_ally(t1) and is_enemy(t2)) or (is_enemy(t1) && is_ally(t2))

static func on_same_team(t1: s, t2: s) -> bool:
	return (t1 == t2) or (is_neutral(t1) and is_neutral(t2)) or \
		(is_ally(t1) and is_ally(t2)) or (is_enemy(t1) and is_enemy(t2))
