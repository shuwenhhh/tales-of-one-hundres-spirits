extends CanvasLayer

signal failed(error: Error)
signal revealed

const NODE_NAME := "ChapterTransition"
const FADE_OUT := .6
const FADE_IN := .85
var target_scene: String
var veil: ColorRect
var stage: String = "fading_out"

static func start(tree: SceneTree, scene: String, on_failure: Callable = Callable()) -> Error:
	if tree.root.has_node(NODE_NAME):
		return ERR_BUSY
	if not ResourceLoader.exists(scene, "PackedScene"):
		return ERR_FILE_NOT_FOUND
	var script: GDScript = load("res://scripts/scene_transition.gd")
	var overlay = script.new()
	overlay.name = NODE_NAME
	overlay.target_scene = scene
	if on_failure.is_valid():
		overlay.failed.connect(on_failure)
	tree.root.add_child(overlay)
	overlay._travel.call_deferred()
	return OK

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	veil = ColorRect.new()
	veil.color = Color(.025, .03, .055, 0)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()

func _fade(alpha: float, seconds: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(veil, "color:a", alpha, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _travel() -> void:
	var tree := get_tree()
	var previous := tree.current_scene
	var previous_physics := previous.is_physics_processing() if is_instance_valid(previous) else false
	if is_instance_valid(previous):
		previous.set_physics_process(false)
	# Load while fading, keeping the old scene and its rain alive until covered.
	var error := ResourceLoader.load_threaded_request(target_scene, "PackedScene")
	await _fade(1.0, FADE_OUT)
	stage = "loading"
	if error == OK:
		while ResourceLoader.load_threaded_get_status(target_scene) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await tree.process_frame
		if ResourceLoader.load_threaded_get_status(target_scene) == ResourceLoader.THREAD_LOAD_LOADED:
			var scene := ResourceLoader.load_threaded_get(target_scene) as PackedScene
			error = tree.change_scene_to_packed(scene)
		else:
			error = ERR_CANT_OPEN
	if error != OK:
		await _fade(0.0, .35)
		if is_instance_valid(previous):
			previous.set_physics_process(previous_physics)
		failed.emit(error)
		queue_free()
		return
	await tree.scene_changed
	var arriving := tree.current_scene
	var arriving_physics := arriving.is_physics_processing()
	arriving.set_physics_process(false)
	# Present the new scene fully covered before revealing its first frame.
	await tree.create_timer(.10).timeout
	stage = "fading_in"
	await _fade(0.0, FADE_IN)
	if is_instance_valid(arriving):
		arriving.set_physics_process(arriving_physics)
	revealed.emit()
	queue_free()
