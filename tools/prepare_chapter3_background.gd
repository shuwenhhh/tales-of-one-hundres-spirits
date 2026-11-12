extends SceneTree

const SOURCE := "res://assets/chapter3/backgrounds/moon_bamboo_wedding_source_v1.png"
const OUTPUT := "res://assets/chapter3/backgrounds/moon_bamboo_wedding_pixel_v1.png"

func _initialize() -> void:
	var image := Image.load_from_file(SOURCE)
	if image.is_empty():
		push_error("Could not read chapter-three bamboo background")
		quit(1)
		return
	image.resize(960, 540, Image.INTERPOLATE_NEAREST)
	var err := image.save_png(OUTPUT)
	if err != OK:
		push_error("Could not save chapter-three bamboo background: %s" % err)
		quit(1)
		return
	print("Chapter-three bamboo background prepared at 960x540")
	quit(0)
