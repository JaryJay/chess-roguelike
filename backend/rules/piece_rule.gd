class_name PieceRule

var tags: Array[String]
var moves: Array[PieceMoveAbility]
var credit_cost: int

func _init(_tags: Array[String], _moves: Array[PieceMoveAbility], _credit_cost: int) -> void:
	tags = _tags
	moves = _moves
	credit_cost = _credit_cost
