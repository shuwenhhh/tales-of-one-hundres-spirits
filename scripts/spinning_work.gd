extends RefCounted

const SCALE := 0.125
const CANVAS := Vector2(1374, 1145)
const BASE := Vector2(735, 429) - Vector2(870, 1035) * SCALE
# 172x143 pixel versions (tools/pixelize_sprites.py). Mesh UVs and the CANVAS
# rect are size-independent, so at SCALE each texel lands on one screen pixel.
var worker: Texture2D = pixel_texture(preload("res://assets/chapter1/pixel/spinning/worker.png"))
var frame: Texture2D = pixel_texture(preload("res://assets/chapter1/pixel/spinning/frame.png"))

static func pixel_texture(source: Texture2D) -> Texture2D:
	var tex := CanvasTexture.new()
	tex.diffuse_texture = source
	tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return tex
var elapsed: float = 0.0
var wheel_angle: float = 0.0
var speed: float = 1.0
var mesh := ArrayMesh.new()

func advance(dt: float, working: bool) -> void:
	speed = move_toward(speed, 1.0 if working else 0.0, dt * 2.0)
	elapsed += dt * speed
	wheel_angle += dt * speed * 1.25

func draw_equipment(canvas: Node2D) -> void:
	canvas.world_transform(BASE, 0.0, Vector2.ONE * SCALE)
	# The fixed frame and stool never follow the grandmother's combat movement.
	canvas.draw_texture_rect(frame, Rect2(Vector2.ZERO, CANVAS), false)
	var center := Vector2(329, 584)
	var radii := Vector2(150, 197)
	var rim := PackedVector2Array()
	for i in range(65):
		var a := TAU * i / 64.0
		rim.append(center + Vector2(cos(a), sin(a)) * radii)
	canvas.draw_polyline(rim, Color("100f19"), 34.0, false)
	canvas.draw_polyline(rim, Color("815039"), 24.0, false)
	canvas.draw_polyline(rim, Color("ad7452"), 8.0, false)
	for i in range(6):
		var a := wheel_angle + TAU * i / 6.0
		var end := center + Vector2(cos(a), sin(a)) * radii * 0.91
		canvas.draw_line(center, end, Color("16131c"), 22.0, false)
		canvas.draw_line(center, end, Color("82543c"), 13.0, false)
	canvas.draw_circle(center, 35.0, Color("15121a"))
	canvas.draw_circle(center, 25.0, Color("a66f4d"))
	# Spindle in front of wheel, kept in place when the worker leaves.
	canvas.draw_line(Vector2(160, 704), Vector2(292, 704), Color("201a20"), 24.0, false)
	canvas.draw_line(Vector2(160, 704), Vector2(292, 704), Color("875c41"), 14.0, false)
	for i in range(9):
		canvas.draw_line(Vector2(190+i*7, 682), Vector2(195+i*7, 724), Color("dfd4bb"), 8.0, false)
	canvas.world_transform(Vector2.ZERO)

func deform(point: Vector2, rising: float) -> Vector2:
	var result := point
	var pull := sin(elapsed * 2.5)
	var hand := exp(-point.distance_squared_to(Vector2(711, 590)) / 14000.0)
	var crank := exp(-point.distance_squared_to(Vector2(520, 515)) / 10000.0)
	result += Vector2(pull * 11.0, -pull * 17.0) * hand
	result += Vector2(cos(elapsed * 1.25) * 8.0, sin(elapsed * 1.25) * 8.0) * crank
	var upper := clampf((1000.0 - point.y) / 900.0, 0.0, 1.0)
	result.y -= sin(elapsed * 1.5) * 5.0 * upper
	result.y -= rising * 85.0 * upper
	result.x -= rising * 14.0 * upper
	return result

func draw_worker(canvas: Node2D, rising: float = 0.0) -> void:
	var opacity := 1.0
	if opacity <= 0.0:
		return
	canvas.world_transform(BASE, 0.0, Vector2.ONE * SCALE)
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var colors := PackedColorArray()
	const COLS := 16
	const ROWS := 14
	for y in range(ROWS+1):
		for x in range(COLS+1):
			var uv := Vector2(float(x)/COLS, float(y)/ROWS)
			var pt := deform(uv * CANVAS, rising)
			vertices.append(Vector3(pt.x, pt.y, 0))
			uvs.append(uv)
			colors.append(Color(1, 1, 1, opacity))
	for y in range(ROWS):
		for x in range(COLS):
			var a := y*(COLS+1)+x
			indices.append_array(PackedInt32Array([a,a+1,a+COLS+1,a+1,a+COLS+2,a+COLS+1]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	canvas.draw_mesh(mesh, worker)
	var thread := PackedVector2Array()
	var end := deform(Vector2(670, 586), rising)
	for i in range(17):
		var t := i/16.0
		thread.append(Vector2(288,704).lerp(end,t)+Vector2(0,sin(t*PI)*10.0))
	canvas.draw_polyline(thread, Color(0.92,0.89,0.79,opacity), 8.0, false)
	canvas.world_transform(Vector2.ZERO)
