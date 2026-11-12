extends RefCounted

signal cue_played(cue: StringName)

var players: Dictionary = {}
const LEVELS := {"silk_charge": -12.0, "silk_shot": -8.0, "silk_burst": -8.0, "umbrella_swing": -9.0, "umbrella_hit": -5.0}

func setup(owner_node: Node) -> void:
	for cue: String in LEVELS:
		var player := AudioStreamPlayer.new()
		player.name = cue.to_pascal_case()
		var filename: String = "umbrella_hit_crisp_v2" if cue == "umbrella_hit" else cue
		player.stream = load("res://assets/audio/combat/" + filename + ".wav")
		player.volume_db = LEVELS[cue]
		player.max_polyphony = 2 if cue == "silk_shot" else 1
		owner_node.add_child(player)
		players[cue] = player

func play(cue: String) -> void:
	if cue in ["silk_shot", "silk_burst"]:
		stop("silk_charge")
	var player: AudioStreamPlayer = players[cue]
	player.pitch_scale = randf_range(0.98, 1.02)
	player.play()
	cue_played.emit(StringName(cue))

func stop(cue: String) -> void:
	if players.has(cue):
		players[cue].stop()

func stop_all() -> void:
	for player: AudioStreamPlayer in players.values():
		player.stop()
