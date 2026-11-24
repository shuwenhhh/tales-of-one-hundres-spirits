extends SceneTree

const SOURCE := "res://assets/chapter2/concepts/vine_whip/vector/"
const FILES := [
	"01_small_steps",
	"02_long_whip",
	"03_air_whip",
	"04_corner_vault",
	"05_blossom_rain",
]

func _initialize() -> void:
	for name in FILES:
		var image := Image.load_from_file(SOURCE + name + ".svg")
		if image.is_empty():
			push_error("Could not render SVG: " + name)
			quit(1)
			return
		var error := image.save_png(ProjectSettings.globalize_path(SOURCE + name + "_preview.png"))
		if error != OK:
			push_error("Could not save preview: " + name)
			quit(1)
			return
	print("Chapter 2 vector previews rendered")
	quit()
