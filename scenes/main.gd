extends Node3D

@onready var board: Board = $SubVpContainer/SubVp/Board

func _ready() -> void:
	board.generate_tiles()
