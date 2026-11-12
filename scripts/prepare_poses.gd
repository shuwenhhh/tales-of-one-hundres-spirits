extends SceneTree

func _initialize():
	var img = Image.load_from_file("res://assets/chapter1/grandmother_poses.png")
	var w = img.get_width()
	var h = img.get_height()
	var seen = PackedByteArray()
	seen.resize(w * h)
	var groups: Array = []
	for y in h:
		for x in w:
			var start = y * w + x
			if seen[start] or img.get_pixel(x, y).a < 0.3:
				continue
			var pixels = PackedInt32Array([start])
			seen[start] = 1
			var head = 0
			var bounds = Rect2i(x, y, 1, 1)
			while head < pixels.size():
				var p = pixels[head]
				head += 1
				var px = p % w
				var py = p / w
				bounds = bounds.expand(Vector2i(px, py))
				for n in [Vector2i(px - 1, py), Vector2i(px + 1, py), Vector2i(px, py - 1), Vector2i(px, py + 1)]:
					if n.x < 0 or n.x >= w or n.y < 0 or n.y >= h:
						continue
					var index = n.y * w + n.x
					if seen[index] == 0 and img.get_pixelv(n).a >= 0.3:
						seen[index] = 1
						pixels.append(index)
			if pixels.size() > 1000:
				groups.append({"pixels": pixels, "bounds": bounds})
	groups.sort_custom(func(a, b): return a.pixels.size() > b.pixels.size())
	if groups.size() < 4:
		push_error("Expected four separate poses")
		quit(1)
		return
	groups = groups.slice(0, 4)
	groups.sort_custom(func(a, b): return a.bounds.position.x < b.bounds.position.x)
	var max_height = 1
	for g in groups:
		max_height = maxi(max_height, g.bounds.size.y)
	var scale_factor = 140.0 / max_height
	for i in 4:
		var g = groups[i]
		var rect: Rect2i = g.bounds
		var piece = Image.create(rect.size.x + 1, rect.size.y + 1, false, Image.FORMAT_RGBA8)
		var sum_x = 0.0
		var count = 0
		for p in g.pixels:
			var pt = Vector2i(p % w, p / w)
			piece.set_pixelv(pt - rect.position, img.get_pixelv(pt))
			if pt.y > rect.end.y - rect.size.y * 0.08:
				sum_x += pt.x - rect.position.x
				count += 1
		var foot_x = sum_x / maxf(count, 1)
		piece.resize(maxi(1, roundi(piece.get_width() * scale_factor)), maxi(1, roundi(piece.get_height() * scale_factor)), Image.INTERPOLATE_NEAREST)
		var canvas = Image.create(180, 160, false, Image.FORMAT_RGBA8)
		canvas.blit_rect(piece, Rect2i(Vector2i.ZERO, piece.get_size()), Vector2i(roundi(90 - foot_x * scale_factor), 158 - piece.get_height()))
		canvas.save_png("res://assets/chapter1/boss_pose_%d.png" % i)
		print("POSE ", i, " bounds ", rect)
	quit()
