extends SceneTree

const OUTPUT := "res://art_review/chapter2/"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://chapter2.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.phase = "battle"
	game.battle_elapsed = 3.0
	game.grief = 1
	game.boss_state = "rest"
	game.boss_x = 600.0
	game.x = 550.0
	game.y = game.FLOOR - 80.0
	game.vy = -180.0
	game.facing = 1
	game.attack_up = true
	game.attack_time = 0.20
	game._physics_process(0.02)
	if game.phase != "settling":
		push_error("Last hit did not start the settling phase")
		quit(1)
		return
	for frame in 180:
		if game.phase != "settling":
			break
		game._physics_process(1.0 / 60.0)
		if frame == 48:
			await save_frame(game, "settling_grounded.png")
	if game.phase != "dialogue":
		push_error("Victory dialogue did not begin")
		quit(1)
		return
	game.dialogue_box.reveal_or_continue()
	await save_frame(game, "settled_dialogue.png")
	print("CHAPTER 2 SETTLED DIALOGUE CAPTURED")
	quit()

func save_frame(game: Node2D, file_name: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + file_name)
