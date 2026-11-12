extends SceneTree

func _initialize():
	call_deferred("run")

func run():
	var g = load("res://chapter1.tscn").instantiate()
	g.test_mode = true
	root.add_child(g)
	g.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute("res://art_review/five_attacks")
	for state in ["diagonal_cast","volley","dash","air_fire","land"]:
		g.phase = "battle"
		g.boss = Vector2(660,245 if state == "air_fire" else 429)
		g.player = Vector2(240,429)
		g.boss_direction = -1
		g.boss_state = state
		g.boss_time = 0.4
		g.toast_time = 0
		g.bullets.clear()
		if state == "diagonal_cast":
			g.silk_aim = g.player + Vector2(0,-30)
			g.update_boss(0.5)
			g.update_bullets(0.75)
			g.boss_state = "diagonal_cast"
		if state == "volley":
			for x in [340,470,600]:
				g.spawn_silk(Vector2(x,395),Vector2(-260,0),42)
		if state == "air_fire":
			for i in 8:
				var d = Vector2.from_angle(i * TAU / 8 + PI / 8)
				g.spawn_silk(g.boss + Vector2(0,-55) + d*115,d*170,44)
		if state == "land":
			g.impact_time = 0.25
		g.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art_review/five_attacks/game_" + state + ".png")
	g.queue_free()
	await process_frame
	quit()
