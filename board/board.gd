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
	var tile: = tiles.values()[0] as Tile
	var piece: Queen = preload("res://pieces/queen.tscn").instantiate()
	add_child(piece)
	piece.set_pos(tile.pos)
	piece.position = tile.position
	pieces[piece.pos()] = piece

func on_tile_selected(tile: Tile) -> void:
	print("Selected tile")
	tile_selected.emit(tile)

func has_tile(pos: Vector2i) -> bool:
	return tiles.has(pos)

func get_piece(pos: Vector2i) -> Piece:
	return pieces.get(pos)
