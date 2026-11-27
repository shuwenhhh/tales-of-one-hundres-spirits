extends RefCounted

# Chunky pixel-style cotton that explodes outward from a single point of
# impact: small balls and square tufts fly out, slow down and shrink away.
# Nothing lingers over the fight, so it never hides the actors. Drawn on the
# normal canvas, snapped to a coarse grid.

const GRID := 3.0
const COTTON := [Color("fffdf6"), Color("b9b3de")]
const BLOSSOM := [Color("ffdbe8"), Color("d583aa")]
const DUST := [Color("d9d3ea"), Color("8f88b4")]

var balls: Array[Dictionary] = []
var pops: Array[Dictionary] = []

func burst(at: Vector2, size := 34.0, colors: Array = COTTON) -> void:
	pops.append({"at": at, "age": 0.0, "reach": size * 0.9, "color": colors[0]})
	var power := sqrt(size / 34.0)
	for i in int(size * 0.55):
		var direction := Vector2.from_angle(randf() * TAU)
		direction.y -= 0.25
		balls.append({"pos": at, "velocity": direction * randf_range(110.0, 460.0) * power, "age": 0.0, "life": randf_range(0.3, 0.62),
			"radius": GRID * (1 + randi() % 3) * minf(1.4, power), "square": i % 3 == 0, "light": colors[0], "shade": colors[1], "drag": 4.2, "lift": 150.0})

# Kept for big moments: one larger explosion from the same single point.
func scatter(at: Vector2, count: int, _spread: Vector2, size := 34.0, colors: Array = COTTON) -> void:
	burst(at, size * sqrt(float(count)), colors)

# A few low puffs kicked up from the ground by a jump, landing or dash.
func dust(at: Vector2, push := 0.0) -> void:
	for i in 6:
		var velocity := Vector2(randf_range(-70.0, 70.0) + push * randf_range(40.0, 120.0), randf_range(-70.0, -10.0))
		balls.append({"pos": at + Vector2(randf_range(-6.0, 6.0), 0), "velocity": velocity, "age": 0.0, "life": randf_range(0.22, 0.4),
			"radius": GRID * (1 + randi() % 2), "square": i % 2 == 0, "light": DUST[0], "shade": DUST[1], "drag": 5.0, "lift": -40.0})

func advance(delta: float) -> void:
	for i in range(pops.size() - 1, -1, -1):
		pops[i].age += delta
		if pops[i].age >= 0.14:
			pops.remove_at(i)
	for i in range(balls.size() - 1, -1, -1):
		var ball := balls[i]
		ball.age += delta
		if ball.age >= ball.life:
			balls.remove_at(i)
			continue
		ball.velocity *= maxf(0.0, 1.0 - ball.drag * delta)
		ball.velocity.y += ball.lift * delta
		ball.pos += ball.velocity * delta

func clear() -> void:
	balls.clear()
	pops.clear()

func draw(canvas: CanvasItem) -> void:
	var cell := Vector2(GRID, GRID)
	for pop in pops:
		# A thin ring snaps outward for a few frames to mark the point of impact.
		var t: float = pop.age / 0.14
		canvas.draw_arc(pop.at, pop.reach * (0.3 + 0.7 * t), 0.0, TAU, 20, Color(pop.color, 1.0 - t), GRID)
	for ball in balls:
		var left: float = 1.0 - ball.age / ball.life
		var radius: float = maxf(GRID * 0.5, snappedf(ball.radius * minf(1.0, left * 1.8), GRID * 0.5))
		var centre: Vector2 = (ball.pos as Vector2).snapped(cell)
		if ball.square:
			canvas.draw_rect(Rect2(centre - Vector2(radius, radius), Vector2(radius, radius) * 2.0), ball.light)
		else:
			canvas.draw_circle(centre + Vector2(GRID * 0.5, GRID), radius, ball.shade)
			canvas.draw_circle(centre, radius, ball.light)
