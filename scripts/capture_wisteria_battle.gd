extends SceneTree

const OUTPUT := "res://art_review/chapter2/wisteria_battle/"
var game

func _initialize() -> void:
	call_deferred("run")

func capture(file_name: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + file_name + ".png")

func run() -> void:
	seed(2197)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var lab = preload("res://scenes/vine_attack_lab.tscn").instantiate()
	root.add_child(lab)
	lab.set_process(false)
	lab.caption.hide()
	game = lab.game
	game.clear_vines()
	game.phase = "explore"
	game.x = 155.0
	game.boss_x = game.INTRO_TREE_X
	game.boss_state = "rest"
	game.flower_bob = 0.0
	await capture("00_tree_idle_breathe_in")
	game.flower_bob = 1.5
	await capture("00_tree_idle_breathe_out")
	game.phase = "peace"
	game.grief = 0
	game.x = 520.0
	game.boss_x = 670.0
	game.flower_bob = 1.5
	await capture("00_after_battle")
	game.phase = "battle"
	game.grief = game.MAX_GRIEF
	game.x = 340.0
	game.flower_bob = 0.0
	game.boss_state = "rest"
	game.boss_is_walking = false
	await capture("00_held_idle")
	game.boss_is_walking = true
	game.boss_walk_distance = 24.0
	await capture("00_held_walk")
	game.boss_is_walking = false
	game.boss_state = "leap_rise"
	game.boss_air_y = -58.0
	await capture("00_held_leap")
	game.boss_air_y = 0.0
	lab.restart()
	lab.set_pose(0.02)
	await capture("00_uncoiling")
	var vine = game.current_vine
	var times := [0.28, 0.52, vine.snap_time(), vine.snap_time() + vine.hold_duration + 0.18, vine.end_time() - 0.14]
	var names := ["01_windup", "02_wave", "03_crack", "04_relax", "05_retract"]
	for i in times.size():
		lab.set_pose(times[i])
		await capture(names[i])
	game.clear_vines()
	game.boss_x = 660.0
	game.x = 440.0
	game.start_boss_leap()
	while game.current_vine.elapsed < game.current_vine.snap_time():
		game.update_boss(1.0 / 240.0)
	await capture("06_air_crack")
	game.clear_vines()
	game.boss_air_y = 0.0
	game.boss_x = 630.0
	game.x = 430.0
	game.grief = 3
	game.wind_time = 2.4
	game.shots.clear()
	for i in 10:
		game.spawn_tree_petal(i * 8.0)
		var petal: Dictionary = game.shots[-1]
		var travel := i * 0.12
		petal.x += petal.vx * travel
		petal.y += petal.vy * travel
	game.start_ground_whip("long")
	while game.current_vine.elapsed < game.current_vine.snap_time() - game.current_vine.tip_contact_lead:
		game.update_boss(1.0 / 240.0)
	await capture("07_rain_and_whip")
	game.x = game.boss_x - 70.0
	game.facing = 1
	game.attack_time = 0.20
	game.attack_up = false
	game.apply_boss_hit()
	await capture("08_hit_feedback")
	game.boss_flash = 0.0
	game.boss_spark = game.HIT_SPARK_DURATION - 0.12
	await capture("08_hit_feedback_scatter")
	print("WISTERIA BATTLE CAPTURED: " + OUTPUT)
	quit()
