extends Node2D
var game
var slow := false
var paused := false
var idle_time := 0.0
var caption: Label
func _ready() -> void:
	game = preload("res://chapter2.tscn").instantiate()
	game.test_mode = true
	add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.phase = "battle"
	game.battle_elapsed = 3.0
	game.boss_x = 670.0
	game.x = 340.0
	game.invincible = 1000.0
	caption = Label.new()
	caption.position = Vector2(280,35)
	caption.add_theme_color_override("font_color",Color("fff0d9"))
	add_child(caption)
	restart()
func restart() -> void:
	game.clear_vines()
	game.start_ground_whip("long")
	idle_time = 0.0
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE: slow = not slow
		if event.physical_keycode == KEY_P: paused = not paused
		if event.physical_keycode == KEY_R: restart()
func _process(delta: float) -> void:
	if not paused:
		if is_instance_valid(game.current_vine) and game.current_vine.stage != game.VINE_STAGE_DONE:
			game.boss_state = "whip_prepare" if game.current_vine.stage == 0 else "whip_release"
			game.advance_vines(delta * (0.25 if slow else 1.0))
		else:
			idle_time += delta
			if idle_time > 0.5: restart()
	game.queue_redraw()
	var name_text := "rest"
	if is_instance_valid(game.current_vine): name_text = ["WINDUP","WAVE","CRACK","REEL IN","DONE","RELAX"][game.current_vine.stage]
	caption.text = "%s  |  %s\nSpace: 0.25x / 1x    P: pause    R: restart" % [name_text, "0.25x" if slow else "1x"]
func set_pose(time: float) -> void:
	paused = true
	restart()
	while game.current_vine.elapsed < time - 0.00001:
		game.boss_state = "whip_prepare" if game.current_vine.stage == 0 else "whip_release"
		game.advance_vines(minf(1.0 / 240.0, time - game.current_vine.elapsed))
	game.queue_redraw()
