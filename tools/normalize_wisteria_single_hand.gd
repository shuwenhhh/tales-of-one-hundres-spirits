extends SceneTree

const OUT := "res://assets/chapter2/wisteria/single_hand/"
const SOURCE_CELL := 512
const FRAME_SIZE := 192
const SCALED_CELL := 164
const TOP_PAD := 25
const MOVE_PAD := Vector2i(10, 28)

func _initialize() -> void:
	var cast := Image.load_from_file(ProjectSettings.globalize_path(OUT + "cast_source.png"))
	if cast == null:
		quit(1)
		return
	for frame in 6:
		normalize_frame(cast, frame).save_png(OUT + "cast-%02d.png" % frame)
	normalize_frame(cast, 0).save_png(OUT + "idle.png")
	if FileAccess.file_exists(OUT + "move_source.png"):
		var move := Image.load_from_file(ProjectSettings.globalize_path(OUT + "move_source.png"))
		for frame in 4:
			normalize_frame(move, frame, MOVE_PAD).save_png(OUT + "walk-%02d.png" % frame)
		var jump_sources := [0, 4, 5, 1]
		for frame in 4:
			normalize_frame(move, jump_sources[frame], MOVE_PAD).save_png(OUT + "leap-%02d.png" % frame)
	# Matte contact sheet for review; actual game frames retain binary transparency.
	var preview := Image.create(3 * FRAME_SIZE, 2 * FRAME_SIZE, false, Image.FORMAT_RGBA8)
	preview.fill(Color("453c54"))
	for frame in 6:
		preview.blend_rect(normalize_frame(cast, frame), Rect2i(0, 0, FRAME_SIZE, FRAME_SIZE), Vector2i(frame % 3, frame / 3) * FRAME_SIZE)
	preview.resize(1152, 768, Image.INTERPOLATE_NEAREST)
	DirAccess.make_dir_recursive_absolute("res://art_review/chapter2/single_hand")
	preview.save_png("res://art_review/chapter2/single_hand/poses.png")
	print("Single-hand sprites normalized: shared scale, 192px cells, foot y=182")
	quit()

func normalize_frame(source: Image, frame: int, padding: Vector2i = Vector2i(0, TOP_PAD)) -> Image:
	# One shared scale and anchor for the entire sheet: no per-pose stretching.
	var crop := source.get_region(Rect2i((frame % 3) * SOURCE_CELL, (frame / 3) * SOURCE_CELL, SOURCE_CELL, SOURCE_CELL))
	crop.convert(Image.FORMAT_RGBA8)
	crop.resize(SCALED_CELL, SCALED_CELL, Image.INTERPOLATE_NEAREST)
	for py in crop.get_height():
		for px in crop.get_width():
			var color := crop.get_pixel(px, py)
			color.a = 1.0 if color.a >= 0.55 else 0.0
			crop.set_pixel(px, py, color)
	var result := Image.create(FRAME_SIZE, FRAME_SIZE, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	result.blit_rect(crop, Rect2i(0, 0, SCALED_CELL, SCALED_CELL), padding)
	return result
