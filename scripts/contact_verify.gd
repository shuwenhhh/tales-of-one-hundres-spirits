extends SceneTree
var g
var failures := 0
var checks := 0
func check(ok: bool, name: String):
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ",name)
func tick(seconds: float, fps: int):
	for i in int(ceil(seconds*fps)):
		g._physics_process(1.0/fps)
func setup():
	g.retry()
	g.invulnerable = 10
	g.player = Vector2(650,429)
	g.boss = Vector2(735,429)
	g.boss_origin = g.boss
	g.boss_target = g.boss
	g.boss_state = "recover"
	g.attack_hit = false
	g.facing = 1
func _initialize():
	call_deferred("run")
func run():
	g = load("res://chapter1.tscn").instantiate()
	g.test_mode = true
	root.add_child(g)
	g.set_physics_process(false)
	for fps in [15,30,60,120]:
		for direction in [-1,1]:
			for state in ["rest","cast","wrap","rise","air_charge","air_fire","dive","land","recover","dash_prepare"]:
				setup()
				g.facing = direction
				g.boss.x = g.player.x + direction*85
				g.boss_origin = g.boss
				g.boss_target = g.boss
				g.boss_state = state
				g.begin_attack()
				tick(0.25,fps)
				check(g.resolve == 29,"%d fps dir %d state %s contact" % [fps,direction,state])
				tick(0.12,fps)
				check(g.resolve == 29,"one swing only once")
		setup()
		for i in 3:
			g.begin_attack()
			tick(0.55,fps)
			check(g.resolve == 29-i,"consecutive attacks in same recovery")
		setup()
		g.boss.x = 450
		g.begin_attack()
		tick(0.3,fps)
		check(g.resolve == 30 and g.hit_stop == 0,"behind is a miss")
		setup()
		g.boss.x = 900
		g.begin_attack()
		tick(0.3,fps)
		check(g.resolve == 30,"out of reach is a miss")
		setup()
		g.player.y = 362
		g.boss = Vector2(650,245)
		g.boss_origin = g.boss
		g.boss_target = g.boss
		g.boss_state = "air_fire"
		g.begin_attack(true)
		tick(0.25,fps)
		check(g.resolve == 29,"up attack at real jump apex reaches airborne cloak")
	setup()
	g.equipped = false
	g.begin_attack()
	tick(0.3,60)
	check(g.resolve == 30,"unequipped cannot hit")
	setup()
	g.resolve = 2
	for i in 2:
		g.begin_attack()
		tick(0.55,60)
	check(g.phase == "dialogue" and g.resolve == 0,"consecutive hits finish battle")
	while g.phase == "dialogue": g.next_line()
	check(g.phase == "peace" and g.memory,"memory flow preserved")
	g.swing_audio.stop()
	g.hit_audio.stop()
	g.queue_free()
	await process_frame
	print("CONTACT RESULT: %d checks, %d failures" % [checks,failures])
	quit(failures)
