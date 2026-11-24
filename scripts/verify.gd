extends SceneTree

var game
var failures = 0

func check(condition: bool, label: String):
	if condition:
		print("PASS: " + label)
	else:
		push_error("FAIL: " + label)
		failures += 1

func key(code: int):
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._unhandled_key_input(event)

func tick(seconds: float):
	for i in int(seconds * 60):
		game._physics_process(1.0 / 60)

func finish_story() -> void:
	while game.phase in ["dialogue", "silk_lesson", "silk_reveal"]:
		if game.phase == "dialogue":
			key(KEY_E)
		elif game.phase == "silk_lesson":
			key(KEY_K)
		else:
			tick(1.0)

func _initialize():
	call_deferred("run")

func run():
	game = load("res://chapter1.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	check(game.frames.size() == 6, "six handdrawn heroine poses loaded")
	key(KEY_SPACE)
	tick(0.2)
	check(game.player.y < 400, "jump rises above silk trajectory")
	tick(1)
	check(game.player.y == 429, "landing aligned to road")
	game.player.x = 900
	key(KEY_SHIFT)
	tick(0.3)
	check(game.player.x <= 930, "dash respects right boundary")
	game.player.x = 650
	key(KEY_E)
	check(game.phase == "dialogue", "nearby interaction starts dialogue")
	check(game.panic_line_index > 0 and not game.is_grandmother_panicked(), "grandmother begins dialogue calm")
	while game.phase in ["dialogue", "standing"]:
		if game.phase == "standing":
			tick(game.RISE_DURATION + 0.1)
		else:
			if game.dialogue[game.line_index].contains("HOT! HOT! HOT!!"):
				check(game.line_index == game.panic_line_index and game.is_grandmother_panicked(), "panic begins at hot outburst")
			if game.dialogue[game.line_index].contains("Make it stop."):
				check(game.line_index > game.panic_line_index and game.is_grandmother_panicked(), "panic persists through last prebattle line")
			key(KEY_E)
	check(game.phase == "battle", "dialogue enters battle")
	game.attack_number = 1
	game.update_boss(1.81)
	check(game.boss_state in ["diagonal_cast", "cast", "dash_prepare", "wrap"], "boss chooses an existing attack from the player's position")
	game.enter_boss_state("cast")
	game.update_boss(0.86)
	game.update_boss(0.01)
	check(game.bullets.size() == 1, "horizontal silk spawns once")
	game.update_boss(0.2)
	check(game.bullets.size() == 1, "no repeated event emission")
	game.bullets.clear()
	game.boss_state = "wrap"
	game.boss_time = 0
	game.update_boss(1.36)
	check(game.boss_state == "rise" and game.bullets.is_empty(), "wrap prepares flight without firing")
	game.update_boss(0.91)
	check(game.boss.y < 300, "boss moves into air")
	game.update_boss(1.01)
	check(game.bullets.size() == 8, "radial attack produces eight independent threads")
	game.update_boss(0.81)
	game.update_boss(0.66)
	game.update_boss(0.46)
	check(game.boss.y == game.FLOOR_Y and game.boss_state == "land", "air attack returns to ground")
	game.boss = Vector2(735,429)
	game.bullets.clear()
	game.invulnerable = 0
	game.spawn_silk(game.player + Vector2(-30, -30), Vector2(600, 0))
	game.update_bullets(0.1)
	check(game.hp == 5, "swept hit catches fast silk")
	game.spawn_silk(game.player + Vector2(-30, -30), Vector2(600, 0))
	game.update_bullets(0.1)
	check(game.hp == 5, "invulnerability prevents repeated damage")
	game.bullets.clear()
	game.player.x = 650
	game.facing = 1
	game.equipped = false
	game.begin_attack()
	check(game.attack == 0, "unequipped umbrella cannot attack")
	game.equipped = true
	game.boss_state = "recover"
	game.boss_time = 0
	game.begin_attack()
	tick(0.2)
	check(game.resolve == game.MAX_RESOLVE - 1, "umbrella hit reduces obsession")
	tick(0.1)
	check(game.resolve == game.MAX_RESOLVE - 1, "single swing cannot hit twice")
	game.bullets.clear()
	game.boss_state = "wrap"
	game.boss_time = 0
	game.attack_cd = 0
	game.begin_attack()
	tick(0.2)
	check(game.resolve == game.MAX_RESOLVE - 2, "new swing damages cloak without hidden immunity")
	game.memory_open = true
	var before = game.clock_time
	tick(0.3)
	check(game.clock_time == before, "memory overlay pauses combat")
	game.memory_open = false
	game.hp = 1
	game.invulnerable = 0
	game.spawn_silk(game.player + Vector2(-10, -30), Vector2(100, 0))
	game.update_bullets(0.1)
	check(game.phase == "failed", "last hit enters retry screen")
	key(KEY_R)
	check(game.phase == "battle" and game.hp == 6 and game.resolve == game.MAX_RESOLVE and game.bullets.is_empty(), "retry restores combat state")
	# Play repeated real umbrella attacks through the collision code.
	game.player.x = 650
	for i in game.MAX_RESOLVE:
		game.boss_state = "recover"
		game.boss = Vector2(735, game.FLOOR_Y)
		game.player = Vector2(650, game.FLOOR_Y)
		game.recovery_hit = false
		game.boss_time = 0
		game.attack_cd = 0
		game.begin_attack()
		tick(0.2)
	check(game.phase == "dialogue" and game.resolve == 0, "combat victory enters story dialogue")
	check(game.panic_line_index == -1 and not game.is_grandmother_panicked(), "postbattle dialogue restores calm portrait")
	finish_story()
	check(game.phase == "peace" and game.memory, "postbattle dialogue unlocks memory")
	key(KEY_E)
	check(game.phase == "dialogue", "grandmother remains interactable after battle")
	finish_story()
	check(game.memory, "repeat dialogue preserves single memory flag")
	game.phase = "explore"
	game.player.x = 440
	game.memory = false
	game.toast_time = 0
	game.hit_stop = 0
	game.queue_redraw()
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview.png")
	print("RESULT: " + str(failures) + " failures")
	quit(failures)
