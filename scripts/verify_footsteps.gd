extends SceneTree

var failures: int = 0

func check(condition: bool, message: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + message)
	if not condition:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var host := Node.new()
	root.add_child(host)
	var walk = preload("res://scripts/hero_walk.gd").new()
	walk.setup_audio(host)
	check(walk.step_sounds.size() == 2, "approved light left/right footstep samples loaded")
	for stream in walk.step_sounds:
		check(stream != null and stream.get_length() > 0.1 and stream.get_length() < 0.2, "short one-shot sample")
	walk.advance(14.0, true)
	check(walk.step_index == 1, "first grounded movement plays a contact")
	check(walk.step_audio.stream == walk.step_sounds[0], "first foot plays sample 1")
	walk.advance(14.0, true)
	check(walk.step_audio.stream == walk.step_sounds[1], "second foot plays sample 2")
	walk.advance(28.0, true)
	check(walk.step_audio.stream == walk.step_sounds[0], "next foot repeats sample 1")
	check(walk.step_index == 3, "contacts follow each half-stride across cycle wrap")
	walk.advance(0.0, true)
	check(not walk.step_audio.playing and walk.step_index == 3, "standing stops audio without extra steps")
	walk.advance(30.0, false)
	check(walk.step_index == 3, "airborne movement produces no footsteps")
	walk.advance(-2.0, true)
	check(walk.step_index == 4, "leftward walking also produces steps")
	walk.stop_audio()
	check(not walk.step_audio.playing, "pause stops the current step")
	for chapter in [1, 2]:
		var game = load("res://chapter%d.tscn" % chapter).instantiate()
		if chapter == 1:
			game.test_mode = true
		root.add_child(game)
		game.set_physics_process(false)
		check(game.walk.step_audio.get_parent() == game, "chapter %d owns its footstep player" % chapter)
		if chapter == 2:
			check(game.get_child(0) is Sprite2D, "garden shader retains its backdrop node")
		game.walk.advance(2.0, true)
		game.paused = true
		game._physics_process(1.0 / 60.0)
		check(not game.walk.step_audio.playing, "chapter %d pause silences steps" % chapter)
		game.queue_free()
	host.queue_free()
	walk = null
	await process_frame
	print("FOOTSTEPS RESULT: ", failures, " failures")
	quit(failures)
