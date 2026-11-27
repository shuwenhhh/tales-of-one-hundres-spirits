extends RefCounted

# Umbrella combat effects, meant for the additive fx layer.
#   burst(): a landed strike - flash, crossed slashes, double shock ring,
#            radial streaks and a spray of sparks. A blocked strike uses the
#            same shapes in gold and bounces its sparks back.
#   swing(): the crescent trail of the umbrella itself.
# Purely visual; advance with real frame time so it keeps moving in hit-stop.

const FxLayer := preload("res://scripts/fx_layer.gd")
const LIFE := 0.55
const FLASH := 0.09
const SLASH := 0.2
const STREAKS := 0.26
const FOCUS := 0.14
const SWING_LIFE := 0.2
const GRAVITY := 700.0
const HIT_COLORS := [Color(1.0, 1.0, 1.0), Color(0.45, 0.9, 1.0), Color(1.0, 0.88, 0.5)]
const BLOCK_COLORS := [Color(1.0, 1.0, 0.9), Color(1.0, 0.75, 0.25), Color(1.0, 0.5, 0.15)]

var bursts: Array[Dictionary] = []
var swings: Array[Dictionary] = []

func burst(at: Vector2, facing: float, strong := false, blocked := false) -> void:
	var colors: Array = BLOCK_COLORS if blocked else HIT_COLORS
	var sparks: Array[Dictionary] = []
	for i in (44 if strong else 28):
		var velocity := Vector2.from_angle(randf_range(-1.35, 0.75)) * randf_range(260.0, 980.0 if strong else 780.0)
		# A landed hit throws most sparks on past the target; a block bounces them back.
		var forward := (facing if i % 5 != 0 else -facing) if not blocked else (-facing if i % 3 != 0 else facing)
		velocity.x *= forward
		sparks.append({"pos": at, "velocity": velocity, "life": randf_range(0.25, LIFE), "color": colors[i % colors.size()]})
	var streaks: Array[float] = []
	for i in 12:
		streaks.append(i * TAU / 12.0 + randf_range(-0.2, 0.2))
	bursts.append({"at": at, "age": 0.0, "facing": facing, "tilt": randf_range(-0.6, -0.2), "scale": 2.3 if strong else 1.7,
		"glow": colors[1], "upright": blocked, "sparks": sparks, "streaks": streaks})

# `variant` cycles the look of successive swings: 0 slashes downward, 1 rises
# from below, 2 is a wide double crescent.
func swing(at: Vector2, facing: float, upward := false, variant := 0) -> void:
	swings.append({"at": at, "age": 0.0, "facing": facing, "upward": upward, "variant": 0 if upward else variant % 3})

func advance(delta: float) -> void:
	for i in range(swings.size() - 1, -1, -1):
		swings[i].age += delta
		if swings[i].age >= SWING_LIFE:
			swings.remove_at(i)
	for i in range(bursts.size() - 1, -1, -1):
		var b := bursts[i]
		b.age += delta
		if b.age >= LIFE:
			bursts.remove_at(i)
			continue
		for spark: Dictionary in b.sparks:
			spark.velocity.y += GRAVITY * delta
			spark.velocity *= 1.0 - 2.6 * delta
			spark.pos += spark.velocity * delta

func clear() -> void:
	bursts.clear()
	swings.clear()

