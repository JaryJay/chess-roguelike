class_name BoardNode extends Node2D

enum BoardNodeState {
	NOT_INITIALIZED,
	INITIALIZED,
}

var b: Board = Board.new()
@onready var tile_nodes: TileNodes = $TileNodes
@onready var piece_nodes: PieceNodes = $PieceNodes

var player_team: Team = Team.PLAYER
var state: BoardNodeState = BoardNodeState.NOT_INITIALIZED
var selected_piece_node: PieceNode = null

func init_randomly() -> void:
	assert(is_node_ready())
	assert(state == BoardNodeState.NOT_INITIALIZED)
	_generate_tiles()
	_generate_pieces()
	state = BoardNodeState.INITIALIZED

func _on_piece_node_selected(piece_node: PieceNode) -> void:
	# if you click a piece when it's the opponent's turn
	if b.team_to_move != player_team:
		if _can_select_piece_node(piece_node):
			_select_piece_node(piece_node)
		else:
			_select_piece_node(null)
		return
	
	if selected_piece_node:
		assert(selected_piece_node.piece().team == player_team)
		

func _on_tile_node_selected(tile_node: TileNode) -> void:
	pass # Replace with function body.

func _select_piece_node(piece_node: PieceNode) -> void:
	selected_piece_node = piece_node

func _can_select_piece_node(piece_node: PieceNode) -> bool:
	return piece_node.piece().team == player_team

func _generate_tiles() -> void:
	var tile_positions: = TilesGenerator.generate_tiles()
	b.tile_map.set_tiles(tile_positions)
	tile_nodes.create_tile_nodes(tile_positions)

func _generate_pieces() -> void:
	var enemy_army: = PiecesGenerator.generate_army(1000, b, Team.ENEMY_AI)
	var army: = PiecesGenerator.generate_army(1000, b, Team.PLAYER)
	var pieces: = enemy_army + army
	for piece: Piece in pieces:
		assert(not b.piece_map.has_piece(piece.pos))
		assert(b.tile_map.has_tile(piece.pos))
		
		b.piece_map.put_piece(piece.pos, piece)
		piece_nodes.spawn_piece(piece)
	
	for piece_node: PieceNode in piece_nodes.get_all_piece_nodes():
		assert(b.piece_map.has_piece(piece_node.piece().pos))
		assert(b.piece_map.get_piece(piece_node.piece().pos) == piece_node.piece())
