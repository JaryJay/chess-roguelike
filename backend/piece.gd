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

var type: Type
var team: Team
var pos: Vector2i

func _init(_type: Type, _team: Team, _pos: Vector2i) -> void:
	type = _type
	team = _team
	pos = _pos

func get_available_moves(b: Board) -> Array[Move]:
	assert(type != Type.UNSET, "Type must be set")
	assert(b.tile_map.has_tile(pos), "There should be a tile at the current piece position")
	match type:
		Type.KING:
			return _king_get_available_moves(b)
		Type.QUEEN:
			return _queen_get_available_moves(b)
		Type.ROOK:
			return _rook_get_available_moves(b)
		Type.BISHOP:
			return _bishop_get_available_moves(b)
		Type.KNIGHT:
			return _knight_get_available_moves(b)
		Type.PAWN:
			return _pawn_get_available_moves(b)
	
	assert(false, "piece.gd: get_avilable_moves not implemented for type %s" % type)
	return []

func is_attacking_square(p: Vector2i, b: Board) -> bool:
	assert(type != Type.UNSET, "Type must be set")
	assert(b.piece_map.has_piece(p), "There should be a piece that we're checking")
	assert(b.tile_map.has_tile(p), "There should be a tile at the target position")
	assert(b.tile_map.has_tile(pos), "There should be a tile at the current piece position")
	assert(p != pos, "There should not be two pieces in the same position")
	match type:
		Type.KING:
			return _king_is_attacking_square(p, b)
		Type.QUEEN:
			return _queen_is_attacking_square(p, b)
		Type.ROOK:
			return _rook_is_attacking_square(p, b)
		Type.BISHOP:
			return _bishop_is_attacking_square(p, b)
		Type.KNIGHT:
			return _knight_is_attacking_square(p, b)
		Type.PAWN:
			return _pawn_is_attacking_square(p, b)
	
	assert(false, "piece.gd: is_attacking_square not implemented for type %s" % type)
	return false;

#region get_available_moves implementation

const BOARD_LENGTH_UPPER_BOUND: int = 20

const EIGHT_DIRECTIONS: = [
	Vector2i(1, 0),
	Vector2i(1, 1),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
]

func _king_get_available_moves(b: Board) -> Array[Move]:
	var available_moves: Array[Move] = []

	for dir: Vector2i in EIGHT_DIRECTIONS:
		var next_pos: = pos + dir
		if not b.tile_map.has_tile(next_pos): continue
		var piece: = b.piece_map.get_piece(next_pos)

		if piece:
			if piece.team.is_hostile_to(team):
				available_moves.append(Move.new(pos, next_pos, Move.CAPTURE))
			continue

		available_moves.append(Move.new(pos, next_pos))

	# Eliminate moves that would put king in check
	# TODO
	
	# TODO: Add castling

	return available_moves

func _queen_get_available_moves(b: Board) -> Array[Move]:
	return _get_moves_along_rays(EIGHT_DIRECTIONS, b)

const FOUR_DIRECTIONS: = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),  Vector2i(0, -1)]

func _rook_get_available_moves(b: Board) -> Array[Move]:
	return _get_moves_along_rays(FOUR_DIRECTIONS, b)

const DIAGONAL_DIRECTIONS: = [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)]

func _bishop_get_available_moves(b: Board) -> Array[Move]:
	return _get_moves_along_rays(DIAGONAL_DIRECTIONS, b)

const KNIGHT_DIRECTIONS: = [
	Vector2i(2, 1),
	Vector2i(1, 2),
	Vector2i(-1, 2),
	Vector2i(-2, 1),
	Vector2i(-2, -1),
	Vector2i(-1, -2),
	Vector2i(1, -2),
	Vector2i(2, -1),
]

func _knight_get_available_moves(b: Board) -> Array[Move]:
	var available_moves: Array[Move] = []

	for dir: Vector2i in KNIGHT_DIRECTIONS:
		var next_pos: = pos + dir
		if not b.tile_map.has_tile(next_pos): continue

		if not b.piece_map.has_piece(next_pos):
			available_moves.append(Move.new(pos, next_pos))
		elif b.piece_map.get_piece(next_pos).team.is_hostile_to(team):
			available_moves.append(Move.new(pos, next_pos, Move.CAPTURE))

	return available_moves

const DIAGONALS_PLAYER: = [Vector2i(1, -1), Vector2i(1, -1)]
const DIAGONALS_ENEMY: = [Vector2i(1, 1), Vector2i(1, 1)]

