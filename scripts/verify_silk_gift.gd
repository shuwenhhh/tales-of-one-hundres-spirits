extends SceneTree

const JOURNEY := preload("res://scripts/journey_state.gd")
var failures: int = 0
var game

func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1

func key(code: int, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	event.echo = echo
	game._unhandled_key_input(event)

func open_guard() -> void:
	game.silk_guard.cancel()
	game.silk_guard.cooldown = 0
	key(KEY_J)
	var ordinary_attack: float = game.attack if game.scene_file_path == "res://chapter1.tscn" else game.attack_time
	check(ordinary_attack > 0 and not game.silk_guard.active(), "single J remains an ordinary umbrella strike")
	key(KEY_J)
	check(not game.silk_guard.active(), "rapid J strikes never activate guard")
	key(KEY_K)
	var duration: float = game.silk_guard.remaining
	key(KEY_K)
	check(game.silk_guard.remaining == duration, "extra K presses do not extend the active guard")

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art_review/silk_gift/" + name + ".png")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if OS.get_environment("TALES_TEST_RUN") != "1":
		push_error("Use isolated APPDATA / LOCALAPPDATA and TALES_TEST_RUN=1.")
		quit(2)
		return
	create_timer(40).timeout.connect(func() -> void: quit(2))
	DirAccess.make_dir_recursive_absolute("res://art_review/silk_gift")
	var empty := ConfigFile.new()
	for path in [JOURNEY.PATH, JOURNEY.PATH + ".bak", "user://chapter1_memory.cfg", "user://chapter2_memory.cfg"]:
		empty.save(path)
	game = load("res://chapter1.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.set_process(false)
	check(not game.silk_guard.enabled, "fresh journey starts with the ordinary umbrella")
	key(KEY_K)
	key(KEY_J)
	key(KEY_J)
	check(not game.silk_guard.active() and game.dash == 0, "neither K nor JJ opens the umbrella or dashes before the gift")
	key(KEY_B)
	check(game.inventory.opened and game.inventory.title.text == "随身的伞", "backpack opens before the gift without revealing unlocked rules")
	key(KEY_B)
	game.retry()
	game.test_mode = false
	game.resolve = 0
	game.win_battle()
	while game.phase == "dialogue":
		if game.dialogue[game.line_index].contains("Try opening it"):
			game.dialogue_box.reveal_or_continue()
			game._process(.01)
			await shot("00_gift_dialogue")
		game.next_line()
	check(game.phase == "silk_lesson", "closing conversation stops at the actual umbrella lesson")
	check("Grandmother: Now, take this. The roads aren't safe at night." in game.dialogue and "Grandmother: Ho ho! Off you go, little one!" in game.dialogue, "revised gift dialogue stays in the same language as Chapter One")
	key(KEY_E)
	game._process(.5)
	check(game.phase == "silk_lesson" and game.lesson_prompt.visible, "continue and dialogue timing cannot skip the lesson")
	await shot("01_try_umbrella")
	key(KEY_J)
	key(KEY_J)
	check(game.phase == "silk_lesson" and not game.silk_guard.active() and game.attack == 0, "J no longer completes the umbrella lesson")
	key(KEY_K, true)
	check(not game.silk_guard.active(), "keyboard auto-repeat cannot start the lesson")
	key(KEY_K)
	check(game.phase == "silk_reveal" and game.silk_guard.active() and game.dash == 0, "one K press opens the umbrella without dashing")
	game._physics_process(.24)
	game._process(.24)
	check(game.silk_guard.right_frames.size() == 6 and game.silk_guard.frame_index() == 3, "six-frame full-body animation reaches the approved open guard pose")
	await shot("02_opened_umbrella")
	key(KEY_E)
	check(game.phase == "silk_reveal", "the open-umbrella reveal completes before dialogue resumes")
	game._physics_process(1.0)
	check(game.phase == "dialogue" and game.guard_practiced and not game.silk_guard.active(), "successful practice resumes the next story line and clears visual effects")
	check(bool(JOURNEY.load_progress().get_value("abilities", "silk_guard", false)), "silk gift is persisted after successful practice")
	check(not "[silk_guard_lesson]" in JOURNEY.recorded_dialogue(JOURNEY.CHAPTERS[0]), "journal keeps the story without exposing internal tutorial markers")
	game.dialogue_box.reveal_or_continue()
	game._process(.01)
	await shot("04_dialogue_resumes")
	while game.phase == "dialogue":
		game.next_line()
	game.retry()
	key(KEY_B)
	check(game.inventory.opened and game.inventory.title.text == "婆婆送的伞" and "反弹" in game.inventory.rules.text, "backpack shows the gift name and defense/reflection rules")
	var old_time: float = game.battle_time
	game._physics_process(1.0)
	check(game.battle_time == old_time, "opening the backpack freezes gameplay")
	await shot("03_backpack")
	if DisplayServer.get_name() != "headless":
		var original_size := root.size
		root.size = Vector2i(1280, 720)
		await shot("05_backpack_1280")
		check(game.inventory.rules.get_global_rect().end.y < game.inventory.size.y - 45 and game.inventory.close_button.get_global_rect().end.x <= game.inventory.size.x, "backpack description and close control fit the larger window")
		root.size = original_size
		await process_frame
	# The full screen UI must handle Escape without also pausing the game.
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	Input.flush_buffered_events()
	check(not game.inventory.opened and not game.paused, "Escape closes the backpack without pausing behind it")
	game.queue_free()
	await process_frame
	for chapter in [1, 2, 3]:
		game = load("res://chapter%d.tscn" % chapter).instantiate()
		game.test_mode = true
		root.add_child(game)
		current_scene = game
		game.set_physics_process(false)
		game.set_process(false)
		game.phase = "battle"
		if chapter == 1:
			check(not game.silk_guard.enabled, "replaying Chapter One keeps guard locked before its gift even with a completed save")
			key(KEY_K)
			check(not game.silk_guard.active() and game.dash == 0, "K stays inactive before Grandmother's gift on replay")
			# Test first-chapter projectile reflection in the post-gift state.
			game.silk_guard.enabled = true
		else:
			check(game.silk_guard.enabled, "chapter %d inherits the permanent silk gift" % chapter)
		game.facing = 1
		game.hp = 6
		if chapter == 1:
			game.player = Vector2(400, game.FLOOR_Y)
			game.boss = Vector2(560, game.FLOOR_Y)
			game.boss_state = "recover"
			game.invulnerable = 0
		elif chapter == 2:
			game.x = 400
			game.boss_x = 560
			game.battle_elapsed = 10
			game.boss_state = "open_window"
			game.open_window_time = 3
			game.invincible = 0
		else:
			game.player = Vector2(400, game.FLOOR)
			game.boss_x = 560
			game.invincible = 0
		open_guard()
		check(game.silk_guard.active(), "chapter %d K activates guard" % chapter)
		if chapter == 1:
			game.spawn_silk(Vector2(475, game.FLOOR_Y - 37), Vector2(-300, 0))
			game.update_bullets(.12)
			check(game.bullets.size() == 1 and game.bullets[0].get("reflected", false) and game.hp == 6, "silk is reflected before it hits Xiaoyu")
			game.update_bullets(.5)
			check(game.resolve == game.MAX_RESOLVE - 1, "returned silk damages Grandmother")
			game.spawn_silk(Vector2(475, game.FLOOR_Y - 37), Vector2(-300, 0))
			game.update_bullets(.12)
			game.update_bullets(.5)
			check(game.resolve == game.MAX_RESOLVE - 1, "one guard cannot multiply counter damage across an entire volley")
			game.damage_player()
			check(game.hp == 6, "open umbrella also blocks frontal melee")
			game.hit_stop = 0
			game.invulnerable = 0
			game.spawn_silk(Vector2(360, game.FLOOR_Y - 30), Vector2(300, 0))
			game.update_bullets(.5)
		elif chapter == 2:
			game.shots.append({"x": 475.0, "y": game.FLOOR - 37.0, "vx": -300.0, "vy": 0.0, "angle": 0.0, "life": 5.0, "kind": "rain"})
			game.update_boss(.12)
			check(game.shots.size() == 1 and game.shots[0].get("reflected", false) and game.hp == 6, "blossom projectile is reflected by the open umbrella")
			game.update_boss(.5)
			check(game.grief == game.MAX_GRIEF - 1, "returned blossom damages the Peach Spirit")
			game.invincible = 0
			game.damage_player(false)
			check(game.hp == 6, "open umbrella blocks a frontal branch strike")
			game.damage_player(true, Vector2(380, game.FLOOR - 37))
		else:
			game.foxfires.append({"pos": Vector2(475, game.FLOOR - 37), "velocity": Vector2(-300, 0), "reflected": false})
			game._update_foxfires(.12)
			check(game.foxfires.size() == 1 and game.foxfires[0].reflected and game.hp == 6, "foxfire is reflected without requiring an attack hitbox")
			game._update_foxfires(.3)
			check(game.boss_hp == game.MAX_BOSS_HP - 1, "returned guard foxfire damages Qingyan")
			game.invincible = 0
			game._damage_player()
			check(game.hp == 6, "open umbrella blocks a frontal fox strike")
			game._damage_player(Vector2(380, game.FLOOR - 37))
		check(game.hp == 5, "chapter %d guard does not protect Xiaoyu's back" % chapter)
		game.silk_guard.advance(1.5, true)
		check(not game.silk_guard.presenting() and game.silk_guard.flash == 0, "chapter %d guard, closing pose and reflection flash expire" % chapter)
		game.combat_sounds.stop_all()
		game.queue_free()
		game = null
		await process_frame
	await create_timer(.2).timeout
	var cycle = load("res://scripts/silk_guard.gd").new()
	cycle.setup(true)
	var press := InputEventKey.new()
	press.physical_keycode = KEY_K
	press.pressed = true
	cycle.handle_input(press, 1)
	var poses: Dictionary = {}
	for frame in range(60):
		if frame == 20:
			cycle.deflect()
		if cycle.presenting():
			poses[cycle.frame_index()] = true
		cycle.advance(1.0 / 60.0, true)
	check(poses.size() == 6 and not cycle.presenting(), "opening, contact and closing use all six poses and return completely to idle")
	for texture: CanvasTexture in cycle.right_frames:
		check(texture.diffuse_texture.get_image().get_used_rect().end.y == 88, "guard sprite keeps its foot baseline on the road")
	cycle = null
	# Old clears grant the ability, but do not silently mark the new lesson done.
	empty.save(JOURNEY.PATH)
	empty.save(JOURNEY.PATH + ".bak")
	var legacy := ConfigFile.new()
	legacy.set_value("story", "silkworm", true)
	legacy.save("user://chapter1_memory.cfg")
	check(JOURNEY.has_silk_guard() and not JOURNEY.silk_guard_practiced(), "old chapter clears receive guard without skipping the new practice scene")
	print("SILK GIFT RESULT: ", failures, " failures")
	quit(failures)
