@tool class_name PieceSprite2D extends Sprite2D

enum PieceColor {
	BLACK,
	WHITE,
}

@export var color: PieceColor = PieceColor.WHITE :
	set(value):
		color = value
		_set_texture()
@export var white_texture: Texture2D :
	set(value):
		white_texture = value
		_set_texture()
@export var black_texture: Texture2D :
	set(value):
		black_texture = value
		_set_texture()

func _ready() -> void:
	_set_texture()

func _set_texture() -> void:
	texture = white_texture if color == PieceColor.WHITE else black_texture
	update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:
	if white_texture == null and black_texture == null:
		return ["One or more piece textures must be set"]
	return []
