extends Node2D

# Distant fox wedding lights sit between the painted grove and the characters.
const LANTERNS := [
	Vector3(763.0, 321.0, 0.62),
	Vector3(810.0, 306.0, 0.75),
	Vector3(849.0, 328.0, 0.66),
]

var time := 0.0

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	for i in LANTERNS.size():
		var lantern: Vector3 = LANTERNS[i]
		var pulse := pow(0.5 + 0.5 * sin(time * 1.28 + i * 0.67), 2.4)
		var glimmer := 0.5 + 0.5 * sin(time * 3.1 + i * 1.83)
		var opacity := (0.12 + pulse * 0.68 + glimmer * 0.1) * (0.75 + lantern.z * 0.25)
		var drift := sin(time * 0.34 + i * 0.9) * 2.0
		var center := Vector2(roundf(lantern.x + drift), roundf(lantern.y))
		var size := maxf(5.0, roundf(9.0 * lantern.z))
		_draw_lantern(center, size, opacity)

func _draw_lantern(center: Vector2, size: float, opacity: float) -> void:
	draw_circle(center, size * 4.1, Color(0.76, 0.14, 0.12, opacity * 0.055))
	draw_circle(center, size * 2.6, Color(0.95, 0.25, 0.14, opacity * 0.12))
	draw_circle(center, size * 1.45, Color(1.0, 0.42, 0.2, opacity * 0.24))
	var paper := Rect2(center.x - size * 0.5, center.y - size * 0.8, size, size * 1.6)
	draw_rect(paper, Color(0.61, 0.09, 0.1, opacity))
	draw_rect(Rect2(center.x - size * 0.23, center.y - size * 0.47, size * 0.46, size * 0.94), Color(1.0, 0.48, 0.23, opacity * 0.87))
	draw_line(center + Vector2(-size * 0.58, -size * 0.9), center + Vector2(size * 0.58, -size * 0.9), Color(0.29, 0.11, 0.17, opacity), 1.0)
	draw_line(center + Vector2(0, size * 0.8), center + Vector2(0, size * 1.35), Color(0.7, 0.15, 0.14, opacity * 0.7), 1.0)
