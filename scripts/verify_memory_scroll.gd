extends SceneTree

const JOURNEY := preload("res://scripts/journey_state.gd")
const FRIENDS := preload("res://scripts/friend_stories.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + message)
	if not condition:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art_review/memory_scroll/" + name + ".png")

func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame

func action(name: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = name
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()

func reset_test_saves() -> void:
	var empty := ConfigFile.new()
	for path in [JOURNEY.PATH, JOURNEY.PATH + ".bak", "user://chapter1_memory.cfg", "user://chapter2_memory.cfg"]:
		empty.save(path)

func run() -> void:
	if OS.get_environment("TALES_TEST_RUN") != "1" or not "scroll_test" in OS.get_environment("APPDATA"):
		push_error("Use isolated APPDATA containing scroll_test and TALES_TEST_RUN=1.")
		quit(2)
		return
	create_timer(45).timeout.connect(func() -> void: quit(2))
	root.size = Vector2i(960, 540)
	DirAccess.make_dir_recursive_absolute("res://art_review/memory_scroll")
	reset_test_saves()
	JOURNEY.set_preference("fullscreen", false)
	JOURNEY.complete_chapter("res://chapter0.tscn")
	var ending: Array[String] = ["Grandmother: I can hear the rain."]
	JOURNEY.complete_chapter("res://chapter1.tscn", ending)
	JOURNEY.meet_chapter("res://chapter2.tscn")
	var before := JOURNEY.load_progress().encode_to_text()
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	var menu = current_scene
	menu.buttons[2].grab_focus()
	menu.buttons[2].pressed.emit()
	var panel = menu.memories_panel
	check(panel.open_amount < .01 and not panel.opened, "Memories begins as a closed scroll")
	check(panel.cards.size() == FRIENDS.ENTRIES.size(), "all five chapter spirits appear on the scroll")
	check(not panel.details.visible and menu.overlay.color == Color.BLACK, "only the scroll appears against empty space, without the menu artwork or external panels")
	await shot("01_closed")
	await create_timer(.65).timeout
	check(panel.open_amount > .05 and panel.open_amount < .9, "scroll gradually reveals from the center")
	check(panel.reveal.size.x < panel.SCROLL_RECT.size.x and panel.cards[0].disabled, "opening clips the painting and blocks premature interaction")
	await shot("02_opening")
	await create_timer(1.25).timeout
	check(panel.opened and is_equal_approx(panel.open_amount, 1.0), "scroll finishes unrolling")
	check(panel.portraits[0].material.get_shader_parameter("revealed") and panel.portraits[1].material.get_shader_parameter("revealed"), "cleared spirits display their full-color portraits")
	check(not panel.portraits[2].material.get_shader_parameter("revealed") and panel.cards[2].get_meta("known"), "encountered but unfinished spirit still displays a silhouette")
	check(not panel.portraits[3].material.get_shader_parameter("revealed"), "unknown spirits display silhouettes")
	await shot("03_mixed_progress")
	await click(panel.cards[1])
	check(panel.selected_index == 1 and panel.name_label.text == "Grandmother" and panel.description.text == FRIENDS.ENTRIES[1].story and panel.details.visible, "a single click displays the spirit's full story inside the scroll")
	check(panel.description.get_theme_font("normal_font").get_font_name() != "", "story text uses the antique serif font")
	await shot("07_story_on_scroll")
	await click(panel.back_button)
	check(not panel.story_visible and panel.cards[1].visible, "Back returns to the parade on the same scroll")
	await click(panel.cards[3])
	check(panel.selected_index == 3 and panel.name_label.text == "Unknown Spirit" and not "Qingyan" in panel.description.text, "locked spirits show only an unlock hint with no story spoilers")
	panel.show_parade()
	panel.cards[0].grab_focus()
	action("ui_right")
	await process_frame
	check(panel.selected_index == 1, "keyboard navigation updates the selected spirit")
	action("ui_accept")
	await process_frame
	check(panel.story_visible and menu.modal_page == "memories", "Enter reads the story directly without opening another window")
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	menu._unhandled_key_input(escape)
	check(not panel.story_visible and panel.selected_index == 1, "Escape returns from the story and retains selection")
	await click(panel.close_button)
	check(panel.closing and menu.overlay.visible, "Close rolls the scroll up before returning")
	await create_timer(.85).timeout
	check(not menu.overlay.visible and root.gui_get_focus_owner() == menu.buttons[2], "closing restores focus to Memories")
	menu._show_memories()
	await create_timer(.3).timeout
	menu._close_modal()
	await create_timer(.8).timeout
	check(not menu.overlay.visible, "closing during the opening animation is safe")
	check(before == JOURNEY.load_progress().encode_to_text(), "viewing memories never changes story progress")
	for entry: Dictionary in FRIENDS.ENTRIES:
		JOURNEY.complete_chapter(entry.scene)
	menu._show_memories()
	panel = menu.memories_panel
	await create_timer(1.9).timeout
	check(panel.portraits.all(func(p: TextureRect) -> bool: return p.material.get_shader_parameter("revealed")), "every completed chapter reveals its own illustration")
	await shot("04_all_revealed")
	for index in range(FRIENDS.ENTRIES.size()):
		await click(panel.cards[index])
		check(panel.description.text == FRIENDS.ENTRIES[index].story, "complete story remains available: " + FRIENDS.ENTRIES[index].name)
		panel.show_parade()
	root.size = Vector2i(800, 600)
	await shot("05_four_three")
	check(panel.stage.get_global_rect().end.x <= panel.size.x + 1, "scroll fits a narrower aspect ratio")
	root.size = Vector2i(1280, 720)
	await shot("06_large_window")
	print("MEMORY SCROLL RESULT: %d failures" % failures)
	quit(1 if failures > 0 else 0)
