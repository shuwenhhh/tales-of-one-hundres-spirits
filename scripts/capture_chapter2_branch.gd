extends SceneTree

# Capture the actual on-screen branch poses for visual review.
var game

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art_review/chapter2/" + name + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://art_review/chapter2")
	game = load("res://chapter2.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.phase = "battle"
	game.x = 435.0
	game.boss_x = 495.0
	game.boss_facing = -1
	game.facing = 1
	game.boss_state = "rest"
	await capture("peach_branch_rest")
	game.boss_state = "branch_prepare"
	await capture("peach_branch_prepare")
	game.boss_state = "branch_swing"
	await capture("peach_branch_swing")
	game.boss_state = "branch_lunge"
	await capture("peach_branch_lunge")
	game.boss_state = "leap_dive"
	game.boss_air_y = -46.0
	await capture("peach_branch_leap")
	game.boss_air_y = 0.0
	game.boss_state = "branch_prepare"
	game.warning_played = true
	await capture("peach_branch_warning")
	game.warning_played = false
	game.boss_state = "blossom_cast"
	game.boss_time = 0.0
	game.battle_elapsed = 2.0
	game.grief = 4
	game.cast_released = false
	game.update_boss(0.53)
	game.update_boss(0.3)
	await capture("peach_blossom_cast")
	game.boss_state = "rest"
	game.grief = 6
	game.x = 435.0
	game.boss_x = 495.0
	game.apply_boss_hit()
	await capture("peach_boss_hit_feedback")
	game.impact_pause = 0.0
	game.invincible = 0.0
	game.damage_player(false)
	await capture("peach_xiaoyu_hit_feedback")
	game.impact_pause = 0.0
	game.grief = 1
	game.x = 435.0
	game.boss_x = 495.0
	game.apply_boss_hit()
	await capture("peach_after_final_hit")
	game._physics_process(1.61)
	await capture("peach_postbattle_dialogue")
	game.queue_free()
	await process_frame
	quit()
