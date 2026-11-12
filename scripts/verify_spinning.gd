extends SceneTree
var game
var failures := 0
const OUT := "user://"
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: "+label)
	else:
		push_error(label)
		failures += 1
func tick(seconds: float) -> void:
	for i in range(int(seconds*60)):
		game._physics_process(1.0/60)
func key(code: int) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	game._unhandled_key_input(e)
func snap(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run() -> void:
	root.content_scale_size = Vector2i(960,540)
	game = load("res://chapter1.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	check(not game.granny_stood and game.phase == "explore", "starts seated and working")
	var angle: float = game.spinning.wheel_angle
	tick(0.6)
	check(game.spinning.wheel_angle > angle, "wheel turns before approach")
	await snap("spinning-opening")

	angle = game.spinning.wheel_angle
	game.paused = true
	tick(0.5)
	check(is_equal_approx(angle, game.spinning.wheel_angle), "pause freezes animation")
	game.paused = false
	var move := InputEventKey.new()
	move.physical_keycode = KEY_D
	move.keycode = KEY_D
	move.pressed = true
	Input.parse_input_event(move)
	Input.flush_buffered_events()
	tick(3.3)
	move = move.duplicate()
	move.pressed = false
	Input.parse_input_event(move)
	Input.flush_buffered_events()
	check(game.phase == "dialogue" and game.met_granny, "walking close automatically starts dialogue")
	check(game.line_index == 0 and not game.granny_stood, "conversation begins seated")
	tick(0.6)
	check(game.spinning.speed == 0.0, "wheel settles to stop during conversation")
	await snap("spinning-dialogue")
	key(KEY_E)
	key(KEY_E)
	check(game.phase == "standing", "after opening exchange grandmother rises")
	var index: int = game.line_index
	key(KEY_E)
	check(game.line_index == index, "rise animation cannot skip dialogue")
	tick(0.55)
	await snap("spinning-rise")
	tick(0.6)
	check(game.granny_stood and game.phase == "dialogue" and game.line_index == 2, "rise resumes correct dialogue line")
	await snap("spinning-standing")
	while game.phase == "dialogue":
		key(KEY_E)
	check(game.phase == "battle", "dialogue continues into existing battle")
	tick(0.4)
	check(game.spinning.speed == 0.0, "equipment stays stopped during battle")
	game.boss.x = 820
	await snap("spinning-equipment-retained")
	game.retry()
	check(game.granny_stood and game.met_granny and game.phase == "battle", "retry does not restart intro")
	game.phase = "peace"
	game.player.x = game.boss.x-80
	tick(0.1)
	check(game.phase == "peace", "proximity dialogue is not repeated after battle")
	print("FAILURES: ",failures)
	quit(failures)
