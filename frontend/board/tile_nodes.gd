class_name TileNodes extends Node2D

signal tile_node_selected(tile_node: TileNode)

const tile_node_scene := preload("res://frontend/tile/tile_node.tscn")

var _tile_nodes: Array[Array]
var _cached_tile_count := 0
var _highlighted_tiles: Array[Vector2i] = []
var _premove_from: Vector2i = Vector2i(-1, -1)
var _premove_to: Vector2i = Vector2i(-1, -1)
var _drag_hover_tile: Vector2i = Vector2i(-1, -1)

func get_all_tile_nodes() -> Array[TileNode]:
	var all_tile_nodes: Array[TileNode] = []
	
	for y in _tile_nodes.size():
		for x in _tile_nodes[y].size():
			var pos := Vector2i(x, y)
			if has_tile_node(pos):
				all_tile_nodes.append(get_tile_node(pos))
	
	return all_tile_nodes

func create_tile_nodes(tile_positions: Array[Vector2i]) -> void:
	_tile_nodes.resize(Config.max_board_size)
	for y in _tile_nodes.size():
		_tile_nodes[y] = []
		_tile_nodes[y].resize(Config.max_board_size)
		_tile_nodes[y].fill(null)
	
	for tile_pos: Vector2i in tile_positions:
		var tile_node: TileNode = tile_node_scene.instantiate()
		add_child(tile_node)
		tile_node.init(tile_pos)
		tile_node.selected.connect(_on_tile_node_selected.bind(tile_node))
		_tile_nodes[tile_pos.y][tile_pos.x] = tile_node
		_cached_tile_count += 1

		# Animate tile node
		tile_node.scale = Vector2.ONE * 0.4
		tile_node.modulate = Color.TRANSPARENT
		tile_node.position += Vector2(0, -10)
		var tw := tile_node.create_tween().set_parallel().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		var n := tile_pos.x + tile_pos.y
		tw.tween_interval(pow(n / 14.0, 3) * 0.8 + n * 0.05)
		tw.chain().tween_property(tile_node, "scale", Vector2.ONE, 0.2)
		tw.tween_property(tile_node, "modulate", Color.WHITE, 0.2)
		tw.tween_property(tile_node, "position", Vector2(0, 10), 0.2).as_relative()

	assert(num_tile_nodes() == tile_positions.size())

func highlight_tiles(tiles: Array[Vector2i]) -> void:
	for tile_pos: Vector2i in _highlighted_tiles:
		get_tile_node(tile_pos).set_show_dot(false)
	for tile_pos: Vector2i in tiles:
		get_tile_node(tile_pos).set_show_dot(true)
	_highlighted_tiles = tiles

func highlight_premove_squares(squares: Array[Vector2i]) -> void:
	clear_premove_highlight()
	for pos: Vector2i in squares:
		if has_tile_node(pos):
			get_tile_node(pos).set_show_premove(true)

func highlight_premove_tiles(from: Vector2i, to: Vector2i) -> void:
	highlight_premove_squares([from, to])

func clear_premove_highlight() -> void:
	for tile_node: TileNode in get_all_tile_nodes():
		tile_node.set_show_premove(false)
	_premove_from = Vector2i(-1, -1)
	_premove_to = Vector2i(-1, -1)

func set_drag_hover_tile(board_pos: Vector2i) -> void:
	if _drag_hover_tile == board_pos:
		return
	if _drag_hover_tile != Vector2i(-1, -1) and has_tile_node(_drag_hover_tile):
		get_tile_node(_drag_hover_tile).set_show_drag_hover(false)
	_drag_hover_tile = board_pos
	if _drag_hover_tile != Vector2i(-1, -1) and has_tile_node(_drag_hover_tile):
		get_tile_node(_drag_hover_tile).set_show_drag_hover(true)

func clear_drag_hover() -> void:
	set_drag_hover_tile(Vector2i(-1, -1))

func world_pos_to_board_pos(world_pos: Vector2) -> Vector2i:
	var local := to_local(world_pos)
	var grid := local / 16.0 + Vector2.ONE * Config.max_board_size * 0.5
	return Vector2i(roundi(grid.x), roundi(grid.y))

func get_tile_at_world_pos(world_pos: Vector2) -> TileNode:
	var board_pos := world_pos_to_board_pos(world_pos)
	if not has_tile_node(board_pos):
		return null
	return get_tile_node(board_pos)

func is_board_pos_in_bounds(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.y >= 0 and coord.x < Config.max_board_size and coord.y < Config.max_board_size

func get_tile_node(coord: Vector2i) -> TileNode:
	assert(is_board_pos_in_bounds(coord))
	return _tile_nodes[coord.y][coord.x]

func has_tile_node(coord: Vector2i) -> bool:
	if not is_board_pos_in_bounds(coord):
		return false
	return _tile_nodes[coord.y][coord.x] != null

func num_tile_nodes() -> int:
	return _cached_tile_count

func _on_tile_node_selected(tile_node: TileNode) -> void:
	tile_node_selected.emit(tile_node)
