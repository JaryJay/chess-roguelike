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
	var raw_positions: = generate_raw_positions()
	var pruned_positions: = prune_positions(raw_positions)
	return normalize_positions(pruned_positions)

static func generate_raw_positions() -> Array[Vector2i]:
	var raw_positions: Array[Vector2i] = []
	
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
				raw_positions.append(Vector2i(x, y))
	
	return raw_positions

static func prune_positions(positions: Array[Vector2i]) -> Array[Vector2i]:
	if not PRUNE_TILES:
		return positions
		
	var pruned_positions: Array[Vector2i] = []
	# Prune positions that are not cardinally adjacent to another tile
	for tile_pos: Vector2i in positions:
		var good_tile: = false
		for cardinal_dir: Vector2i in CARDINAL_DIRECTIONS:
			if positions.has(tile_pos + cardinal_dir):
				good_tile = true
				break
		if good_tile:
			pruned_positions.append(tile_pos)
		else:
			print("pruned position %v" % tile_pos)
	
	return pruned_positions

static func normalize_positions(positions: Array[Vector2i]) -> Array[Vector2i]:
	# Calculate average position
	var avg_pos: = Vector2.ZERO
	for pos in positions:
		avg_pos += Vector2(pos)
	avg_pos /= positions.size()
	
	# Calculate the offset needed to center the tiles
	var target_center: = Vector2(MAX_X / 2, MAX_Y / 2)
	var offset: = (target_center - avg_pos).round()
	
	# Apply the offset to all positions
	var normalized_positions: Array[Vector2i] = []
	for pos in positions:
		var new_pos: = Vector2i(pos) + Vector2i(offset)
		# Ensure the new position is within bounds
		if new_pos.x >= 0 and new_pos.x < MAX_X and new_pos.y >= 0 and new_pos.y < MAX_Y:
			normalized_positions.append(new_pos)
	
	return normalized_positions