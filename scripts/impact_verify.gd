extends SceneTree
var game
var failures := 0
func check(ok: bool, label: String):
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: failures += 1
func ticks(n: int):
	for i in n: game._physics_process(1.0/60)
func _initialize():
	call_deferred("run")
func run():
	game = load("res://chapter1.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.phase = "battle"
	game.player = Vector2(650,429)
	game.boss = Vector2(735,429)
	game.boss_state = "recover"
	game.begin_attack()
	ticks(3)
	check(game.resolve == 30 and game.thrust_extension() == 0, "anticipation does not hit")
	ticks(3)
	check(game.resolve == 29 and game.hit_stop > 0, "fast thrust triggers one impact")
	check(game.hit_feedback > 0, "normal combat still displays its impact splash")
	check(game.hit_audio.playing and game.swing_played, "swing and impact audio triggered")
	var before: float = game.boss_time
	var attack_before: float = game.attack
	game.begin_attack(true)
	check(game.buffered_attack > 0 and game.buffered_up, "upward input buffered during stop")
	ticks(2)
	check(game.boss_time == before and game.attack == attack_before, "combat and attack freeze together")
	game.queue_redraw()
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview_impact.png")
	ticks(23)
	check(game.hit_stop == 0 and game.attack_up and game.attack > 0, "buffered attack resumes without repeated key press")
	ticks(40)
	check(game.recoil == 0 and game.shake_time == 0, "feedback returns to rest")
	check(game.hit_feedback == 0, "ordinary hit splash expires after the attack")
	check(game.resolve == 28, "two distinct buffered swings each damage once")
	game.phase = "explore"
	game.attack_cd = 0
	game.begin_attack()
	ticks(10)
	check(game.hit_stop == 0 and game.shake_time == 0, "miss has no impact pause or shake")
	game.hit_stop = 0.065
	game.paused = true
	ticks(10)
	check(game.hit_stop == 0.065, "pause preserves hit stop")
	game.paused = false
	game.retry()
	check(game.hit_stop == 0 and game.buffered_attack == 0, "retry clears pending feedback and input")
	game.player = Vector2(650, game.FLOOR_Y)
	game.facing = 1
	game.boss_state = "recover"
	game.resolve = 1
	game.begin_attack()
	ticks(6)
	check(game.phase == "dialogue" and game.resolve == 0, "real final hit enters the closing conversation")
	check(game.hit_feedback == 0, "final-hit splash clears immediately on dialogue entry")
	for i in range(4):
		game.next_line()
		ticks(15)
	check(game.hit_feedback == 0, "advancing dialogue cannot leave a suspended splash")
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute("res://art_review/impact")
		game.dialogue_box.show_line("Xiaoyu: Did you ever get them?")
		game.dialogue_box.reveal_or_continue()
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art_review/impact/cleared_dialogue_splash.png")
	game.hit_feedback = .2
	game.hit_stop = 0
	game.phase = "failed"
	ticks(30)
	check(game.hit_feedback == 0, "failure state also expires any remaining splash")
	game.swing_audio.stop()
	game.hit_audio.stop()
	game.queue_free()
	await process_frame
	print("IMPACT RESULT: %d failures" % failures)
	quit(failures)
