extends Control

const JOURNEY := preload("res://scripts/journey_state.gd")
const FRIENDS := preload("res://scripts/friend_stories.gd")
const ART := preload("res://assets/ui/xiaoyu_umbrella_menu_v1.png")
const IVORY := Color("eee4d0")
const GOLD := Color("edcd84")
var menu: VBoxContainer
var overlay: ColorRect
var modal: PanelContainer
var modal_content: VBoxContainer
var last_focus: Control
var buttons: Array[Button] = []
var serif: SystemFont
var leaving: bool = false
var status: Label
var selection_marker: Control
var memories_panel
var modal_page: String = ""
var story_return: String = "memories"
var chapter_gallery

func _ready() -> void:
	JOURNEY.apply_preferences()
	serif = SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"])
	var theme_resource := Theme.new()
	theme_resource.default_font = serif
	theme_resource.default_font_size = 19
	theme_resource.set_color("font_color", "Label", IVORY)
	theme = theme_resource
	var cover := TextureRect.new()
	cover.texture = ART
	cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cover)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.anchor_left = 0.065
	column.anchor_right = 0.27
	column.anchor_top = 0.095
	column.anchor_bottom = 0.85
	column.add_theme_constant_override("separation", 0)
	for entry in [["TALES OF A", 26, 34], ["HUNDRED", 34, 40], ["SPIRITS", 34, 40]]:
		var title := add_label(column, entry[0], entry[1])
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.custom_minimum_size.y = entry[2]
	var gap := Control.new()
	gap.custom_minimum_size.y = 24
	column.add_child(gap)
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 6)
	column.add_child(menu)
	add_menu_button("Begin Story", _begin_story)
	var resume := add_menu_button("Continue Journey", _continue_journey)
	resume.disabled = JOURNEY.continue_scene().is_empty() and JOURNEY.completed_chapters().is_empty()
	resume.focus_mode = Control.FOCUS_NONE if resume.disabled else Control.FOCUS_ALL
	resume.tooltip_text = "Choose your next chapter or revisit a completed story." if not resume.disabled else "Begin a story to start your journey."
	add_menu_button("Memories", _show_memories)
	add_menu_button("Settings", _show_settings)
	add_menu_button("Quit", func() -> void: get_tree().quit())
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	status = add_label(column, "", 11)
	status.modulate = Color("aab3c5")
	status.hide()
	_build_modal()
	selection_marker = Control.new()
	selection_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_marker.size = Vector2(18, 18)
	selection_marker.draw.connect(func() -> void:
		for center in [Vector2(9, 3), Vector2(3, 9), Vector2(15, 9), Vector2(9, 15)]:
			selection_marker.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -3), center + Vector2(3, 0), center + Vector2(0, 3), center + Vector2(-3, 0)]), GOLD))
	add_child(selection_marker)
	buttons[0].grab_focus()

func _process(_delta: float) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	selection_marker.visible = not overlay.visible and focused in buttons
	if selection_marker.visible:
		selection_marker.global_position = focused.global_position + Vector2(-30, (focused.size.y - 18) / 2)

func add_label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func add_menu_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 40
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", IVORY)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_focus_color", GOLD)
	button.add_theme_color_override("font_disabled_color", Color("747f94"))
	for state in ["normal", "pressed", "hover", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.pressed.connect(action)
	button.mouse_entered.connect(func() -> void:
		if not button.disabled and not overlay.visible:
			button.grab_focus())
	menu.add_child(button)
	buttons.append(button)
	return button

func _build_modal() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.035, 0.065, 0.88)
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal = PanelContainer.new()
	overlay.add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.anchor_left = 0.16
	modal.anchor_right = 0.84
	modal.anchor_top = 0.1
	modal.anchor_bottom = 0.9
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("172637")
	panel.border_color = Color("81796e")
	panel.set_border_width_all(1)
	panel.content_margin_left = 30
	panel.content_margin_right = 30
	panel.content_margin_top = 22
	panel.content_margin_bottom = 20
	modal.add_theme_stylebox_override("panel", panel)
	modal_content = VBoxContainer.new()
	modal_content.add_theme_constant_override("separation", 12)
	modal.add_child(modal_content)
	overlay.hide()

func _open_modal(title: String) -> void:
	if not overlay.visible:
		last_focus = get_viewport().gui_get_focus_owner()
	modal_page = ""
	modal.anchor_left = .16
	modal.anchor_right = .84
	modal.anchor_top = .1
	modal.anchor_bottom = .9
	for child in modal_content.get_children():
		modal_content.remove_child(child)
		child.queue_free()
	for button in buttons:
		button.focus_mode = Control.FOCUS_NONE
	add_label(modal_content, title, 28)
	overlay.show()

