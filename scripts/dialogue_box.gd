extends Control

# Shared presentation only: chapter scripts still own story events and branches.
const FONT := preload("res://assets/chapter1/chinese.ttc")
const IVORY := Color("e7dbc3")
var name_label: Label
var body_label: RichTextLabel
var body_font: SystemFont
var speaker_font: SystemFont
var background_wash: GradientTexture2D
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
	anchor_left = .15
	anchor_right = .85
	offset_left = 0
	offset_right = 0
	offset_top = -114
	offset_bottom = -22
	z_index = 30
	body_font = SystemFont.new()
	body_font.font_names = PackedStringArray(["Georgia", "Noto Serif", "Liberation Serif", "Times New Roman", "serif"])
	body_font.fallbacks = [FONT]
	speaker_font = SystemFont.new()
	speaker_font.font_names = body_font.font_names
	speaker_font.font_weight = 700
	speaker_font.fallbacks = [FONT]
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, .35, .75, 1.0])
	gradient.colors = PackedColorArray([Color(.025, .025, .04, .18), Color(.025, .025, .04, .50), Color(.025, .025, .04, .50), Color(.025, .025, .04, .18)])
	background_wash = GradientTexture2D.new()
	background_wash.gradient = gradient
	background_wash.width = 8
	background_wash.height = 256
	background_wash.fill_from = Vector2(.5, 0)
	background_wash.fill_to = Vector2(.5, 1)
	name_label = Label.new()
	name_label.position = Vector2(-2, -36)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_override("font", speaker_font)
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.04, .9))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(name_label)
	body_label = RichTextLabel.new()
	body_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body_label.offset_left = 26
	body_label.offset_top = 16
	body_label.offset_right = -32
	body_label.offset_bottom = -18
	body_label.scroll_active = false
	body_label.bbcode_enabled = false
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_label.add_theme_font_override("normal_font", body_font)
	body_label.add_theme_font_size_override("normal_font_size", 20)
	body_label.add_theme_constant_override("line_separation", 5)
	body_label.add_theme_color_override("default_color", Color("f2e9d8"))
	body_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.04, .95))
	body_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(body_label)
	body_label.resized.connect(_fit_height)
	visible = false

func _fit_height() -> void:
	# Keep short exchanges light; grow upward for longer translated lines.
	var height := clampf(body_label.get_content_height() + 36.0, 92.0, 160.0)
	if not is_equal_approx(offset_top, offset_bottom - height):
		offset_top = offset_bottom - height
	queue_redraw()

static func split_line(raw: String) -> Dictionary:
	if raw.begins_with("(") or raw.begins_with("（"):
		return {"speaker": "", "text": raw}
	var colon := raw.find(":")
	if colon < 0:
		colon = raw.find("：")
	if colon > 0 and colon < 32:
		return {"speaker": raw.substr(0, colon).strip_edges(), "text": raw.substr(colon + 1).strip_edges()}
	return {"speaker": "", "text": raw}

static func merge_lines(source: Array[String], keep_opening: int = 0, story_breaks: PackedStringArray = PackedStringArray()) -> Array[String]:
	var result: Array[String] = []
	for i in range(source.size()):
		var current := split_line(source[i])
		if i >= keep_opening and not result.is_empty():
			var previous := split_line(result[-1])
			var separate: bool = false
			for phrase in story_breaks:
				if current.text.begins_with(phrase) or previous.text.begins_with(phrase):
					separate = true
					break
			var chinese: bool = current.speaker in ["小语", "外婆", "桃花妖", "青砚"] or source[i].begins_with("（")
			var limit := 64 if chinese else 160
			if not separate and previous.speaker == current.speaker and previous.text.length() + current.text.length() < limit:
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
	var accent := Color("e8d2aa")
	if speaker in ["Xiaoyu", "小语"]:
		accent = Color("c2d9db")
	elif speaker in ["桃花妖", "Hibiscus", "Peach Spirit"]:
		accent = Color("e6cad5")
	elif speaker in ["青砚", "Qingyan"]:
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
	visible = true
	_fit_height.call_deferred()
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
	# A translucent ink wash leaves the scenery visible beneath the dialogue.
	draw_texture_rect(background_wash, Rect2(Vector2.ZERO, size), false)
	var border := Color(IVORY, .90)
	var soft := Color(IVORY, .48)
	# Open double-line corners, rather than a closed rectangular frame.
	draw_polyline(PackedVector2Array([Vector2(0, 48), Vector2(0, 6), Vector2(6, 0), Vector2(145, 0)]), border, 1, true)
	draw_polyline(PackedVector2Array([Vector2(4, 41), Vector2(4, 8), Vector2(8, 4), Vector2(135, 4)]), soft, 1, true)
	draw_polyline(PackedVector2Array([Vector2(w, h - 38), Vector2(w, h - 7), Vector2(w - 7, h), Vector2(w - 145, h)]), border, 1, true)
	draw_polyline(PackedVector2Array([Vector2(w - 4, h - 44), Vector2(w - 4, h - 9), Vector2(w - 9, h - 4), Vector2(w - 135, h - 4)]), soft, 1, true)
	for corner in [Vector2(153, 0), Vector2(w - 153, h)]:
		draw_circle(corner, 1.4, soft)
	if is_instance_valid(body_label) and complete():
		var center := Vector2(w - 25, h - 18)
		var alpha := .65 + .25 * sin(clock * 3)
		draw_colored_polygon(PackedVector2Array([center + Vector2(-3, -3), center + Vector2(3, -3), center + Vector2(0, 2)]), Color(IVORY, alpha))
