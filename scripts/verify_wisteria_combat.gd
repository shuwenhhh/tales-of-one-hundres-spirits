extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	seed(2197)
	for airborne in [false, true]:
		for mirrored in [false, true]:
			for dodge in [false, true]:
				var game = preload("res://chapter2.tscn").instantiate()
				game.test_mode = true
				root.add_child(game)
				game.set_physics_process(false)
				game.phase = "battle"
				game.battle_elapsed = 3.0
				game.boss_x = 300.0 if mirrored else 660.0
				game.x = 520.0 if mirrored else 440.0
				if airborne:
					game.start_boss_leap()
				else:
					game.start_ground_whip("long")
				var vine = game.current_vine
				var direction: Vector2 = vine.direction
				var contacts := [0]
				vine.tip_contact.connect(func(_source): contacts[0] += 1)
				for frame in 110:
					if dodge and frame == 48:
						game.x += -200.0 if mirrored else 200.0
					game.update_boss(1.0 / 120.0)
					check(vine.direction == direction, "Committed vine aim changed")
					if vine.damage_active() and airborne:
						check(game.boss_air_y < -60.0, "Air whip hit after landing")
				var expected := 0 if dodge else 1
				check(contacts[0] == expected, "air=%s mirror=%s dodge=%s contacts=%d expected=%d" % [airborne, mirrored, dodge, contacts[0], expected])
				check(game.boss_idle_frame.get_size() == game.boss_cast_frames[0].get_size(), "Pose scale changed")
				game.queue_free()
				await process_frame
	print("WISTERIA COMBAT: %d failures across ground/air, left/right, stationary/dodge" % failures)
	quit(1 if failures else 0)
