class_name TilesGenerator

# The board can only be up to 16x16 in size, max.
# The tile positions can be anywhere from (0, 0) to (11, 11)
const MAX_X: = 12
const MAX_Y: = 12
const NOISE_SCALE: float = 7
const PRUNE_TILES: = false

const CENTER: = Vector2((MAX_X - 1) * 0.5, (MAX_Y - 1) * 0.5)
const CARDINAL_DIRECTIONS = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

static func generate_tiles() -> Array[Vector2i]:
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

			if absf(val) > 0.25:
				tentative_tile_positions.append(Vector2i(x, y))
	
	var pruned_tile_positions: Array[Vector2i] = []
	if PRUNE_TILES:
		# Prune tentative_tile_positions that are not cardinally adjacent to another tile
		for tile_pos: Vector2i in tentative_tile_positions:
			var good_tile: = false
			for cardinal_dir: Vector2i in CARDINAL_DIRECTIONS:
				if tentative_tile_positions.has(tile_pos + cardinal_dir):
					good_tile = true
					break
			if good_tile:
				pruned_tile_positions.append(tile_pos)
			else:
				print("pruned position %v" % tile_pos)
	else:
		pruned_tile_positions = tentative_tile_positions
	
	return pruned_tile_positions
