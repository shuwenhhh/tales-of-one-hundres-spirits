extends ScrollContainer

signal story_requested(scene: String)
signal replay_requested(scene: String)

const JOURNEY := preload("res://scripts/journey_state.gd")
const FRIENDS := preload("res://scripts/friend_stories.gd")
var cards: Array[Control] = []

func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	follow_focus = true
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	add_child(list)
	var completed := JOURNEY.completed_chapters()
	for entry: Dictionary in FRIENDS.ENTRIES:
		var known := JOURNEY.has_met(entry.scene)
		var cleared: bool = entry.scene in completed
		var card := PanelContainer.new()
		card.set_meta("scene", entry.scene)
		card.set_meta("completed", cleared)
		card.set_meta("known", known)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("152030") if known else Color("141c29")
		style.border_color = Color("86755f") if cleared else Color("3d475b")
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 14
		style.content_margin_bottom = 14
		card.add_theme_stylebox_override("panel", style)
		list.add_child(card)
		cards.append(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)
		card.add_child(row)
		if known:
			var portrait := TextureRect.new()
			portrait.texture = entry.portrait
			portrait.custom_minimum_size = Vector2(104, 148)
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			row.add_child(portrait)
		else:
			var hidden := Label.new()
			hidden.text = "?"
			hidden.custom_minimum_size = Vector2(104, 140)
			hidden.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hidden.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hidden.add_theme_font_size_override("font_size", 48)
			hidden.modulate = Color("67718a")
			row.add_child(hidden)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_theme_constant_override("separation", 7)
		row.add_child(details)
		add_label(details, entry.name if known else "???", 23, Color("ead8b5") if known else Color("858ca0"))
		add_label(details, entry.role if known else "Not yet met", 13, Color("aeb2c8"))
		var body := RichTextLabel.new()
		body.text = entry.summary if cleared else (entry.intro if known else "An empty page. A friend and a story still wait beyond the rain.")
		body.fit_content = true
		body.scroll_active = false
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_size_override("normal_font_size", 15)
		body.add_theme_color_override("default_color", Color("d3d0ce"))
		details.add_child(body)
		if cleared:
			var actions := HBoxContainer.new()
			actions.add_theme_constant_override("separation", 12)
			details.add_child(actions)
			add_action(actions, "Read Story", func() -> void: story_requested.emit(entry.scene))
			add_action(actions, "Replay Chapter", func() -> void: replay_requested.emit(entry.scene))
		else:
			add_label(details, "Story unfinished" if known else "", 12, Color("8e96a9"))

func add_label(parent: Node, text: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func add_action(parent: Node, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(125, 30)
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(action)
	parent.add_child(button)
