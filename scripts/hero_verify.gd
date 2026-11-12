extends SceneTree

var game
var failures := 0

func check(ok: bool, label: String):
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func _initialize():
	call_deferred("run")

func run():
	game = load("res://chapter1.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	check(game.equipped, "umbrella initially equipped")
	game.player = Vector2(480,429)
	game.boss = Vector2(565,429)
	game.facing = 1
	game.begin_attack()
	game.attack = 0.2
	check(game.umbrella_overlaps_boss(), "right swing reaches right target")
	game.boss.x = 395
	check(not game.umbrella_overlaps_boss(), "right swing cannot hit behind player")
	game.attack_cd = 0
	game.facing = -1
	game.begin_attack()
	game.attack = 0.2
	check(game.umbrella_overlaps_boss(), "left swing reaches left target")
	game.facing = 1
	check(game.umbrella_overlaps_boss(), "turning does not change active swing direction")
	game.attack_cd = 0
	game.player = Vector2(480,360)
	game.boss = Vector2(480,245)
	game.begin_attack(true)
	game.attack = 0.2
	check(game.umbrella_overlaps_boss(), "upward swing reaches airborne cloak from jump apex")
	game.phase = "battle"
	game.boss_state = "air_fire"
	game.boss_time = 0
	game.attack = 0.2
	game._physics_process(1.0/60)
	check(game.resolve == game.MAX_RESOLVE-1 and game.hit_feedback > 0, "upward impact reduces obsession and emits spark")
	game._physics_process(1.0/60)
	check(game.resolve == game.MAX_RESOLVE-1, "one hit per swing")
	game.phase = "explore"
	game.toast_time = 0
	game.hit_feedback = 0
	game.boss = Vector2(735,429)
	game.player = Vector2(480,429)
	for state in ["idle", "right", "left", "up"]:
		game.attack = 0 if state == "idle" else 0.17
		game.attack_up = state == "up"
		game.attack_facing = -1 if state == "left" else 1
		game.queue_redraw()
		await process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://preview_hero_"+state+".png")
	print("HERO RESULT: %d failures" % failures)
	quit(failures)
