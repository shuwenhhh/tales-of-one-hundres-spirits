extends SceneTree

const SOURCE := "res://assets/chapter3/concepts/qingyan_purple_breath_sheet_v1.png"
const OUTPUT := "res://assets/chapter3/pixel/"

func _initialize() -> void:
	var source := Image.new()
	if source.load(SOURCE) != OK or source.get_size() != Vector2i(1536, 1024):
		push_error("Missing or unexpected Qingyan breath sheet")
		quit(1)
		return
	for i in 6:
		var frame := source.get_region(Rect2i((i % 3) * 512 + 60, (i / 3) * 512 + 50, 340, 440))
		frame.convert(Image.FORMAT_RGBA8)
		for y in frame.get_height():
			for x in frame.get_width():
				var c := frame.get_pixel(x, y)
				if c.a < 0.2 or c.b > c.r * 1.01 and c.b > c.g * 1.05 and c.b > 0.25:
					frame.set_pixel(x, y, Color.TRANSPARENT)
		frame.resize(128, 176, Image.INTERPOLATE_NEAREST)
		var bounds := frame.get_used_rect()
		var foot_offset := frame.get_height() - bounds.end.y
		var aligned := Image.create(128, 176, false, Image.FORMAT_RGBA8)
		aligned.fill(Color.TRANSPARENT)
		aligned.blit_rect(frame, bounds, bounds.position + Vector2i(0, foot_offset))
		frame = aligned
		print("Breath frame %d: feet moved down %d pixels" % [i, foot_offset])
		if frame.save_png(OUTPUT + "qingyan_breath_%d.png" % i) != OK:
			push_error("Could not save Qingyan breath frame %d" % i)
			quit(1)
			return
	var orb := source.get_region(Rect2i(835, 120, 112, 75))
	orb.resize(30, 20, Image.INTERPOLATE_NEAREST)
	if orb.save_png(OUTPUT + "foxfire_purple_flight.png") != OK:
		push_error("Could not save purple foxfire")
		quit(1)
		return
	print("Prepared 6 breath frames and purple foxfire")
	quit(0)
