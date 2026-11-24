extends SceneTree

var game
var held := 0
var seen: Dictionary = {}

func key(code: int):
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._unhandled_key_input(event)

func move_axis(axis: int):
	if held == axis:
		return
	for code in [KEY_A,KEY_D]:
		var event = InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = (axis == -1 and code == KEY_A) or (axis == 1 and code == KEY_D)
		Input.parse_input_event(event)
	Input.flush_buffered_events()
	held = axis

func _initialize():
	call_deferred("run")

func advance_story() -> void:
	while game.phase in ["dialogue", "standing", "silk_lesson", "silk_reveal"]:
		if game.phase == "dialogue":
			key(KEY_E)
		elif game.phase == "standing":
			game._physics_process(game.RISE_DURATION + .01)
		elif game.phase == "silk_lesson":
			key(KEY_K)
		else:
			game._physics_process(1.0)

func run():
	game = load("res://chapter1.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	move_axis(1)
	for i in 190:
		game._physics_process(1.0/60)
	move_axis(0)
	key(KEY_E)
	advance_story()
	var elapsed := 0.0
	while game.phase == "battle" and elapsed < 360:
		seen[game.boss_state] = true
		var delta: float = game.boss.x-game.player.x
		var axis := 0
		if game.boss_state == "recover":
			if absf(delta) > 70:
				axis = int(signf(delta))
			elif delta * game.facing < 0:
				axis = int(signf(delta))
			key(KEY_J)
		elif game.boss_state in ["rest","cast"]:
			if absf(delta)>125:
				axis = int(signf(delta))
		elif game.boss_state in ["rise","air_charge","air_fire"]:
			var safe_x: float = game.boss_target.x + 85
			if absf(safe_x-game.player.x)>8:
				axis = int(signf(safe_x-game.player.x))
		if game.boss_state == "cast" and game.boss_time > 0.65 and game.player.y == game.FLOOR_Y:
			key(KEY_SPACE)
		if game.boss_state == "dash" and absf(delta)<100 and game.player.y == game.FLOOR_Y:
			key(KEY_SPACE)
		# React to independently moving silk, using normal jump/dash input only.
		for b in game.bullets:
			var future: Vector2 = b.pos + b.velocity * 0.08
			if future.distance_to(game.player+Vector2(0,-30)) < 35 and game.invulnerable <= 0:
				if game.player.y == game.FLOOR_Y:
					key(KEY_SPACE)
				else:
					key(KEY_SHIFT)
		move_axis(axis)
		var old_hp = game.hp
		game._physics_process(1.0/60)
		if game.hp != old_hp:
			print("HIT state=",game.boss_state," time=",game.boss_time," player=",game.player," boss=",game.boss)
		elapsed += 1.0/60
	move_axis(0)
	print("MOVING PLAYTEST: seconds=",elapsed," hp=",game.hp," resolve=",game.resolve," phase=",game.phase," states=",seen.keys())
	if game.phase != "dialogue" or game.resolve != 0 or not seen.has("air_fire") or not seen.has("dash"):
		quit(1)
		return
	game.test_mode = false
	game.save_path = "user://moving_boss_verification.cfg"
	advance_story()
	var cfg = ConfigFile.new()
	assert(cfg.load(game.save_path)==OK and cfg.get_value("story","silkworm",false))
	DirAccess.remove_absolute(game.save_path)
	print("PASS: moving boss combat, dialogue and memory save completed with keyboard inputs")
	if DisplayServer.get_name() != "headless":
		for state in ["rest","cast","air_fire","wrap","dash","land"]:
			game.phase = "battle"
			game.resolve = 15
			game.toast_time = 0
			game.hit_feedback = 0
			game.boss_direction = -1
			game.bullets.clear()
			game.boss = Vector2(600,245 if state=="air_fire" else 429)
			game.boss_state = state
			game.boss_time = 0.6
			game.player = Vector2(360,429)
			if state == "air_fire":
				for i in 8:
					var dir = Vector2.from_angle(i*TAU/8)
					game.spawn_silk(game.boss+Vector2(0,-55)+dir*115,dir*170,44)
			if state == "cast":
				game.spawn_silk(Vector2(460,395),Vector2(-260,0),72)
			game.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://preview_moving_"+state+".png")
	quit(0)
