extends SceneTree

func _initialize() -> void:
	var source := AudioStreamMP3.new()
	source.data = FileAccess.get_file_as_bytes("res://assets/audio/footsteps/source/child_walking_excitedly_850275_hq.mp3")
	var playback := source.instantiate_playback()
	playback.start()
	var frames := playback.mix_audio(1.0, int(source.get_length() * AudioServer.get_mix_rate()))
	var bytes := PackedByteArray()
	bytes.resize(frames.size() * 2)
	for i in range(frames.size()):
		bytes.encode_s16(i * 2, int(clampf((frames[i].x + frames[i].y) * 0.5, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(AudioServer.get_mix_rate())
	wav.stereo = false
	wav.data = bytes
	var error := wav.save_to_wav("res://assets/audio/footsteps/source/decoded.wav")
	if error != OK:
		quit(1)
		return
	print("Decoded ", frames.size(), " frames at ", wav.mix_rate, " Hz")
	quit()
