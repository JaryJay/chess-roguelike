class_name Piece

# Note to self: the int type in GDScript is a signed 64-bit integer.
enum Type {
	UNSET = 0,
	RESERVED_00 = 2**0,
	KING = 2**1,
	RESERVED_01 = 2**2,
	RESERVED_02 = 2**3,
	RESERVED_03 = 2**4,
	RESERVED_04 = 2**5,
	QUEEN = 2**6,
	RESERVED_05 = 2**8,
	RESERVED_06 = 2**9,
	RESERVED_07 = 2**10,
	ROOK = 2**11,
	RESERVED_08 = 2**12,
	RESERVED_09 = 2**13,
	RESERVED_10 = 2**14,
	RESERVED_11 = 2**15,
	BISHOP = 2**16,
	RESERVED_12 = 2**17,
	RESERVED_13 = 2**18,
	RESERVED_14 = 2**19,
	RESERVED_15 = 2**20,
	KNIGHT = 2**21,
	RESERVED_16 = 2**22,
	RESERVED_17 = 2**23,
	RESERVED_18 = 2**24,
	RESERVED_19 = 2**25,
	PAWN = 2**26,
	RESERVED_20 = 2**27,
	RESERVED_21 = 2**28,
	RESERVED_22 = 2**29,
	RESERVED_23 = 2**30,
}

const MOVED: int = 1

var type: Type
var team: Team
var pos: Vector2i
var info: int = 0

func _init(_type: Type, _team: Team, _pos: Vector2i = Vector2i.ZERO, _info: int = 0) -> void:
	type = _type
	team = _team
	pos = _pos
	info = _info

## Returns all available moves for the current player
## Will include illegal moves, which should be filtered out by the caller
func get_available_moves(b: Board) -> Array[Move]:
	assert(type != Type.UNSET, "Type must be set")
	assert(b.tile_map.has_tile(pos), "There should be a tile at the current piece position")
	
	var rule := PieceRules.get_rule(type)
	
	var moves: Array[Move] = []
	for move_ability: PieceMoveAbility in rule.moves:
		moves.append_array(_get_moves_along_rays([move_ability.dir], b, move_ability.dist, true))

	if rule.tags.has("king"):
		moves.append_array(_king_get_additional_moves(b))
	elif rule.tags.has("pawn"):
		moves.append_array(_pawn_get_additional_moves(b))
	
	return moves

func is_attacking_square(p: Vector2i, b: Board) -> bool:
	assert(type != Type.UNSET, "Type must be set")
	assert(b.tile_map.has_tile(p), "There should be a tile at the target position")
	assert(b.tile_map.has_tile(pos), "There should be a tile at the current piece position")
	if p == pos:
		return false
	var rule := PieceRules.get_rule(type)
	
	if rule.tags.has("pawn"):
		if _pawn_is_attacking_square(p, b):
			return true
	
	for move_ability: PieceMoveAbility in rule.moves:
		if _is_attacking_from_ray(p, move_ability.dir, b, move_ability.dist):
			return true
	return false

#region get_available_moves implementation

const BOARD_LENGTH_UPPER_BOUND: int = 20

func _king_get_additional_moves(_b: Board) -> Array[Move]:
	return []

const DIAGONALS_PLAYER := [Vector2i(1, -1), Vector2i(1, -1)]
const DIAGONALS_ENEMY := [Vector2i(1, 1), Vector2i(1, 1)]

func _pawn_get_additional_moves(b: Board) -> Array[Move]:
	var available_moves: Array[Move] = []
	
	var facing_dir := _get_pawn_facing_direction()
	
	# If info = 0, we have never moved
	if info == 0:
		# 1 or 2 squares forward, no captures allowed
		available_moves.append_array(_get_moves_along_rays([facing_dir], b, 2, false))
	else:
		# 1 forward, no captures allowed
		available_moves.append_array(_get_moves_along_rays([facing_dir], b, 1, false))
	
	# Check for captures
	for side: Vector2i in PAWN_SIDES:
		var square := pos + side + facing_dir
		if b.piece_map.has_piece(square) and b.piece_map.get_piece(square).team.is_hostile_to(team):
			available_moves.append(Move.new(pos, square, Move.CAPTURE))
	
	var moves_including_promotion: Array[Move] = []
	for move: Move in available_moves:
		if b.tile_map.is_promotion_tile(move.to, team):
			for promo_type: Piece.Type in _pawn_promotion_types():
				moves_including_promotion.append(Move.new(pos, move.to, move.info, promo_type))
		else:
			moves_including_promotion.append(move)
	
	return moves_including_promotion

