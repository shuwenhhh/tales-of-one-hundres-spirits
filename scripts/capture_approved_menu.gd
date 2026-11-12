extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(960, 540)
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	menu.buttons[0].grab_focus()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://art_review/english_menu")
	var result := root.get_texture().get_image().save_png("res://art_review/english_menu/00_approved_menu.png")
	print("Approved main menu screenshot saved")
	menu.queue_free()
	await process_frame
	quit(0 if result == OK else 1)
