extends Node2D

@onready var board: BoardNode = $BoardNode

func _ready() -> void:
	PieceRules.load_pieces()
	board.init_randomly()
