extends Control

const FONT := preload("res://assets/chapter1/chinese.ttc")
const OPEN_ART := preload("res://assets/ui/silk_umbrella_open.png")
const CLOSED_ART := preload("res://assets/chapter1/girl_handdrawn/umbrella.png")
const IVORY := Color("e7dbc3")
var opened: bool = false
var item_button: Button
var item_art: TextureRect
var title: Label
var description: Label
var quote: Label
var use_label: Label
var rules: Label
var close_button: Button

func mount(owner_node: Node) -> void:
	var layer := CanvasLayer.new()
	layer.name = "InventoryLayer"
	layer.layer = 60
	owner_node.add_child(layer)
	layer.add_child(self)
	if not InputMap.has_action(&"open_inventory"):
		InputMap.add_action(&"open_inventory")
		var key := InputEventKey.new()
		key.physical_keycode = KEY_B
		InputMap.action_add_event(&"open_inventory", key)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Noto Serif CJK SC", "SimSun", "Songti SC", "Georgia", "serif"])
	serif.fallbacks = [FONT]
	var styling := Theme.new()
	styling.default_font = serif
	styling.default_font_size = 17
	styling.set_color("font_color", "Label", IVORY)
	theme = styling
	var header := Label.new()
	header.text = "随身之物"
	header.add_theme_font_size_override("font_size", 26)
	add_child(header)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.anchor_left = .085
	header.offset_top = 48
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 68)
	add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.anchor_left = .17
	content.anchor_right = .88
	content.anchor_top = .21
	content.anchor_bottom = .82
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = .85
	content.add_child(left)
	item_button = Button.new()
	item_button.custom_minimum_size = Vector2(180, 220)
	item_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for style_name in ["normal", "hover", "pressed", "focus"]:
		item_button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	left.add_child(item_button)
	item_art = TextureRect.new()
	item_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_button.add_child(item_art)
	item_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	item_art.offset_left = 20
	item_art.offset_right = -20
	item_art.offset_top = 10
	item_art.offset_bottom = -10
	var equipped := Label.new()
	equipped.text = "已装备"
	equipped.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equipped.modulate = Color(.75, .74, .77)
	left.add_child(equipped)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	content.add_child(right)
	title = _label(right, "", 28)
	description = _label(right, "", 17)
	quote = _label(right, "", 18)
	quote.size_flags_vertical = Control.SIZE_EXPAND_FILL
	use_label = _label(right, "", 23)
	use_label.modulate = Color("e6c895")
	rules = _label(right, "", 17)
	close_button = Button.new()
	close_button.text = "B / Esc · 关闭"
	close_button.add_theme_font_size_override("font_size", 15)
	close_button.add_theme_color_override("font_color", IVORY)
	for style_name in ["normal", "hover", "pressed", "focus"]:
		close_button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	add_child(close_button)
	close_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	close_button.offset_left = -200
	close_button.offset_right = -45
	close_button.offset_top = -58
	close_button.offset_bottom = -25
	close_button.pressed.connect(close)
	item_button.focus_neighbor_bottom = item_button.get_path_to(close_button)
	close_button.focus_neighbor_top = close_button.get_path_to(item_button)
	item_button.focus_next = item_button.get_path_to(close_button)
	close_button.focus_next = close_button.get_path_to(item_button)
	resized.connect(queue_redraw)
	visible = false

func _label(parent: Control, value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func present(unlocked: bool) -> void:
	item_art.texture = OPEN_ART if unlocked else CLOSED_ART
	title.text = "婆婆送的伞" if unlocked else "随身的伞"
	description.text = "婆婆亲手缝上的蚕丝衬里。" if unlocked else "陪小语走进雨夜的一把旧伞。"
	quote.text = "“这一带一直不算安全，\n拿着这个。”" if unlocked else "伞面有些磨薄了。"
	use_label.text = "K · 撑伞" if unlocked else "J · 挥伞"
	rules.text = "防御正面攻击\n反弹迎面弹幕\n\n仅短暂生效，收伞后稍歇再用。\n背后仍会受到伤害" if unlocked else "挥动雨伞进行攻击。"
	opened = true
	show()
	item_button.grab_focus()
	queue_redraw()

func close() -> void:
	opened = false
	hide()

func _input(event: InputEvent) -> void:
	if not opened:
		return
	if event is InputEventKey or event is InputEventJoypadButton:
		if event.is_action_pressed(&"open_inventory") or event.is_action_pressed(&"ui_cancel"):
			close()
			get_viewport().set_input_as_handled()
		elif not event.is_action(&"ui_focus_next") and not event.is_action(&"ui_focus_prev") and not event.is_action(&"ui_accept") and not event.is_action(&"ui_up") and not event.is_action(&"ui_down"):
			get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(.035, .04, .075, .91))
	var color := Color(IVORY, .8)
	for corner in [Vector2(22, 22), Vector2(size.x - 22, 22), Vector2(22, size.y - 22), Vector2(size.x - 22, size.y - 22)]:
		var direction := Vector2(1 if corner.x < size.x / 2 else -1, 1 if corner.y < size.y / 2 else -1)
		for inset in [0.0, 3.0]:
			var origin: Vector2 = corner + direction * inset
			draw_polyline(PackedVector2Array([origin + Vector2(direction.x * 28, 0), origin, origin + Vector2(0, direction.y * 23)]), color, 1, true)
	draw_line(Vector2(size.x * .51, size.y * .20), Vector2(size.x * .51, size.y * .80), Color(IVORY, .3), 1)
	if is_instance_valid(item_button):
		var rect := item_button.get_global_rect().grow(-4)
		for corner in [rect.position, Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), rect.end]:
			var direction := Vector2(1 if corner.x < rect.get_center().x else -1, 1 if corner.y < rect.get_center().y else -1)
			draw_polyline(PackedVector2Array([corner + Vector2(direction.x * 8, 0), corner, corner + Vector2(0, direction.y * 8)]), color, 1, true)
