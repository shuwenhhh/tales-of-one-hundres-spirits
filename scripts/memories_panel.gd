extends Control

signal close_requested
signal selection_changed(scene: String)

const JOURNEY := preload("res://scripts/journey_state.gd")
const FRIENDS := preload("res://scripts/friend_stories.gd")
const PAPER := preload("res://assets/ui/memories/parchment.png")
const PORTRAITS := [preload("res://assets/ui/memories/umbrella.png"), preload("res://assets/ui/memories/grandmother.png"), preload("res://assets/ui/memories/peach.png"), preload("res://assets/ui/memories/qingyan.png"), preload("res://assets/ui/memories/faceless.png")]
const INK := Color("302d2e")
const VERMILION := Color("a74d36")
const SCROLL_RECT := Rect2(38, 117, 884, 306)
const UNROLL_SECONDS := 1.8
const SILHOUETTE := "shader_type canvas_item; uniform bool revealed = false; void fragment() { vec4 tex = texture(TEXTURE, UV); COLOR = revealed ? tex : vec4(vec3(0.20, 0.21, 0.23), tex.a); }"

var initial_selection: String = ""
var cards: Array[Control] = []
var portraits: Array[TextureRect] = []
var portrait_rects: Array[Rect2] = []
var plaques: Array[Control] = []
var story_visible := false
var selected_index := 0
var opened := false
var closing := false
var open_amount: float = 0.0:
	set(value):
		open_amount = clampf(value, 0.0, 1.0)
		if is_instance_valid(reveal):
			_update_reveal()