func draw(canvas: CanvasItem) -> void:
	for s in swings:
		var k: float = s.age / SWING_LIFE
		# The crescent sweeps downward across the front, or overhead for an upward strike.
		var from := -2.2 if s.upward else -1.25
		var to: float = lerpf(from, -0.7 if s.upward else 0.95, minf(1.0, k * 2.2))
		var tail: float = lerpf(from, to, clampf(k * 1.6 - 0.35, 0.0, 1.0))
		if s.variant == 1:
			tail = -tail
			to = -to
		if s.facing < 0:
			var mirrored := PI - tail
			tail = PI - to
			to = mirrored
		var fade := 1.0 - k
		var wide: bool = s.variant == 2
		for radius: float in ([82.0, 54.0] if wide else [58.0]):
			for pass_spec in [[18.0, 0.22, Color(0.35, 0.8, 1.0)], [9.0, 0.5, Color(0.6, 0.95, 1.0)], [3.5, 1.0, Color.WHITE]]:
				canvas.draw_arc(s.at, radius + 10.0 * k, tail, to, 20, Color(pass_spec[2], pass_spec[1] * fade), pass_spec[0] * fade * (1.25 if wide else 1.0), true)
	for b in bursts:
		var at: Vector2 = b.at
		var age: float = b.age
		var size: float = b.scale
		var glow: Color = b.glow
		var t := age / LIFE
		# Kept tight and brief so the struck boss's red flash stays readable behind it.
		FxLayer.glow(canvas, at, 46.0 * size * (1.0 - t * 0.5), Color(glow, 0.55 * pow(1.0 - t, 3.0)))
		for delay in [0.0, 0.07]:
			if age < delay:
				continue
			var rt: float = (age - delay) / (LIFE - delay)
			var grow := 1.0 - pow(1.0 - rt, 3.0)
			canvas.draw_arc(at, (12.0 + (70.0 - delay * 300.0) * grow) * size, 0.0, TAU, 40, Color(glow, pow(1.0 - rt, 2.0)), 1.0 + 6.0 * (1.0 - rt), true)
		if age < FOCUS:
			# Focus lines race in from the screen edges toward the point of impact.
			var k := age / FOCUS
			for angle: float in b.streaks:
				var ray := Vector2.from_angle(angle + 0.13)
				canvas.draw_line(at + ray * (230.0 + 110.0 * k), at + ray * 900.0, Color(1, 1, 1, 0.5 * (1.0 - k)), 5.0 * (1.0 - k) + 1.0)
		if age < STREAKS:
			var k := age / STREAKS
			for angle: float in b.streaks:
				var ray := Vector2.from_angle(angle)
				var inner := (18.0 + 80.0 * k) * size
				canvas.draw_line(at + ray * inner, at + ray * (inner + 46.0 * size * (1.0 - k)), Color(1, 1, 1, 1.0 - k), 3.2 * (1.0 - k) + 0.5, true)
		if age < SLASH:
			var k := age / SLASH
			var reach := (40.0 + 78.0 * sqrt(k)) * size
			# A hit slashes along the strike; a block is an upright four-point clash star.
			var along := Vector2.UP if b.upright else Vector2(b.facing, 0).rotated(b.tilt * b.facing)
			var across := along.orthogonal()
			var cross := 0.85 if b.upright else 0.55
			for pass_spec in [[18.0, 0.45, glow], [6.5, 1.0, Color.WHITE]]:
				var width: float = pass_spec[0] * (1.0 - k) * size * 0.6
				var color := Color(pass_spec[2], pass_spec[1] * (1.0 - k))
				canvas.draw_line(at - along * reach, at + along * reach, color, width, true)
				canvas.draw_line(at - across * reach * cross, at + across * reach * cross, color, width * 0.75, true)
		if age < FLASH:
			var f := 1.0 - age / FLASH
			canvas.draw_circle(at, (20.0 + 16.0 * f) * size, Color(glow, 0.2 * f), true, -1.0, true)
			canvas.draw_circle(at, (7.0 + 9.0 * f) * size, Color(1, 1, 1, 0.8 * f), true, -1.0, true)
		for spark: Dictionary in b.sparks:
			var left: float = 1.0 - age / spark.life
			if left <= 0.0:
				continue
			var color: Color = spark.color
			color.a = left
			var head: Vector2 = spark.pos
			canvas.draw_line(head - spark.velocity * 0.05, head, color, 1.5 + 3.0 * left, true)
			# Chunky square heads, snapped to the pixel grid like the sprites.
			var side := 3.0 if left < 0.5 else 6.0
			canvas.draw_rect(Rect2(head.snapped(Vector2(3, 3)) - Vector2(side, side) * 0.5, Vector2(side, side)), color)
