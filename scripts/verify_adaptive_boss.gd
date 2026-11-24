extends SceneTree

var failures: int = 0
var game

func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func shot() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute("res://art_review/adaptive_boss")
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art_review/adaptive_boss/aimed_fan.png")

func choices_at(position: Vector2) -> Dictionary:
	game.player = position
	game.boss = Vector2(480, game.FLOOR_Y)
	game.last_boss_attack = ""
	game.ground_attacks = 3
	game.boss_rng.seed = 71027
	var counts := {"diagonal_cast": 0, "cast": 0, "dash_prepare": 0, "wrap": 0}
	for i in range(800):
		counts[game.choose_boss_attack()] += 1
	return counts

func run() -> void:
	create_timer(30).timeout.connect(func() -> void: quit(2))
	game = load("res://chapter1.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	var near := choices_at(Vector2(380, game.FLOOR_Y))
	var far := choices_at(Vector2(30, game.FLOOR_Y))
	var jumping := choices_at(Vector2(30, game.FLOOR_Y - 100))
	check(near.wrap > far.wrap, "close players provoke more takeoffs")
	check(far.dash_prepare > near.dash_prepare, "distant players provoke more gap-closing attacks")
	check(jumping.diagonal_cast > far.diagonal_cast and jumping.cast < far.cast, "jumping players provoke aimed fans instead of low horizontal shots")
	check(near.values().min() > 0 and far.values().min() > 0, "positions bias choices without forcing one predictable answer")
	game.player = Vector2(280, game.FLOOR_Y)
	game.boss = Vector2(480, game.FLOOR_Y)
	game.last_boss_attack = "wrap"
	game.boss_rng.seed = 71027
	var repeated_flights := 0
	for i in range(800):
		if game.choose_boss_attack() == "wrap":
			repeated_flights += 1
	check(repeated_flights < 80, "recent attacks are strongly discouraged from repeating")
	var launches: Dictionary = {}
	var landings: Dictionary = {}
	game.boss_rng.seed = 71028
	for i in range(24):
		game.retry()
		game.player = Vector2(280, game.FLOOR_Y)
		game.boss = Vector2(480, game.FLOOR_Y)
		game.enter_boss_state("wrap")
		game.update_boss(.71)
		launches[roundi(game.boss_target.x)] = true
		game.update_boss(.91)
		game.update_boss(1.01)
		game.update_boss(.81)
		landings[roundi(game.boss_target.x)] = true
	check(launches.size() > 12 and landings.size() > 12, "identical player positions still produce varied takeoffs and landings")
	game.bullets.clear()
	game.update_boss(.66)
	game.update_boss(.46)
	game.update_boss(.41)
	var resting_at: Vector2 = game.boss
	check(game.boss_state == "recover" and game.recovery_duration >= 1.05 and game.recovery_duration <= 1.45, "landing gives a brief 1.05 to 1.45 second punish window")
	game.player.x = 30
	game.update_boss(.35)
	check(game.boss_state == "recover" and game.boss == resting_at, "boss stays grounded and does not chase during the opening")
	game.player = game.boss - Vector2(84, 0)
	game.facing = 1
	game.begin_attack()
	for i in range(10):
		game._physics_process(1.0 / 60.0)
	check(game.resolve == game.MAX_RESOLVE - 1, "the ground opening accepts normal player umbrella attacks")
	check(game.recovery_duration - game.boss_time <= .41, "a hit shortens the remaining idle opening")
	for i in range(60):
		game._physics_process(1.0 / 60.0)
		if game.attack_cd <= 0:
			break
	game.begin_attack()
	for i in range(25):
		game._physics_process(1.0 / 60.0)
		if game.resolve == game.MAX_RESOLVE - 2:
			break
	check(game.resolve == game.MAX_RESOLVE - 2 and game.evading and game.boss_state == "sidestep", "two real consecutive hits make Grandmother sidestep instead of flying away")
	var evasion_start: Vector2 = game.boss
	for i in range(60):
		game._physics_process(1.0 / 60.0)
	check(game.boss.y == game.FLOOR_Y and absf(game.boss.x - evasion_start.x) > 45, "pressure response retreats while preserving the ground fight")
	for wall in [95.0, 865.0]:
		game.retry()
		game.boss = Vector2(wall, game.FLOOR_Y)
		game.player = Vector2(wall + (84 if wall == 95 else -84), game.FLOOR_Y)
		game.enter_boss_state("recover")
		game.respond_to_ground_hit()
		game.respond_to_ground_hit()
		check(game.evading and game.evasion_target_x == wall, "cornered boss avoids crossing the player at a wall")
	for side in [-1, 1]:
		for altitude in [0.0, -110.0]:
			game.retry()
			game.boss = Vector2(480, game.FLOOR_Y)
			game.player = Vector2(480 + side * 90, game.FLOOR_Y + altitude)
			game.enter_boss_state("diagonal_cast")
			game.update_boss(.3)
			game.player.x += side * 10
			game.update_boss(.36)
			var locked: Vector2 = game.silk_aim
			var origin: Vector2 = game.aimed_silk_origin()
			game.player.x -= side * 80
			game.update_boss(.2)
			check(game.bullets.size() == 3, "fan still releases three simultaneous strands")
			var direction: Vector2 = game.bullets[1].velocity.normalized()
			check(direction.dot((locked - origin).normalized()) > .999 and game.silk_aim == locked, "central strand targets the player's windup position with a dodge window")
			if altitude == 0:
				check(game.bullets[0].velocity.y <= 0 or game.bullets[2].velocity.y <= 0, "close-range fan does not send all three strands into the road")
				if side == -1:
					game.player = locked + Vector2(0, 36)
					game.update_bullets(.16)
					game.invulnerable = 0
					await shot()
	game.retry()
	game.boss_rng.seed = 71029
	game.invulnerable = 999
	var seen: Dictionary = {}
	var live_attacks: Dictionary = {}
	for tick in range(7200):
		var elapsed := tick / 60.0
		game.player.x = 480.0 + sin(elapsed * .6) * 340.0
		game._physics_process(1.0 / 60.0)
		seen[game.boss_state] = true
		if game.boss_state in ["diagonal_cast", "cast", "dash_prepare", "wrap"]:
			live_attacks[game.boss_state] = true
	check(live_attacks.size() == 4 and seen.has("land") and seen.has("recover"), "two minutes of actual combat reach all four attacks and brief ground openings without stalling")
	check(game.boss.x >= 95 and game.boss.x <= 865 and game.hp == 6, "live simulation keeps boss inside the arena with test-only invulnerability")
	game.combat_sounds.stop_all()
	game.queue_free()
	game = null
	await process_frame
	await create_timer(.2).timeout
	print("ADAPTIVE BOSS RESULT: ", failures, " failures")
	quit(failures)
