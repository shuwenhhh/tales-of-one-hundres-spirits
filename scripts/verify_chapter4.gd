extends SceneTree

const JOURNEY := preload("res://scripts/journey_state.gd")
const SCENE := "res://chapter4.tscn"
var failed := false

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# Run with an isolated APPDATA so progress checks cannot touch a player's save.
	if not "spirits-ch4-check" in OS.get_environment("APPDATA"):
		quit(2)
		return
	JOURNEY.complete_chapter("res://chapter3.tscn")
	var gallery = preload("res://scripts/chapter_gallery.gd").new()
	root.add_child(gallery)
	check(gallery.cards.back().get_meta("scene") == SCENE, "Missing chapter selection card")
	gallery.queue_free()
	var game = load(SCENE).instantiate()
	root.add_child(game)
	game.player.x = game.BOSS_X - 140
	game._physics_process(0.016)
	check(game.phase == "explore", "Dialogue triggered away from the stall")
	game.player.x = game.BOSS_X - 80
	game._physics_process(0.016)
	check(game.phase == "dialogue" and game.mood == 0, "Opening smile")
	while game.phase == "dialogue":
		game._next_line()
	for mood in 3:
		check(game.mood == mood and game.stage == "warning", "Expected attack warning")
		game.player.x = game.boss_x
		var before: int = game.hp
		game._update_attacks(0.66)
		check(game.hp == before, "Warning dealt damage")
		game.invincible = 0
		game._update_attacks(0.016)
		check(game.hp == before - 1 and game.hit_feedback > 0, "Missing contact damage or impact")
		game._update_attacks(0.016)
		check(game.hp == before - 1, "Contact ignored invulnerability")
		if mood == 1:
			check(game.boss_rise > 0, "Missing bounce")
		game.player.y = 100
		while game.stage == "active":
			game._update_attacks(0.016)
		game._update_attacks(1.16)
		game.player.y = game.FLOOR
	game.stage = "recover"
	game.player.x = game.boss_x - 50
	game.attack_facing = 1
	game.attack_time = 0.2
	game.hit_stop = 0
	game._physics_process(0.016)
	check(game.boss_hp == game.MAX_BOSS_HP - 1 and game.boss_flash > 0, "Umbrella strike missed")
	game._hit_boss(game.boss_hp)
	check(game.phase == "dialogue" and game.after_lines == "peace", "Missing ending")
	while game.phase == "dialogue":
		game._next_line()
	check(game.phase == "peace" and SCENE in JOURNEY.completed_chapters(), "Completion not saved")
	game.queue_free()
	await process_frame
	await process_frame
	print("Chapter four checks ", "FAILED" if failed else "passed")
	quit(1 if failed else 0)

