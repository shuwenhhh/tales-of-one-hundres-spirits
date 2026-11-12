extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://chapter2.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	assert(game.boss_frames.size() == 6)
	assert(game.thrust_windup == 0.5)
	assert(game.thrust_recovery == 0.5)

	# The narrated transition starts a harmless retreat before any attack.
	game.x = 600.0
	game.boss_x = 700.0
	var opening: Array[String] = ["(The flowering branches quietly close the garden gate.)"]
	game.start_lines(opening, "battle")
	while game.phase == "dialogue":
		game.next_line()
	assert(game.boss_state == "opening_retreat")
	var hp_before: int = game.hp
	game.update_boss(0.6)
	assert(game.battle_elapsed < game.OPENING_GRACE)
	assert(game.boss_state == "opening_retreat")
	game.damage_player(false)
	assert(game.hp == hp_before)
	game.update_boss(0.61)
	assert(game.boss_state == "rest")
	assert(absf(game.boss_x - game.x) >= game.OPENING_SAFE_DISTANCE)

	# Thrust: long locked windup, a flash 0.15 s before release, brief contact,
	# then a 0.5 s recovery that keeps the committed facing.
	game.battle_elapsed = 2.0
	game.boss_state = "rest"
	game.boss_time = 0.3
	game.pattern = 0
	game.x = 610.0
	game.boss_x = 700.0
	game.update_boss(0.02)
	assert(game.boss_state == "branch_prepare")
	assert(game.branch_mode == "thrust")
	assert(game.boss_facing == -1)
	game.update_boss(0.34)
	assert(not game.warning_played)
	game.update_boss(0.02)
	assert(game.warning_played)
	assert(game.boss_state == "branch_prepare")
	game.update_boss(0.14)
	assert(game.boss_state == "branch_lunge")
	game.invincible = 0.0
	hp_before = game.hp
	game.update_boss(0.04)
	assert(game.hp == hp_before)
	game.update_boss(0.08)
	assert(game.hp == hp_before - 1)
	game.update_boss(0.16)
	assert(game.boss_state == "recover")
	game.x = 850.0
	game.update_boss(0.2)
	assert(game.boss_state == "recover")
	assert(game.boss_facing == -1)
	game.update_boss(0.31)
	assert(game.boss_state == "rest")
	game.boss_state = "branch_lunge"
	game.boss_time = 0.1
	game.boss_target_x = game.boss_x
	game.x = game.boss_x
	game.invincible = 0.0
	hp_before = game.hp
	game.update_boss(0.016)
	assert(game.hp == hp_before - 1)

	# Body overlap hurts once, knocks Xiaoyu away, and grants one second of safety.
	game.boss_state = "rest"
	game.boss_time = 0.0
	game.x = 500.0
	game.boss_x = 500.0
	game.invincible = 0.0
	game.knockback_time = 0.0
	game.attack_time = 0.0
	hp_before = game.hp
	game._physics_process(0.016)
	assert(game.hp == hp_before - 1)
	assert(game.x < 500.0)
	assert(game.invincible >= 0.98)
	game._physics_process(0.016)
	assert(game.hp == hp_before - 1)

	# Shift dash may cross the boss body instead of being snapped back.
	game.boss_state = "rest"
	game.boss_x = 500.0
	game.x = 460.0
	game.knockback_time = 0.0
	game.dash_cooldown = 0.0
	game.invincible = 0.0
	var shift := InputEventKey.new()
	shift.pressed = true
	shift.physical_keycode = KEY_SHIFT
	game._unhandled_key_input(shift)
	assert(game.dash_time > 0.0)
	game.x = 510.0
	hp_before = game.hp
	game._physics_process(0.016)
	assert(game.x > game.boss_x)
	assert(game.hp == hp_before)

	# Three rapid hits provoke an escape or guard; a guarded hit counters.
	game.battle_elapsed = 10.0
	game.grief = 8
	game.boss_x = 495.0
	game.x = 440.0
	game.boss_facing = -1
	game.reaction_cooldown = 0.0
	game.hit_streak = 0
	game.last_hit_at = 0.0
	for hit in 3:
		game.battle_elapsed = 10.0 + hit * 0.4
		game.apply_boss_hit()
	assert(game.boss_state in ["backhop", "parry"])
	assert(game.reaction_cooldown > 0.0)
	game.boss_state = "parry"
	game.boss_time = 0.0
	var grief_before: int = game.grief
	game.apply_boss_hit()
	assert(game.grief == grief_before)
	assert(game.boss_state == "counter_prepare")
	game.update_boss(0.11)
	assert(game.warning_played)
	game.update_boss(0.15)
	assert(game.boss_state == "branch_lunge")

	# At the left wall she jumps over the player rather than remaining trapped.
	game.boss_state = "rest"
	game.boss_time = 0.5
	game.boss_x = 60.0
	game.x = 170.0
	game.reaction_cooldown = 0.0
	game.invincible = 2.0
	game.update_boss(0.016)
	assert(game.boss_state == "vault")
	game.update_boss(0.58)
	assert(game.boss_x > game.x)
	assert(game.boss_state == "recover")

	# At half resolve she summons petals, then resumes the duel while they fall.
	game.grief = 5
	game.battle_elapsed = 20.0
	game.last_hit_at = 0.0
	game.hit_streak = 0
	game.reaction_cooldown = 2.0
	game.apply_boss_hit()
	assert(game.grief == 4)
	assert(game.ultimate_pending)
	game.boss_state = "rest"
	game.boss_time = 0.0
	game.update_boss(0.016)
	assert(game.boss_state == "blossom_cast")
	game.update_boss(0.53)
	assert(game.cast_released)
	assert(game.wind_time > 0.0)
	assert(game.shots.size() > 0)
	game.update_boss(0.38)
	assert(game.boss_state == "rest")
	assert(game.wind_time > 0.0)
	game.update_boss(0.02)
	assert(game.boss_state != "blossom_cast")

	# Petals freeze without damage; the last hit still reaches the calm ending.
	game.invincible = 0.0
	hp_before = game.hp
	game.damage_player(true)
	assert(game.hp == hp_before)
	assert(game.freeze_time == 1.0)
	game.freeze_time = 0.0
	game.invincible = 2.0
	game.knockback_time = 0.0
	game.dash_time = 0.0
	game.x = 640.0
	game.boss_x = 700.0
	game.facing = 1
	game.grief = 1
	game.phase = "battle"
	game.boss_state = "rest"
	game.attack_time = 0.20
	game.hit_this_swing = false
	game._physics_process(0.02)
	assert(game.phase == "settling")
	game._physics_process(1.61)
	assert(game.phase == "dialogue")
	game.queue_free()
	await process_frame
	print("chapter2 boss encounter OK")
	quit()