func _modal_text(text: String) -> RichTextLabel:
	var body := RichTextLabel.new()
	body.text = text
	body.bbcode_enabled = false
	body.scroll_active = true
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size", 16)
	body.add_theme_color_override("default_color", IVORY)
	modal_content.add_child(body)
	return body

func _add_close() -> void:
	var close := Button.new()
	close.text = "Back"
	close.custom_minimum_size.y = 34
	close.pressed.connect(_close_modal)
	modal_content.add_child(close)
	close.grab_focus()

func _close_modal() -> void:
	overlay.hide()
	for button in buttons:
		button.focus_mode = Control.FOCUS_NONE if button.disabled else Control.FOCUS_ALL
	if is_instance_valid(last_focus):
		last_focus.grab_focus()

func _show_memories() -> void:
	_open_modal("Memories")
	modal_page = "memories"
	modal.anchor_left = .07
	modal.anchor_right = .93
	modal.anchor_top = .06
	modal.anchor_bottom = .94
	memories_panel = preload("res://scripts/memories_panel.gd").new()
	modal_content.add_child(memories_panel)
	memories_panel.story_requested.connect(_read_friend_story)
	memories_panel.replay_requested.connect(_go_to)
	_add_close()

func _read_friend_story(scene: String) -> void:
	if scene not in JOURNEY.completed_chapters():
		return
	var friend := FRIENDS.find(scene)
	if friend.is_empty():
		return
	story_return = "chapters" if modal_page == "chapters" else "memories"
	_open_modal(friend.name)
	modal_page = "story"
	var body: String = friend.chapter + "\n\n" + friend.story
	var transcript := JOURNEY.recorded_dialogue(scene)
	if not transcript.is_empty():
		body += "\n\n— RECORDED CONVERSATION —\n\n" + transcript
	_modal_text(body)
	var back := Button.new()
	back.text = "Back to Chapters" if story_return == "chapters" else "Back to Memories"
	back.custom_minimum_size.y = 34
	back.pressed.connect(_return_from_story)
	modal_content.add_child(back)
	back.grab_focus()

func _show_settings() -> void:
	_open_modal("Settings")
	var cfg := JOURNEY.preferences()
	for entry in [["mute", "Mute audio"], ["fullscreen", "Fullscreen"], ["reduce_shake", "Reduce screen shake"]]:
		var key: String = entry[0]
		var toggle := CheckButton.new()
		toggle.text = entry[1]
		toggle.button_pressed = bool(cfg.get_value("settings", key, false))
		toggle.toggled.connect(func(enabled: bool) -> void:
			JOURNEY.set_preference(key, enabled)
			JOURNEY.apply_preferences())
		modal_content.add_child(toggle)
	_modal_text("A / D or arrows: Move    Space: Jump\nJ: Umbrella strike / reflect foxfire (Chapter Three)\nW / Up + J: Upward strike (Chapter One)\nShift / K: Dodge    L / S: Guard with the open umbrella    E: Listen    Ctrl: Fast-forward dialogue\n1: Equip umbrella / M: Memories (Chapter One)\nEsc: Pause    Q while paused: Main menu\n\nContinue Journey starts after your furthest completed chapter. Read stories or replay cleared chapters in Memories. Chapter Three dialogue is currently Chinese.")
	_add_close()

func _begin_story() -> void:
	_go_to("res://chapter0.tscn")

func _continue_journey() -> void:
	_show_chapters()

func _show_chapters() -> void:
	_open_modal("Continue Journey")
	modal_page = "chapters"
	modal.anchor_left = .05
	modal.anchor_right = .95
	modal.anchor_top = .035
	modal.anchor_bottom = .965
	chapter_gallery = preload("res://scripts/chapter_gallery.gd").new()
	modal_content.add_child(chapter_gallery)
	chapter_gallery.chapter_requested.connect(_go_to)
	chapter_gallery.story_requested.connect(_read_friend_story)
	_add_close()
	if is_instance_valid(chapter_gallery.continue_button):
		chapter_gallery.continue_button.grab_focus()

func _return_from_story() -> void:
	if story_return == "chapters":
		_show_chapters()
	else:
		_show_memories()

func _go_to(scene: String) -> void:
	if leaving:
		return
	leaving = true
	var error := get_tree().change_scene_to_file(scene)
	if error != OK:
		leaving = false
		status.text = "Could not open this chapter. Please try again."
		status.show()
		push_error("Scene change failed: %s" % error)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE and overlay.visible:
		if modal_page == "story":
			_return_from_story()
		else:
			_close_modal()
		get_viewport().set_input_as_handled()
