extends SceneTree

const FOXFIRE_SOURCE := "res://assets/chapter3/concepts/foxfire_style_b_ember.png"
const QINGYAN_SOURCE := "res://assets/chapter3/concepts/qingyan_masked_v1.png"
const ACTION_SOURCE := "res://assets/chapter3/concepts/qingyan_action_strip_v1.png"
const OUTPUT := "res://assets/chapter3/pixel"

func _initialize() -> void:
	var out_dir := ProjectSettings.globalize_path(OUTPUT)
	var err := DirAccess.make_dir_recursive_absolute(out_dir)
	if err != OK:
		push_error("Could not create chapter 3 pixel directory: %s" % err)
		quit(1)
		return
	var fire := Image.load_from_file(FOXFIRE_SOURCE)
	if fire.is_empty():
		push_error("Could not read foxfire concept")
		quit(1)
		return
	fire.convert(Image.FORMAT_RGBA8)
	var half := fire.get_width() / 2
	var idle := _trim_alpha(fire.get_region(Rect2i(0, 0, half, fire.get_height())))
	var charge := _trim_alpha(fire.get_region(Rect2i(half, 0, fire.get_width() - half, fire.get_height())))
	if idle.is_empty() or charge.is_empty():
		push_error("Could not isolate both foxfire states")
		quit(1)
		return
	_save_flame(idle, "foxfire_b_idle.png")
	_save_flame(charge, "foxfire_b_charge.png")
	var boss := _trim_alpha(Image.load_from_file(QINGYAN_SOURCE))
	if boss.is_empty():
		push_error("Could not read Qingyan concept")
		quit(1)
		return
	var boss_width := maxi(1, roundi(168.0 * boss.get_width() / float(boss.get_height())))
	boss.resize(boss_width, 168, Image.INTERPOLATE_NEAREST)
	boss.save_png(OUTPUT + "/qingyan_idle.png")
	var strip := Image.load_from_file(ACTION_SOURCE)
	if strip.is_empty():
		push_error("Could not read Qingyan action strip")
		quit(1)
		return
	var names := ["walk_0", "walk_1", "walk_2", "jump", "cast"]
	var cell_width := strip.get_width() / 5
	for i in 5:
		var frame := _trim_alpha(strip.get_region(Rect2i(i * cell_width, 0, cell_width, strip.get_height())))
		if frame.is_empty():
			push_error("Empty Qingyan action frame %d" % i)
			quit(1)
			return
		var height := 168 if i != 3 else 150
		var width := maxi(1, roundi(float(height) * frame.get_width() / float(frame.get_height())))
		frame.resize(width, height, Image.INTERPOLATE_NEAREST)
		var canvas := Image.create_empty(110, 176, false, Image.FORMAT_RGBA8)
		canvas.fill(Color.TRANSPARENT)
		canvas.blit_rect(frame, Rect2i(0, 0, width, height), Vector2i((110 - width) / 2, 176 - height))
		canvas.save_png(OUTPUT + "/qingyan_%s.png" % names[i])
	print("Chapter 3 pixel art prepared: B foxfire 18x18 canvas, Qingyan %dx168" % boss_width)
	quit(0)

func _trim_alpha(source: Image) -> Image:
	if source.is_empty():
		return source
	source.convert(Image.FORMAT_RGBA8)
	for py in source.get_height():
		for px in source.get_width():
			var color := source.get_pixel(px, py)
			if color.a < 0.5:
				source.set_pixel(px, py, Color.TRANSPARENT)
			else:
				color.a = 1.0
				source.set_pixel(px, py, color)
	var used := source.get_used_rect()
	if used.size == Vector2i.ZERO:
		return Image.new()
	return source.get_region(used)

func _save_flame(source: Image, filename: String) -> void:
	var span := maxf(source.get_width(), source.get_height())
	var width := maxi(1, roundi(source.get_width() * 14.0 / span))
	var height := maxi(1, roundi(source.get_height() * 14.0 / span))
	source.resize(width, height, Image.INTERPOLATE_NEAREST)
	var palette: Array[Color] = [Color("7c2426"), Color("d94132"), Color("ee5835"), Color("ff8a42"), Color("ffd073"), Color("fff2cf")]
	for py in height:
		for px in width:
			var color := source.get_pixel(px, py)
			if color.a < 0.5:
				source.set_pixel(px, py, Color.TRANSPARENT)
				continue
			var best := palette[0]
			var distance := INF
			for candidate in palette:
				var dr := color.r - candidate.r
				var dg := color.g - candidate.g
				var db := color.b - candidate.b
				var score := dr * dr + dg * dg + db * db
				if score < distance:
					distance = score
					best = candidate
			source.set_pixel(px, py, best)
	var canvas := Image.create_empty(18, 18, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	var origin := Vector2i((18 - width) / 2, (18 - height) / 2)
	canvas.blit_rect(source, Rect2i(Vector2i.ZERO, Vector2i(width, height)), origin)
	canvas.save_png(OUTPUT + "/" + filename)
