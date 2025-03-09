class_name Faction extends Resource

var name: String
var display_name: String
var description: String
var piece_types: Array[Piece.Type]

func _init(_name: String, _display_name: String, _description: String, _piece_types: Array[Piece.Type]) -> void:
	self.name = _name
	self.display_name = _display_name
	self.description = _description
	self.piece_types = _piece_types

func _to_string() -> String:
	return "Faction(%s, %s, %v)" % [display_name, description, piece_types]


