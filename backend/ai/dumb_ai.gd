class_name DumbAI extends AbstractAI

func get_move(board: Board) -> Move:
	OS.delay_msec(500)
	var moves := board.get_available_moves()
	if moves.is_empty():
		return null
	return moves[randi() % moves.size()]
