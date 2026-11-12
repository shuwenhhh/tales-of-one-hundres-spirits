extends SceneTree

func _initialize():
	for kind in ["ascent","landing"]:
		var src = Image.load_from_file("res://assets/chapter1/boss_flight/%s-source.png" % kind)
		for i in 6:
			var split: int = 512 if kind == "ascent" else 560
			var row: int = i / 3
			var cell = Rect2i((i%3)*512, 0 if row == 0 else split, 512, split if row == 0 else 1024-split)
			if row == 1:
				# Generated rows are not exact grids: retain extended sleeves and hems.
				var edges: Array = [0,560,1040,1536] if kind == "ascent" else [0,560,1080,1536]
				cell.position.x = edges[i%3]
				cell.size.x = edges[i%3+1]-edges[i%3]
			var piece = src.get_region(cell)
			# Discard the generated translucent halo when normalizing sprite alpha.
			for py in piece.get_height():
				for px in piece.get_width():
					var color = piece.get_pixel(px,py)
					if color.a < 0.95: piece.set_pixel(px,py,Color.TRANSPARENT)
			var first := Vector2i(-1,-1)
			for y in piece.get_height():
				for x in piece.get_width():
					var c = piece.get_pixel(x,y)
					if c.a > 0.9 and c.r > 0.65 and c.g > 0.45 and c.r > c.b*1.1:
						first = Vector2i(x,y)
						break
				if first.x >= 0: break
			assert(first.x >= 0)
			var face_x := 0.0
			var count := 0
			for y in range(first.y,mini(first.y+55,piece.get_height())):
				for x in range(maxi(0,first.x-65),mini(piece.get_width(),first.x+65)):
					var c = piece.get_pixel(x,y)
					if c.a > 0.9 and c.r > 0.65 and c.g > 0.45 and c.r > c.b*1.1:
						face_x += x
						count += 1
			face_x /= maxf(count,1)
			var bounds = piece.get_used_rect()
			var cropped = piece.get_region(bounds)
			var scale := 0.29
			cropped.resize(roundi(cropped.get_width()*scale),roundi(cropped.get_height()*scale),Image.INTERPOLATE_LANCZOS)
			var canvas = Image.create(256,300,false,Image.FORMAT_RGBA8)
			var face_height: float = ([67,88,94,96,94,90] if kind == "ascent" else [90,82,63,39,60,88])[i]
			var x = roundi(128 - (face_x + 18 - bounds.position.x)*scale)
			var y = roundi(240-face_height-(first.y+27-bounds.position.y)*scale)
			# Grounded poses share the same contact baseline.
			if (kind == "ascent" and i < 2) or (kind == "landing" and i >= 3):
				y = 240-cropped.get_height()
			assert(x>=0 and y>=0 and x+cropped.get_width()<=256 and y+cropped.get_height()<=300)
			canvas.blit_rect(cropped,Rect2i(Vector2i.ZERO,cropped.get_size()),Vector2i(x,y))
			canvas.save_png("res://assets/chapter1/boss_flight/%s_%d.png" % [kind,i])
			print(kind," ",i," crop=",bounds," anchor=",Vector2(x,y))
	quit()
