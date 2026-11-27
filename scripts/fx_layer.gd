extends Node2D

# Additive overlay for combat effects, so flashes, sparks and petals glow
# against the dusk backgrounds instead of sitting flat on top of them.
# The owning scene supplies a painter that draws onto this layer.

var painter: Callable

func _init() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if painter.is_valid():
		painter.call(self)

# Soft round glow built from stacked translucent discs.
static func glow(canvas: CanvasItem, at: Vector2, radius: float, color: Color) -> void:
	for i in 6:
		canvas.draw_circle(at, radius * (1.0 - i / 6.5), Color(color, color.a * 0.1), true, -1.0, true)
