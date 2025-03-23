class_name GameCamera extends Camera2D

static var _instance: GameCamera

static func get_instance() -> GameCamera:
	return _instance

const SHAKE_STEPS_PER_SECOND: float = 10

func _ready() -> void:
	if _instance == null:
		_instance = self

# Screen shake
func shake(duration: float, strength: float) -> void:
	assert(duration > 0.0)
	assert(strength > 0.0 and strength <= 50.0)

	var steps := ceilf(duration * SHAKE_STEPS_PER_SECOND)
	var tw := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	for i in range(steps):
		var rand_dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		var step_strength := pow(((steps - i) / steps), 3.0) * strength
		tw.tween_property(self, "offset", rand_dir * step_strength, 0.5 / SHAKE_STEPS_PER_SECOND)
		tw.tween_property(self, "offset", Vector2.ZERO, 0.5 / SHAKE_STEPS_PER_SECOND)
