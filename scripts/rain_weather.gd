extends RefCounted

# Ambient weather uses render time, independently of combat and hit-stop.
var drops: Array[Vector2] = []
var viewport_size := Vector2(960, 540)

func reset(size: Vector2) -> void:
	viewport_size = size
	drops.clear()
	for i in range(95):
		drops.append(Vector2(randf_range(0, size.x), randf_range(0, size.y)))

func advance(delta: float) -> void:
	for i in range(drops.size()):
		var near_layer := i % 3 == 0
		drops[i] += Vector2(-48, 270 if near_layer else 190) * delta
		if drops[i].y > viewport_size.y + 12 or drops[i].x < -12:
			drops[i] = Vector2(randf_range(0, viewport_size.x + 100), -12)

func draw(canvas: CanvasItem) -> void:
	for i in range(drops.size()):
		var near_layer := i % 3 == 0
		var length := Vector2(-2, 10) if near_layer else Vector2(-1, 6)
		var color := Color(.79, .82, .95, .29 if near_layer else .19)
		canvas.draw_line(drops[i], drops[i] + length, color, 1.0)
