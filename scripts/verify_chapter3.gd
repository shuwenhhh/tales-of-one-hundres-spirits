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
	check(game.BOSS_WALK.size() == 3 and game.BOSS_JUMP != null and game.BOSS_CAST != null, "walk, jump and cast sprites load")
	game.player.x = 559.0
	game._physics_process(0.016)
	check(game.phase == "dialogue", "approach starts dialogue")
	for i in game.lines.size():
		game._next_line()
	check(game.phase == "battle", "dialogue starts battle")
	var start_x: float = game.boss_x
	game._update_attacks(0.25)
	check(game.boss_x > start_x, "boss walks toward player")
	game._start_next_attack()
	check(game.boss_attack == "dash_windup", "first pattern is dash")
	game._update_attacks(0.39)
	check(game.boss_attack == "dash_windup", "dash waits for white flash")
	game._update_attacks(0.02)
	check(game.boss_attack == "dash", "dash starts after 0.4 seconds")
	var dash_origin: float = game.boss_x
	game.player.y = game.FLOOR - 100.0
	game._update_attacks(0.2)
	check(game.boss_x - dash_origin > 100.0 and game.hp == game.MAX_PLAYER_HP, "dash travels and jump avoids hit")
	game.player.y = game.FLOOR
	game._set_boss_state("fan_windup")
	game._update_attacks(0.39)
	check(game.foxfires.is_empty(), "fan has prefire warning")
	game._update_attacks(0.02)
	check(game.foxfires.size() == 3, "fan fires exactly three foxfires")
	var hand: Vector2 = game._hand_position()
	var spawned_at_hand := true
	for fire in game.foxfires:
		spawned_at_hand = spawned_at_hand and fire.pos.distance_to(hand) < 0.01 and fire.velocity.length() >= 389.0
	check(spawned_at_hand, "foxfires come from hand at doubled speed")
	game.foxfires.clear()
	game._set_boss_state("teleport_vanish")
	game.boss_visible = false
	game.facing = -1
	game.player.x = 540.0
	game._update_attacks(0.19)
	check(game.boss_attack == "teleport_pause" and game.boss_x > game.player.x and game.boss_visible, "teleport appears behind player")
	game._update_attacks(0.29)
	check(game.boss_attack == "teleport_pause", "teleport pauses 0.3 seconds")
	game._update_attacks(0.02)
	check(game.boss_attack == "teleport_strike", "teleport strikes after pause")
	game.boss_hp = 4
	check(is_equal_approx(game._windup(), 0.28), "half health reduces windup by 30 percent")
	game._set_boss_state("fan_windup")
	game._update_attacks(0.29)
	check(game.foxfires.size() == 3, "half health fan launches earlier")
	game.foxfires.clear()
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
	check(longest_idle <= 1.5, "boss never remains motionless longer than 1.5 seconds")
	check(observed.has("backjump") and observed.has("dash") and observed.has("fan_windup") and observed.has("teleport_pause"), "movement and all three attacks cycle")
	game.boss_hp = 1
	game._hit_boss(1)
	check(game.phase == "peace" and game.foxfires.is_empty(), "victory clears foxfires")
	game.queue_free()
	await process_frame
	print("Chapter 3 fox boss: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
