class_name Team extends Node

## Team types
enum s {
	## Always hostile towards enemies
	ALLY_PLAYER = 15,
	
	## Always hostile towards allies
	ENEMY_AI_0 = 20,
	ENEMY_AI_1 = 22,
	ENEMY_AI_2 = 24,
	ENEMY_AI_3 = 26,
	ENEMY_AI_4 = 28,
	
	## Reserved for future
	SPECIAL_ENEMY_AI = 50,
	RESERVED = 100,
}

static func is_ai(team: s) -> bool:
	return is_enemy(team)

static func is_player(team: s) -> bool:
	return team == s.ALLY_PLAYER

static func is_ally(team: s) -> bool:
	return 10 <= team and team <= 19

static func is_enemy(team: s) -> bool:
	return 20 <= team and team <= 30

static func hostile_to_each_other(t1: s, t2: s) -> bool:
	return (is_ally(t1) and is_enemy(t2)) or (is_enemy(t1) && is_ally(t2))

static func on_same_team(t1: s, t2: s) -> bool:
	return (is_ally(t1) and is_ally(t2)) or (is_enemy(t1) and is_enemy(t2))
