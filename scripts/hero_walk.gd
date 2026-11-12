extends RefCounted

signal footfall

# Full redrawn frames share one scale, pixel palette and bottom-center anchor.
# Distance drives both frame selection and alternating footstep contacts.
const STRIDE := 56.0
var distance: float = 0.0
var walking: bool = false
var step_audio: AudioStreamPlayer
var step_sounds: Array[AudioStream] = []
var step_index: int = 0
var walk_frames: Array[Texture2D] = []
var walk_grips: Array[Vector2] = []

func setup_audio(owner_node: Node) -> void:
	step_audio = AudioStreamPlayer.new()
	step_audio.name = "Footsteps"
	# The approved airy samples are already quiet; preserve their preview level.
	step_audio.volume_db = 0.0
	step_audio.max_polyphony = 1
	owner_node.add_child(step_audio)
	for i in range(1, 3):
		step_sounds.append(load("res://assets/audio/footsteps/light_step_%d.wav" % i))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/chapter1/pixel/girl/walk_v2/manifest.json"))
	for entry: Dictionary in data.frames:
		var texture := CanvasTexture.new()
		texture.diffuse_texture = load("res://" + entry.path)
		texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		walk_frames.append(texture)
		walk_grips.append(Vector2(entry.grip[0], entry.grip[1]))

func stop_audio() -> void:
	if is_instance_valid(step_audio):
		step_audio.stop()

func play_step() -> void:
	footfall.emit()
	if is_instance_valid(step_audio) and not step_sounds.is_empty():
		step_audio.stream = step_sounds[step_index % step_sounds.size()]
		step_audio.pitch_scale = 1.0
		step_audio.volume_db = 0.0
		step_audio.play()
		step_index += 1

func advance(displacement: float, grounded: bool) -> void:
	var was_walking := walking
	walking = grounded and absf(displacement) > 0.01
	if walking:
		if not was_walking:
			distance = 0.0
			play_step()
		var next_distance := distance + absf(displacement)
		var contacts := int(floor(next_distance / (STRIDE * 0.5))) - int(floor(distance / (STRIDE * 0.5)))
		for contact in range(contacts):
			play_step()
		distance = fposmod(next_distance, STRIDE)
	else:
		stop_audio()

static func foot_at(cycle: float) -> Vector2:
	var t := fposmod(cycle, 1.0)
	if t < 0.5:
		return Vector2(STRIDE * (0.25 - t), 0.0)
	var swing := (t - 0.5) * 2.0
	return Vector2(lerpf(-STRIDE * 0.25, STRIDE * 0.25, swing), -sin(swing * PI) * 7.0)

func frame_index() -> int:
	return int(floor(distance / STRIDE * 8.0)) % 8

func carry_grip() -> Vector2:
	return walk_grips[frame_index()] if walking and not walk_grips.is_empty() else Vector2(-2, -24)

func draw_body(canvas: CanvasItem, _texture: Texture2D, tint: Color = Color.WHITE) -> void:
	canvas.draw_texture_rect(walk_frames[frame_index()], Rect2(-32, -72, 64, 80), false, tint)

static func draw_shadow(canvas: CanvasItem, foot: Vector2, floor_y: float) -> void:
	var altitude := maxf(0.0, floor_y - foot.y)
	var radius := lerpf(12.0, 6.0, clampf(altitude / 100.0, 0.0, 1.0))
	var points := PackedVector2Array()
	for i in range(12):
		var a := TAU * i / 12.0
		points.append(Vector2(foot.x + cos(a) * radius, floor_y + 1.0 + sin(a) * 2.0).round())
	canvas.draw_colored_polygon(points, Color(0.08, 0.07, 0.14, 0.25))
