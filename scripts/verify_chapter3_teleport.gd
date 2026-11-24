extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://chapter3.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.phase = "battle"
	game.player = Vector2(500, game.FLOOR)
	game.facing = 1
	game._set_boss_state("teleport_vanish")
	var landing: float = game.teleport_landing
	var initial_hp: int = game.hp
	game._update_attacks(0.3)
	assert(game.boss_attack == "teleport_preview" and not game.boss_visible)
	game.player.x += 50
	game._update_attacks(0.59)
	assert(game.teleport_landing == landing and not game.boss_visible and game.hp == initial_hp)
	game._update_attacks(0.02)
	assert(game.boss_visible and game.boss_x == landing and game.player_flash == 0)
	game._update_attacks(0.59)
	assert(game.foxfires.is_empty() and game.hp == initial_hp)
	game._update_attacks(0.02)
	assert(game.foxfires.size() == 1 and game.boss_attack == "teleport_recover")
	game.player.y = game.FLOOR - 100
	for i in 45:
		game._update_attacks(0.016)
	assert(game.hp == initial_hp and game.boss_attack == "teleport_recover")
	game.foxfires.clear()
	game._update_attacks(0.2)
	assert(game.boss_attack == "approach")
	print("Teleport: warning, fixed landing, no contact damage, jump dodge and recovery passed")
	game.queue_free()
	quit()
