extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var lab = preload("res://scenes/vine_attack_lab.tscn").instantiate()
	root.add_child(lab)
	lab.set_process(false)
	lab.caption.visible = false
	var vine = lab.game.current_vine
	var times := [0.28, vine.warning_duration+vine.propagation_time()*0.5+vine.extend_duration*0.5, vine.snap_time()+0.008, vine.snap_time()+vine.hold_duration+0.18, vine.end_time()-0.14]
	var names := ["01_windup","02_wave","03_crack","04_relax","05_retract"]
	DirAccess.make_dir_recursive_absolute("res://art_review/chapter2/vine_v2")
	for i in times.size():
		lab.set_pose(times[i])
		await process_frame
		await RenderingServer.frame_post_draw
		var frame := root.get_texture().get_image()
		if frame == null:
			quit(1)
			return
		frame.save_png("res://art_review/chapter2/vine_v2/"+names[i]+".png")
	print("VINE KEYFRAMES CAPTURED")
	quit()
