extends RefCounted

# Blossom explosion: a glowing flash, a thick expanding ring and a spray of
# large spinning petals. Used when a boss attack goes off. Purely visual and
# meant for the additive fx layer.

const FxLayer := preload("res://scripts/fx_layer.gd")
const SILK := [Color("fffaf0"), Color("cfdcff"), Color("9fb4f5"), Color("ffffff")]
const PEACH := [Color("ffc2d8"), Color("ff7fb0"), Color("ffe9c4"), Color("f0508c")]
const GRAVITY := 170.0

var petals: Array[Dictionary] = []
var rings: Array[Dictionary] = []

func burst(at: Vector2, colors: Array, count := 16, speed := 260.0, aim := Vector2.ZERO) -> void:
	rings.append({"at": at, "age": 0.0, "life": 0.5, "reach": speed * 0.36, "color": colors[1]})
	for i in count:
		# With an aim the petals fan out along it; without one they burst in every direction.
		var direction := Vector2.from_angle(randf() * TAU) if aim == Vector2.ZERO else aim.normalized().rotated(randf_range(-0.95, 0.95))
		petals.append({"pos": at + direction * randf_range(2.0, 14.0), "velocity": direction * speed * randf_range(0.3, 1.0),
			"age": 0.0, "life": randf_range(0.6, 1.25), "angle": randf() * TAU, "spin": randf_range(-12.0, 12.0),
			"size": randf_range(7.0, 13.0), "color": colors[i % colors.size()]})

func advance(delta: float) -> void:
	for i in range(rings.size() - 1, -1, -1):
		rings[i].age += delta
		if rings[i].age >= rings[i].life:
			rings.remove_at(i)
	for i in range(petals.size() - 1, -1, -1):
		var p := petals[i]
		p.age += delta
		if p.age >= p.life:
			petals.remove_at(i)
			continue
		p.velocity *= 1.0 - 2.3 * delta
		p.velocity.y += GRAVITY * delta
		p.pos += p.velocity * delta
		p.angle += p.spin * delta

func clear() -> void:
	petals.clear()
	rings.clear()

func draw(canvas: CanvasItem) -> void:
	for ring in rings:
		var t: float = ring.age / ring.life
		var grow := 1.0 - pow(1.0 - t, 3.0)
		var color: Color = ring.color
		FxLayer.glow(canvas, ring.at, (30.0 + ring.reach * 0.9) * (1.0 - t * 0.4), Color(color, 0.8 * pow(1.0 - t, 2.0)))
		canvas.draw_arc(ring.at, 8.0 + ring.reach * grow, 0.0, TAU, 40, Color(color, 0.9 * (1.0 - t)), 1.0 + 7.0 * (1.0 - t), true)
		canvas.draw_arc(ring.at, 8.0 + ring.reach * grow * 0.62, 0.0, TAU, 32, Color(1, 1, 1, 0.6 * (1.0 - t)), 0.5 + 3.0 * (1.0 - t), true)
		if t < 0.2:
			canvas.draw_circle(ring.at, (8.0 + ring.reach * 0.26) * (1.0 - t / 0.2), Color(1, 1, 1, 0.55 * (1.0 - t / 0.2)), true, -1.0, true)
	for p in petals:
		var left: float = 1.0 - p.age / p.life
		var axis := Vector2.from_angle(p.angle)
		var side := axis.orthogonal()
		# The petal flips as it tumbles, so its width pulses.
		var width: float = p.size * 0.55 * (0.3 + 0.7 * absf(cos(p.angle * 1.7)))
		var length: float = p.size * (0.6 + 0.4 * left)
		var color: Color = p.color
		color.a = minf(1.0, left * 2.4)
		canvas.draw_colored_polygon(PackedVector2Array([p.pos + axis * length, p.pos + side * width, p.pos - axis * length * 0.7, p.pos - side * width]), color)
		canvas.draw_circle(p.pos, p.size * 1.3, Color(color, color.a * 0.14), true, -1.0, true)
