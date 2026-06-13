class_name Settings

const SETTINGS_PATH := "user://settings.cfg"

# "mouse_and_keyboard" or "touch"
const INPUT_MODE: String = "touch"

static var premoving_enabled: bool = true

static func load_user_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	premoving_enabled = config.get_value("settings", "premoving_enabled", true)

static func save_premoving_enabled(enabled: bool) -> void:
	premoving_enabled = enabled
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("settings", "premoving_enabled", enabled)
	config.save(SETTINGS_PATH)
