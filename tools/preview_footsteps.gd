extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var host := Node.new()
	root.add_child(host)
	var walk = load("res://scripts/hero_walk.gd").new()
	walk.setup_audio(host)
	var recorder := AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, recorder)
	recorder.set_recording_active(true)
	await create_timer(0.12).timeout
	for step in range(10):
		walk.play_step()
		await create_timer(28.0 / 155.0).timeout
	walk.stop_audio()
	await create_timer(0.3).timeout
	recorder.set_recording_active(false)
	var recording := recorder.get_recording()
	DirAccess.make_dir_recursive_absolute("res://art_review/audio")
	var result := recording.save_to_wav("res://art_review/audio/walking_preview.wav")
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	host.queue_free()
	walk = null
	await process_frame
	print("Footstep preview saved: ", recording.get_length(), " seconds")
	quit(0 if result == OK else 1)
