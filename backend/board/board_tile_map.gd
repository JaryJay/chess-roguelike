class_name BoardTileMap

var _tiles: Array[Array]
var _cached_tile_count := 0

func get_all_tiles() -> Array[Vector2i]:
	var all_tiles: Array[Vector2i] = []
	
	for y in _tiles.size():
		for x in _tiles[y].size():
			var pos := Vector2i(x, y)
			if has_tile(pos):
				all_tiles.append(pos)
	
	return all_tiles

func set_tiles(tile_positions: Array[Vector2i]) -> void:
	_tiles.resize(Config.max_board_size)
	for y in _tiles.size():
		_tiles[y] = []
		_tiles[y].resize(Config.max_board_size)
		_tiles[y].fill(false)
	
	for tile_pos: Vector2i in tile_positions:
		_tiles[tile_pos.y][tile_pos.x] = true
		_cached_tile_count += 1
	assert(num_tiles() == tile_positions.size())

func is_promotion_tile(pos: Vector2i, team: Team) -> bool:
	var y_modifier := -1 if team.is_player() else 1
	var pawn_facing_dir := Vector2i(0, y_modifier)
	return !has_tile(pos + pawn_facing_dir)

func has_tile(coord: Vector2i) -> bool:
	if coord.x < 0 or coord.x >= Config.max_board_size or coord.y < 0 or coord.y >= Config.max_board_size:
		return false
	return _tiles[coord.y][coord.x]

func num_tiles() -> int:
	return _cached_tile_count
