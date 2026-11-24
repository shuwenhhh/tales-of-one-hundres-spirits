extends SceneTree

const JOURNEY := preload("res://scripts/journey_state.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + message)
	if not condition:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art_review/english_menu/" + name + ".png")

func action_key(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func game_key(game: Node, code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._unhandled_key_input(event)

func run() -> void:
	# This runner writes test saves: use the isolated APPDATA folder documented in README.
	if OS.get_environment("TALES_TEST_RUN") != "1":
		push_error("Use isolated APPDATA / LOCALAPPDATA and set TALES_TEST_RUN=1 before running this test.")
		quit(2)
		return
	create_timer(35).timeout.connect(func() -> void: quit(2))
	DirAccess.make_dir_recursive_absolute("res://art_review/english_menu")
	root.size = Vector2i(960, 540)
	JOURNEY.set_preference("fullscreen", false)
	JOURNEY.set_preference("mute", false)
	var empty := ConfigFile.new()
	empty.save(JOURNEY.PATH)
	empty.save("user://chapter1_memory.cfg")
	empty.save("user://chapter2_memory.cfg")
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	var menu = current_scene
	check(menu.buttons[1].disabled, "Continue is disabled before a journey exists")
	check(root.gui_get_focus_owner() == menu.buttons[0], "Begin Story has keyboard focus")
	action_key("ui_down")
	await process_frame
	check(root.gui_get_focus_owner() == menu.buttons[2], "keyboard navigation skips disabled Continue")
	await shot("01_main_menu")
	menu.buttons[2].pressed.emit()
	await process_frame
	check(menu.overlay.visible and menu.memories_panel.cards.size() == menu.FRIENDS.ENTRIES.size() and not menu.memories_panel.cards[0].get_meta("completed"), "Memories opens with locked spirit silhouettes")
	await create_timer(1.9).timeout
	await shot("02_memories")
	menu._close_modal()
	await create_timer(.85).timeout
	check(root.gui_get_focus_owner() == menu.buttons[2], "closing a panel restores menu focus")
	menu.buttons[3].pressed.emit()
	await process_frame
	var mute: CheckButton = menu.modal_content.get_child(1)
	mute.button_pressed = true
	check(AudioServer.is_bus_mute(0) and JOURNEY.preferences().get_value("settings", "mute", false), "audio toggle applies and persists")
	mute.button_pressed = false
	var shake: CheckButton = menu.modal_content.get_child(3)
	shake.button_pressed = true
	check(JOURNEY.preferences().get_value("settings", "reduce_shake", false), "reduced shake preference persists")
	await shot("03_settings")
	menu._close_modal()
	JOURNEY.remember_chapter("res://chapter2.tscn")
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	menu = current_scene
	check(not menu.buttons[1].disabled, "Continue is available with a chapter checkpoint")
	menu.buttons[1].pressed.emit()
	await process_frame
	check(menu.modal_page == "chapters" and is_instance_valid(menu.chapter_gallery.continue_button), "Continue shows the current chapter in a gallery")
	await shot("07_chapter_gallery")
	menu.chapter_gallery.continue_button.pressed.emit()
	await process_frame
	await process_frame
	var second = current_scene
	check(second.scene_file_path == "res://chapter2.tscn", "Continue opens the latest chapter")
	second.set_physics_process(false)
	second.x = second.boss_x - 90
	game_key(second, KEY_E)
	check(second.phase == "dialogue" and second.lines[0].begins_with("Xiaoyu:"), "Chapter Two starts its English dialogue")
	for entry in second.lines:
		second.dialogue_box.show_line(entry)
		second.dialogue_box.reveal_or_continue()
		await process_frame
		await process_frame
		check(second.dialogue_box.body_label.get_content_height() <= second.dialogue_box.body_label.size.y, "English dialogue fits: " + entry.left(48))
	second.dialogue_box.show_line(second.lines[1])
	second.dialogue_box.reveal_or_continue()
	await shot("04_chapter_two_english")
	game_key(second, KEY_ESCAPE)
	game_key(second, KEY_Q)
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/main_menu.tscn", "pause then Q returns to main menu")
	menu = current_scene
	menu.buttons[0].pressed.emit()
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/chapter_intro.tscn", "Begin Story opens the chapter introduction")
	current_scene._change_scene()
	await process_frame
	await process_frame
	var first = current_scene
	check(first.scene_file_path == "res://chapter1.tscn" and first.reduce_shake, "chapter one loads and applies accessibility preference")
	first.set_physics_process(false)
	first.player.x = 650
	first.interact()
	first.dialogue_box.reveal_or_continue()
	await shot("05_chapter_one_english")
	game_key(first, KEY_ESCAPE)
	game_key(first, KEY_Q)
	await process_frame
	await process_frame
	await shot("06_menu_with_continue")
	print("ENGLISH MENU RESULT: %d failures" % failures)
	quit(1 if failures > 0 else 0)
