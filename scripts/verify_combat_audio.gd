extends SceneTree

var failures: int = 0
var counts: Dictionary = {}

func check(condition: bool, message: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + message)
	if not condition:
		failures += 1

func heard(cue: StringName) -> void:
	counts[cue] = counts.get(cue, 0) + 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://chapter1.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.combat_sounds.cue_played.connect(heard)
	game.retry()
	game.enter_boss_state("diagonal_cast")
	check(counts.get(&"silk_charge", 0) == 1, "silk windup plays once on state entry")
	game.update_boss(.86)
	check(game.bullets.size() == 3 and counts.get(&"silk_shot", 0) == 1, "three-way shot plays one release")
	game.update_boss(.02)
	check(counts.get(&"silk_shot", 0) == 1, "release does not repeat on later frames")
	game.bullets.clear()
	game.enter_boss_state("air_charge")
	game.update_boss(1.01)
	check(game.bullets.size() == 8 and counts.get(&"silk_burst", 0) == 1, "eight-way silk burst uses one layered sound")
	check(not game.combat_sounds.players["silk_charge"].playing, "release cancels charge sound")
	game.bullets.clear()
	game.enter_boss_state("cast")
	game.update_boss(.86)
	game.update_boss(.01)
	game.update_boss(.85)
	game.update_boss(.85)
	check(counts.get(&"silk_shot", 0) == 4, "each of three sequential shots has its own release")
	counts.clear()
	game.retry()
	game.player.x = 100
	game.begin_attack()
	for tick in range(15):
		game._physics_process(1.0 / 60.0)
	check(counts.get(&"umbrella_swing", 0) == 1 and counts.get(&"umbrella_hit", 0) == 0, "a miss plays only one swing")
	counts.clear()
	game.retry()
	game.player.x = 650
	game.boss_state = "recover"
	game.begin_attack()
	for tick in range(20):
		game._physics_process(1.0 / 60.0)
	check(counts.get(&"umbrella_hit", 0) == 1 and game.resolve == game.MAX_RESOLVE - 1, "confirmed contact plays one impact during hit-stop")
	game.paused = true
	game._physics_process(.016)
	check(not game.hit_audio.playing and not game.swing_audio.playing, "pausing silences combat sounds")
	game.queue_free()
	await process_frame
	counts.clear()
	var second = load("res://chapter2.tscn").instantiate()
	root.add_child(second)
	second.set_physics_process(false)
	second.combat_sounds.cue_played.connect(heard)
	second.phase = "battle"
	second.x = 600
	second.boss_x = 660
	second.facing = 1
	second.attack_time = .31
	second.attack_cooldown = .43
	for tick in range(15):
		second._physics_process(1.0 / 60.0)
	check(counts.get(&"umbrella_swing", 0) == 1 and counts.get(&"umbrella_hit", 0) == 1, "chapter two also separates swing and confirmed impact")
	second.queue_free()
	await process_frame
	print("COMBAT AUDIO RESULT: ", failures, " failures")
	quit(failures)
