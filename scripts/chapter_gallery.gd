extends HBoxContainer

signal chapter_requested(scene: String)
signal story_requested(scene: String)

const JOURNEY := preload("res://scripts/journey_state.gd")
const FRIENDS := preload("res://scripts/friend_stories.gd")
var cards: Array[Control] = []
var continue_button: Button

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 16)
	var next_scene := JOURNEY.continue_scene()
	var cleared := JOURNEY.completed_chapters()
	for index in range(FRIENDS.ENTRIES.size()):
		var entry: Dictionary = FRIENDS.ENTRIES[index]
		var complete: bool = entry.scene in cleared
		var current: bool = entry.scene == next_scene
		var known: bool = complete or current or JOURNEY.has_met(entry.scene)
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.set_meta("scene", entry.scene)
		card.set_meta("completed", complete)
		card.set_meta("current", current)
		cards.append(card)
		var frame := StyleBoxFlat.new()
		frame.bg_color = Color("151a27")
		frame.border_color = Color("e3be77") if current else (Color("89694e") if complete else Color("424653"))
		frame.set_border_width_all(3 if current else 2)
		frame.content_margin_left = 8
		frame.content_margin_right = 8
		frame.content_margin_top = 8
		frame.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", frame)
		add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 7)
		card.add_child(column)
		var artwork := Control.new()
		artwork.custom_minimum_size = Vector2(0, 210)
		artwork.size_flags_vertical = Control.SIZE_EXPAND_FILL
		artwork.clip_contents = true
		column.add_child(artwork)
		if known:
			var backdrop := TextureRect.new()
			backdrop.texture = entry.background
			backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			backdrop.modulate = Color(.65, .65, .7)
			artwork.add_child(backdrop)
			backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			var portrait := TextureRect.new()
			portrait.texture = entry.portrait
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			artwork.add_child(portrait)
			portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			portrait.offset_left = 10
			portrait.offset_right = -10
			portrait.offset_top = 20
			portrait.offset_bottom = -8
		else:
			var hidden := Label.new()
			hidden.text = "?"
			hidden.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hidden.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hidden.add_theme_font_size_override("font_size", 58)
			hidden.modulate = Color("747b90")
			artwork.add_child(hidden)
			hidden.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		caption(column, "CHAPTER %02d" % [index + 1], 12, Color("a8adbc"))
		caption(column, entry.get("chapter_title", entry.chapter) if known else "???", 14, Color("eee1c9"))
		caption(column, "Continue here" if current else ("Completed" if complete else "Not reached"), 13, Color("e7c37b") if current else Color("9da3b2"))
		if current:
			continue_button = action_button(column, "Continue", func() -> void: chapter_requested.emit(entry.scene))
		elif complete:
			var actions := HBoxContainer.new()
			actions.add_theme_constant_override("separation", 5)
			column.add_child(actions)
			action_button(actions, "Read Story", func() -> void: story_requested.emit(entry.scene))
			action_button(actions, "Replay", func() -> void: chapter_requested.emit(entry.scene))
		else:
			var space := Control.new()
			space.custom_minimum_size.y = 32
			column.add_child(space)

func caption(parent: Node, text: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func action_button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 32
	button.add_theme_font_size_override("font_size", 13)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
