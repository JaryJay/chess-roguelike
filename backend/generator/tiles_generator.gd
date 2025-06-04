class_name TilesGenerator

const PRUNE_TILES := true
const CARDINAL_DIRECTIONS = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

static func generate_board_with_tiles(min_tiles: int, retries: int = 10) -> Board:
	var board := Board.new()
	
	for retry in retries:
		var positions := generate_raw_positions()
		var pruned_positions := prune_positions(positions)
		var normalized_positions := normalize_positions(pruned_positions)
		
		if normalized_positions.size() >= min_tiles:
			board.tile_map.set_tiles(normalized_positions)
			return board
			
		print("only generated %d tiles, retrying" % normalized_positions.size())
	
	push_error("Failed to generate board with enough tiles after %d attempts" % retries)
	return board

static func generate_raw_positions() -> Array[Vector2i]:
	var raw_positions: Array[Vector2i] = []
	
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.offset = Vector3(.5, .5, .5)
	for y: int in Config.max_board_size:
		for x: int in Config.max_board_size:
			var val := noise.get_noise_2d(x * Config.tile_generation_noise_scale, y * Config.tile_generation_noise_scale)
			val = (val + 1) / 2
			# val should be boosted depending on how close it is to the center
			var dist := Vector2(x, y).distance_to(Vector2.ONE * Config.max_board_size / 2)
			var normalized_dist := dist / (Config.max_board_size * sqrt(2) / 2)
			val = val * (1 - normalized_dist)

			if absf(val) > Config.tile_generation_threshold:
				raw_positions.append(Vector2i(x, y))
	
	return raw_positions

static func prune_positions(positions: Array[Vector2i]) -> Array[Vector2i]:
	if not PRUNE_TILES:
		return positions
		
	var pruned_positions: Array[Vector2i] = []
	# Prune positions that are not cardinally adjacent to another tile
	for tile_pos: Vector2i in positions:
		var good_tile := false
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
	var avg_pos := Vector2.ZERO
	for pos in positions:
		avg_pos += Vector2(pos)
	avg_pos /= positions.size()
	
	# Calculate the initial offset needed to center the tiles
	var target_center := Vector2(Config.max_board_size / 2, Config.max_board_size / 2)
	var offset := (target_center - avg_pos).round()
	
	# Find the bounds after applying the offset
	var min_pos := Vector2i(INF, INF)
	var max_pos := Vector2i(-INF, -INF)
	for pos in positions:
		var new_pos := Vector2i(pos) + Vector2i(offset)
		min_pos.x = mini(min_pos.x, new_pos.x)
		min_pos.y = mini(min_pos.y, new_pos.y)
		max_pos.x = maxi(max_pos.x, new_pos.x)
		max_pos.y = maxi(max_pos.y, new_pos.y)
	
	# Adjust offset if any positions would be out of bounds
	offset.x += mini(0, -min_pos.x)  # Shift right if too far left
	offset.x -= maxi(0, max_pos.x - (Config.max_board_size - 1))  # Shift left if too far right
	offset.y += mini(0, -min_pos.y)  # Shift down if too far up
	offset.y -= maxi(0, max_pos.y - (Config.max_board_size - 1))  # Shift up if too far down
	
	# Apply the adjusted offset to all positions
	var normalized_positions: Array[Vector2i] = []
	for pos in positions:
		normalized_positions.append(Vector2i(pos) + Vector2i(offset))
	
	return normalized_positions
