class_name TileNodes extends Node2D

signal tile_node_selected(tile_node: TileNode)

const tile_node_scene: = preload("res://frontend/tile/tile_node.tscn")

var _tile_nodes: Array[Array]
var _cached_tile_count: = 0

func get_all_tile_nodes() -> Array[TileNode]:
	var all_tile_nodes: Array[TileNode] = []
	
	for y in _tile_nodes.size():
		for x in _tile_nodes[y].size():
			var pos: = Vector2i(x, y)
			if has_tile_node(pos):
				all_tile_nodes.append(pos)
	
	return all_tile_nodes

func create_tile_nodes(tile_positions: Array[Vector2i]) -> void:
	_tile_nodes.resize(BoardTileMap.MAX_TILE_MAP_SIZE)
	for y in _tile_nodes.size():
		_tile_nodes[y] = []
		_tile_nodes[y].resize(12)
		_tile_nodes[y].fill(false)
	
	for tile_pos: Vector2i in tile_positions:
		var tile_node: TileNode = tile_node_scene.instantiate()
		add_child(tile_node)
		tile_node.init(tile_pos)
		tile_node.mouse_selected.connect(_on_tile_node_selected.bind(tile_node))
		_tile_nodes[tile_pos.y][tile_pos.x] = tile_node
		_cached_tile_count += 1
		
	assert(num_tile_nodes() == tile_positions.size())

func get_tile_node(coord: Vector2i) -> TileNode:
	return _tile_nodes[coord.y][coord.x]

func has_tile_node(coord: Vector2i) -> bool:
	return _tile_nodes[coord.y][coord.x] != null

func num_tile_nodes() -> int:
	return _cached_tile_count

func _on_tile_node_selected(tile_node: TileNode) -> void:
	tile_node_selected.emit(tile_node)
