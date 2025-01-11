class_name Match

var tile_map: MatchTileMap
var piece_map: MatchPieceMap
var team_to_move: Team

func is_team_in_check(team: Team) -> bool:
	return false

func is_match_over() -> bool:
	return false
