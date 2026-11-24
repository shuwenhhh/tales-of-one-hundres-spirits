extends SceneTree

var game
var failures: int = 0

func check(condition: bool, message: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + message)
	if not condition:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func direction_keys(direction: int) -> void:
	for code in [KEY_A, KEY_D]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = (direction < 0 and code == KEY_A) or (direction > 0 and code == KEY_D)
		Input.parse_input_event(event)
	Input.flush_buffered_events()

func run() -> void:
	game = load("res://chapter1.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	for side in [-1.0, 1.0]:
		game.retry()
		game.boss_state = "recover"
		game.boss_time = .6
		game.boss = Vector2(600, game.FLOOR_Y)
		game.boss_origin = game.boss
		game.boss_target = game.boss
		game.player = game.boss + Vector2(side * 12, 0)
		game.resolve_body_overlap(game.player, game.boss)
		check(is_equal_approx((game.player.x - game.boss.x) * side, game.BODY_GAP), "close approach preserves body spacing on side %s" % side)
		var near: Vector2 = game.player
		game.player.x = game.boss.x - side * 8
		game.resolve_body_overlap(near, game.boss)
		check((game.player.x - game.boss.x) * side >= game.BODY_GAP, "fast movement cannot cross through a stationary cloak")
		game.separate_after_hit()
		check(is_equal_approx(absf(game.player.x - game.boss.x), game.HIT_GAP), "hit gently opens a readable gap")
		var after: Vector2 = game.player
		game.separate_after_hit()
		check(game.player == after, "repeated hits do not keep pushing actors out of reach")
	game.retry()
	game.player = Vector2(930, game.FLOOR_Y)
	game.boss = Vector2(900, game.FLOOR_Y)
	game.resolve_body_overlap(game.player, game.boss)
	check(game.player.x <= 930 and game.boss.x <= 865 and game.player.x - game.boss.x >= game.BODY_GAP, "right wall shares blocked displacement with boss")
	game.player = Vector2(30, game.FLOOR_Y)
	game.boss = Vector2(45, game.FLOOR_Y)
	game.resolve_body_overlap(game.player, game.boss)
	check(game.player.x >= 30 and game.boss.x >= 95 and game.boss.x - game.player.x >= game.BODY_GAP, "left wall keeps both actors inside level bounds")
	game.boss = Vector2(600, 245)
	game.player = Vector2(600, game.FLOOR_Y)
	game.resolve_body_overlap(game.player, game.boss)
	check(game.player.x == 600, "airborne boss does not block movement underneath")
	for direction in [-1, 1]:
		for fps in [30, 60, 144]:
			game.retry()
			game.boss_state = "recover"
			game.recovery_duration = 3.0
			game.player = Vector2(30 if direction == 1 else 930, game.FLOOR_Y)
			game.boss = game.player + Vector2(direction * game.BODY_GAP, 0)
			game.boss_origin = game.boss
			game.boss_target = game.boss
			game.facing = -direction
			game.invulnerable = 0
			direction_keys(direction)
			var shift := InputEventKey.new()
			shift.physical_keycode = KEY_SHIFT
			shift.pressed = true
			game._unhandled_key_input(shift)
			check(game.facing == direction, "turning and Shift together uses the requested escape direction")
			for frame in range(int(ceil(.25 * fps))):
				game._physics_process(1.0 / fps)
			direction_keys(0)
			check((game.player.x - game.boss.x) * direction >= game.BODY_GAP and game.hp == 6, "Shift escapes corner through grandmother at %d fps, direction %d" % [fps, direction])
			check(game.player.x >= 30 and game.player.x <= 930 and game.dash_cd > 0, "phase dash retains level bounds and cooldown")
			# Body blocking resumes on the side that was reached, not the old side.
			game.player.x = game.boss.x + direction * 10
			game.resolve_body_overlap(game.player, game.boss)
			check((game.player.x - game.boss.x) * direction >= game.BODY_GAP, "ordinary blocking resumes after phase dash")
	game.retry()
	game.phase = "battle"
	game.invulnerable = 0
	game.boss_state = "recover"
	game.boss_time = .6
	game.player = Vector2(650, game.FLOOR_Y)
	game.facing = 1
	game.begin_attack()
	for tick in range(7):
		game._physics_process(1.0 / 60.0)
	check(game.hit_stop > 0 and game.resolve == game.MAX_RESOLVE - 1, "attack remains in reach after adding body spacing")
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute("res://art_review/combat_readability")
		game.toast = "Jump the low silk; avoid scattered strands and dash through."
		game.toast_time = 10
		game.dash_cd = .5
		game.bullets.clear()
		game.spawn_silk(Vector2(495, 300), Vector2(-260, 0), 65)
		game.spawn_silk(Vector2(470, 370), Vector2(-220, 55), 48)
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art_review/combat_readability/hit_and_silk.png")
		game.hit_stop = 0
		game.recoil = 0
		game.attack = 0
		game.boss_state = "recover"
		game.boss_time = .6
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art_review/combat_readability/spacing_and_hud.png")
	game.queue_free()
	game = null
	await process_frame
	print("READABILITY RESULT: ", failures, " failures")
	quit(failures)
