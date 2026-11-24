extends RefCounted

const ACTION := &"silk_guard"
const DURATION := .65
const COOLDOWN := 1.15
var enabled: bool = false
var remaining: float = 0.0
var cooldown: float = 0.0
var flash: float = 0.0
var facing: int = 1
var counter_claimed: bool = false
var elapsed: float = 0.0
var closing: float = 0.0
var right_frames: Array[Texture2D] = []
var left_frames: Array[Texture2D] = []

func setup(unlocked: bool) -> void:
	enabled = unlocked
	if not InputMap.has_action(ACTION):
		InputMap.add_action(ACTION)
		var key := InputEventKey.new()
		key.physical_keycode = KEY_K
		InputMap.action_add_event(ACTION, key)
	for i in range(6):
		var source: Texture2D = load("res://assets/chapter1/pixel/girl/guard_v1/guard_%02d.png" % i)
		var right := CanvasTexture.new()
		right.diffuse_texture = source
		right.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		right_frames.append(right)
		var image := source.get_image()
		image.flip_x()
		var left := CanvasTexture.new()
		left.diffuse_texture = ImageTexture.create_from_image(image)
		left.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		left_frames.append(left)

func active() -> bool:
	return enabled and remaining > 0.0

func presenting() -> bool:
	return enabled and (remaining > 0.0 or closing > 0.0)

func interrupt_close() -> void:
	closing = 0.0

func handle_input(event: InputEvent, direction: int) -> bool:
	if not enabled or not event.is_action_pressed(ACTION):
		return false
	if active():
		return true
	if cooldown > 0.0:
		return true
	remaining = DURATION
	cooldown = COOLDOWN
	facing = direction
	counter_claimed = false
	elapsed = 0.0
	closing = 0.0
	return true

func advance(delta: float, playable: bool) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	var before := remaining
	if before > 0.0:
		elapsed += minf(delta, before)
	remaining = maxf(0.0, remaining - delta)
	if before > 0.0 and remaining <= 0.0:
		closing = maxf(0.0, .20 - maxf(0.0, delta - before))
	elif before <= 0.0:
		closing = maxf(0.0, closing - delta)
	flash = maxf(0.0, flash - delta)
	if not playable:
		cancel()

func cancel() -> void:
	remaining = 0.0
	flash = 0.0
	closing = 0.0
	elapsed = 0.0

func center(foot: Vector2) -> Vector2:
	return foot + Vector2(facing * 31.0, -37.0)

func intercepts(from: Vector2, to: Vector2, foot: Vector2) -> bool:
	if not active() or (from.x - foot.x) * facing < -5.0:
		return false
	var closest := Geometry2D.get_closest_point_to_segment(center(foot), from, to)
	return (closest.x - foot.x) * facing >= -5.0 and closest.distance_to(center(foot)) <= 30.0

func blocks_body(foot: Vector2, threat: Vector2) -> bool:
	return active() and (threat.x - foot.x) * facing >= -5.0 and absf(threat.y - (foot.y - 37.0)) <= 80.0

func deflect() -> void:
	flash = .16

func claim_counter() -> bool:
	if counter_claimed:
		return false
	counter_claimed = true
	return true

func frame_index() -> int:
	if remaining > 0.0:
		if elapsed < .045:
			return 0
		if elapsed < .095:
			return 1
		if elapsed < .18:
			return 2
		return 4 if flash > 0.0 else 3
	if closing > .13:
		return 2
	return 5 if closing > .06 else 0

func draw(canvas: CanvasItem, foot: Vector2) -> void:
	if not presenting():
		return
	var top_left := foot - Vector2(40 if facing > 0 else 88, 88)
	var frames: Array[Texture2D] = right_frames if facing > 0 else left_frames
	canvas.draw_texture_rect(frames[frame_index()], Rect2(top_left.round(), Vector2(128, 96)), false)
	if flash > 0.0:
		for i in range(5):
			var ray := Vector2.from_angle(-PI / 2.0 + i * PI / 4.0)
			var direction := Vector2(ray.x * facing, ray.y)
			var point := foot + Vector2(facing * 51, -41) + direction * (5.0 + (1.0 - flash / .16) * 10.0)
			canvas.draw_line(point, point + direction * 4.0, Color(1, .93, .72, flash / .16), 1.0)
