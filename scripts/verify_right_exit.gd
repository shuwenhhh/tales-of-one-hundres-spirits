extends SceneTree

func hold_right(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_D
	event.keycode = KEY_D
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute("res://art_review/transitions")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art_review/transitions/" + name + ".png")

func run() -> void:
	create_timer(15).timeout.connect(func() -> void: quit(2))
	var transition_script = load("res://scripts/scene_transition.gd")
	assert(transition_script.start(self, "res://does_not_exist.tscn") == ERR_FILE_NOT_FOUND)
	assert(not root.has_node("ChapterTransition"))
	var game = load("res://chapter1.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.retry()
	hold_right(true)
	game.player.x = 929
	# Reaching the right edge during battle must not unlock the next chapter.
	game._physics_process(1.0 / 60.0)
	assert(game.phase == "battle")
	hold_right(false)
	game.resolve = 0
	game.win_battle()
	while game.phase == "dialogue":
		game.next_line()
	if game.phase == "silk_lesson":
		var tap := InputEventKey.new()
		tap.physical_keycode = KEY_K
		tap.pressed = true
		game._unhandled_key_input(tap)
		game._physics_process(.1)
		game._unhandled_key_input(tap)
		game._physics_process(1.0)
		while game.phase == "dialogue":
			game.next_line()
	assert(game.memory and game.phase == "peace")
	# Standing at the exit, waiting, moving left or pressing N must not switch.
	for step in range(120):
		game._physics_process(1.0 / 60.0)
	assert(game.phase == "peace")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_N
	event.pressed = true
	game._unhandled_key_input(event)
	assert(game.phase == "peace")
	# Start on the grandmother's LEFT, reproducing the roadblock reported in-game.
	game.player.x = game.boss.x - game.BODY_GAP - 10
	var crossed_grandmother := false
	var initial_hp: int = game.hp
	hold_right(true)
	for step in range(600):
		game._physics_process(1.0 / 60.0)
		if game.player.x > game.boss.x + 16:
			crossed_grandmother = true
		if game.phase == "leaving":
			break
	assert(crossed_grandmother)
	assert(game.hp == initial_hp)
	assert(game.phase == "leaving")
	hold_right(false)
	await process_frame
	await process_frame
	var transition = root.get_node("ChapterTransition")
	assert(current_scene == game and transition.veil.color.a < 1.0)
	assert(transition_script.start(self, "res://chapter3.tscn") == ERR_BUSY)
	game.weather.drops[0] = Vector2(400, 100)
	await create_timer(.23).timeout
	assert(transition.veil.color.a > 0 and transition.veil.color.a < 1)
	assert(game.weather.drops[0].y > 100 and not game.is_physics_processing())
	await shot("01_fading_out")
	while transition.stage != "fading_in":
		await process_frame
	assert(current_scene.scene_file_path == "res://chapter2.tscn")
	assert(current_scene.phase == "explore")
	var arriving = current_scene
	var spawn_x: float = arriving.x
	hold_right(true)
	await create_timer(.3).timeout
	assert(arriving.x == spawn_x and not arriving.is_physics_processing())
	assert(transition.veil.color.a > 0 and transition.veil.color.a < 1)
	await shot("02_fading_in")
	while root.has_node("ChapterTransition"):
		await process_frame
	hold_right(false)
	assert(arriving.is_physics_processing())
	await shot("03_peach_garden")
	print("PASS: chapter one right exit fades out, loads under cover, fades in, and restores movement; rain keeps moving")
	# The next walk-right exit shares exactly the same presentation.
	arriving.phase = "peace"
	arriving.grief = 0
	arriving.x = 924
	hold_right(true)
	arriving._physics_process(1.0 / 60.0)
	assert(arriving.phase == "leaving")
	hold_right(false)
	while root.has_node("ChapterTransition"):
		await process_frame
	assert(current_scene.scene_file_path == "res://chapter3.tscn" and current_scene.is_physics_processing())
	print("PASS: chapter two also walks right into chapter three using the shared fade, with no extra key")
	current_scene.queue_free()
	await process_frame
	quit()
