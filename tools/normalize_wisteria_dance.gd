extends SceneTree

const SOURCE := "res://assets/chapter2/wisteria/dance/source.png"
const OUT := "res://assets/chapter2/wisteria/dance/"
const FRAME_SIZE := 192
const SCALED_CELL := 164
const PADDING := Vector2i(14, 28)

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if source == null or source.get_width() != source.get_height() or source.get_width() % 2 != 0:
		push_error("Wisteria dance sheet must be an even square 2x2 grid")
		quit(1)
		return
	var source_cell := source.get_width() / 2
	for frame in 4:
		var crop := source.get_region(Rect2i((frame % 2) * source_cell, (frame / 2) * source_cell, source_cell, source_cell))
		crop.convert(Image.FORMAT_RGBA8)
		crop.resize(SCALED_CELL, SCALED_CELL, Image.INTERPOLATE_NEAREST)
		for py in crop.get_height():
			for px in crop.get_width():
				var color := crop.get_pixel(px, py)
				color.a = 1.0 if color.a >= 0.55 else 0.0
				crop.set_pixel(px, py, color)
		var result := Image.create(FRAME_SIZE, FRAME_SIZE, false, Image.FORMAT_RGBA8)
		result.fill(Color.TRANSPARENT)
		result.blit_rect(crop, Rect2i(Vector2i.ZERO, Vector2i(SCALED_CELL, SCALED_CELL)), PADDING)
		result.save_png(OUT + "dance-%02d.png" % frame)
	print("Wisteria dance sprites normalized: 192px cells, shared scale, foot y≈182")
	quit()
