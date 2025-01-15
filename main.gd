extends Node2D

@onready var board: BoardNode = $BoardNode

func _ready() -> void:
	board.init_randomly()
