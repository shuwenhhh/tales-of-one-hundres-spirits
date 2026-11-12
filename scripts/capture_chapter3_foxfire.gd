extends SceneTree

var game: Node2D

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://art_review/chapter3/" + label + ".png"
	var result := root.get_texture().get_image().save_png(path)
	if result != OK:
		push_error("Could not save " + path)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://art_review/chapter3")
	game = load("res://chapter3.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.phase = "battle"
	game.player = Vector2(670, game.FLOOR)
	game.boss_attack = "approach"
	game.boss_walk_clock = 0.0
	await capture("walk_0")
	game.boss_walk_clock = 0.14
	await capture("walk_1")
	game.boss_walk_clock = 0.27
	await capture("walk_2")
	game.boss_attack = "backjump"
	game.boss_rise = 50.0
	await capture("backjump")
	game.boss_rise = 0.0
	game.boss_attack = "dash_windup"
	game.boss_timer = 0.36
	await capture("dash_warning")
	game.boss_attack = "fan_windup"
	game.boss_timer = 0.36
	await capture("fan_warning")
	game._fire_fan()
	game._update_foxfires(0.23)
	await capture("fan_flight")
	game.foxfires.clear()
	game.boss_attack = "teleport_pause"
	game.boss_x = 745.0
	game.boss_facing = -1
	await capture("teleport_behind")
	game.queue_free()
	await process_frame
	print("Chapter 3 capture complete")
	quit(0)
