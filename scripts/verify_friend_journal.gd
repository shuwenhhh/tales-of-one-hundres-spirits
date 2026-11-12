extends SceneTree

const JOURNEY := preload("res://scripts/journey_state.gd")
var failures: int = 0

func check(condition: bool, message: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + message)
	if not condition:
		failures += 1

func reset_saves() -> void:
	var empty := ConfigFile.new()
	for path in [JOURNEY.PATH, JOURNEY.PATH + ".bak", "user://chapter1_memory.cfg", "user://chapter2_memory.cfg"]:
		empty.save(path)

func shot(name: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art_review/friend_journal/" + name + ".png")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if OS.get_environment("TALES_TEST_RUN") != "1":
		push_error("This test requires isolated APPDATA and TALES_TEST_RUN=1.")
		quit(2)
		return
	create_timer(45).timeout.connect(func() -> void: quit(2))
	DirAccess.make_dir_recursive_absolute("res://art_review/friend_journal")
	JOURNEY.set_preference("fullscreen", false)
	reset_saves()
	check(JOURNEY.continue_scene().is_empty(), "new journey has no resume point")
	JOURNEY.remember_chapter(JOURNEY.CHAPTERS[0])
	check(JOURNEY.continue_scene() == JOURNEY.CHAPTERS[0], "unfinished chapter resumes at its start")
	var opening: Array[String] = ["Grandmother: Is it still raining?"]
	var ending: Array[String] = ["Grandmother: I can hear the rain."]
	JOURNEY.meet_chapter(JOURNEY.CHAPTERS[0], opening)
	check(JOURNEY.has_met(JOURNEY.CHAPTERS[0]) and JOURNEY.completed_chapters().is_empty(), "meeting a friend does not count as victory")
	JOURNEY.complete_chapter(JOURNEY.CHAPTERS[0], ending)
	check(JOURNEY.continue_scene() == JOURNEY.CHAPTERS[1], "chapter one completion unlocks chapter two immediately")
	check("I can hear the rain" in JOURNEY.recorded_dialogue(JOURNEY.CHAPTERS[0]), "recorded conversations survive reloading the save")
	JOURNEY.remember_chapter(JOURNEY.CHAPTERS[0])
	JOURNEY.complete_chapter(JOURNEY.CHAPTERS[0], ["Do not replace the original ending."])
	check(JOURNEY.continue_scene() == JOURNEY.CHAPTERS[1] and "I can hear the rain" in JOURNEY.recorded_dialogue(JOURNEY.CHAPTERS[0]), "replay cannot regress progress or overwrite the recorded story")
	JOURNEY.complete_chapter(JOURNEY.CHAPTERS[1])
	check(JOURNEY.continue_scene() == JOURNEY.CHAPTERS[2], "chapter two completion unlocks chapter three")
	JOURNEY.complete_chapter(JOURNEY.CHAPTERS[2])
	check(JOURNEY.continue_scene().is_empty() and JOURNEY.completed_chapters().size() == 3, "all current chapters complete without looping back to chapter one")
	check(int(JOURNEY.load_progress().get_value("meta", "version", 0)) == 2 and FileAccess.file_exists(JOURNEY.PATH + ".bak"), "progress uses versioned saves with a previous-save backup")
	JOURNEY.remember_chapter(JOURNEY.CHAPTERS[2])
	var primary := ProjectSettings.globalize_path(JOURNEY.PATH)
	var hidden := primary + ".test_hidden"
	var moved := DirAccess.rename_absolute(primary, hidden)
	check(moved == OK, "test can temporarily move its isolated primary save")
	if moved == OK:
		check(JOURNEY.completed_chapters().size() == 3, "previous-save backup restores progress when the primary is missing")
		check(DirAccess.rename_absolute(hidden, primary) == OK, "test restores its primary save")
	reset_saves()
	var old := ConfigFile.new()
	old.set_value("journey", "chapter", JOURNEY.CHAPTERS[0])
	old.save(JOURNEY.PATH)
	var legacy := ConfigFile.new()
	legacy.set_value("story", "silkworm", true)
	legacy.save("user://chapter1_memory.cfg")
	check(JOURNEY.continue_scene() == JOURNEY.CHAPTERS[1], "old silkworm memory takes priority over an earlier visited chapter")
	legacy.set_value("story", "hibiscus", true)
	legacy.save("user://chapter2_memory.cfg")
	check(JOURNEY.continue_scene() == JOURNEY.CHAPTERS[2] and JOURNEY.completed_chapters().size() == 2, "legacy peach memory restores completed chapters")
	reset_saves()
	JOURNEY.remember_chapter(JOURNEY.CHAPTERS[0])
	JOURNEY.meet_chapter(JOURNEY.CHAPTERS[0], opening)
	JOURNEY.complete_chapter(JOURNEY.CHAPTERS[0], ending)
	var peach_opening: Array[String] = ["Peach Spirit: Don't wrinkle the water."]
	JOURNEY.meet_chapter(JOURNEY.CHAPTERS[1], peach_opening)
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._show_memories()
	await shot("01_friends")
	check(menu.memories_panel.cards[0].get_meta("completed") and menu.memories_panel.cards[1].get_meta("known") and not menu.memories_panel.cards[2].get_meta("known"), "journal separates completed, encountered and unknown friends")
	menu.memories_panel.story_requested.emit(JOURNEY.CHAPTERS[0])
	await shot("02_read_story")
	check(menu.modal_page == "story" and "I can hear the rain" in menu.modal_content.get_child(1).text, "Read Story displays the narrative and recorded conversation")
	menu._return_from_story()
	check(menu.modal_page == "memories" and JOURNEY.continue_scene() == JOURNEY.CHAPTERS[1], "reading a story leaves journey progress unchanged")
	menu._show_chapters()
	await shot("03_chapter_gallery")
	check(menu.chapter_gallery.cards[0].get_meta("completed") and menu.chapter_gallery.cards[1].get_meta("current") and not menu.chapter_gallery.cards[2].get_meta("current"), "chapter gallery highlights the next chapter and locks later ones")
	menu.chapter_gallery.story_requested.emit(JOURNEY.CHAPTERS[0])
	menu._return_from_story()
	check(menu.modal_page == "chapters", "story reading returns to the chapter gallery when opened there")
	menu.chapter_gallery.chapter_requested.emit(JOURNEY.CHAPTERS[0])
	await process_frame
	await process_frame
	var first = current_scene
	first.set_physics_process(false)
	check(first.scene_file_path == JOURNEY.CHAPTERS[0] and JOURNEY.continue_scene() == JOURNEY.CHAPTERS[1], "Replay Chapter opens chapter one without moving Continue backwards")
	reset_saves()
	first.interact()
	first.resolve = 0
	first.win_battle()
	check(JOURNEY.continue_scene() == JOURNEY.CHAPTERS[1] and "waiting room" in JOURNEY.recorded_dialogue(JOURNEY.CHAPTERS[0]), "real chapter one victory saves progress before the outro is dismissed")
	first.queue_free()
	await process_frame
	var second = load(JOURNEY.CHAPTERS[1]).instantiate()
	root.add_child(second)
	second.set_physics_process(false)
	second.phase = "battle"
	second.x = second.boss_x - 70
	second.facing = 1
	second.grief = 1
	second.attack_time = .2
	second.boss_state = "ouch"
	second._physics_process(.016)
	check(second.grief == 0 and JOURNEY.continue_scene() == JOURNEY.CHAPTERS[2], "real chapter two final hit advances Continue during the settling animation")
	second._physics_process(second.SETTLE_DURATION + .1)
	check("Take care" in JOURNEY.recorded_dialogue(JOURNEY.CHAPTERS[1]), "chapter two outro is added to the friend's story")
	second.queue_free()
	await process_frame
	var third = load(JOURNEY.CHAPTERS[2]).instantiate()
	root.add_child(third)
	third.set_physics_process(false)
	third.phase = "battle"
	third.boss_hp = 1
	third._hit_boss(1)
	check(JOURNEY.completed_chapters().size() == 3, "real chapter three victory records Qingyan")
	third.queue_free()
	await process_frame
	print("FRIEND JOURNAL RESULT: ", failures, " failures")
	quit(failures)
