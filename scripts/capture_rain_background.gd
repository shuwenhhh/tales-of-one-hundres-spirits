extends SceneTree

# Capture the integrated scene twice and confirm the original rain advances.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://chapter1.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.player = Vector2(570, game.FLOOR_Y)
	game.toast_time = 0.0
	assert(game.background.get_size() == Vector2(1672, 941))
	assert(game.rain.size() == 95)
	DirAccess.make_dir_recursive_absolute("res://art_review/rain_town")
	var first_drop: Vector2 = game.rain[0]
	for frame in range(2):
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png("res://art_review/rain_town/frame_%d.png" % frame)
		assert(result == OK)
		for step in range(30):
			game._process(1.0 / 60.0)
			game._physics_process(1.0 / 60.0)
	assert(game.rain[0] != first_drop)
	assert(game.player.y == game.FLOOR_Y)
	print("PASS: new background loaded, 95 animated raindrops advance, actor remains on road")
	game.queue_free()
	await process_frame
	quit()
