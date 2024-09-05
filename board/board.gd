class_name Board extends Node3D

signal tile_selected(tile: Tile)

# The board can only be up to 16x16 in size, max.
# The tile positions can be anywhere from (0, 0) to (15, 15)
const MAX_X: = 16
const MAX_Y: = 16
const NOISE_SCALE: float = 7

const CENTER: = Vector2((MAX_X - 1) * 0.5, (MAX_Y - 1) * 0.5)

const tile_scene: = preload("res://board/tile.tscn")

var tiles: Dictionary
var pieces: Dictionary

func get_tile(pos: Vector2i) -> Tile:
	return tiles[pos] as Tile

func generate_tiles() -> void:
	var tentative_tile_positions: Array[Vector2i] = []

	var noise: = FastNoiseLite.new()
	noise.seed = randi()
	noise.offset = Vector3(.5, .5, .5)
	for y: int in MAX_Y:
		for x: int in MAX_X:
			var val: = noise.get_noise_2d(x * NOISE_SCALE, y * NOISE_SCALE)
			val = (val + 1) / 2
			print(val)
			# val should be boosted depending on how close it is to the center
			var dist: = Vector2(x, y).distance_to(CENTER)
			var normalized_dist: = dist / (MAX_X * sqrt(2) / 2)
			val = val * (1 - normalized_dist)

			if absf(val) > 0.3:
				tentative_tile_positions.append(Vector2i(x, y))

	for tile_pos: Vector2i in tentative_tile_positions:
		var tile: = tile_scene.instantiate()
		tile.name = "Tile_%v" % tile_pos
		add_child(tile)
		tile.mouse_selected.connect(on_tile_selected.bind(tile))
		tile.position = Vector3(tile_pos.x, 0, tile_pos.y)
		tile.init(tile_pos)

		tiles[tile_pos] = tile

func generate_pieces() -> void:
	var queen: Queen = preload("res://pieces/queen.tscn").instantiate()
	spawn_piece(queen, tiles.values()[0].pos)

	var king: King = preload("res://pieces/king.tscn").instantiate()
	spawn_piece(king, tiles.values()[1].pos)

	var knight: Knight = preload("res://pieces/knight.tscn").instantiate()
	spawn_piece(knight, tiles.values()[2].pos)

func spawn_piece(piece: Piece, dest: Vector2i) -> void:
	assert(not pieces.values().has(piece))
	assert(not get_piece(dest))
	assert(get_tile(dest))

	add_child(piece)
	piece.set_team(Team.s.ALLY_PLAYER)
	piece.set_pos(dest)
	piece.position = get_tile(dest).position
	pieces[piece.pos()] = piece

func move_piece(piece: Piece, dest: Vector2i) -> void:
	assert(pieces.values().has(piece))
	assert(piece.get_available_squares(self).has(dest))

	pieces.erase(piece.pos())

	var existing_piece: = get_piece(dest)
	if existing_piece:
		assert(Team.hostile_to_each_other(piece.team(), existing_piece.team()))
		existing_piece.queue_free()
		pieces.erase(existing_piece)

	piece.set_pos(dest)
	create_tween().tween_property(piece, "position", Vector3(dest.x, 0, dest.y), 0.1)
	pieces[piece.pos()] = piece


func on_tile_selected(tile: Tile) -> void:
	tile_selected.emit(tile)

func has_tile(pos: Vector2i) -> bool:
	return tiles.has(pos)

func get_piece(pos: Vector2i) -> Piece:
	return pieces.get(pos)
