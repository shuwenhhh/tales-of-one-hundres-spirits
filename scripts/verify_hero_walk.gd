extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func hold_key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run() -> void:
	var gait = preload("res://scripts/hero_walk.gd").new()
	# The planted sole stays on the road and cancels world movement during stance.
	var a: Vector2 = gait.foot_at(0.1)
	var b: Vector2 = gait.foot_at(0.2)
	assert(a.y == 0.0 and b.y == 0.0)
	assert(is_equal_approx(b.x - a.x, -gait.STRIDE * 0.1))
	assert(gait.foot_at(0.75).y < -6.0)
	DirAccess.make_dir_recursive_absolute("res://art_review/walking")
	for chapter in [1, 2]:
		var game = load("res://chapter%d.tscn" % chapter).instantiate()
		if chapter == 1:
			game.test_mode = true
		root.add_child(game)
		game.set_physics_process(false)
		assert(game.walk.walk_frames.size() == 8)
		assert(game.walk.walk_grips.size() == 8)
		var seen: Dictionary = {}
		for texture: CanvasTexture in game.walk.walk_frames:
			var image := texture.diffuse_texture.get_image()
			assert(image.get_size() == Vector2i(64, 80))
			assert(image.get_used_rect().end.y == 72)
			seen[hash(image.get_data())] = true
		assert(seen.size() == 8)
		game.walk.distance = 0
		assert(game.walk.frame_index() == 0)
		game.walk.distance = game.walk.STRIDE * .5
		assert(game.walk.frame_index() == 4)
		game.walk.distance = 0
		if chapter == 1:
			game.player.x = 400
			game.toast_time = 0
		else:
			game.x = 400
		for direction in [1, -1]:
			var code: int = KEY_D if direction == 1 else KEY_A
			hold_key(code, true)
			for frame in range(4):
				# A visible test window may receive a focus event between screenshots.
				hold_key(code, true)
				for tick in range(5):
					game._physics_process(1.0 / 60.0)
				assert(game.walk.walking)
				assert(game.facing == direction)
				if DisplayServer.get_name() != "headless":
					game.queue_redraw()
					await process_frame
					await RenderingServer.frame_post_draw
					var screenshot := root.get_texture().get_image()
					var name := "chapter%d_%s_%d" % [chapter, "right" if direction == 1 else "left", frame]
					screenshot.save_png("res://art_review/walking/" + name + ".png")
					var px: float = game.player.x if chapter == 1 else game.x
					var py: float = game.FLOOR_Y if chapter == 1 else game.FLOOR
					var detail := screenshot.get_region(Rect2i(int(px) - 64, int(py) - 80, 128, 96))
					detail.resize(512, 384, Image.INTERPOLATE_NEAREST)
					detail.save_png("res://art_review/walking/" + name + "_detail.png")
					print("Captured ", name)
			hold_key(code, false)
		game._physics_process(1.0 / 60.0)
		assert(not game.walk.walking)
		game.queue_free()
		await process_frame
	print("PASS: eight distinct redrawn frames, consistent sole anchors, distance-driven gait, left/right facing, and idle in both chapters")
	quit()
