extends SceneTree

func _initialize():
	call_deferred("run")

func run():
	var g = load("res://chapter1.tscn").instantiate()
	g.test_mode = true
	root.add_child(g)
	g.set_physics_process(false)
	assert(g.ascent_frames.size()==6 and g.landing_frames.size()==6)
	var samples = [["wrap",0.1,0],["wrap",0.6,1],["rise",0.1,2],["rise",0.3,3],["rise",0.5,4],["rise",0.8,5],["dive_prepare",0.3,0],["dive",0.1,1],["dive",0.35,2],["land",0.1,3],["land",0.3,4],["recover",0.1,5]]
	var checks := 0
	DirAccess.make_dir_recursive_absolute("res://art_review/flight")
	for facing in [-1,1]:
		for i in samples.size():
			g.phase = "battle"
			g.boss_state = samples[i][0]
			g.boss_time = samples[i][1]
			g.boss_direction = facing
			assert(g.flight_pose().index == samples[i][2])
			checks += 1
			g.boss = Vector2(620,429 if g.boss_state in ["wrap","land","recover"] else 280)
			g.boss_target = Vector2(620,429)
			g.toast_time = 0
			g.queue_redraw()
			if DisplayServer.get_name() != "headless":
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://art_review/flight/frame_%d_%02d.png" % [facing,i])
	for tex in g.ascent_frames + g.landing_frames:
		assert(tex.get_size()==Vector2(256,300))
		assert(tex.get_image().get_pixel(0,0).a==0)
		checks += 2
	g.swing_audio.stop()
	g.hit_audio.stop()
	g.queue_free()
	await process_frame
	print("FLIGHT: ",checks," checks passed; 12 frames selected across both facing directions")
	quit()
