class_name BoardTileMap

var _tiles: Array[Array]

func has_tile(coord: Vector2i) -> bool:
	return _tiles[coord.y][coord.x]
