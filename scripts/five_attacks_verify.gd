extends SceneTree

var g
var checks := 0
var failures := 0

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _initialize():
	call_deferred("run")

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	g.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art_review/dynamic_boss/" + name + ".png")

func run():
	g = load("res://chapter1.tscn").instantiate()
	g.test_mode = true
	root.add_child(g)
	g.set_physics_process(false)
	for side in [-1, 1]:
		g.phase = "battle"
		g.boss = Vector2(480, g.FLOOR_Y)
		g.player = Vector2(480 + side * 240, g.FLOOR_Y)
		g.boss_direction = side
		g.bullets.clear()
		g.enter_boss_state("cast")
		g.update_boss(0.84)
		check(g.bullets.is_empty(), "horizontal warning does not damage")
		g.update_boss(0.02)
		g.update_boss(0.01)
		check(g.bullets.size() == 1, "first separate shot")
		g.update_boss(0.5)
		check(g.bullets.size() == 1, "real interval between shots")
		g.update_boss(0.35)
		check(g.bullets.size() == 2, "second separate shot")
		g.update_boss(0.85)
		check(g.bullets.size() == 3, "third separate shot")
		for b in g.bullets:
			check(b.velocity.y == 0 and signf(b.velocity.x) == side, "horizontal direction")
		g.bullets.clear()
		g.enter_boss_state("diagonal_cast")
		g.player.x += 50
		g.update_boss(.66)
		var locked: Vector2 = g.silk_aim
		g.player.x += 50
		g.update_boss(.24)
		check(g.bullets.size() == 3, "three diagonal strands")
		check(g.silk_aim == locked, "aim committed before release")
		g.bullets.clear()
		g.boss = Vector2(480,245)
		g.enter_boss_state("air_charge")
		g.update_boss(1.01)
		check(g.bullets.size() == 8, "eight independent aerial strands")
		for b in g.bullets:
			check(absf(b.velocity.normalized().x) > 0.3, "clear downward safe sector")
		g.player = Vector2(480,g.FLOOR_Y)
		g.hp = 6
		g.invulnerable = 0
		for step in 150:
			g.update_bullets(1.0/60)
		check(g.hp == 6, "standing in lower safe gap survives aerial volley")
		g.update_boss(0.81)
		var landing: Vector2 = g.boss_target
		g.player.x += 100
		g.update_boss(0.5)
		check(g.boss_state == "dive_prepare" and g.boss.y == 245, "hover warning")
		check(g.boss_target == landing, "committed landing position does not chase player")
		g.update_boss(0.16)
		g.update_boss(0.46)
		check(g.boss_state == "land" and g.boss.y == g.FLOOR_Y, "lands at ground")
		g.update_boss(0.41)
		g.update_boss(.5)
		check(g.boss_state == "recover", "landing still gives time for a deliberate counter hit")
		g.update_boss(1.0)
		check(g.boss_state == "rest" and g.rest_duration <= .42, "boss quickly resumes decisions after the shorter landing window")
	DirAccess.make_dir_recursive_absolute("res://art_review/dynamic_boss")
	var airborne_positions: Array[float] = []
	for placement in [Vector2(480, 180), Vector2(480, 780), Vector2(480, 480), Vector2(100, 120), Vector2(860, 840), Vector2(480, 30), Vector2(480, 930)]:
		g.retry()
		g.boss = Vector2(placement.x, g.FLOOR_Y)
		g.player = Vector2(placement.y, g.FLOOR_Y)
		g.enter_boss_state("wrap")
		g.update_boss(.71)
		var airborne: Vector2 = g.boss_target
		airborne_positions.append(airborne.x)
		check(g.boss_state == "rise" and airborne.y >= 220 and airborne.y <= 275, "takeoff retains timing with varied flight height")
		check(airborne.x >= 100 and airborne.x <= 860 and absf(airborne.x - g.player.x) >= 144, "takeoff uses player spacing even near either wall")
		# Move across the arena after launch: ascent remains committed, while
		# the next phase must choose its landing from the player's new position.
		g.player.x = 930 if placement.y < 480 else 30
		g.update_boss(.91)
		check(g.boss.is_equal_approx(airborne) and g.boss_state == "air_charge", "flight reaches its original target without homing")
		g.update_boss(1.01)
		check(g.bullets.size() == 8 and g.boss_state == "air_fire", "same eight-way attack follows the ascent")
		g.update_boss(.81)
		var touchdown: Vector2 = g.boss_target
		check(touchdown.y == g.FLOOR_Y and absf(touchdown.x - g.player.x) >= 89, "landing responds to the latest player position and leaves body room")
		if placement == Vector2(480, 180):
			await shot("01_before_landing")
		g.player.x = 480
		g.update_boss(.66)
		g.update_boss(.46)
		check(g.boss.is_equal_approx(touchdown) and g.boss_state == "land", "same dive timing reaches the committed ground position")
		if placement == Vector2(480, 180):
			await shot("02_landed")
	check(airborne_positions[0] != airborne_positions[1], "moving the player changes the airborne destination")
	g.swing_audio.stop()
	g.hit_audio.stop()
	g.queue_free()
	await process_frame
	print("FIVE ATTACKS: %d checks, %d failures" % [checks,failures])
	quit(failures)
