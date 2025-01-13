class_name BoardNode extends Node2D

signal tile_selected(tile: TileNode)

# The board can only be up to 16x16 in size, max.
# The tile positions can be anywhere from (0, 0) to (11, 11)
const MAX_X: = 12
const MAX_Y: = 12
const NOISE_SCALE: float = 7

const CENTER: = Vector2((MAX_X - 1) * 0.5, (MAX_Y - 1) * 0.5)

var b: Board = Board.new()
@onready var tile_nodes: TileNodes = $TileNodes
@onready var piece_nodes: PieceNodes = $PieceNodes

func generate_tiles() -> void:
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
	
	# Prune tentative_tile_positions that are not cardinally adjacent to another tile
	var pruned_tile_positions: Array[Vector2i] = []
	const cardinal_directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for tile_pos: Vector2i in tentative_tile_positions:
		var good_tile: = false
		for cardinal_dir: Vector2i in cardinal_directions:
			if tentative_tile_positions.has(tile_pos + cardinal_dir):
				good_tile = true
				break
		if good_tile:
			pruned_tile_positions.append(tile_pos)
		else:
			print("pruned position %v" % tile_pos)
	
	b.tile_map.set_tiles(pruned_tile_positions)
	tile_nodes.create_tile_nodes(pruned_tile_positions)

func generate_pieces() -> void:
	var enemy_army: = ArmyGenerator.generate_army(1000, b, Team.ENEMY_AI)
	for piece: Piece in enemy_army:
		piece_nodes.spawn_piece(piece)
	var army: = ArmyGenerator.generate_army(1000, b, Team.PLAYER)
	for piece: Piece in army:
		piece_nodes.spawn_piece(piece)
	
	for piece_node: PieceNode in piece_nodes.get_all_piece_nodes():
		assert(b.piece_map.has_piece(piece_node.piece().pos))
		assert(b.piece_map.get_piece(piece_node.piece().pos) == piece_node.piece())

func spawn_piece_and_piece_node(piece: Piece) -> void:
	assert(not b.piece_map.has_piece(piece.pos))
	assert(b.tile_map.has_tile(piece.pos))
	
	b.piece_map.put_piece(piece.pos, piece)
	piece_nodes.spawn_piece(piece)

func perform_move(move: Move) -> void:
	var piece_node: = piece_nodes.get_piece_node(move.from)
	#assert(b.piece_map.get_piece(piece.state().pos).id == piece.state().id)
	assert(move.is_capture() == has_piece(move.to))
	
	if move.is_capture():
		var captured_piece_node: = get_piece(move.to)
		assert(piece_node.piece().team.is_hostile_to(captured_piece_node.team))
		captured_piece_node.queue_free()
		pieces.erase(move.to)
	
	create_tween().tween_property(piece_node, "position", get_tile(move.to).position, 0.1)
	
	b = b.perform_move(move)
	
	# Update all pieces with the new state
	for piece: Piece in b.piece_map.get_all_pieces():
		var p: = get_piece(piece.pos)
		p.set_piece(piece)
	
	#if move.is_promotion():
		#assert(piece.type != Piece.Type.PAWN and piece.state().type == Piece.Type.PAWN)
		#var old_state: = piece.state()
		#piece.queue_free()
		#piece = ArmyGenerator.queen_scene.instantiate()
		#piece.set_state(old_state)
		#spawn_piece(piece, move.from)
	

func _on_tile_node_selected(tile_node: TileNode) -> void:
	pass # Replace with function body.
