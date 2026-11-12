extends SceneTree

# Renders real game frames after the pixel-grid conversion for visual review.
# Godot --path . --script res://scripts/capture_pixel_grid.gd   (needs a window, not --headless)

var g

func _initialize():
	call_deferred("run")

func shot(name: String):
	print("shot ", name)
	g.toast_time = 0
	g.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art_review/pixel_grid/" + name + ".png")

func run():
	g = load("res://chapter1.tscn").instantiate()
	g.test_mode = true
	root.add_child(g)
	g.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute("res://art_review/pixel_grid")
	# Explore: grandmother seated at the wheel, heroine walking in.
	g.player = Vector2(600, g.FLOOR_Y)
	g.moving = true
	g.clock_time = 0.2
	g.spinning.advance(0.7, true)
	await shot("01_explore_spinning")
	# Standing grandmother next to the stool, heroine idle (like the reported screenshot).
	g.moving = false
	g.granny_stood = true
	g.met_granny = true
	g.phase = "battle"
	g.boss_state = "rest"
	g.boss = Vector2(735, g.FLOOR_Y)
	g.player = Vector2(840, g.FLOOR_Y)
	g.facing = -1
	await shot("02_standing")
	# Battle poses.
	g.player = Vector2(300, g.FLOOR_Y)
	g.facing = 1
	for state in ["cast", "wrap", "dash", "land"]:
		g.boss_state = state
		g.boss_time = 0.1
		g.bullets.clear()
		await shot("03_boss_" + state)
	# Heroine strikes: horizontal and upward (long umbrella).
	g.boss_state = "rest"
	g.player = Vector2(620, g.FLOOR_Y)
	for up in [false, true]:
		g.attack = 0.22
		g.attack_up = up
		g.attack_facing = 1
		await shot("04_strike_" + ("up" if up else "side"))
	g.attack = 0.0
	# Flight frames (ascent).
	g.boss_state = "rise"
	g.boss_time = 0.35
	await shot("05_flight")
	g.queue_free()
	await process_frame
	quit()
