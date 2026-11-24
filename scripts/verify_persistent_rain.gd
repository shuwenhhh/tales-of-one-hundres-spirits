extends SceneTree

var failures: int = 0

func check(condition: bool, message: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + message)
	if not condition:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://art_review/persistent_rain")
	for chapter in [1, 2]:
		var game = load("res://chapter%d.tscn" % chapter).instantiate()
		game.test_mode = true
		root.add_child(game)
		game.set_physics_process(false)
		game.set_process(false)
		check(game.weather.drops.size() == 95, "chapter %d has two ambient rain layers" % chapter)
		var text: Array[String] = ["Xiaoyu: The rain keeps falling."]
		if chapter == 1:
			game.start_dialogue(text, "battle")
		else:
			game.start_lines(text, "battle")
		for state in ["explore", "dialogue", "standing", "battle", "peace", "failed", "leaving"]:
			game.phase = state
			game.weather.drops[0] = Vector2(400, 100)
			game._process(.1)
			check(game.weather.drops[0].y > 100, "chapter %d rain advances during %s" % [chapter, state])
		game.paused = true
		game.weather.drops[0] = Vector2(400, 100)
		game._process(.1)
		check(game.weather.drops[0].y > 100, "chapter %d ambient rain continues behind pause" % chapter)
		game.paused = false
		game.phase = "battle"
		if chapter == 1:
			game.hit_stop = .5
			game.boss_state = "recover"
			game.boss_time = .6
			game.granny_stood = true
			game.player = Vector2(570, game.FLOOR_Y)
			var boss_before: Vector2 = game.boss
			game.weather.drops[0] = Vector2(400, 100)
			game._process(.1)
			game._physics_process(.016)
			check(game.boss == boss_before and game.boss_time == .6 and game.hit_stop > 0, "hit-stop still freezes combat")
			check(game.rain[0] == game.weather.drops[0] and game.rain[0].y > 100, "rain continues during hit-stop without double physics stepping")
		else:
			game.x = 570
			game.hp = 6
			game.invincible = 0.0
			game.battle_elapsed = 2.0
			game.damage_player(true)
			game.weather.drops[0] = Vector2(400, 100)
			game._process(.1)
			check(game.weather.drops[0].y > 100 and game.hp == 5, "blossom damage does not stop the ambient rain")
		if DisplayServer.get_name() != "headless":
			for frame in range(2):
				game._process(.12)
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://art_review/persistent_rain/chapter%d_%d.png" % [chapter, frame])
		game.weather.drops[0] = Vector2(100, 555)
		game.weather.advance(.1)
		check(game.weather.drops[0].y == -12, "chapter %d drops recycle indefinitely" % chapter)
		game.queue_free()
		await process_frame
	print("PERSISTENT RAIN RESULT: ", failures, " failures")
	quit(failures)
