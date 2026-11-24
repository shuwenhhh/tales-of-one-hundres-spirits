extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func run() -> void:
	var game = load("res://chapter3.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.phase = "battle"
	game.boss_visible = true
	game.foxfires.clear()
	game.invincible = 0.0
	game.player = Vector2(320.0, game.FLOOR)
	game.boss_x = 300.0
	game._set_boss_state("approach")
	var hp_before: int = game.hp
	game._update_attacks(0.016)
	check(game.hp == hp_before, "ordinary boss movement and body contact do not damage player")
	check(absf(game.player.x - game.boss_x) >= game.BODY_GAP, "ordinary boss movement separates grounded bodies")
	game.boss_x = 400.0
	game.player = Vector2(398.0, game.FLOOR)
	game._keep_player_out_of_boss(450.0)
	check(game.player.x >= game.boss_x + game.BODY_GAP and game.hp == hp_before, "player cannot walk through boss")
	game.boss_x = 300.0
	game.player = Vector2(500.0, game.FLOOR)
	game.invincible = 0.0
	game._set_boss_state("dash")
	game.dash_target = 740.0
	check(game._boss_texture() == game.BOSS_JUMP, "dash uses a leap pose instead of walking sprite")
	game._update_attacks(0.4)
	check(game.hp == hp_before - 1 and game.boss_attack == "recover", "dash deals one telegraphed attack hit")
	check(game.boss_x < game.player.x and absf(game.player.x - game.boss_x) >= game.BODY_GAP, "dash stops at player instead of passing through")
	game.hit_stop = 0.0
	game.invincible = 0.0
	game.foxfires.clear()
	game.player = Vector2(600.0, game.FLOOR)
	game.boss_x = 400.0
	game.facing = -1
	game._set_boss_state("teleport_vanish")
	game.boss_visible = false
	game._update_attacks(0.3)
	game._update_attacks(0.6)
	check(game.boss_attack == "teleport_pause" and game.boss_x > game.player.x, "teleport appears behind player")
	game._update_attacks(0.61)
	game._update_attacks(0.2)
	check(game.boss_attack == "teleport_recover" and absf(game.player.x - game.boss_x) >= game.BODY_GAP, "teleport strike stops at player")
	game.player = Vector2(925.0, game.FLOOR)
	game.facing = -1
	game.boss_x = 500.0
	game._set_boss_state("teleport_vanish")
	game.boss_visible = false
	game._update_attacks(0.3)
	game._update_attacks(0.6)
	check(game.boss_x >= game.BOSS_MIN_X and game.boss_x <= game.BOSS_MAX_X and absf(game.player.x - game.boss_x) >= game.BODY_GAP, "right edge teleport remains visible and separate")
	game.player = Vector2(35.0, game.FLOOR)
	game.facing = 1
	game.boss_x = 500.0
	game._set_boss_state("teleport_vanish")
	game.boss_visible = false
	game._update_attacks(0.3)
	game._update_attacks(0.6)
	check(game.boss_x >= game.BOSS_MIN_X and game.boss_x <= game.BOSS_MAX_X and absf(game.player.x - game.boss_x) >= game.BODY_GAP, "left edge teleport remains visible and separate")
	check(game.BOSS_MIN_X >= 104.0 and game.BOSS_MAX_X <= 856.0, "boss bounds include tail and wide attack pose")
	game.queue_free()
	await process_frame
	print("Chapter 3 collision: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

