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

func run() -> void:
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
	assert(current_scene.scene_file_path == "res://chapter2.tscn")
	assert(current_scene.phase == "explore")
	print("PASS: exit locked before victory; after victory, walking from grandmother's left crosses her safely and enters chapter two without an entry key")
	current_scene.queue_free()
	await process_frame
	quit()
