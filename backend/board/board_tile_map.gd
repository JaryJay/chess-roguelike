class_name BoardTileMap

const MAX_TILE_MAP_SIZE: = 12

var _tiles: Array[Array]
var _cached_tile_count: = 0

func get_all_tiles() -> Array[Vector2i]:
	var all_tiles: Array[Vector2i] = []
	
	for y in _tiles.size():
		for x in _tiles[y].size():
			var pos: = Vector2i(x, y)
			if has_tile(pos):
				all_tiles.append(pos)
	
	return all_tiles

func set_tiles(tile_positions: Array[Vector2i]) -> void:
	_tiles.resize(MAX_TILE_MAP_SIZE)
	for y in _tiles.size():
		_tiles[y] = []
		_tiles[y].resize(12)
		_tiles[y].fill(false)
	
	for tile_pos: Vector2i in tile_positions:
		_tiles[tile_pos.y][tile_pos.x] = true
		_cached_tile_count += 1
	assert(num_tiles() == tile_positions.size())

func is_promotion_tile(pos: Vector2i, team: Team) -> bool:
	var y_modifier: = -1 if team.is_player() else 1
	var pawn_facing_dir: = Vector2i(0, y_modifier)
	return !has_tile(pos + pawn_facing_dir)

func has_tile(coord: Vector2i) -> bool:
	return _tiles[coord.y][coord.x]

func num_tiles() -> int:
	return _cached_tile_count
