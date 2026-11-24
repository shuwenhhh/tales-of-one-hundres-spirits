extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://chapter1.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	var lines: Array[String] = ["Grandmother: AAAAAH! HOT! HOT! HOT!"]
	game.start_dialogue(lines, "battle")
	game.dialogue_box.reveal_or_continue()
	await create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://art_review/story_corners")
	root.get_texture().get_image().save_png("res://art_review/story_corners/panic.png")
	game.queue_free()
	await process_frame
	quit()