var opening_tween: Tween
var stage: Control
var reveal: Control
var painting: Control
var story_surface: TextureRect
var rollers: Control
var details: Control
var name_label: Label
var description: RichTextLabel
var back_button: Button
var close_button: Button
var completed: Array[String] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	completed = JOURNEY.completed_chapters()
	var book_font := SystemFont.new()
	book_font.font_names = PackedStringArray(["Palatino Linotype", "Book Antiqua", "Baskerville", "Georgia", "Times New Roman"])
	var book_theme := Theme.new()
	book_theme.default_font = book_font
	book_theme.default_font_size = 17
	theme = book_theme
	stage = Control.new()
	stage.size = Vector2(960, 540)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	reveal = Control.new()
	reveal.clip_contents = true
	reveal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(reveal)
	painting = Control.new()
	painting.size = SCROLL_RECT.size
	painting.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal.add_child(painting)
	var texture := TextureRect.new()
	texture.texture = PAPER
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.size = SCROLL_RECT.size
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painting.add_child(texture)
	# A quiet inner paper surface keeps story text legible on the existing scroll.
	story_surface = TextureRect.new()
	var quiet_paper := AtlasTexture.new()
	quiet_paper.atlas = PAPER
	quiet_paper.region = Rect2(PAPER.get_width() * .43, PAPER.get_height() * .38, PAPER.get_width() * .17, PAPER.get_height() * .2)
	story_surface.texture = quiet_paper
	story_surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	story_surface.position = Vector2(0, 7)
	story_surface.size = Vector2(SCROLL_RECT.size.x, SCROLL_RECT.size.y - 14)
	story_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painting.add_child(story_surface)
	story_surface.hide()
	for index in range(FRIENDS.ENTRIES.size()):
		_build_spirit(index)
	rollers = Control.new()
	rollers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rollers.draw.connect(_draw_rollers)
	stage.add_child(rollers)
	_build_details()
	close_button = _button(painting, "×", Rect2(845, 10, 26, 26), close_scroll)
	close_button.add_theme_font_size_override("font_size", 23)
	close_button.tooltip_text = "Close scroll"
	close_button.grab_focus()
	for index in range(FRIENDS.ENTRIES.size()):
		if FRIENDS.ENTRIES[index].scene == initial_selection:
			selected_index = index
			break
	_focus_spirit(selected_index)
	resized.connect(_fit_stage)
	_fit_stage()
	_update_reveal()
	opening_tween = create_tween()
	opening_tween.tween_property(self, "open_amount", 1.0, UNROLL_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	opening_tween.tween_callback(_finish_opening)

func _fit_stage() -> void:
	var factor := minf(size.x / 960.0, size.y / 540.0)
	stage.scale = Vector2.ONE * factor
	stage.position = (size - Vector2(960, 540) * factor) / 2

func _slot_x(index: int) -> float:
	return 95.0 + index * 174.0

func _build_spirit(index: int) -> void:
	var entry: Dictionary = FRIENDS.ENTRIES[index]
	var cleared: bool = entry.scene in completed
	var portrait := TextureRect.new()
	portrait.texture = PORTRAITS[index]
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var target_height: float = [190, 184, 246, 250, 172][index]
	var factor := minf(155.0 / portrait.texture.get_width(), target_height / portrait.texture.get_height())
	portrait.size = portrait.texture.get_size() * factor
	portrait.position = Vector2(_slot_x(index) - portrait.size.x / 2, 270 - portrait.size.y)
	var shader := Shader.new()
	shader.code = SILHOUETTE
	var material_resource := ShaderMaterial.new()
	material_resource.shader = shader
	material_resource.set_shader_parameter("revealed", cleared)
	portrait.material = material_resource
	painting.add_child(portrait)
	portraits.append(portrait)
	portrait_rects.append(Rect2(portrait.position, portrait.size))
	var plaque := Panel.new()
	plaque.position = Vector2(index * 174 + 12, 47)
	plaque.size = Vector2(19, 100)
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plaque_style := StyleBoxFlat.new()
	plaque_style.bg_color = Color("b45d42") if cleared else Color("ceb98e")
	plaque_style.border_color = INK
	plaque_style.set_border_width_all(1)
	plaque.add_theme_stylebox_override("panel", plaque_style)
	painting.add_child(plaque)
	plaques.append(plaque)
	var short_name: String = ["UMBRELLA", "GRANDMA", "PEACH", "QINGYAN", "FACELESS"][index] if cleared else "???"
	var vertical_name := ""
	for character in short_name:
		vertical_name += character + "\n"
	var name := _label(plaque, vertical_name.strip_edges(), Rect2(0, 3, 19, 94), 9, INK)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name.add_theme_constant_override("line_spacing", -2)
	var button := Button.new()
	button.position = Vector2(index * 174 + 12, 10)
	button.size = Vector2(170, 278)
	button.disabled = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("scene", entry.scene)
	button.set_meta("completed", cleared)
	button.set_meta("known", JOURNEY.has_met(entry.scene))
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.pressed.connect(show_story.bind(index))
	button.focus_entered.connect(_focus_spirit.bind(index))
	painting.add_child(button)
	cards.append(button)

func _build_details() -> void:
	details = Control.new()
	details.size = SCROLL_RECT.size
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painting.add_child(details)
	# Text is printed directly on the same scroll, with no separate description box.
	name_label = _label(details, "", Rect2(283, 26, 545, 35), 25, INK)
	description = RichTextLabel.new()
	description.position = Vector2(283, 70)
	description.size = Vector2(545, 192)
	description.bbcode_enabled = false
	description.scroll_active = true
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("normal_font_size", 17)
	description.add_theme_constant_override("line_separation", 3)
	description.add_theme_color_override("default_color", INK)
	details.add_child(description)
	back_button = _button(details, "← Back", Rect2(740, 267, 88, 26), show_parade)
	details.hide()

func _focus_spirit(index: int) -> void:
	if closing:
		return
	selected_index = index
	selection_changed.emit(FRIENDS.ENTRIES[index].scene)

func show_story(index: int) -> void:
	if not opened or closing:
		return
	_focus_spirit(index)
	story_visible = true
	story_surface.show()
	var entry: Dictionary = FRIENDS.ENTRIES[index]
	var cleared: bool = entry.scene in completed
	name_label.text = entry.name if cleared else "Unknown Spirit"
	description.text = entry.story if cleared else "This spirit's story is still hidden. Complete its chapter to reveal its portrait and hear its story."
	description.scroll_to_line(0)
	for i in range(portraits.size()):
		portraits[i].visible = i == index
		cards[i].hide()
		plaques[i].hide()
	var portrait := portraits[index]
	var factor := minf(207.0 / portrait.texture.get_width(), 246.0 / portrait.texture.get_height())
	portrait.size = portrait.texture.get_size() * factor
	portrait.position = Vector2(145 - portrait.size.x / 2, 278 - portrait.size.y)
	details.show()
	back_button.grab_focus()

func show_parade() -> void:
	if closing:
		return
	story_visible = false
	story_surface.hide()
	details.hide()
	for i in range(portraits.size()):
		portraits[i].show()
		portraits[i].position = portrait_rects[i].position
		portraits[i].size = portrait_rects[i].size
		cards[i].show()
		plaques[i].show()
	if opened:
		cards[selected_index].grab_focus()

func _finish_opening() -> void:
	opened = true
	for card: Button in cards:
		card.disabled = false
		card.focus_mode = Control.FOCUS_ALL
	for index in range(cards.size()):
		cards[index].focus_neighbor_left = cards[index].get_path_to(cards[(index - 1 + cards.size()) % cards.size()])
		cards[index].focus_neighbor_right = cards[index].get_path_to(cards[(index + 1) % cards.size()])
	var focused := get_viewport().gui_get_focus_owner()
	if focused == close_button or focused == null:
		cards[selected_index].grab_focus()

func close_scroll() -> void:
	if closing:
		return
	closing = true
	opened = false
	close_button.disabled = true
	for card: Button in cards:
		card.disabled = true
		card.focus_mode = Control.FOCUS_NONE
	back_button.disabled = true
	if opening_tween and opening_tween.is_running():
		opening_tween.kill()
	opening_tween = create_tween()
	opening_tween.tween_property(self, "open_amount", 0.0, maxf(.3, open_amount * .75)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	opening_tween.tween_callback(func() -> void: close_requested.emit())

func _update_reveal() -> void:
	var width := SCROLL_RECT.size.x * open_amount
	reveal.position = Vector2(480 - width / 2, SCROLL_RECT.position.y)
	reveal.size = Vector2(width, SCROLL_RECT.size.y)
	painting.position = Vector2(SCROLL_RECT.position.x - reveal.position.x, 0)
	if is_instance_valid(rollers):
		rollers.queue_redraw()

func _draw_rollers() -> void:
	var half_width := SCROLL_RECT.size.x * open_amount / 2
	var top := SCROLL_RECT.position.y
	for x in [480 - half_width, 480 + half_width]:
		rollers.draw_style_box(_wood_style(), Rect2(x - 11, top - 8, 22, 322))
		rollers.draw_rect(Rect2(x - 11, top + 29, 22, 248), Color("273747"))
		for y in range(int(top + 41), int(top + 274), 25):
			rollers.draw_arc(Vector2(x, y), 6, .1, PI, 12, Color("a99563"), .8, true)
		for y in [top - 11, top + 9, top + 291, top + 311]:
			rollers.draw_style_box(_cap_style(), Rect2(x - 13, y, 26, 10))
		rollers.draw_line(Vector2(x - 6, top + 22), Vector2(x - 6, top + 289), Color(1, .9, .6, .14), 2, true)

func _wood_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("5b4030")
	style.border_color = Color("2c2728")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, .3)
	style.shadow_size = 4
	return style

func _cap_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("b29358")
	style.border_color = Color("57402e")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style

func _label(parent: Node, text: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, rect: Rect2, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", VERMILION)
	button.add_theme_color_override("font_focus_color", VERMILION)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.pressed.connect(action)
	parent.add_child(button)
	return button
