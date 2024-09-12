class_name Board extends Node2D


signal tile_selected(tile: Tile)

# The board can only be up to 16x16 in size, max.
# The tile positions can be anywhere from (0, 0) to (15, 15)
const MAX_X: = 16
const MAX_Y: = 16
const NOISE_SCALE: float = 7

const CENTER: = Vector2((MAX_X - 1) * 0.5, (MAX_Y - 1) * 0.5)

const tile_scene: = preload("res://board/tile.tscn")

var state: BoardState = BoardState.new()

func generate_tiles() -> void:
	var tentative_tile_positions: Array[Vector2i] = []

	var noise: = FastNoiseLite.new()
	noise.seed = randi()
	noise.offset = Vector3(.5, .5, .5)
	for y: int in MAX_Y:
		for x: int in MAX_X:
			var val: = noise.get_noise_2d(x * NOISE_SCALE, y * NOISE_SCALE)
			val = (val + 1) / 2
			# val should be boosted depending on how close it is to the center
			var dist: = Vector2(x, y).distance_to(CENTER)
			var normalized_dist: = dist / (MAX_X * sqrt(2) / 2)
			val = val * (1 - normalized_dist)

			if absf(val) > 0.3:
				tentative_tile_positions.append(Vector2i(x, y))
	
	# Prune tentative_tile_positions that are not cardinally adjacent to another tile
	var pruned_tile_positions: Array[Vector2i] = []
	const cardinal_directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for tile_pos: Vector2i in tentative_tile_positions:
		var good_tile: = false
		for cardinal_dir: Vector2i in cardinal_directions:
			if tentative_tile_positions.has(tile_pos + cardinal_dir):
				good_tile = true
				break
		if good_tile:
			pruned_tile_positions.append(tile_pos)
		else:
			print("pruned position %v" % tile_pos)

	for tile_pos: Vector2i in pruned_tile_positions:
		var tile: = tile_scene.instantiate()
		tile.name = "Tile_%v" % tile_pos
		add_child(tile)
		tile.mouse_selected.connect(on_tile_selected.bind(tile))
		tile.position = Vector2(tile_pos.x, tile_pos.y) * 16
		tile.init(tile_pos)

		state.tiles[tile_pos] = tile

func generate_pieces() -> void:
	var enemy_army: = ArmyGenerator.generate_army(1680, state, Team.ENEMY_AI)
	for piece: Piece in enemy_army:
		spawn_piece(piece, piece.pos())
	
	var army: = ArmyGenerator.generate_army(1680, state, Team.PLAYER)
	for piece: Piece in army:
		spawn_piece(piece, piece.pos())
	
	#var king: King = preload("res://pieces/king.tscn").instantiate()
	#spawn_piece(king, tiles.values()[1].pos())
#
	#var knight: Knight = preload("res://pieces/knight.tscn").instantiate()
	#spawn_piece(knight, tiles.values()[2].pos())
#
	#var bishop: Bishop = preload("res://pieces/bishop.tscn").instantiate()
	#spawn_piece(bishop, tiles.values()[3].pos())
#
	#var rook: Rook = preload("res://pieces/rook.tscn").instantiate()
	#spawn_piece(rook, tiles.values()[4].pos())
#
	#var pawn: Pawn = preload("res://pieces/pawn.tscn").instantiate()
	#spawn_piece(pawn, tiles.values()[-1].pos())

func spawn_piece(piece: Piece, dest: Vector2i) -> void:
	assert(not state.pieces.values().has(piece))
	assert(not state.get_piece(dest))
	assert(state.get_tile(dest))

	add_child(piece)
	piece.set_pos(dest)
	piece.position = state.get_tile(dest).position
	state.pieces[piece.pos()] = piece

func perform_move(move: Move) -> void:
	var piece: = move.piece
	assert(state.pieces.values().has(piece))
	assert(piece.get_available_squares(state).has(move.to))

	state.pieces.erase(piece.pos())

	var existing_piece: = state.get_piece(move.to)
	if existing_piece:
		assert(piece.team().is_hostile_to(existing_piece.team()))
		existing_piece.queue_free()
		state.pieces.erase(existing_piece)

	piece.set_pos(move.to)
	create_tween().tween_property(piece, "position", Vector2(move.to.x, move.to.y) * 16, 0.1)
	state.pieces[piece.pos()] = piece

func on_tile_selected(tile: Tile) -> void:
	tile_selected.emit(tile)
