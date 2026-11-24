extends RefCounted

const PATH := "user://journey.cfg"
const SETTINGS := "user://settings.cfg"
const SAVE_VERSION := 2
const CHAPTERS: Array[String] = ["res://chapter1.tscn", "res://chapter2.tscn", "res://chapter3.tscn", "res://chapter4.tscn"]

const ORDER: Array[String] = ["res://chapter0.tscn", "res://chapter1.tscn", "res://chapter2.tscn", "res://chapter3.tscn", "res://chapter4.tscn"]

static func remember_chapter(scene: String) -> void:
	if scene not in ORDER:
		return
	var cfg := load_progress()
	cfg.set_value("journey", "chapter", scene)
	var error := save_progress(cfg)
	if error != OK:
		push_warning("Could not save chapter checkpoint: %s" % error)

static func memory_unlocked(path: String, key: String) -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(path) == OK and bool(cfg.get_value("story", key, false))

static func continue_scene() -> String:
	var cleared := completed_chapters()
	if not cleared.is_empty():
		var furthest := -1
		for scene in cleared:
			furthest = maxi(furthest, ORDER.find(scene))
		return ORDER[furthest + 1] if furthest + 1 < ORDER.size() else ""
	# Preserve chapter checkpoints from saves that did not yet track victories.
	var scene := str(load_progress().get_value("journey", "chapter", ""))
	if scene in ORDER:
		return scene
	return ""

static func load_progress() -> ConfigFile:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		cfg.load(PATH + ".bak")
	return cfg

static func save_progress(cfg: ConfigFile) -> Error:
	if int(cfg.get_value("meta", "version", 1)) > SAVE_VERSION:
		push_warning("This journey was saved by a newer game version.")
		return ERR_INVALID_DATA
	cfg.set_value("meta", "version", SAVE_VERSION)
	var error := cfg.save(PATH + ".tmp")
	if error != OK:
		return error
	if FileAccess.file_exists(PATH):
		# Keep the last readable save if the primary file was damaged.
		var previous := ConfigFile.new()
		if previous.load(PATH) == OK:
			error = DirAccess.copy_absolute(ProjectSettings.globalize_path(PATH), ProjectSettings.globalize_path(PATH + ".bak"))
			if error != OK:
				return error
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH + ".tmp"), ProjectSettings.globalize_path(PATH))

static func scene_list(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array or value is PackedStringArray:
		for entry in value:
			if entry is String and entry in ORDER and entry not in result:
				result.append(entry)
	return result

static func completed_chapters() -> Array[String]:
	var cleared := scene_list(load_progress().get_value("journey", "cleared", []))
	# Old memory flags are proof of completion; later chapters imply earlier ones.
	var legacy_end := -1
	if memory_unlocked("user://chapter1_memory.cfg", "silkworm"):
		legacy_end = 0
	if memory_unlocked("user://chapter2_memory.cfg", "hibiscus"):
		legacy_end = 1
	for i in range(legacy_end + 1):
		if CHAPTERS[i] not in cleared:
			cleared.append(CHAPTERS[i])
	return cleared

static func has_met(scene: String) -> bool:
	return scene in completed_chapters() or scene in scene_list(load_progress().get_value("journey", "encountered", []))

static func has_silk_guard() -> bool:
	return bool(load_progress().get_value("abilities", "silk_guard", false)) or CHAPTERS[0] in completed_chapters()

static func silk_guard_practiced() -> bool:
	return bool(load_progress().get_value("abilities", "silk_guard_practiced", false))

static func unlock_silk_guard() -> Error:
	var cfg := load_progress()
	cfg.set_value("abilities", "silk_guard", true)
	cfg.set_value("abilities", "silk_guard_practiced", true)
	return save_progress(cfg)

static func story_key(scene: String, kind: String) -> String:
	return "chapter_%d_%s" % [ORDER.find(scene), kind]

static func meet_chapter(scene: String, opening: Array[String] = []) -> void:
	if scene not in ORDER:
		return
	var cfg := load_progress()
	var encountered := scene_list(cfg.get_value("journey", "encountered", []))
	var key := story_key(scene, "opening")
	if scene in encountered and (opening.is_empty() or cfg.has_section_key("stories", key)):
		return
	if scene not in encountered:
		encountered.append(scene)
	cfg.set_value("journey", "encountered", encountered)
	if not opening.is_empty() and not cfg.has_section_key("stories", key):
		cfg.set_value("stories", key, opening)
	var error := save_progress(cfg)
	if error != OK:
		push_warning("Could not record the encounter: %s" % error)

static func complete_chapter(scene: String, ending: Array[String] = []) -> void:
	if scene not in ORDER:
		return
	var cfg := load_progress()
	if scene in scene_list(cfg.get_value("journey", "cleared", [])) and (ending.is_empty() or cfg.has_section_key("stories", story_key(scene, "ending"))):
		return
	var cleared := completed_chapters()
	if scene not in cleared:
		cleared.append(scene)
	cfg.set_value("journey", "cleared", cleared)
	if not ending.is_empty() and not cfg.has_section_key("stories", story_key(scene, "ending")):
		cfg.set_value("stories", story_key(scene, "ending"), ending)
	var error := save_progress(cfg)
	if error != OK:
		push_warning("Could not save chapter completion: %s" % error)

static func recorded_dialogue(scene: String) -> String:
	var cfg := load_progress()
	var sections: Array[String] = []
	for kind in ["opening", "ending"]:
		var raw: Variant = cfg.get_value("stories", story_key(scene, kind), [])
		if raw is Array or raw is PackedStringArray:
			var lines: Array[String] = []
			for entry in raw:
				if entry is String:
					lines.append(entry)
			if not lines.is_empty():
				sections.append(("THE ENCOUNTER" if kind == "opening" else "AFTER THE STORM") + "\n\n" + "\n\n".join(lines))
	return "\n\n".join(sections)

static func preferences() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	return cfg

static func set_preference(key: String, value: Variant) -> void:
	var cfg := preferences()
	cfg.set_value("settings", key, value)
	var error := cfg.save(SETTINGS)
	if error != OK:
		push_warning("Could not save settings: %s" % error)

static func apply_preferences() -> void:
	var cfg := preferences()
	AudioServer.set_bus_mute(0, bool(cfg.get_value("settings", "mute", false)))
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if bool(cfg.get_value("settings", "fullscreen", false)) else DisplayServer.WINDOW_MODE_WINDOWED)
