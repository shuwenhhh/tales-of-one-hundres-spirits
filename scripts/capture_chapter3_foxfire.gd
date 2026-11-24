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
	await capture("opening_positions")
	game.player = Vector2(350, game.FLOOR)
	game._start_opening()
	while game.line_index < game.lines.size() - 1 and not game.lines[game.line_index].begins_with("（身后静了下来"):
		game._next_line()
		if game.lines[game.line_index].begins_with("小语：我才不上当呢"):
			game.dialogue_box.body_label.visible_characters = -1
			await capture("refusal_grounded")
	game._process(0.4)
	await capture("turn_midway")
	game._process(0.61)
	game.dialogue_box.body_label.visible_characters = -1
	await capture("fox_reveal")
	game.dialogue_box.hide()
	game.phase = "battle"
	game.boss_visible = true
	game.player = Vector2(300, game.FLOOR)
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
	game.player.x = 205.0
	game.boss_timer = 0.36
	await capture("fan_warning")
	game.fan_shots = 0
	game._fire_fan_shot()
	game.boss_attack = "fan_firing"
	game.boss_timer = 0.05
	await capture("fan_first")
	game._update_foxfires(0.28)
	game._fire_fan_shot()
	game._update_foxfires(0.28)
	game._fire_fan_shot()
	game.boss_timer = 0.3
	game._update_foxfires(0.08)
	await capture("fan_flight")
	game.foxfires.clear()
	game.boss_hp = 4
	game._start_ground_fires()
	game.boss_timer = 0.3
	await capture("ground_warning")
	game.boss_attack = "ground_burn"
	await capture("ground_burn")
	game.ground_fires.clear()
	game.boss_attack = "teleport_pause"
	game.boss_x = 210.0
	game.boss_facing = 1
	await capture("teleport_behind")
	game.boss_attack = "dash"
	game.boss_x = game.BOSS_MIN_X
	game.boss_facing = 1
	await capture("dash_left_edge")
	game.boss_x = game.BOSS_MAX_X
	game.boss_facing = -1
	await capture("dash_right_edge")
	game.queue_free()
	await process_frame
	print("Chapter 3 capture complete")
	quit(0)
