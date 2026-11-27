extends Node2D

# Paints a sprite as a flat-coloured silhouette over itself, for hit flashes.
# Tinting cannot do this: a dark sprite multiplied by red stays dark. The
# owning scene supplies a painter that redraws the sprite onto this layer.

var painter: Callable

func _init() -> void:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform vec4 tint : source_color = vec4(1.0, 0.1, 0.1, 0.0); void fragment() { COLOR = vec4(tint.rgb, texture(TEXTURE, UV).a * tint.a); }"
	var flat := ShaderMaterial.new()
	flat.shader = shader
	material = flat
	visible = false

# `amount` 0 hides the silhouette, 1 covers the sprite completely.
func flash(color: Color, amount: float) -> void:
	visible = amount > 0.01
	if visible:
		(material as ShaderMaterial).set_shader_parameter("tint", Color(color, clampf(amount, 0.0, 1.0)))
		queue_redraw()

func _draw() -> void:
	if painter.is_valid():
		painter.call(self)
