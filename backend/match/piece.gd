class_name Piece

enum Type {
	UNSET,
	PAWN,
	KNIGHT,
	BISHOP,
	ROOK,
	QUEEN,
	KING,
	RESERVED_0,
	RESERVED_1,
}

var type: Type
var team: Team
var pos: Vector2i

func _init(_type: Type, _team: Team, _pos: Vector2i) -> void:
	type = _type
	team = _team
	pos = _pos

func get_available_moves(m: Match) -> Array[Move]:
	assert(type != Type.UNSET, "Type must be set")
	assert(m.tile_map.has_tile(pos), "There should be a tile at the current piece position")
	match type:
		Type.KING:
			return king_get_available_moves(m)
		Type.QUEEN:
			return queen_get_available_moves(m)
		Type.ROOK:
			return rook_get_available_moves(m)
		Type.BISHOP:
			return bishop_get_available_moves(m)
		Type.KNIGHT:
			return knight_get_available_moves(m)
		Type.PAWN:
			return pawn_get_available_moves(m)
	
	assert(false, "piece.gd: get_avilable_moves not implemented for type %s" % type)
	return []

#region get_available_moves implementation

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

func king_get_available_moves(m: Match) -> Array[Move]:
	var available_moves: Array[Move] = []

	for dir: Vector2i in EIGHT_DIRECTIONS:
		var next_pos: = pos + dir
		if not m.tile_map.has_tile(next_pos): continue
		var piece: = m.piece_map.get_piece(next_pos)

		if piece:
			if piece.team.is_hostile_to(team):
				available_moves.append(next_pos)
			continue

		available_moves.append(Move.new(pos, next_pos))

	# Eliminate moves that would put king in check
	# TODO
	
	# TODO: Add castling

	return available_moves

func queen_get_available_moves(m: Match) -> Array[Move]:
	var available_moves: Array[Move] = []

	for dir: Vector2i in EIGHT_DIRECTIONS:
		var next_pos: = pos
		for i in range(20):
			next_pos += dir
			if not m.tile_map.has_tile(next_pos): break
			var piece: = m.piece_map.get_piece(next_pos)
	
			if piece:
				if piece.team.is_hostile_to(team):
					available_moves.append(next_pos)
				break
	
			available_moves.append(next_pos)
			continue
	
	return available_moves

const FOUR_DIRECTIONS: = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),  Vector2i(0, -1)]

func rook_get_available_moves(m: Match) -> Array[Move]:
	var available_moves: Array[Move] = []

	for dir: Vector2i in FOUR_DIRECTIONS:
		var next_pos: = pos
		for i in range(20):
			next_pos += dir
			if not m.tile_map.has_tile(next_pos): break
			var piece: = m.piece_map.get_piece(next_pos)

			if piece:
				if piece.team.is_hostile_to(team):
					available_moves.append(next_pos)
				break

			available_moves.append(Move.new(pos, next_pos))
			continue

	return available_moves

const DIAGONAL_DIRECTIONS: = [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)]

func bishop_get_available_moves(m: Match) -> Array[Move]:
	var available_moves: Array[Move] = []

	for dir: Vector2i in DIAGONAL_DIRECTIONS:
		var next_pos: = pos
		for i in range(20):
			next_pos += dir
			if not m.tile_map.has_tile(next_pos): break
			var piece: = m.piece_map.get_piece(next_pos)

			if piece:
				if piece.team.is_hostile_to(team):
					available_moves.append(next_pos)
				break

			available_moves.append(Move.new(pos, next_pos))
			continue

	return available_moves

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

func knight_get_available_moves(m: Match) -> Array[Move]:
	var available_moves: Array[Move] = []

	for dir: Vector2i in KNIGHT_DIRECTIONS:
		var next_pos: = pos + dir
		if not m.tile_map.has_tile(next_pos): continue
		var piece: = m.piece_map.get_piece(next_pos)

		if not piece or piece.team.is_hostile_to(team):
			available_moves.append(Move.new(pos, next_pos))

	return available_moves

const DIAGONALS_PLAYER: = [Vector2i(1, -1), Vector2i(1, -1)]
const DIAGONALS_ENEMY: = [Vector2i(1, 1), Vector2i(1, 1)]

func pawn_get_available_moves(m: Match) -> Array[Move]:
	var available_moves: Array[Move] = []
	
	var y_modifier: = -1 if team.is_player() else 1
	
	var forwards: = pos + Vector2i(0, y_modifier)
	if m.tile_map.has_tile(forwards) and not m.piece_map.has_piece(forwards):
		if m.tile_map.has_tile(forwards + Vector2i(0, y_modifier)):
			# In this case, we don't promote
			available_moves.append(Move.new(pos, forwards))
		else:
			# We promote the piece if there is no longer another tile in front
			for promotion_type: Move.Promotion in Move.Promotion.keys():
				available_moves.append(Move.new(pos, forwards, promotion_type))
	
	var sides: = [Vector2i.LEFT, Vector2i.RIGHT]
	for side: Vector2i in sides:
		var square: = pos + side + Vector2i(0, y_modifier)
		if m.piece_map.has_piece(square) and m.piece_map.get_piece(square).team.is_hostile_to(team):
			if m.tile_map.has_tile(square + Vector2i(0, y_modifier)):
				# Don't promote
				available_moves.append(Move.new(pos, square))
			else:
				for promotion_type: Move.Promotion in Move.Promotion.keys():
					available_moves.append(Move.new(pos, forwards, promotion_type))
	
	return available_moves

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
