class_name AudioManager extends Node

## Central audio manager. Add AudioStream resources to the AudioStreamPlayer children
## to enable in-game sounds. The players are created automatically at runtime.
##
## Expected child node names (created in _ready):
##   MovePlayer, CapturePlayer, CheckPlayer, PromotionPlayer, WinPlayer, LosePlayer

static var _instance: AudioManager

static func get_instance() -> AudioManager:
	return _instance

func _ready() -> void:
	if _instance == null:
		_instance = self
	_ensure_player("MovePlayer")
	_ensure_player("CapturePlayer")
	_ensure_player("CheckPlayer")
	_ensure_player("PromotionPlayer")
	_ensure_player("WinPlayer")
	_ensure_player("LosePlayer")

func _ensure_player(player_name: String) -> void:
	if not has_node(player_name):
		var player := AudioStreamPlayer.new()
		player.name = player_name
		add_child(player)

## Plays a named sound if its AudioStreamPlayer has a stream assigned.
func play(sound_name: String) -> void:
	var player_name := _sound_to_player_name(sound_name)
	var player: AudioStreamPlayer = get_node_or_null(player_name)
	if player and player.stream:
		player.play()

func _sound_to_player_name(sound_name: String) -> String:
	return sound_name.capitalize() + "Player"

## Called from game.gd when board_node emits sound_event.
func on_sound_event(event_name: String) -> void:
	play(event_name)
