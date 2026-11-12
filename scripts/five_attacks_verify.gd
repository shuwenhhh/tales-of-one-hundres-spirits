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
		var locked: Vector2 = g.silk_aim
		g.player.x += 50
		g.update_boss(0.9)
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
		check(g.boss_target == landing, "landing marker does not chase player")
		g.update_boss(0.16)
		g.update_boss(0.46)
		check(g.boss_state == "land" and g.boss.y == g.FLOOR_Y, "lands at ground")
		g.update_boss(0.41)
		g.update_boss(1.5)
		check(g.boss_state == "recover", "at least 1.5 seconds counter window")
	g.swing_audio.stop()
	g.hit_audio.stop()
	g.queue_free()
	await process_frame
	print("FIVE ATTACKS: %d checks, %d failures" % [checks,failures])
	quit(failures)
