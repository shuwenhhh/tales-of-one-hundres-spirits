extends Control

const NEXT_SCENE := "res://chapter1.tscn"
var leaving: bool = false
var ready_to_continue: bool = false
var fade: Tween
@onready var veil: ColorRect = $Veil
@onready var prompt: Label = $Prompt

func _ready() -> void:
	fade = create_tween()
	fade.tween_property(veil, "color:a", 0.0, 1.6).set_trans(Tween.TRANS_SINE)
	fade.tween_callback(func() -> void: ready_to_continue = true)
	fade.tween_property(prompt, "modulate:a", 0.8, 0.7)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE and not leaving:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		get_viewport().set_input_as_handled()
		return
	if leaving or not ready_to_continue:
		return
	var proceed: bool = false
	if event is InputEventMouseButton:
		proceed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		proceed = event.pressed
	elif event is InputEventKey:
		proceed = event.pressed and not event.echo and event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	elif event is InputEventJoypadButton:
		proceed = event.pressed and event.button_index == JOY_BUTTON_A
	if proceed:
		get_viewport().set_input_as_handled()
		_enter_chapter()

func _enter_chapter() -> void:
	if leaving:
		return
	leaving = true
	if fade and fade.is_running():
		fade.kill()
	fade = create_tween()
	fade.tween_property(prompt, "modulate:a", 0.0, 0.2)
	fade.tween_property(veil, "color:a", 1.0, 0.65).set_trans(Tween.TRANS_SINE)
	fade.tween_callback(_change_scene)

func _change_scene() -> void:
	var result := get_tree().change_scene_to_file(NEXT_SCENE)
	if result != OK:
		push_error("Unable to open chapter one: %s" % result)
		leaving = false
		veil.color.a = 0.0
		prompt.text = "Could not enter the chapter. Click to try again."
		prompt.modulate.a = 1.0
