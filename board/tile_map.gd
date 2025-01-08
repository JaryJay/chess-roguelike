class_name BoardTileMap

var tiles: Array[Array]

func get_tile(x: int, y: int) -> Tile:
	return tiles[x][y] as Tile