func _pawn_promotion_types() -> Array[Piece.Type]:
	return [Piece.Type.QUEEN, Piece.Type.ROOK, Piece.Type.BISHOP, Piece.Type.KNIGHT]

#endregion

#region is_attacking_square implementation

func _pawn_is_attacking_square(p: Vector2i, _b: Board) -> bool:
	var facing_dir := _get_pawn_facing_direction()
	
	for side: Vector2i in PAWN_SIDES:
		if pos + facing_dir + side == p:
			return true
	
	return false

#endregion

#region common utils for get_available_moves and is_attacking_square

func _get_moves_along_rays(
	ray_dirs: Array[Vector2i],
	b: Board,
	ray_length: int = BOARD_LENGTH_UPPER_BOUND,
	enable_capture := true,
) -> Array[Move]:
	var available_moves: Array[Move] = []
	for dir: Vector2i in ray_dirs:
		var next_pos := pos
		for i in range(mini(ray_length, Config.max_board_size)):
			next_pos += dir
			if not b.tile_map.has_tile(next_pos): break
			if b.piece_map.has_piece(next_pos):
				var piece := b.piece_map.get_piece(next_pos)
				if enable_capture and piece.team.is_hostile_to(team):
					available_moves.append(Move.new(pos, next_pos, Move.CAPTURE))
				break
			available_moves.append(Move.new(pos, next_pos))
	return available_moves

func _get_pawn_facing_direction() -> Vector2i:
	var y_modifier := -1 if team.is_player() else 1
	return Vector2i(0, y_modifier)

var PAWN_SIDES := [Vector2i.LEFT, Vector2i.RIGHT]

func _is_in_direction(target: Vector2i, dir: Vector2i) -> bool:
	var delta := target - pos
	
	# Handle straight moves
	if dir.x == 0:
		return delta.x == 0 and delta.y * dir.y > 0
	if dir.y == 0:
		return delta.y == 0 and delta.x * dir.x > 0
		
	# This is equivalent to checking delta.x / dir.x == delta.y / dir.y > 0, except without
	# integer division truncating stuff
	return delta.x * dir.y == delta.y * dir.x

func _is_attacking_from_ray(
	p: Vector2i,
	dir: Vector2i,
	b: Board,
	ray_length: int = BOARD_LENGTH_UPPER_BOUND,
) -> bool:
	# Quick check if target is even in this direction
	if not _is_in_direction(p, dir):
		return false
		
	var next_pos := pos
	for i in range(mini(ray_length, Config.max_board_size)):
		next_pos += dir
		if next_pos == p:
			return true
		if !b.tile_map.has_tile(next_pos) or b.piece_map.has_piece(next_pos):
			return false
	return false

#endregion

func get_worth() -> float:
	assert(type != Piece.Type.UNSET, "Type must be set")
	match type:
		Piece.Type.KING:
			return 1_000_000
		Piece.Type.QUEEN:
			return 9
		Piece.Type.ROOK:
			return 5
		Piece.Type.BISHOP:
			return 3.2
		Piece.Type.KNIGHT:
			return 3
		Piece.Type.PAWN:
			return 1
	assert(false, "Impossible!!!")
	return 0

func duplicate() -> Piece:
	var new_piece := Piece.new(type, team, pos, info)
	assert(self.equals(new_piece), "%s != %s" % [self._to_string(), new_piece._to_string()])
	return new_piece

func equals(p: Piece) -> bool:
	return pos == p.pos and type == p.type and team == p.team and info == p.info

func _to_string() -> String:
	return "Piece(%s, %s, %v, %d)" % [type_to_string(type), team, pos, info]

static func type_to_string(piece_type: Piece.Type) -> String:
	return Piece.Type.keys().filter(func(key: String): return Piece.Type[key] == piece_type)[0]

const STRING_TO_TYPE: Dictionary[String, Piece.Type] = {
	"king": Piece.Type.KING,
	"queen": Piece.Type.QUEEN,
	"rook": Piece.Type.ROOK,
	"bishop": Piece.Type.BISHOP,
	"knight": Piece.Type.KNIGHT,
	"pawn": Piece.Type.PAWN,
}
const TYPE_TO_STRING: Dictionary[Piece.Type, String] = {
	Piece.Type.KING: "king",
	Piece.Type.QUEEN: "queen",
	Piece.Type.ROOK: "rook",
	Piece.Type.BISHOP: "bishop",
	Piece.Type.KNIGHT: "knight",
	Piece.Type.PAWN: "pawn",
}
