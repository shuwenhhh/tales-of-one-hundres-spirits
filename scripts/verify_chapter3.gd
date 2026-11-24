extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + description)

func run() -> void:
	var game = load("res://chapter3.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	check(game.phase == "explore", "chapter loads")
	check(game.BOSS_WALK.size() == 3 and game.BOSS_JUMP != null and game.BOSS_BREATH.size() == 6 and game.FIRE_PURPLE_SPRITE != null, "walk, jump, breath and violet foxfire sprites load")
	check(game.player.x < game.boss_x and game.facing == 1 and game.boss_facing == -1 and not game.boss_visible, "hero enters from left while fox hides on right")
	game.player.x = 349.0
	game._physics_process(0.016)
	check(game.phase == "explore", "opening waits until hero approaches from left")
	game.player.x = 350.0
	game.player.y = game.FLOOR - 80.0
	game._physics_process(0.016)
	check(game.phase == "explore", "opening does not freeze heroine in midair")
	game.player.y = game.FLOOR
	game._physics_process(0.016)
	check(game.phase == "dialogue" and is_equal_approx(game.player.y, game.FLOOR), "opening starts once heroine lands")
	check(not game.boss_visible and game.facing == 1 and "|".join(game.lines).contains("看得见我吗"), "fox calls unseen while hero looks back into rain")
	check("|".join(game.lines).contains("我才不上当呢"), "hero refuses the first invitation to turn around")
	check("|".join(game.lines).contains("迎亲队伍") and "|".join(game.lines).contains("犯了禁忌"), "opening explains the witnessed fox wedding taboo")
	for i in game.lines.size():
		var reveal_next: bool = game.line_index + 1 < game.lines.size() and game.lines[game.line_index + 1].begins_with("（身后静了下来")
		if reveal_next:
			check(not game.boss_visible, "fox remains hidden through the heroine's refusal")
		game._next_line()
		if game.turn_time >= 0.0:
			game._process(1.01)
		if reveal_next:
			check(game.boss_visible and game.facing == -1 and game.boss_x < game.player.x - 150.0 and game.boss_x > game.player.x - 220.0, "fox appears behind heroine only when she finally turns")
	check(game.phase == "battle" and game.boss_visible and game.facing == -1, "hero turns right toward fox before battle")
	var start_x: float = game.boss_x
	game._update_attacks(0.25)
	check(game.boss_x > start_x, "boss walks left toward player")
	game._start_next_attack()
	check(game.boss_attack == "dash_windup", "first pattern is dash")
	game._update_attacks(0.39)
	check(game.boss_attack == "dash_windup", "dash waits for white flash")
	game._update_attacks(0.02)
	check(game.boss_attack == "dash", "dash starts after 0.4 seconds")
	var dash_origin: float = game.boss_x
	game.player.y = game.FLOOR - 100.0
	game._update_attacks(0.2)
	check(game.boss_x - dash_origin > 100.0 and game.hp == game.MAX_PLAYER_HP, "leftward dash travels and jump avoids hit")
	game.player.y = game.FLOOR
	game._set_boss_state("fan_windup")
	game._update_attacks(0.39)
	check(game.foxfires.is_empty(), "fan has prefire warning")
	game._update_attacks(0.02)
	check(game.foxfires.size() == 1 and game.boss_attack == "fan_firing", "fan fires first foxfire after warning")
	game._update_attacks(0.27)
	check(game.foxfires.size() == 1, "fan waits between shots")
	game._update_attacks(0.02)
	check(game.foxfires.size() == 2, "fan fires second foxfire separately")
	game._update_attacks(0.24)
	check(game.foxfires.size() == 2, "fan waits before third shot")
	game._update_attacks(0.04)
	check(game.foxfires.size() == 3 and game.boss_attack == "fan_wait", "fan finishes all three shots before waiting")
	game._update_attacks(0.7)
	check(game.boss_attack == "fan_wait", "next move waits while foxfires remain active")
	game.foxfires.clear()
	game._update_attacks(0.02)
	check(game.boss_attack == "recover", "fan begins recovery after foxfires resolve")
	var hand: Vector2 = game._hand_position()
	var spawned_at_hand := true
	for fire in game.foxfires:
		spawned_at_hand = spawned_at_hand and fire.velocity.length() >= 259.0
	check(spawned_at_hand and hand.x > 0, "foxfires launch from hand at readable speed")
	game.foxfires.clear()
	game.facing = -1
	game.player.x = 540.0
	game._set_boss_state("teleport_vanish")
	game._update_attacks(0.3)
	game._update_attacks(0.6)
	check(game.boss_attack == "teleport_pause" and game.boss_x > game.player.x and game.boss_visible, "teleport appears behind player")
	game._update_attacks(0.59)
	check(game.boss_attack == "teleport_pause", "teleport visibly charges for 0.6 seconds")
	game._update_attacks(0.02)
	check(game.boss_attack == "teleport_recover" and game.foxfires.size() == 1, "teleport releases visible flame wave")
	game.foxfires.clear()
	game.boss_hp = 4
	check(is_equal_approx(game._windup(), 0.28), "half health reduces windup by 30 percent")
	game._set_boss_state("fan_windup")
	game._update_attacks(0.29)
	check(game.foxfires.size() == 1, "half health fan launches earlier")
	game.foxfires.clear()
	game.pattern_index = 2
	game._start_next_attack()
	check(game.boss_attack == "ground_windup" and game.ground_fires.size() == 3, "phase two replaces teleport with three ground fires")
	var ground_gap: float = game.ground_fires[1] - game.ground_fires[0]
	check(is_equal_approx(ground_gap, 110.0), "ground fires leave clear dodge gaps")
	var hp_before_ground: int = game.hp
	game._update_attacks(0.4)
	check(game.boss_attack == "ground_windup" and game.hp == hp_before_ground, "ground fire warns without early damage")
	game._update_attacks(0.46)
	check(game.boss_attack == "ground_burn", "ground fire starts after warning")
	game.player.x = (game.ground_fires[0] + game.ground_fires[1]) * 0.5
	game._update_attacks(0.3)
	check(game.hp == hp_before_ground and is_equal_approx(game._ground_height(), 161.0), "gap is safe at full fox height")
	game.player.y = game.FLOOR - 100.0
	game._update_attacks(game.GROUND_ACTIVE + 0.01)
	check(game.boss_attack == "recover" and game.ground_fires.is_empty() and game.hp == hp_before_ground, "jump clears ground fire until it ends")
	game.player = Vector2(game.boss_x + 35.0, game.FLOOR)
	game._set_boss_state("recover")
	game.hug_time = 1.49
	game._update_attacks(0.02)
	check(game.boss_attack == "backjump" and game.forced_fan, "hugging triggers backjump and fan")
	game._update_attacks(0.43)
	check(game.boss_attack == "fan_windup", "backjump leads into fan")
	game._set_boss_state("recover")
	game.player.x = game.boss_x - 40.0
	game.attack_facing = 1
	game.attack_time = 0.18
	game.hit_this_swing = false
	game.foxfires.clear()
	game.foxfires.append({"pos": game.player + Vector2(36, -38), "velocity": Vector2(-390, 0), "reflected": false})
	game._update_foxfires(0.01)
	check(game.foxfires[0].reflected, "J reflects fan foxfire")
	var old_hp: int = game.boss_hp
	game.foxfires[0].pos = Vector2(game.boss_x, game.FLOOR - 85.0)
	game._update_foxfires(0.001)
	check(game.boss_hp == old_hp - 2 and game.hit_stop > 0.0 and game.boss_flash > 0.0, "reflected hit flashes and stops")
	game.hit_stop = 0.0
	game.invincible = 0.0
	game.player = Vector2(game.boss_x + 5.0, game.FLOOR)
	var old_player_hp: int = game.hp
	game._damage_player()
	check(game.hp == old_player_hp - 1 and game.player_flash > 0.0 and game.hit_stop > 0.0, "player hit flashes and stops")
	game.hit_stop = 0.0
	game.invincible = 999.0
	game.boss_hp = 8
	game.foxfires.clear()
	game._set_boss_state("approach")
	game.boss_last_motion = 0.0
	var longest_idle := 0.0
	var observed := {}
	for i in 800:
		game._update_attacks(0.016)
		longest_idle = maxf(longest_idle, game.boss_last_motion)
		observed[game.boss_attack] = true
	check(longest_idle <= 4.0, "boss allows readable teleport charge and recovery")
	check(observed.has("backjump") and observed.has("dash") and observed.has("fan_windup") and observed.has("teleport_pause"), "movement and all three attacks cycle")
	game.boss_hp = 1
	game._hit_boss(1)
	check(game.phase == "dialogue" and game.after_lines == "peace" and game.foxfires.is_empty(), "victory starts ending dialogue and clears foxfires")
	check("|".join(game.lines).contains("收下一杯喜酒") and "|".join(game.lines).contains("杯子拿着就行。酒我喝"), "ending resolves taboo through the offered cup")
	check("|".join(game.lines).contains("喜欢的人类姑娘") and "|".join(game.lines).contains("她今天嫁给别人") and "|".join(game.lines).contains("只要有人记得，你就一直存在") and "|".join(game.lines).contains("我记住了"), "ending links the human bride to the memory theme")
	for i in game.lines.size():
		game._next_line()
	check(game.phase == "peace", "finishing ending dialogue completes the scene")
	game.queue_free()
	await process_frame
	print("Chapter 3 fox boss: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

