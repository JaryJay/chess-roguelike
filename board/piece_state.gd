class_name PieceState

var id: int
var pos: Vector2i
var type: Piece.Type
var team: Team

func _init(_pos: Vector2i, _type: Piece.Type, _team: Team) -> void:
	id = generate_id()
	pos = _pos
	type = _type
	team = _team

func get_available_squares(b_state: BoardState) -> Array[Vector2i]:
	assert(type != Piece.Type.UNSET, "Type must be set")
	match type:
		Piece.Type.KING:
			return king_get_available_squares(b_state)
		Piece.Type.QUEEN:
			return queen_get_available_squares(b_state)
		Piece.Type.ROOK:
			return rook_get_available_squares(b_state)
		Piece.Type.BISHOP:
			return bishop_get_available_squares(b_state)
		Piece.Type.KNIGHT:
			return knight_get_available_squares(b_state)
		Piece.Type.PAWN:
			return pawn_get_available_squares(b_state)
	
	assert(false, "Impossible!!")
	return []

#region get_available_square implementation

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

func king_get_available_squares(s: BoardState) -> Array[Vector2i]:
	var available_squares: Array[Vector2i] = []

	for dir: Vector2i in EIGHT_DIRECTIONS:
		var currently_checking: = pos + dir
		if not s.has_tile(currently_checking): continue
		var piece_state: = s.get_piece_state(currently_checking)

		if piece_state:
			if piece_state.team.is_hostile_to(team):
				available_squares.append(currently_checking)
			continue

		available_squares.append(currently_checking)

	# Eliminate squares that would put king in check
	# TODO

	return available_squares

func queen_get_available_squares(s: BoardState) -> Array[Vector2i]:
	var available_squares: Array[Vector2i] = []

	for dir: Vector2i in EIGHT_DIRECTIONS:
		var currently_checking: = pos + dir
		while true:
			if not s.has_tile(currently_checking): break
			var piece_state: = s.get_piece_state(currently_checking)
	
			if piece_state:
				if piece_state.team.is_hostile_to(team):
					available_squares.append(currently_checking)
				break
	
			available_squares.append(currently_checking)
			currently_checking = currently_checking + dir
			continue
	
	return available_squares

const FOUR_DIRECTIONS: = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),  Vector2i(0, -1)]

func rook_get_available_squares(s: BoardState) -> Array[Vector2i]:
	var available_squares: Array[Vector2i] = []

	for dir: Vector2i in FOUR_DIRECTIONS:
		var currently_checking: = pos + dir
		while true:
			if not s.has_tile(currently_checking): break
			var piece_state: = s.get_piece_state(currently_checking)

			if piece_state:
				if piece_state.team.is_hostile_to(team):
					available_squares.append(currently_checking)
				break

			available_squares.append(currently_checking)
			currently_checking = currently_checking + dir
			continue

	return available_squares

const DIAGONAL_DIRECTIONS: = [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)]

func bishop_get_available_squares(s: BoardState) -> Array[Vector2i]:
	var available_squares: Array[Vector2i] = []

	for dir: Vector2i in DIAGONAL_DIRECTIONS:
		var currently_checking: = pos + dir
		while true:
			if not s.has_tile(currently_checking): break
			var piece_state: = s.get_piece_state(currently_checking)

			if piece_state:
				if piece_state.team.is_hostile_to(team):
					available_squares.append(currently_checking)
				break

			available_squares.append(currently_checking)
			currently_checking = currently_checking + dir
			continue

	return available_squares

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

func knight_get_available_squares(s: BoardState) -> Array[Vector2i]:
	var available_squares: Array[Vector2i] = []

	for dir: Vector2i in KNIGHT_DIRECTIONS:
		var currently_checking: = pos + dir
		if not s.has_tile(currently_checking): continue
		var piece_state: = s.get_piece_state(currently_checking)

		if not piece_state or piece_state.team.is_hostile_to(team):
			available_squares.append(currently_checking)

	return available_squares

const DIAGONALS_PLAYER: = [Vector2i(1, -1), Vector2i(1, -1)]
const DIAGONALS_ENEMY: = [Vector2i(1, 1), Vector2i(1, 1)]

func pawn_get_available_squares(s: BoardState) -> Array[Vector2i]:
	var available_squares: Array[Vector2i] = []
	
	var y_modifier: = -1 if team.is_player() else 1
	
	var forwards: = pos + Vector2i(0, y_modifier)
	if s.has_tile(forwards) and not s.has_piece(forwards):
		available_squares.append(forwards)
	
	var sides: = [Vector2i.LEFT, Vector2i.RIGHT]
	for side: Vector2i in sides:
		var square: = pos + side + Vector2i(0, y_modifier)
		if s.has_piece(square) and s.get_piece_state(square).team.is_hostile_to(team):
			available_squares.append(square)
	
	return available_squares

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

func duplicate() -> PieceState:
	var new_piece_state: = PieceState.new(pos, type, team)
	new_piece_state.id = id
	assert(self.equals(new_piece_state))
	return new_piece_state

func equals(p: PieceState) -> bool:
	return id == p.id and pos == p.pos and type == p.type and team == p.team

# Generating ids
static var _next_id: = 1
static func generate_id() -> int:
	var _id: = _next_id
	_next_id += 1
	return _id
