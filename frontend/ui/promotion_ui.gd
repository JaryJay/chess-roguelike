class_name PromotionUI extends ColorRect

signal promotion_chosen(promotion_type: Piece.Type)

func _on_queen_button_pressed() -> void:
	promotion_chosen.emit(Piece.Type.QUEEN)
func _on_rook_button_pressed() -> void:
	promotion_chosen.emit(Piece.Type.ROOK)
func _on_bishop_button_pressed() -> void:
	promotion_chosen.emit(Piece.Type.BISHOP)
func _on_knight_button_pressed() -> void:
	promotion_chosen.emit(Piece.Type.KNIGHT)



