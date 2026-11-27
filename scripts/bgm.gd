extends RefCounted

# Looping background music that fades in while wanted and out when not.
# A missing music file leaves the scene silent instead of failing to load.

const SILENT_DB := -40.0
const FADE_DB_PER_SECOND := 36.0

var player: AudioStreamPlayer
var level_db := -12.0

func setup(owner_node: Node, path: String, level := -12.0) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = true
	level_db = level
	player = AudioStreamPlayer.new()
	player.name = "Bgm"
	player.stream = stream
	player.volume_db = SILENT_DB
	owner_node.add_child(player)

func update(wanted: bool, delta: float, held := false) -> void:
	if player == null:
		return
	player.stream_paused = held
	if held:
		return
	if wanted and not player.playing:
		player.volume_db = SILENT_DB
		player.play()
	player.volume_db = move_toward(player.volume_db, level_db if wanted else SILENT_DB, FADE_DB_PER_SECOND * delta)
	if not wanted and player.playing and player.volume_db <= SILENT_DB:
		player.stop()
