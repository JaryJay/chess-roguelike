extends Node2D

@onready var board: BoardNode = $BoardNode

func _enter_tree() -> void:
	Config.load_config()
	PieceRules.load_pieces()

func _ready() -> void:
	board.init_randomly()
