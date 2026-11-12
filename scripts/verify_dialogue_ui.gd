extends SceneTree

var failures: int = 0

func check(condition: bool, message: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + message)
	if not condition:
		failures += 1

func key(game: Node, code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._unhandled_key_input(event)

func ctrl(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_CTRL
	event.keycode = KEY_CTRL
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art_review/dialogue/" + name + ".png")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://chapter1.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.retry()
	game.invulnerable = 0
	game.player.x = 570
	game.toast_time = 0
	var sample: Array[String] = ["Grandmother: They did. A long time ago.", "Grandmother: I was a silkworm, then. I made a cocoon.", "Xiaoyu: Did you ever get your wings?"]
	var merged: Array[String] = game.dialogue_box.merge_lines(sample)
	check(merged.size() == 2 and "cocoon" in merged[0], "adjacent same-speaker sentences combine without dropping text")
	game.start_dialogue(sample, "peace")
	check(game.dialogue_box.body_label.visible_characters == 0, "new lines begin hidden")
	game._process(.2)
	check(game.dialogue_box.body_label.visible_characters > 0 and not game.dialogue_box.complete(), "text appears progressively")
	DirAccess.make_dir_recursive_absolute("res://art_review/dialogue")
	await shot("01_typewriter")
	key(game, KEY_E)
	check(game.line_index == 0 and game.dialogue_box.complete(), "first continue press reveals the current line")
	await shot("02_grandmother")
	var grandmother_color: Color = game.dialogue_box.name_label.get_theme_color("font_color")
	key(game, KEY_E)
	check(game.line_index == 1 and not game.dialogue_box.complete(), "second continue press advances and resets typewriter")
	check(game.dialogue_box.name_label.get_theme_color("font_color") != grandmother_color, "heroine and grandmother have distinct name colors")
	game.dialogue_box.reveal_or_continue()
	await shot("03_xiaoyu")
	game.start_dialogue(sample, "peace")
	ctrl(true)
	game._process(.3)
	game._process(.3)
	check(game.line_index == 1, "holding Ctrl reveals then advances dialogue")
	ctrl(false)
	var before: float = game.dialogue_box.text_progress
	game.paused = true
	game._process(1.0)
	check(game.dialogue_box.text_progress == before and not game.dialogue_box.visible, "pause freezes and hides the dialogue")
	game.paused = false
	game._process(.01)
	check(game.dialogue_box.visible, "dialogue returns after pause")
	game.queue_free()
	await process_frame
	var second = load("res://chapter2.tscn").instantiate()
	second.test_mode = true
	root.add_child(second)
	second.set_physics_process(false)
	second.set_process(false)
	second.x = 570
	var chinese: Array[String] = ["桃花妖：没有。我总想等花开得更好些。", "桃花妖：再等一下。水一静，他就回来了。", "小语：可他已经不会来了，对吗？"]
	second.start_lines(chinese, "battle")
	check(second.lines.size() == 2, "Chinese same-speaker lines also combine")
	second.dialogue_box.reveal_or_continue()
	await process_frame
	await shot("04_peach_spirit")
	check(second.dialogue_box.body_label.get_content_height() <= second.dialogue_box.body_label.size.y, "Chinese text fits the dialogue box")
	key(second, KEY_SPACE)
	check(second.line == 1, "chapter two uses the same continue behavior")
	second.queue_free()
	await process_frame
	print("DIALOGUE UI RESULT: ", failures, " failures")
	quit(failures)
