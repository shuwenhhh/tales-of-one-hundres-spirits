extends SceneTree

# Normalize the generated transparent family atlas without resampling its linework.
# The first two figures have staggered outlines rather than perfectly equal cells.
func _initialize() -> void:
	var source := Image.load_from_file("res://assets/ui/memories/cast_source.png")
	if source == null or source.is_empty():
		quit(1)
		return
	print("Scroll atlas: ", source.get_size())
	print("Format / alpha / corner: ", source.get_format(), " / ", source.detect_alpha(), " / ", source.get_pixel(0, 0))
	source.convert(Image.FORMAT_RGBA8)
	# Discard nearly invisible atlas specks before finding the content bounds.
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			if source.get_pixel(x, y).a < .15:
				source.set_pixel(x, y, Color(0, 0, 0, 0))
	var w := source.get_width()
	var h := source.get_height()
	var edges := [0, 278, 687, 1098, 1394, w]
	var names := ["umbrella", "grandmother", "peach", "qingyan", "faceless"]
	for index in range(5):
		var left: int = edges[index]
		var right: int = edges[index + 1]
		if index == 0:
			right = 375
		var image := source.get_region(Rect2i(left, 0, right - left, h))
		if index <= 1:
			for y in range(h):
				var seam := int(lerpf(370, 278, clampf((y - 570.0) / 130.0, 0, 1)))
				if index == 0:
					image.fill_rect(Rect2i(seam, y, image.get_width() - seam, 1), Color(0, 0, 0, 0))
				elif seam > left:
					image.fill_rect(Rect2i(0, y, seam - left, 1), Color(0, 0, 0, 0))
		image = image.get_region(image.get_used_rect())
		var result := image.save_png("res://assets/ui/memories/%s.png" % names[index])
		if result != OK:
			quit(1)
			return
		print(names[index], ": ", image.get_size())
	quit(0)