func _pawn_get_available_moves(b: Board) -> Array[Move]:
	var available_moves: Array[Move] = []
	
	var facing_dir: = _get_pawn_facing_direction()
	
	var forwards: = pos + facing_dir
	if b.tile_map.has_tile(forwards) and not b.piece_map.has_piece(forwards):
		# Going forwards is possible
		if b.tile_map.has_tile(forwards + facing_dir):
			# In this case, we don't promote
			available_moves.append(Move.new(pos, forwards))
		else:
			# We promote the piece if there is no longer another tile in front
			for promo_type: Piece.Type in _pawn_promotion_types():
				available_moves.append(Move.new(pos, forwards, 0, promo_type))
	
	for side: Vector2i in PAWN_SIDES:
		var square: = pos + side + facing_dir
		if b.piece_map.has_piece(square) and b.piece_map.get_piece(square).team.is_hostile_to(team):
			if b.tile_map.has_tile(square + facing_dir):
				# Don't promote
				available_moves.append(Move.new(pos, square, Move.CAPTURE))
			else:
				for promo_type: Piece.Type in _pawn_promotion_types():
					available_moves.append(Move.new(pos, square, Move.CAPTURE, promo_type))
	
	return available_moves

func _pawn_promotion_types() -> Array[Piece.Type]:
	return [Piece.Type.QUEEN, Piece.Type.ROOK, Piece.Type.BISHOP, Piece.Type.KNIGHT]

#endregion

#region is_attacking_square implementation

func _king_is_attacking_square(p: Vector2i, b: Board) -> bool:
	var _abs = (p - pos).abs()
	return _abs.x <= 1 && _abs.y <= 1

func _queen_is_attacking_square(p: Vector2i, b: Board) -> bool:
	var _abs: = (p - pos).abs()
	if _abs.x != 0 and _abs.y != 0 and _abs.x != _abs.y:
		return false
	assert(_abs != Vector2i.ZERO)
	var dir: = (p - pos) / maxi(_abs.x, _abs.y)
	assert (dir.abs().x <= 1 && dir.abs().y <= 1)
	
	return _is_attacking_from_ray(p, dir, b)

func _rook_is_attacking_square(p: Vector2i, b: Board) -> bool:
	var diff: = p - pos
	if diff.x != 0 and diff.y != 0:
		return false
	var dir: = diff / absi(diff.x) if diff.x != 0 else diff / absi(diff.y)
	
	return _is_attacking_from_ray(p, dir, b)

func _bishop_is_attacking_square(p: Vector2i, b: Board) -> bool:
	var diff: = p - pos
	if diff.abs().x != diff.abs().y:
		return false
	var dir: = diff / diff.abs().x
	
	return _is_attacking_from_ray(p, dir, b)

func _knight_is_attacking_square(p: Vector2i, b: Board) -> bool:
	var abs_diff: = (p - pos).abs()
	return (abs_diff.x == 1 and abs_diff.y == 2) or (abs_diff.x == 2 and abs_diff.y == 1)

func _pawn_is_attacking_square(p: Vector2i, b: Board) -> bool:
	var facing_dir: = _get_pawn_facing_direction()
	
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
) -> Array[Move]:
	var available_moves: Array[Move] = []
	for dir: Vector2i in ray_dirs:
		var next_pos: = pos
		for i in range(ray_length):
			next_pos += dir
			if not b.tile_map.has_tile(next_pos): break
			var piece: = b.piece_map.get_piece(next_pos)
			if piece:
				if piece.team.is_hostile_to(team):
					available_moves.append(next_pos)
				break
			available_moves.append(Move.new(pos, next_pos))
	return available_moves

func _get_pawn_facing_direction() -> Vector2i:
	var y_modifier: = -1 if team.is_player() else 1
	return Vector2i(0, y_modifier)

var PAWN_SIDES: = [Vector2i.LEFT, Vector2i.RIGHT]

func _is_attacking_from_ray(
	p: Vector2i,
	dir: Vector2i,
	b: Board,
	ray_length: int = BOARD_LENGTH_UPPER_BOUND,
) -> bool:
	var next_pos: = pos
	for i in range(ray_length):
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
	var new_piece: = Piece.new(type, team, pos)
	assert(self.equals(new_piece))
	return new_piece

func equals(p: Piece) -> bool:
	return pos == p.pos and type == p.type and team == p.team
