extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://chapter2.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	assert(game.boss_idle_frame != null)
	assert(game.boss_walk_frames.size() == 4)
	assert(game.boss_leap_frames.size() == 4)
	assert(game.boss_cast_frames.size() == 6)
	assert(game.boss_dance_frames.size() == 4)
	assert(game.hazard_blossoms.size() == 3)
	assert(game.silk_guard.enabled)

	# The opening retreat remains harmless and creates space.
	game.x = 155.0
	game._physics_process(0.016)
	assert(game.phase == "explore")
	assert(is_equal_approx(game.boss_x, game.INTRO_TREE_X))
	game.x = 300.0
	game._physics_process(0.016)
	assert(game.phase == "dialogue")
	while game.phase == "dialogue":
		game.next_line()
	assert(game.boss_state == "opening_retreat")
	assert(game.held_vine_visible())
	var hp_before: int = game.hp
	game.update_boss(0.6)
	assert(game.vines.is_empty())
	game.damage_player(false)
	assert(game.hp == hp_before)
	game.update_boss(0.61)
	assert(game.boss_state == "rest")
	assert(absf(game.boss_x - game.x) >= game.OPENING_SAFE_DISTANCE)

	# She walks in short, animated steps until a long whip can reach Xiaoyu.
	game.battle_elapsed = 2.0
	game.x = 180.0
	game.boss_x = 700.0
	game.boss_time = 0.0
	game.update_boss(0.1)
	assert(game.boss_is_walking)
	assert(game.held_vine_visible())
	assert(game.boss_walk_distance > 0.0)

	# The ground whip stays synchronized with the hand throughout its phases.
	game.x = 450.0
	game.boss_x = 700.0
	game.start_ground_whip("long")
	var vine = game.current_vine
	assert(not game.held_vine_visible())
	game.update_boss(0.3)
	assert(vine.stage == vine.Stage.WARNING)
	assert(game.hp == hp_before)
	game.x = 850.0
	game.boss_x += 30.0
	game.update_boss(0.02)
	assert(vine.to_global(vine.points[0]).distance_to(game.get_node("VineOrigin").global_position) < 0.01)
	game.update_boss(vine.end_time())
	assert(vine.stage == vine.Stage.DONE)
	game.update_boss(0.01)
	assert(game.boss_state == "recover")
	game.clear_vines()
	assert(game.held_vine_visible())
	game.x = 485.0
	game.boss_x = 600.0
	game.start_ground_whip("low")
	var low_vine = game.current_vine
	game.apply_boss_hit()
	assert(low_vine.cancelled)
	assert(not low_vine.damage_active())
	assert(game.impact_pause == game.HIT_PAUSE)
	game.update_boss(0.3)
	assert(game.boss_state == "ouch")
	game.clear_vines()
	# Overlap still hurts and separates bodies; Shift may pass through.
	game.boss_state = "rest"
	game.boss_time = 0.0
	game.x = 500.0
	game.boss_x = 500.0
	game.invincible = 0.0
	game.knockback_time = 0.0
	game.attack_time = 0.0
	game.impact_pause = 0.0
	hp_before = game.hp
	game._physics_process(0.016)
	assert(game.hp == hp_before - 1)
	assert(absf(game.x - game.boss_x) >= game.BODY_SEPARATION)
	assert(game.invincible >= 0.98)
	game.boss_state = "rest"
	game.boss_x = 500.0
	game.x = 460.0
	game.knockback_time = 0.0
	game.dash_cooldown = 0.0
	game.invincible = 0.0
	game.impact_pause = 0.0
	var shift := InputEventKey.new()
	shift.pressed = true
	shift.physical_keycode = KEY_SHIFT
	game._unhandled_key_input(shift)
	game.x = 510.0
	hp_before = game.hp
	game._physics_process(0.016)
	assert(game.x > game.boss_x)
	assert(game.hp == hp_before)
	game.dash_time = 0.0

	# A corner escape is movement only: no surprise ground vine after opening retreat.
	game.boss_state = "rest"
	game.boss_time = 0.6
	game.boss_x = 60.0
	game.x = 170.0
	game.y = game.FLOOR
	game.invincible = 2.0
	game.reaction_cooldown = 0.0
	game.update_boss(0.016)
	assert(game.boss_state == "vault")
	assert(game.current_vine == null)
	assert(game.vines.is_empty())
	game.update_boss(game.BOSS_VAULT_DURATION)
	assert(game.vines.is_empty())
	assert(game.boss_state == "recover")
	assert(game.boss_x > game.x)
	game.clear_vines()

	# Air attack commits to the apex, cracks while airborne, then lands on the locked side.
	game.boss_x = 700.0
	game.x = 480.0
	game.start_boss_leap()
	var landing: float = game.boss_target_x
	var air_vine = game.current_vine
	var air_root: Vector2 = air_vine.global_position
	game.update_boss(game.leap_rise_duration)
	assert(game.boss_state == "leap_whip")
	var locked_direction: Vector2 = air_vine.direction
	game.x = 900.0
	while air_vine.elapsed < air_vine.snap_time() + 0.01:
		game.update_boss(1.0 / 120.0)
	assert(game.boss_state == "leap_whip")
	assert(game.boss_air_y < -60.0)
	assert(air_vine.damage_active())
	assert(air_vine.direction == locked_direction)
	while game.boss_state == "leap_whip":
		game.update_boss(1.0 / 120.0)
	game.update_boss(game.leap_dive_duration)
	assert(air_vine.global_position == air_root)
	assert(is_equal_approx(game.boss_x, landing))
	assert(game.boss_state == "recover")
	game.clear_vines()
	# Rain first triggers strictly below half of the current grief pool.
	game.boss_state = "rest"
	game.grief = game.SECOND_PHASE_HALF + 1
	game.battle_elapsed = 20.0
	game.last_hit_at = 0.0
	game.hit_streak = 0
	game.reaction_cooldown = 2.0
	game.ultimate_pending = false
	game.apply_boss_hit()
	assert(game.grief == game.SECOND_PHASE_HALF)
	assert(not game.ultimate_pending)
	game.battle_elapsed += 2.0
	game.apply_boss_hit()
	assert(game.grief == game.SECOND_PHASE_HALF - 1)
	assert(game.ultimate_pending)
	game.boss_state = "rest"
	game.boss_time = 0.0
	game.update_boss(0.016)
	assert(game.boss_state == "blossom_cast")
	game.update_boss(game.BLOSSOM_RELEASE_TIME + 0.01)
	assert(game.wind_time > 0.0)
	assert(game.shots.size() > 0)
	game.update_boss(game.BLOSSOM_CAST_DURATION - game.BLOSSOM_RELEASE_TIME)
	assert(game.boss_state == "recover")
	game.x = game.boss_x - 200.0
	game.update_boss(game.BLOSSOM_CAST_RECOVERY + 0.01)
	assert(game.boss_state == "rest")
	game.update_boss(0.4)
	assert(game.boss_state in ["whip_prepare", "leap_rise"])
	assert(game.wind_time > 0.0)

	# Falling blossoms retain the normal one-heart hurt response.
	game.grief = 3
	game.boss_state = "ouch"
	game.boss_time = 0.0
	game.boss_knockback_time = 0.0
	game.wind_time = 0.0
	game.shots.clear()
	game.hp = 6
	game.x = 640.0
	game.y = game.FLOOR
	game.invincible = 0.0
	game.shots.append({"x": game.x, "y": game.y - 28.0, "vx": 0.0, "vy": 0.0, "angle": 0.0, "life": 1.0, "kind": "rain"})
	game.update_boss(0.016)
	assert(game.hp == 5)
	assert(game.shots.is_empty())
	assert(game.girl_flash > 0.0)
	assert(game.invincible == game.HURT_INVINCIBILITY)

	# The last airborne hit lands and separates the actors before dialogue.
	game.invincible = 2.0
	game.knockback_time = 0.0
	game.x = 650.0
	game.boss_x = 700.0
	game.facing = 1
	game.y = game.FLOOR - 80.0
	game.vy = -180.0
	game.attack_up = true
	game.dash_time = 0.12
	game.grief = 1
	game.phase = "battle"
	game.boss_state = "rest"
	game.attack_time = 0.20
	game.hit_this_swing = false
	game.impact_pause = 0.0
	game._physics_process(0.02)
	assert(game.phase == "settling")
	assert(game.dash_time == 0.0)
	assert(game.shots.is_empty())
	assert(game.wind_time == 0.0)
	game.impact_pause = 0.0
	for frame in 150:
		if game.phase != "settling":
			break
		game._physics_process(1.0 / 60.0)
	assert(game.phase == "dialogue")
	assert(game.y == game.FLOOR)
	assert(game.vy == 0.0)
	assert(absf(game.x - game.boss_x) >= game.SETTLE_PLAYER_GAP - 1.0)
	assert(game.facing == 1)
	# Near the left wall, the safe speaking position is on the open side.
	game.phase = "battle"
	game.grief = 1
	game.boss_x = 48.0
	game.x = 32.0
	game.y = game.FLOOR - 80.0
	game.vy = -180.0
	game.facing = 1
	game.attack_up = true
	game.attack_time = 0.20
	game.hit_this_swing = false
	game.impact_pause = 0.0
	game._physics_process(0.02)
	assert(game.phase == "settling")
	for frame in 150:
		if game.phase != "settling":
			break
		game._physics_process(1.0 / 60.0)
	assert(game.phase == "dialogue")
	assert(game.y == game.FLOOR)
	assert(game.x >= game.boss_x + game.SETTLE_PLAYER_GAP - 1.0)
	# The vine tip can pass the body, but a raised umbrella facing its caster counters it.
	game.phase = "battle"
	game.battle_elapsed = 3.0
	game.boss_x = 600.0
	game.x = 500.0
	game.y = game.FLOOR
	game.grief = game.MAX_GRIEF
	game.hp = 6
	game.invincible = 0.0
	game.silk_guard.remaining = 0.3
	game.silk_guard.facing = 1
	game.silk_guard.counter_claimed = false
	game._on_vine_tip_contact(Vector2(480.0, game.FLOOR - 35.0))
	assert(game.hp == 6)
	assert(game.grief == game.MAX_GRIEF - 1)
	game.silk_guard.cancel()
	game.silk_guard.remaining = 0.3
	game.silk_guard.facing = -1
	game.grief = game.MAX_GRIEF
	game.impact_pause = 0.0
	game._on_vine_tip_contact(Vector2(480.0, game.FLOOR - 35.0))
	assert(game.hp == 5)
	assert(game.grief == game.MAX_GRIEF)
	# Three close hits force a readable counter. Its windup has no damage,
	# and a fourth hit cannot cancel the committed sweep.
	game.clear_vines()
	game.phase = "battle"
	game.battle_elapsed = 10.0
	game.boss_state = "rest"
	game.boss_x = 600.0
	game.x = 550.0
	game.y = game.FLOOR
	game.facing = 1
	game.attack_time = 0.18
	var contact: Vector2 = game.umbrella_hit_position()
	assert(contact.x >= game.boss_x - 40.0 and contact.x <= game.boss_x + 40.0)
	assert(contact.y >= game.FLOOR - 132.0 and contact.y <= game.FLOOR)
	game.hp = 6
	game.grief = game.MAX_GRIEF
	game.invincible = 0.0
	game.hit_streak = 0
	game.reaction_cooldown = 0.0
	game.silk_guard.cancel()
	for hit in game.CLOSE_COUNTER_HITS:
		game.apply_boss_hit()
		game.battle_elapsed += 0.2
	assert(game.branch_mode == "close" and game.boss_state == "whip_prepare")
	var counter = game.current_vine
	game.update_boss(0.34)
	assert(game.hp == 6)
	game.apply_boss_hit()
	assert(game.current_vine == counter and not counter.cancelled)
	for frame in 80:
		game.update_boss(1.0 / 120.0)
	assert(game.hp == 5)
	for defense in ["retreat", "guard"]:
		game.clear_vines()
		game.x = game.boss_x - 50.0
		game.invincible = 0.0
		game.hp = 6
		game.start_ground_whip("close")
		if defense == "retreat":
			game.x -= 160.0
		else:
			game.silk_guard.remaining = 0.5
			game.silk_guard.facing = 1
			game.silk_guard.counter_claimed = false
		for frame in 110:
			game.update_boss(1.0 / 120.0)
		assert(game.hp == 6)
	# A player touching the visible middle of the vine is hit while the whip is live.
	var segment_vine = load("res://scenes/vine_attack.tscn").instantiate()
	game.add_child(segment_vine)
	segment_vine.begin(Vector2(500.0, 350.0), Vector2(750.0, 350.0), 1, game.FLOOR)
	segment_vine.seek(segment_vine.snap_time() + 0.01)
	var middle: Vector2 = segment_vine.to_global(segment_vine.line.points[5])
	assert(middle.distance_to(segment_vine.to_global(segment_vine.tip_position)) > segment_vine.tip_hit_radius + segment_vine.player_hit_radius)
	assert(not is_inf(segment_vine.contact_on_vine(middle, segment_vine.player_hit_radius).x))
	var vine_contacts := [0]
	segment_vine.tip_contact.connect(func(_source): vine_contacts[0] += 1)
	segment_vine.advance(1.0 / 120.0, middle)
	assert(vine_contacts[0] == 1)
	segment_vine.advance(1.0 / 120.0, middle)
	assert(vine_contacts[0] == 1)
	segment_vine.queue_free()
	game.queue_free()
	await process_frame
	print("chapter2 vine whip encounter OK")
	quit()
