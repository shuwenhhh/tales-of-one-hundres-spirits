extends Control

# Shared presentation only: chapter scripts still own story events and branches.
const FONT := preload("res://assets/chapter1/chinese.ttc")
const IVORY := Color("e7dbc3")
var name_label: Label
var body_label: RichTextLabel
var hint_label: Label
var text_progress: float = 0.0
var hold_elapsed: float = 0.0
var clock: float = 0.0
var rate: float = 40.0
var speaker: String = ""
var text: String = ""

func mount(owner_node: Node) -> void:
	# The gameplay roots are Node2D; anchor against a screen-space CanvasLayer.
	var layer := CanvasLayer.new()
	layer.name = "DialogueLayer"
	layer.layer = 20
	owner_node.add_child(layer)
	layer.add_child(self)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = 48
	offset_right = -48
	offset_top = -140
	offset_bottom = -18
	z_index = 30
	name_label = Label.new()
	name_label.position = Vector2(25, -13)
	name_label.add_theme_font_override("font", FONT)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.04, .9))
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(name_label)
	body_label = RichTextLabel.new()
	body_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body_label.offset_left = 27
	body_label.offset_top = 29
	body_label.offset_right = -27
	body_label.offset_bottom = -27
	body_label.scroll_active = false
	body_label.bbcode_enabled = false
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_label.add_theme_font_override("normal_font", FONT)
	body_label.add_theme_font_size_override("normal_font_size", 20)
	body_label.add_theme_color_override("default_color", Color("f2e9d8"))
	add_child(body_label)
	hint_label = Label.new()
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_left = 28
	hint_label.offset_top = -23
	hint_label.offset_right = -45
	hint_label.offset_bottom = -5
	hint_label.add_theme_font_override("font", FONT)
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.add_theme_color_override("font_color", Color(.77, .76, .72, .65))
	add_child(hint_label)
	visible = false

static func split_line(raw: String) -> Dictionary:
	if raw.begins_with("(") or raw.begins_with("（"):
		return {"speaker": "", "text": raw}
	var colon := raw.find(":")
	if colon < 0:
		colon = raw.find("：")
	if colon > 0 and colon < 32:
		return {"speaker": raw.substr(0, colon).strip_edges(), "text": raw.substr(colon + 1).strip_edges()}
	return {"speaker": "", "text": raw}

static func merge_lines(source: Array[String], keep_opening: int = 0) -> Array[String]:
	var result: Array[String] = []
	for i in range(source.size()):
		var current := split_line(source[i])
		if i >= keep_opening and not result.is_empty():
			var previous := split_line(result[-1])
			var chinese: bool = current.speaker in ["小语", "外婆", "桃花妖", "青砚"] or source[i].begins_with("（")
			var limit := 64 if chinese else 160
			if previous.speaker == current.speaker and previous.text.length() + current.text.length() < limit:
				result[-1] += ("" if chinese else " ") + current.text
				continue
		result.append(source[i])
	return result

func show_line(raw: String) -> void:
	var entry := split_line(raw)
	speaker = entry.speaker
	text = entry.text
	var chinese: bool = speaker in ["小语", "外婆", "桃花妖", "青砚"] or raw.begins_with("（")
	name_label.text = speaker if not speaker.is_empty() else ("旁白" if chinese else "Narration")
	var accent := Color("e9c58b")
	if speaker in ["Xiaoyu", "小语"]:
		accent = Color("a8d6e0")
	elif speaker in ["桃花妖", "Hibiscus", "Peach Spirit"]:
		accent = Color("e9adc6")
	elif speaker == "青砚":
		accent = Color("e8b7a6")
	elif speaker.is_empty():
		accent = Color("bcb6be")
	name_label.add_theme_color_override("font_color", accent)
	body_label.add_theme_color_override("default_color", Color("d0c9cf") if speaker.is_empty() else Color("f2e9d8"))
	body_label.text = text
	body_label.visible_characters = 0
	text_progress = 0
	hold_elapsed = 0
	rate = 26.0 if chinese else 40.0
	hint_label.text = "E / 空格 · 继续        按住 Ctrl · 快进" if chinese else "E / Space · Continue        Hold Ctrl · Fast-forward"
	visible = true
	queue_redraw()

func complete() -> bool:
	return body_label.visible_characters < 0 or body_label.visible_characters >= text.length()

func reveal_or_continue() -> bool:
	if complete():
		return true
	body_label.visible_characters = -1
	text_progress = text.length()
	hold_elapsed = 0
	queue_redraw()
	return false

func advance_time(delta: float, fast_forward: bool) -> bool:
	clock += delta
	if not complete():
		text_progress += delta * rate * (12.0 if fast_forward else 1.0)
		body_label.visible_characters = mini(text.length(), int(text_progress))
		hold_elapsed = 0
	elif fast_forward:
		hold_elapsed += delta
		if hold_elapsed >= .22:
			return true
	else:
		hold_elapsed = 0
	queue_redraw()
	return false

func _draw() -> void:
	var w := size.x
	var h := size.y
	var contour := PackedVector2Array([Vector2(0, 15), Vector2(15, 0), Vector2(w, 0), Vector2(w, h - 15), Vector2(w - 15, h), Vector2(0, h)])
	draw_colored_polygon(contour, Color(.025, .025, .045, .82))
	var title_width := 150.0
	if is_instance_valid(name_label):
		title_width = maxf(95.0, FONT.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 52)
	draw_rect(Rect2(14, -15, title_width - 19, 30), Color(.025, .025, .045, .84))
	var border := Color(IVORY, .85)
	draw_polyline(PackedVector2Array([Vector2(0, 42), Vector2(0, 15), Vector2(15, 0), Vector2(20, 0)]), border, 1)
	draw_line(Vector2(title_width, 0), Vector2(minf(title_width + 104, w - 20), 0), Color(IVORY, .55), 1)
	draw_polyline(PackedVector2Array([Vector2(w, h - 42), Vector2(w, h - 15), Vector2(w - 15, h), Vector2(w - 128, h)]), border, 1)
	draw_polyline(PackedVector2Array([Vector2(w - 4, h - 43), Vector2(w - 4, h - 17), Vector2(w - 17, h - 4), Vector2(w - 130, h - 4)]), Color(IVORY, .45), 1)
	if is_instance_valid(body_label) and complete():
		var center := Vector2(w - 25, h - 18)
		var alpha := .65 + .25 * sin(clock * 3)
		draw_colored_polygon(PackedVector2Array([center + Vector2(-3, -3), center + Vector2(3, -3), center + Vector2(0, 2)]), Color(IVORY, alpha))
