class_name Upgrades

const PATH_TO_UPGRADES := "res://upgrades.json"

static var upgrades: Array[Upgrade] = []

static func load_upgrades() -> void:
	var file := FileAccess.open(PATH_TO_UPGRADES, FileAccess.READ)
	if file == null:
		push_error("Failed to open upgrades.json")
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("Failed to parse upgrades.json")
		return

	upgrades.clear()

	var upgrades_data: Array = json.data
	for data: Dictionary in upgrades_data:
		if data["type"] == "swap":
			var remove_types: Array[String] = []
			if data.has("remove_types"):
				remove_types.append_array(data["remove_types"])
			var add_types: Array[String] = []
			if data.has("add_types"):
				add_types.append_array(data["add_types"])

			var upgrade := SwapUpgrade.new(data["display_name"], data["description"], remove_types, add_types)
			upgrades.append(upgrade)
		elif data["type"] == "gamble":
			var possibilities: Array[GambleUpgrade.GamblePossibility] = []
			if data.has("possibilities"):
				for possibility: Dictionary in data["possibilities"]:
					var remove_types: Array[String] = []
					if possibility.has("remove_types"):
						remove_types.append_array(possibility["remove_types"])
					var add_types: Array[String] = []
					if possibility.has("add_types"):
						add_types.append_array(possibility["add_types"])

					possibilities.append(GambleUpgrade.GamblePossibility.new(remove_types, add_types, possibility["weight"]))

			var upgrade := GambleUpgrade.new(data["display_name"], data["description"], possibilities)
			upgrades.append(upgrade)
		else:
			assert(false, "upgrades.gd: Unknown upgrade type: " + data["type"])
