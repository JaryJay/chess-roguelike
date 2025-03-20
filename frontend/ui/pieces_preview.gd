class_name PiecesPreview extends FlowContainer

@onready var piece_texture_rect_template: TextureRect = $PieceTextureRectTemplate

func set_piece_types(piece_types: Array[Piece.Type], team: Team = Team.PLAYER) -> void:
	var sorted_piece_types: Array[Piece.Type] = piece_types.duplicate()
	sorted_piece_types.sort()
	var color_suffix: String = "white" if team == Team.PLAYER else "black"

	for child: Control in get_children():
		if child != piece_texture_rect_template:
			child.queue_free()
	for piece_type in sorted_piece_types:
		var piece_texture_rect: TextureRect = piece_texture_rect_template.duplicate()
		piece_texture_rect.texture = load("res://frontend/pieces/textures/%s_%s.tres" % [Piece.TYPE_TO_STRING[piece_type], color_suffix])
		piece_texture_rect.show()
		add_child(piece_texture_rect)
