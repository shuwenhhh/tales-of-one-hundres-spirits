extends Node2D

const JOURNEY := preload("res://scripts/journey_state.gd")
const TRANSITION := preload("res://scripts/scene_transition.gd")
const SILK_LESSON := "[silk_guard_lesson]"

const FLOOR_Y = 429.0
const WALK_SPEED := 120.0
const SAVE_PATH = "user://chapter1_memory.cfg"
const MAX_RESOLVE = 30
const NEXT_CHAPTER := "res://chapter2.tscn"
const RIGHT_EXIT_X := 925.0
const BODY_GAP := 84.0
const HIT_GAP := 90.0
# The art's walking surface is at 84% height; map it to the gameplay floor.
const BACKGROUND_ROAD_Y := 0.84
const ASCENT_BOUNDS := [Rect2(97,153,116,87), Rect2(108,132,114,108), Rect2(87,127,128,133), Rect2(69,130,145,122), Rect2(81,131,126,124), Rect2(93,126,121,117)]
const LANDING_BOUNDS := [Rect2(106,123,117,106), Rect2(105,109,105,148), Rect2(100,90,115,144), Rect2(99,170,139,70), Rect2(102,160,135,80), Rect2(101,134,113,106)]
const ASCENT_HEIGHTS := [130.0, 130.0, 130.0, 130.0, 130.0, 130.0]
const LANDING_HEIGHTS := [130.0, 130.0, 130.0, 92.0, 96.0, 116.0]
var background: Texture2D
var font = preload("res://assets/chapter1/chinese.ttc")
var frames: Array[Texture2D] = []
var granny: Texture2D
var spinning = preload("res://scripts/spinning_work.gd").new()
var met_granny: bool = false
var granny_stood: bool = false
var rise_time: float = 0.0
const RISE_DURATION := 1.1
var boss_frames: Array[Texture2D] = []
var ascent_frames: Array[Texture2D] = []
var landing_frames: Array[Texture2D] = []
var umbrella: Texture2D
var umbrella_long: Texture2D
var player = Vector2(165, FLOOR_Y)
var boss = Vector2(735, FLOOR_Y)
var vy = 0.0
var facing = 1
var moving = false
var walk = preload("res://scripts/hero_walk.gd").new()
var silk_guard = preload("res://scripts/silk_guard.gd").new()
var inventory = preload("res://scripts/inventory_panel.gd").new()
var guard_practiced: bool = false
var lesson_prompt: Label
var lesson_reveal: float = 0.0
var hp = 6
var resolve = MAX_RESOLVE
var phase = "explore"
var clock_time = 0.0
var dash = 0.0
var dash_speed: float = 490.0
var dash_cd = 0.0
var invulnerable = 0.0
var attack = 0.0
var attack_cd = 0.0
var attack_hit = false
var attack_up := false
var attack_facing := 1
var hit_position := Vector2.ZERO
var hit_stop := 0.0
var recoil := 0.0
var shake_time := 0.0
var feedback_clock := 0.0
var world_offset := Vector2.ZERO
var buffered_attack := 0.0
var buffered_up := false
var swing_played := false
var reduce_shake := false
var swing_audio: AudioStreamPlayer
var hit_audio: AudioStreamPlayer
var combat_sounds = preload("res://scripts/combat_sounds.gd").new()
var recovery_hit = false
var hit_feedback = 0.0
var boss_state = "rest"
var boss_time = 0.0
var boss_direction = -1
var boss_origin := Vector2.ZERO
var boss_target := Vector2.ZERO
var impact_time := 0.0
var attack_number = 0
var boss_rng := RandomNumberGenerator.new()
var last_boss_attack: String = ""
var ground_attacks: int = 0
var recovery_duration: float = 1.6
var rest_duration: float = 1.0
var ground_hit_count: int = 0
var last_ground_hit: float = -10.0
var evading: bool = false
var evasion_target_x: float = 0.0
var volley_shots: int = 0
var silk_aim := Vector2.ZERO
var bullets: Array[Dictionary] = []
var rain: Array[Vector2] = []
var weather = preload("res://scripts/rain_weather.gd").new()
var dialogue: Array[String] = []
var dialogue_box = preload("res://scripts/dialogue_box.gd").new()
var story_portraits: Texture2D
var story_panic: Texture2D
var story_memories: Texture2D
var story_sky_dream: Texture2D
var story_free_moth: Texture2D
var story_silkworm: Texture2D
var story_cocoon: Texture2D
var line_index = 0
var panic_line_index = -1
var after_dialogue = "battle"
var memory = false
var memory_open = false
var paused = false
var equipped = true
var toast = ""
var toast_time = 0.0
var battle_time = 0.0
var test_mode = false
var save_path = SAVE_PATH

# Character art is pre-reduced to its on-screen size (tools/pixelize_sprites.py):
# one art pixel == one screen pixel, sampled NEAREST so every character shares
# the background's pixel grid. Text and UI keep the node's LINEAR filter.
static func pixel_texture(path: String) -> Texture2D:
	var tex := CanvasTexture.new()
	tex.diffuse_texture = load(path)
	tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return tex

func _ready():
	boss_rng.randomize()
	if not test_mode:
		JOURNEY.remember_chapter("res://chapter1.tscn")
		JOURNEY.apply_preferences()
		reduce_shake = bool(JOURNEY.preferences().get_value("settings", "reduce_shake", false))
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	walk.setup_audio(self)
	background = pixel_texture("res://assets/chapter1/backgrounds/rain_town_pixel_v1.png")
	combat_sounds.setup(self)
	dialogue_box.mount(self)
	story_portraits = pixel_texture("res://assets/chapter1/story_dialogue/portraits.png")
	story_panic = pixel_texture("res://assets/chapter1/story_dialogue/grandmother_panic.png")
	story_memories = pixel_texture("res://assets/chapter1/story_dialogue/memories.png")
	story_sky_dream = pixel_texture("res://assets/chapter1/story_dialogue/sky_dream.png")
	story_free_moth = pixel_texture("res://assets/chapter1/story_dialogue/free_moth.png")
	story_silkworm = pixel_texture("res://assets/chapter1/story_dialogue/silkworm.png")
	story_cocoon = pixel_texture("res://assets/chapter1/story_dialogue/cocoon.png")
	# Chapter One always begins before this playthrough's gift, even on old saves.
	silk_guard.setup(false)
	guard_practiced = JOURNEY.silk_guard_practiced()
	inventory.mount(self)
	lesson_prompt = Label.new()
	lesson_prompt.text = "Press K · Open the umbrella"
	lesson_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lesson_prompt.add_theme_font_override("font", font)
	lesson_prompt.add_theme_font_size_override("font_size", 18)
	lesson_prompt.add_theme_color_override("font_color", Color("e7dbc3"))
	lesson_prompt.add_theme_color_override("font_shadow_color", Color("111827"))
	lesson_prompt.add_theme_constant_override("shadow_offset_y", 2)
	dialogue_box.get_parent().add_child(lesson_prompt)
	lesson_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	lesson_prompt.offset_top = -90
	lesson_prompt.offset_bottom = -52
	lesson_prompt.hide()
	swing_audio = combat_sounds.players["umbrella_swing"]
	hit_audio = combat_sounds.players["umbrella_hit"]
	for i in 6:
		frames.append(pixel_texture("res://assets/chapter1/pixel/girl/pose_%d.png" % i))
	for i in 6:
		boss_frames.append(pixel_texture("res://assets/chapter1/pixel/granny/pose_%d.png" % i))
		ascent_frames.append(pixel_texture("res://assets/chapter1/pixel/granny/ascent_%d.png" % i))
		landing_frames.append(pixel_texture("res://assets/chapter1/pixel/granny/landing_%d.png" % i))
	granny = boss_frames[0]
	umbrella = pixel_texture("res://assets/chapter1/pixel/girl/umbrella.png")
	umbrella_long = pixel_texture("res://assets/chapter1/pixel/girl/umbrella_long.png")
	weather.reset(Vector2(960, 540))
	rain = weather.drops
	var cfg = ConfigFile.new()
	if not test_mode and cfg.load(save_path) == OK:
		memory = cfg.get_value("story", "silkworm", false)
	if not test_mode:
		memory = memory or "res://chapter1.tscn" in JOURNEY.completed_chapters()
	queue_redraw()

func _unhandled_key_input(event):
	if not event.pressed or event.echo:
		return
	var key = event.physical_keycode
	if event.is_action_pressed(&"open_inventory") and not paused and not memory_open and phase in ["explore", "battle", "peace"]:
		if inventory.opened:
			inventory.close()
		else:
			silk_guard.cancel()
			walk.stop_audio()
			combat_sounds.stop_all()
			inventory.present(silk_guard.enabled)
		return
	if inventory.opened:
		return
	if key == KEY_F6:
		reduce_shake = not reduce_shake
		if not test_mode:
			JOURNEY.set_preference("reduce_shake", reduce_shake)
		return
	if key == KEY_Q and paused:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	if key == KEY_ESCAPE:
		if memory_open:
			memory_open = false
		else:
			paused = not paused
		queue_redraw()
		return
	if key == KEY_M:
		memory_open = not memory_open
		queue_redraw()
		return
	if paused or memory_open:
		walk.stop_audio()
		return
	if phase == "leaving":
		return
	if phase == "standing":
		return
	if phase == "failed":
		if key == KEY_R:
			retry()
		return
	if phase == "silk_lesson":
		if silk_guard.handle_input(event, facing) and silk_guard.active():
			equipped = true
			phase = "silk_reveal"
			lesson_reveal = .95
			silk_guard.deflect()
			combat_sounds.play("umbrella_swing")
		return
	if phase == "silk_reveal":
		return
	if phase == "dialogue":
		if key in [KEY_E, KEY_ENTER, KEY_SPACE]:
			if dialogue_box.reveal_or_continue():
				next_line()
		return
	if silk_guard.handle_input(event, facing):
		if silk_guard.active():
			equipped = true
			attack = 0
			buffered_attack = 0
			dash = 0
			walk.stop_audio()
			combat_sounds.play("umbrella_swing")
		return
	if silk_guard.active():
		return
	if key in [KEY_SPACE, KEY_SHIFT]:
		silk_guard.interrupt_close()
	if key == KEY_E and absf(player.x - boss.x) < 110 and phase in ["explore", "peace"]:
		interact()
	if key == KEY_1:
		equipped = not equipped
		attack = 0
		buffered_attack = 0
	if key == KEY_SPACE and player.y >= FLOOR_Y - 1:
		vy = -355
	if key == KEY_SHIFT and dash_cd <= 0:
		var direction := int(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		if direction != 0:
			facing = direction
		dash_speed = 490.0
		var gap_ahead: float = (boss.x - player.x) * facing
		if phase == "battle" and bodies_overlap_vertically() and gap_ahead >= 0.0 and gap_ahead <= BODY_GAP + 26.0:
			# Cover the whole cloak in one dash instead of ending inside it and
			# being pushed back into the corner when ordinary collision resumes.
			var exit_x := clampf(boss.x + facing * (BODY_GAP + 4.0), 30.0, 930.0)
			dash_speed = maxf(dash_speed, absf(exit_x - player.x) / .18)
		dash = 0.18
		dash_cd = 0.9
		invulnerable = maxf(invulnerable, 0.23)
	if key == KEY_J:
		begin_attack()

func begin_attack(upward: bool = false):
	if silk_guard.active():
		return
	silk_guard.interrupt_close()
	if equipped and phase in ["battle", "explore", "peace"] and (hit_stop > 0 or (attack_cd > 0 and attack_cd < 0.16)):
		buffered_attack = maxf(0.18, attack_cd + 0.04)
		buffered_up = upward or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
		return
	if equipped and attack_cd <= 0 and phase in ["battle", "explore", "peace"]:
		attack_up = upward or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
		attack_facing = facing
		attack = 0.34
		attack_cd = 0.42
		swing_played = false
		attack_hit = false

func interact():
	if phase not in ["explore", "peace"]:
		return
	met_granny = true
	if phase == "peace":
		start_dialogue([
			"Grandmother: Is it still raining?",
			"Xiaoyu: No. It hasn't stopped.",
		], "peace")
	else:
		start_dialogue([
			"Xiaoyu: AH! You scared me!",
			"Xiaoyu: Oh... Hello, Grandma!",
			"Grandmother: Oh! A little visitor!",
			"Grandmother: How old are you, sweetie? Seven? Eight?",
			"Xiaoyu: I'm not THAT little!",
			"Grandmother: Ho ho! Of course not.",
			"Grandmother: What brings you out in this weather?",
			"Xiaoyu: I got lost...",
			"Grandmother: Oh, you poor thing.",
			"Grandmother: Come along. Grandma has candy!",
			"Xiaoyu: Really?!",
			"Grandmother: Unless I've eaten it all.",
			"Xiaoyu: ...",
			"Grandmother: Ho ho! Just kidding!",
			"Xiaoyu: Hehe...",
			"Xiaoyu: ...Is it just me, or is it really hot here?",
			"Grandmother: Hot?",
			"Xiaoyu: Yeah. I'm sweating.",
			"Xiaoyu: But it's raining...",
			"Grandmother: ...",
			"Grandmother: Hot...",
			"Grandmother: Yes. It is hot.",
			"Grandmother: Very... hot...",
			"Xiaoyu: Grandma?",
			"Grandmother: AAAAAAH!!",
			"Grandmother: HOT! HOT! HOT!!",
			"Xiaoyu: W-WHAT?!",
			"Grandmother: IT BURNS!!",
			"Xiaoyu: Grandma! It's raining!",
			"Grandmother: THEN WHY WON'T IT STOP?!",
			"Xiaoyu: What won't stop?!",
			"Grandmother: The water...",
			"Grandmother: I can hear it boiling...",
			"Xiaoyu: ...Grandma?",
			"Grandmother: Please...",
			"Grandmother: Make it stop.",
		], "battle")

func start_dialogue(lines: Array[String], next_phase: String):
	silk_guard.cancel()
	walk.stop_audio()
	combat_sounds.stop("silk_charge")
	var story_breaks := PackedStringArray()
	if next_phase == "peace" and resolve <= 0:
		story_breaks = PackedStringArray(["I used to be a silkworm", "I made myself a little cocoon", "I thought if I waited", "I dreamed I could fly", "Someone put my cocoon", "They wanted the silk", "I suppose they had no use", "Now, take this"])
	elif next_phase == "battle":
		story_breaks = PackedStringArray(["Hot...", "Yes. It is hot.", "Very... hot...", "AAAAAAH!!", "HOT! HOT! HOT!!", "IT BURNS!!", "The water...", "I can hear it boiling...", "Please...", "Make it stop."])
	dialogue = dialogue_box.merge_lines(lines, 2 if next_phase == "battle" and not granny_stood else 0, story_breaks)
	line_index = 0
	panic_line_index = -1
	if next_phase == "battle":
		for i in dialogue.size():
			if dialogue[i].contains("HOT! HOT! HOT!!"):
				panic_line_index = i
				break
	after_dialogue = next_phase
	phase = "dialogue"
	moving = false
	hit_stop = 0
	hit_feedback = 0.0
	buffered_attack = 0
	attack = 0
	dash = 0
	dash_speed = 490.0
	vy = 0
	player.y = FLOOR_Y
	dialogue_box.show_line(dialogue[0])
	if not test_mode:
		if next_phase == "battle":
			JOURNEY.meet_chapter("res://chapter1.tscn", dialogue)
		elif next_phase == "peace" and resolve <= 0:
			var recorded: Array[String] = []
			for entry: String in dialogue:
				if entry != SILK_LESSON:
					recorded.append(entry)
			JOURNEY.complete_chapter("res://chapter1.tscn", recorded)

func next_line():
	line_index += 1
	if line_index < dialogue.size() and dialogue[line_index] == SILK_LESSON:
		silk_guard.enabled = true
		if not guard_practiced:
			phase = "silk_lesson"
			silk_guard.cooldown = 0
			silk_guard.cancel()
			dialogue_box.hide()
			return
		line_index += 1
	if line_index < dialogue.size():
		dialogue_box.show_line(dialogue[line_index])
	if line_index >= dialogue.size():
		dialogue_box.hide()
		phase = after_dialogue
		if phase == "battle":
			# The portrait conversation stays continuous; stand when combat begins.
			granny_stood = true
			rise_time = RISE_DURATION
			boss_state = "rest"
			boss_time = 0
			toast_time = 0
		elif phase == "peace" and resolve <= 0:
			unlock_memory()

func enter_next_chapter() -> void:
	silk_guard.cancel()
	walk.stop_audio()
	combat_sounds.stop_all()
	var error := TRANSITION.start(get_tree(), NEXT_CHAPTER, _chapter_transition_failed)
	if error != OK:
		_chapter_transition_failed(error)

func _chapter_transition_failed(error: Error) -> void:
	phase = "peace"
	toast = "Could not load the Peach Blossom Garden."
	toast_time = 12.0
	push_warning("Chapter transition failed: %s" % error)

func unlock_memory():
	memory = true
	if not test_mode:
		var cfg = ConfigFile.new()
		cfg.set_value("story", "silkworm", true)
		var error = cfg.save(save_path)
		if error != OK:
			push_warning("Could not save memory: " + str(error))

func retry():
	silk_guard.cancel()
	silk_guard.cooldown = 0
	combat_sounds.stop_all()
	met_granny = true
	granny_stood = true
	player = Vector2(550, FLOOR_Y)
	boss = Vector2(735, FLOOR_Y)
	boss_origin = boss
	boss_target = boss
	boss_direction = -1
	impact_time = 0.0
	recovery_hit = false
	hit_feedback = 0.0
	hit_stop = 0
	recoil = 0
	shake_time = 0
	buffered_attack = 0
	hp = 6
	resolve = MAX_RESOLVE
	vy = 0
	dash = 0
	dash_cd = 0
	dash_speed = 490.0
	attack = 0
	attack_cd = 0
	attack_up = false
	equipped = true
	invulnerable = 1.5
	bullets.clear()
	boss_state = "rest"
	boss_time = 0
	attack_number = 0
	last_boss_attack = ""
	ground_attacks = 0
	recovery_duration = 1.6
	rest_duration = 1.0
	ground_hit_count = 0
	last_ground_hit = -10.0
	evading = false
	battle_time = 0
	phase = "battle"

func _process(delta: float) -> void:
	weather.advance(delta)
	queue_redraw()
	dialogue_box.visible = phase == "dialogue" and not paused and not memory_open and not inventory.opened
	lesson_prompt.visible = phase == "silk_lesson" and not paused and not memory_open
	if lesson_prompt.visible:
		lesson_prompt.anchor_right = 0
		lesson_prompt.offset_left = clampf(player.x - 170.0, 24.0, get_viewport_rect().size.x - 364.0)
		lesson_prompt.offset_right = lesson_prompt.offset_left + 340.0
	if dialogue_box.visible and dialogue_box.advance_time(delta, Input.is_physical_key_pressed(KEY_CTRL)):
		next_line()

func _physics_process(dt):
	if paused or memory_open or inventory.opened:
		walk.stop_audio()
		combat_sounds.stop_all()
		return
	if phase == "leaving":
		return
	silk_guard.advance(dt, phase in ["explore", "battle", "peace", "silk_lesson", "silk_reveal"])
	if phase == "silk_lesson":
		return
	if phase == "silk_reveal":
		lesson_reveal -= dt
		silk_guard.remaining = maxf(silk_guard.remaining, .12)
		if lesson_reveal <= 0:
			silk_guard.cancel()
			guard_practiced = true
			if not test_mode:
				var error := JOURNEY.unlock_silk_guard()
				if error != OK:
					push_warning("Could not save the silk gift: %s" % error)
			phase = "dialogue"
			next_line()
		return
	spinning.advance(dt, (phase == "explore" and not met_granny) or (phase == "dialogue" and after_dialogue == "battle" and line_index >= dialogue.size() - 3))
	if phase == "standing":
		rise_time = minf(RISE_DURATION, rise_time + dt)
		if rise_time >= RISE_DURATION:
			granny_stood = true
			phase = "dialogue"
		queue_redraw()
		return
	feedback_clock += dt
	shake_time = maxf(0, shake_time - dt)
	if hit_stop > 0:
		hit_stop = maxf(0, hit_stop - dt)
		queue_redraw()
		return
	recoil = maxf(0, recoil - dt)
	buffered_attack = maxf(0, buffered_attack - dt)
	clock_time += dt
	impact_time = maxf(0, impact_time - dt)
	toast_time = maxf(0, toast_time - dt)
	hit_feedback = maxf(0, hit_feedback - dt)
	if phase in ["dialogue", "failed"]:
		queue_redraw()
		return
	dash_cd = maxf(0, dash_cd - dt)
	invulnerable = maxf(0, invulnerable - dt)
	attack_cd = maxf(0, attack_cd - dt)
	var previous_attack: float = attack
	var previous_player: Vector2 = player
	var previous_boss: Vector2 = boss
	attack = maxf(0, attack - dt)
	if attack > 0 and attack <= 0.28 and not swing_played:
		swing_played = true
		combat_sounds.play("umbrella_swing")
	if buffered_attack > 0 and attack_cd <= 0:
		buffered_attack = 0
		begin_attack(buffered_up)
		previous_attack = attack
	var axis = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	if silk_guard.active():
		axis = 0
		facing = silk_guard.facing
	elif axis != 0:
		silk_guard.interrupt_close()
	moving = axis != 0
	var dash_active: bool = dash > 0.0
	if dash > 0:
		player.x += facing * dash_speed * dt
		dash -= dt
	else:
		player.x += axis * WALK_SPEED * dt
		if axis != 0:
			facing = int(axis)
	vy += 940 * dt
	player.y += vy * dt
	if player.y >= FLOOR_Y:
		player.y = FLOOR_Y
		vy = 0
	player.x = clampf(player.x, 30, 930)
	if phase == "peace" and resolve <= 0 and player.x >= RIGHT_EXIT_X and (axis > 0 or (dash > 0 and facing > 0)):
		phase = "leaving"
		call_deferred("enter_next_chapter")
		return
	if phase == "explore" and not met_granny and absf(player.x-boss.x) < 160.0 and player.y >= FLOOR_Y-1:
		facing = 1 if player.x < boss.x else -1
		interact()
		queue_redraw()
		return
	if phase == "battle":
		battle_time += dt
		update_boss(dt)
		resolve_body_overlap(previous_player, previous_boss, dash_active)
		update_bullets(dt)
		# Sample the moving weapon against the moving boss during the active part.
		# Each swing owns its hit flag; no hidden invulnerability between swings.
		if phase == "battle" and equipped and not attack_hit and previous_attack >= 0.14 and attack <= 0.28:
			var steps: int = maxi(8, int((player.distance_to(previous_player)+boss.distance_to(previous_boss))/4.0)+1)
			for i in range(steps+1):
				var t: float = float(i)/steps
				var remaining: float = lerpf(previous_attack,attack,t)
				if remaining > 0.28 or remaining < 0.14:
					continue
				if weapon_contacts(player.lerp(previous_player,1-t),boss.lerp(previous_boss,1-t),remaining):
					attack_hit = true
					resolve = maxi(0,resolve-1)
					trigger_impact()
					separate_after_hit(dash_active)
					if resolve <= 0:
						win_battle()
					else:
						respond_to_ground_hit()
					break

	moving = absf(player.x - previous_player.x) > 0.01
	walk.advance(player.x - previous_player.x, phase in ["explore", "battle", "peace"] and player.y >= FLOOR_Y and attack <= 0 and dash <= 0)
	queue_redraw()

func bodies_overlap_vertically() -> bool:
	return player.y > boss.y - 105.0 and player.y - 58.0 < boss.y - 8.0

func separate_bodies(gap: float, side: float, player_share: float) -> void:
	var missing: float = gap - (player.x - boss.x) * side
	if missing <= 0.0:
		return
	var old_boss_x: float = boss.x
	player.x = clampf(player.x + side * missing * player_share, 30.0, 930.0)
	var remaining := maxf(0.0, gap - (player.x - boss.x) * side)
	boss.x = clampf(boss.x - side * remaining, 95.0, 865.0)
	# Translate committed motion paths too, so the next frame cannot undo contact.
	var shift := Vector2(boss.x - old_boss_x, 0)
	boss_origin += shift
	boss_target += shift

func resolve_body_overlap(previous_player: Vector2, previous_boss: Vector2, dash_active: bool = false) -> void:
	# Only an active enemy blocks the road. Once calmed, she must not gate the exit.
	if phase != "battle" or not bodies_overlap_vertically():
		return
	# Include the final movement frame even if its dash timer just reached zero.
	if dash_active or dash > 0.0:
		return
	# Fast boss attacks retain their swept damage and can cross the player.
	# Their recovery/landing restores ordinary body spacing on the next frame.
	if boss_state in ["dash", "dive"] and phase == "battle":
		return
	var side := signf(previous_player.x - previous_boss.x)
	if side == 0.0:
		side = -float(facing)
	separate_bodies(BODY_GAP, side, 1.0)

func separate_after_hit(dash_active: bool = false) -> void:
	if dash_active or dash > 0.0:
		return
	if not bodies_overlap_vertically() or absf(player.y - boss.y) > 45.0:
		return
	var side := signf(player.x - boss.x)
	if side == 0.0:
		side = -float(attack_facing)
	# Stop adding distance once both actors are clearly separated, so combos reach.
	separate_bodies(HIT_GAP, side, 0.65)

func respond_to_ground_hit() -> void:
	if phase != "battle" or boss.y < FLOOR_Y - 10.0 or boss_state not in ["rest", "recover", "land", "cast", "volley", "diagonal_cast", "release"]:
		return
	ground_hit_count = ground_hit_count + 1 if battle_time - last_ground_hit <= 1.05 else 1
	last_ground_hit = battle_time
	if ground_hit_count >= 2:
		var away := signf(boss.x - player.x)
		if away == 0.0:
			away = -float(facing)
		var retreat: float = clampf(boss.x + away * 110.0, 95.0, 865.0)
		# At a wall, lift off in place rather than bulldozing the player sideways.
		if absf(retreat - boss.x) < 55.0:
			retreat = boss.x
		enter_boss_state("sidestep")
		evading = true
		evasion_target_x = retreat
		ground_hit_count = 0
	elif boss_state == "recover":
		recovery_duration = minf(recovery_duration, boss_time + .40)
	elif boss_state == "rest":
		rest_duration = minf(rest_duration, boss_time + .18)

func flight_target_from_player(spacing: float, height: float) -> Vector2:
	# Prefer the near side but sometimes cross over; switch again if the wall
	# cannot fit the spacing. Sample once per flight phase, never home.
	var side := signf(boss.x - player.x)
	if side == 0.0:
		side = -float(facing)
	if boss_rng.randf() < .35:
		side *= -1.0
	var target_x: float = player.x + side * spacing
	if target_x < 100.0 or target_x > 860.0:
		target_x = player.x - side * spacing
	return Vector2(clampf(target_x, 100.0, 860.0), height)

func choose_boss_attack() -> String:
	var distance: float = absf(player.x - boss.x)
	var weights := {"diagonal_cast": 3.8, "cast": 2.4, "dash_prepare": 2.0, "wrap": 1.4}
	if distance < 145.0:
		weights = {"diagonal_cast": 1.8, "cast": .35, "dash_prepare": .9, "wrap": 3.6}
	elif distance > 340.0:
		weights = {"diagonal_cast": 3.8, "cast": .7, "dash_prepare": 3.0, "wrap": 2.4}
	if player.y < FLOOR_Y - 45.0:
		weights.diagonal_cast *= 2.6
		weights.cast *= .2
		weights.dash_prepare *= .5
	# Let the ground vocabulary play out before the aerial pattern returns.
	if ground_attacks < 3:
		weights.wrap = 0.0
	elif ground_attacks >= 4:
		weights.wrap *= 2.0
	if not last_boss_attack.is_empty():
		weights[last_boss_attack] *= .12
	var total := 0.0
	for weight: float in weights.values():
		total += weight
	var roll := boss_rng.randf() * total
	for state: String in weights:
		roll -= float(weights[state])
		if roll <= 0.0:
			return state
	return "diagonal_cast"

func aimed_silk_origin() -> Vector2:
	# Emit beside the extended arm at chest height. The old high, far-forward
	# origin made every strand point steeply into the road at melee distance.
	return boss + Vector2(boss_direction * 40.0, -50.0)

func update_boss(dt):
	boss_time += dt
	match boss_state:
		"sidestep":
			boss.x = move_toward(boss.x, evasion_target_x, 360.0 * dt)
			if boss_time >= .38:
				enter_boss_state("rest")
		"rest":
			if absf(player.x - boss.x) > 155:
				boss.x = move_toward(boss.x, player.x, 80 * dt)
			boss_direction = -1 if player.x < boss.x else 1
			if boss_time >= rest_duration:
				boss_direction = -1 if player.x < boss.x else 1
				var chosen := choose_boss_attack()
				last_boss_attack = chosen
				ground_attacks = 0 if chosen == "wrap" else ground_attacks + 1
				enter_boss_state(chosen)
		"diagonal_cast":
			# Track the windup, then commit for its last 0.2 seconds.
			if boss_time - dt < .65:
				silk_aim = player + Vector2(0, -36)
				boss_direction = -1 if silk_aim.x < boss.x else 1
			if boss_time >= 0.85:
				combat_sounds.play("silk_shot")
				for offset in [-0.32, 0.0, 0.32]:
					var origin: Vector2 = aimed_silk_origin()
					var direction: Vector2 = (silk_aim - origin).normalized().rotated(offset)
					spawn_silk(origin, direction * 250, 38.0)
				enter_boss_state("release")
		"cast":
			if boss_time >= 0.85:
				enter_boss_state("volley")
		"volley":
			# A full jump fits between shots; aim stays committed for the volley.
			while volley_shots < 3 and boss_time >= volley_shots * 0.85:
				combat_sounds.play("silk_shot")
				spawn_silk(boss + Vector2(boss_direction * 55, -34), Vector2(boss_direction * 260, 0), 42.0)
				volley_shots += 1
			if boss_time >= 1.95:
				enter_boss_state("release")
		"release":
			if boss_time >= 0.3:
				enter_boss_state("recover")
		"wrap":
			if evading:
				boss.x = move_toward(boss.x, evasion_target_x, 210.0 * dt)
			if boss_time >= 0.7:
				boss_target = flight_target_from_player(boss_rng.randf_range(145.0, 255.0), boss_rng.randf_range(220.0, 275.0))
				enter_boss_state("rise")
		"rise":
			boss = boss_origin.lerp(boss_target, smoothstep(0.0,1.0,minf(boss_time/0.9,1.0)))
			if boss_time >= 0.9:
				enter_boss_state("air_charge")
		"air_charge":
			if boss_time >= 1.0:
				combat_sounds.play("silk_burst")
				for i in 8:
					var direction = Vector2.from_angle(i * TAU / 8 + PI / 8)
					spawn_silk(boss + Vector2(0, -55) + direction * 52, direction * 170, 44.0)
				enter_boss_state("air_fire")
		"air_fire":
			if boss_time >= 0.8:
				boss_target = flight_target_from_player(boss_rng.randf_range(90.0, 145.0), FLOOR_Y)
				enter_boss_state("dive_prepare")
		"dive_prepare":
			if boss_time >= 0.65:
				enter_boss_state("dive")
		"dive":
			var old: Vector2 = boss
			boss = boss_origin.lerp(boss_target, pow(minf(boss_time/0.45,1.0),2))
			var near: Vector2 = Geometry2D.get_closest_point_to_segment(player + Vector2(0,-30), old + Vector2(0,-30), boss + Vector2(0,-30))
			if near.distance_to(player + Vector2(0,-30)) < 30:
				damage_player()
			if boss_time >= 0.45:
				impact_time = 0.4
				enter_boss_state("land")
		"dash_prepare":
			if boss_time >= 0.8:
				boss_target = Vector2(clampf(boss.x + boss_direction * 240,95,865),FLOOR_Y)
				enter_boss_state("dash")
		"dash":
			var old = boss
			boss = boss_origin.lerp(boss_target,minf(boss_time/0.65,1.0))
			var closest = Geometry2D.get_closest_point_to_segment(player + Vector2(0,-30),old+Vector2(0,-30),boss+Vector2(0,-30))
			if closest.distance_to(player+Vector2(0,-30)) < 30:
				damage_player()
			if boss_time >= 0.65:
				enter_boss_state("land")
		"land":
			if boss_time >= 0.4:
				enter_boss_state("recover")
		"recover":
			# A brief punish window, shortened further when pressured by hits.
			if boss_time >= recovery_duration:
				enter_boss_state("rest")
				attack_number += 1

func enter_boss_state(state: String):
	var previous_state: String = boss_state
	boss_state = state
	boss_time = 0.0
	boss_origin = boss
	if state != "sidestep":
		evading = false
	if state in ["wrap", "air_charge", "dive_prepare"] and not is_equal_approx(player.x, boss.x):
		boss_direction = -1 if player.x < boss.x else 1
	if state in ["cast", "diagonal_cast", "air_charge"]:
		combat_sounds.play("silk_charge")
	if state == "volley":
		volley_shots = 0
	if state == "diagonal_cast":
		silk_aim = player + Vector2(0,-36)
	if state == "recover":
		recovery_duration = boss_rng.randf_range(1.05, 1.45) if previous_state == "land" else boss_rng.randf_range(.65, .95)
	if state == "rest":
		rest_duration = boss_rng.randf_range(.22, .42)
	if state in ["recover", "air_fire"]:
		recovery_hit = false

func damage_player(source: Vector2 = Vector2(INF, INF)):
	if phase == "battle" and silk_guard.blocks_body(player, boss + Vector2(0, -50) if is_inf(source.x) else source):
		silk_guard.deflect()
		combat_sounds.play("umbrella_hit")
		if silk_guard.claim_counter():
			_silk_counter_boss()
		return
	if invulnerable > 0 or phase != "battle":
		return
	silk_guard.cancel()
	hp -= 1
	invulnerable = 1.2
	if hp <= 0:
		phase = "failed"
		combat_sounds.stop_all()
		bullets.clear()

func spawn_silk(pos: Vector2, velocity: Vector2, length: float = 44.0):
	bullets.append({"pos": pos, "velocity": velocity, "life": 5.0,"length":length})

func _silk_counter_boss() -> void:
	if phase != "battle":
		return
	resolve = maxi(0, resolve - 1)
	hit_position = silk_guard.center(player)
	trigger_impact()
	if resolve <= 0:
		win_battle()
	else:
		respond_to_ground_hit()

func update_bullets(dt):
	for i in range(bullets.size() - 1, -1, -1):
		var b = bullets[i]
		var old: Vector2 = b.pos
		b.pos += b.velocity * dt
		b.life -= dt
		if b.get("reflected", false):
			var target: Vector2 = boss + Vector2(0, -55)
			if Geometry2D.get_closest_point_to_segment(target, old, b.pos).distance_to(target) < 35:
				bullets.remove_at(i)
				if b.get("guard_damage", false):
					_silk_counter_boss()
				if phase != "battle":
					return
			elif b.life <= 0 or b.pos.x < -30 or b.pos.x > 990 or b.pos.y < -40 or b.pos.y > FLOOR_Y:
				bullets.remove_at(i)
			continue
		if silk_guard.intercepts(old, b.pos, player):
			b.pos = silk_guard.center(player)
			b.reflected = true
			b.guard_damage = silk_guard.claim_counter()
			b.velocity = (boss + Vector2(0, -55) - b.pos).normalized() * maxf(b.velocity.length(), 280.0)
			silk_guard.deflect()
			combat_sounds.play("umbrella_hit")
			continue
		var body = player + Vector2(0, -30)
		var tail = old - b.velocity.normalized() * b.get("length",44.0)
		var closest = Geometry2D.get_closest_point_to_segment(body, tail, b.pos)
		if closest.distance_to(body) < 19 and invulnerable <= 0:
			bullets.remove_at(i)
			damage_player(old)
			if phase == "failed":
				return
		elif b.life <= 0 or b.pos.y > FLOOR_Y or b.pos.x < -30 or b.pos.x > 990 or b.pos.y < -40:
			bullets.remove_at(i)

func win_battle():
	bullets.clear()
	boss.y = FLOOR_Y
	boss_state = "rest"
	start_dialogue([
		"Grandmother: ...Oh. It's stopped.",
		"Xiaoyu: The spinning wheel?",
		"Grandmother: The boiling, dear.",
		"Xiaoyu: It's just rain now.",
		"Grandmother: Hehe. So it is.",
		"Xiaoyu: Grandma... what happened?",
		"Grandmother: I used to be a silkworm.",
		"Xiaoyu: A SILKWORM?!",
		"Grandmother: What? Were you expecting a princess?",
		"Xiaoyu: ...Maybe.",
		"Grandmother: Ho ho!",
		"Grandmother: I made myself a little cocoon.",
		"Grandmother: I thought if I waited long enough, I'd grow wings and see the sky.",
		"Grandmother: I dreamed I could fly wherever I pleased.",
		"Xiaoyu: ...Did you?",
		"Grandmother: No, dear.",
		"Grandmother: Someone put my cocoon in boiling water.",
		"Grandmother: They wanted the silk to make clothes.",
		"Grandmother: I suppose they had no use for the wings.",
		"Xiaoyu: ...That's not fair.",
		"Grandmother: No. It wasn't.",
		"Grandmother: But there were others, you know.",
		"Grandmother: We were all waiting for our wings.",
		"Grandmother: Will you remember us?",
		"Xiaoyu: I promise.",
		"Grandmother: Thank you, dear.",
		"Grandmother: ...Oh, listen.",
		"Xiaoyu: The rain?",
		"Grandmother: It's cold.",
		"Grandmother: How lovely.",
		"Grandmother: Now, take this. The roads aren't safe at night.",
		"Xiaoyu: Is this silk?",
		"Grandmother: I wove it into your umbrella. Try opening it.",
		SILK_LESSON,
		"Xiaoyu: The rain bounced right off.",
		"Grandmother: It can stop more than rain. But you still need to dodge.",
		"Xiaoyu: Thank you, Grandma!",
		"Grandmother: Ho ho! Off you go, little one!",
	], "peace")

func words(text: String, pos: Vector2, size: int = 16, color: Color = Color("d6dce8")):
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func panel(rect: Rect2):
	draw_style_box(panel_style(), rect)

func panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.05, 0.09, 0.96)
	style.border_color = Color("58657e")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style

func draw_actor(tex: Texture2D, foot: Vector2, height: float, flip: bool = false, tint: Color = Color.WHITE):
	var width = height * tex.get_width() / float(tex.get_height())
	world_transform(foot, 0, Vector2(-1 if flip else 1, 1))
	draw_texture_rect(tex, Rect2(-width / 2, -height, width, height), false, tint)
	world_transform(Vector2.ZERO)

func is_grandmother_panicked() -> bool:
	return after_dialogue == "battle" and panic_line_index >= 0 and line_index >= panic_line_index

func draw_story_dialogue() -> void:
	if story_portraits == null or dialogue.is_empty() or line_index >= dialogue.size():
		return
	var line: String = dialogue[line_index]
	var aftermath: bool = after_dialogue == "peace" and resolve <= 0
	# Keep the panic portraits through every line after the outburst, until combat.
	var panic: bool = is_grandmother_panicked()
	var girl_column: int = 1 if panic else 2 if aftermath else 0
	var granny_column: int = 1 if panic else 2 if aftermath else 0
	# The portraits replace the small in-world actors during conversation.
	# Cells have alpha around the figures, leaving the live mountain and rain visible.
	var cell := Vector2(512, 512)
	var memory_column := -1
	var memory_subject: Texture2D
	if aftermath:
		if line.contains("I used to be a silkworm"):
			memory_subject = story_silkworm
		elif line.contains("little cocoon"):
			memory_subject = story_cocoon
		if line.contains("boiling water") or line.contains("silk to make clothes"):
			memory_column = 2
	var free_flight: bool = aftermath and line.contains("I dreamed I could fly")
	var sky_dream: bool = aftermath and line.contains("I'd grow wings and see the sky")
	if memory_subject != null:
		var size := memory_subject.get_size()
		size *= 246.0 / maxf(size.x, size.y)
		draw_texture_rect(memory_subject, Rect2(Vector2(480, 210) - size / 2, size), false)
	elif free_flight and story_free_moth != null:
		var drift := Vector2(sin(clock_time * 1.4) * 5.0, -sin(clock_time * 1.1) * 5.0)
		draw_texture_rect(story_free_moth, Rect2(Vector2(351, 73) + drift, Vector2(260, 260)), false, Color(1, 1, 1, .87))
	elif sky_dream and story_sky_dream != null:
		draw_texture_rect(story_sky_dream, Rect2(346, 80, 270, 270), false, Color(1, 1, 1, .86))
	elif memory_column >= 0 and story_memories != null:
		var memory_cell := story_memories.get_size().x / 3.0
		draw_texture_rect_region(story_memories, Rect2(323, 103, 315, 246), Rect2(memory_column * memory_cell, 0, memory_cell, story_memories.get_size().y), Color(1, 1, 1, .82))
	# Square atlas cells must use square destinations: independent width/height
	# scaling stretched the figures. Anchor both portraits to the bottom corners.
	draw_texture_rect_region(story_portraits, Rect2(-30, 260, 260, 260), Rect2(girl_column * cell.x, 0, cell.x, cell.y))
	if panic and story_panic != null:
		var panic_size := story_panic.get_size() * (260.0 / story_panic.get_height())
		draw_texture_rect(story_panic, Rect2(Vector2(850, 520) - Vector2(panic_size.x / 2.0, panic_size.y), panic_size), false)
	else:
		draw_texture_rect_region(story_portraits, Rect2(720, 260, 260, 260), Rect2(granny_column * cell.x, cell.y, cell.x, cell.y))

func _draw():
	var strength: float = pow(shake_time / 0.18, 2) if not reduce_shake else 0.0
	world_offset = Vector2(sin(feedback_clock*95)*3.0,cos(feedback_clock*113)*1.7)*strength
	world_transform(Vector2.ZERO)
	var source_size := background.get_size()
	var source_floor := source_size.y * BACKGROUND_ROAD_Y
	# Keep the full illustration while aligning the stone surface with actors and
	# the spinning wheel. Both regions meet on the same source row, without a seam.
	draw_texture_rect_region(background, Rect2(0, 0, 960, FLOOR_Y), Rect2(0, 0, source_size.x, source_floor))
	draw_texture_rect_region(background, Rect2(0, FLOOR_Y, 960, 540 - FLOOR_Y), Rect2(0, source_floor, source_size.x, source_size.y - source_floor))
	weather.draw(self)
	if inventory.opened:
		return
	if phase == "dialogue" and not paused and not memory_open:
		draw_story_dialogue()
		return
	if granny == null or frames.is_empty():
		return
	spinning.draw_equipment(self)
	var seated: bool = not granny_stood and (phase == "explore" or phase == "standing" or (phase == "dialogue" and after_dialogue == "battle"))
	var rise: float = rise_time / RISE_DURATION if phase == "standing" else 0.0
	var show_worker: bool = seated and rise < 0.72
	if show_worker:
		spinning.draw_worker(self, rise)
	var bob = sin(clock_time * 2) * 1.0 if boss_state in ["rest","air_charge","air_fire"] else 0.0
	var pose = 0
	if phase == "battle":
		if boss_state in ["cast","diagonal_cast","volley","release"]:
			pose = 1
		elif boss_state in ["sidestep","wrap","rise","dash_prepare","dive_prepare"]:
			pose = 3
		elif boss_state in ["air_charge","air_fire"]:
			pose = 2
		elif boss_state in ["dash","dive"]:
			pose = 4
		elif boss_state == "land" or (boss_state == "recover" and boss_time < 0.5):
			pose = 5
	world_transform(boss + Vector2(attack_facing * 9 * recoil / 0.18, bob), -attack_facing * 0.045 * recoil/0.18, Vector2(-1 if boss_direction > 0 else 1, 1))
	# One shared scale preserves the head size while dash/landing change the silhouette.
	# Pixel poses are already at the shared 0.32 scale; draw 1:1 on whole pixels.
	var size: Vector2 = boss_frames[pose].get_size()
	var flight = flight_pose()
	var tint = Color(1.65,1.65,1.8) if hit_stop > 0 else Color.WHITE
	if show_worker:
		tint.a = 0.0
	if not flight.is_empty():
		var texture: Texture2D = ascent_frames[flight.index] if flight.kind == "ascent" else landing_frames[flight.index]
		var bounds: Rect2 = ASCENT_BOUNDS[flight.index] if flight.kind == "ascent" else LANDING_BOUNDS[flight.index]
		var height: float = ASCENT_HEIGHTS[flight.index] if flight.kind == "ascent" else LANDING_HEIGHTS[flight.index]
		var width: float = height * bounds.size.x / bounds.size.y
		draw_texture_rect_region(texture, Rect2(-width * .5, -height, width, height), bounds, tint)
	else:
		draw_texture_rect(boss_frames[pose], Rect2(Vector2(-floorf(size.x/2),-size.y), size), false, tint)
	world_transform(Vector2.ZERO)
	if phase == "battle" and boss_state in ["cast","diagonal_cast","volley"]:
		var hand = boss + Vector2(boss_direction * 55, -34)
		if boss_state == "diagonal_cast":
			hand = aimed_silk_origin()
			for offset in [-0.32, 0.0, 0.32]:
				var aim: Vector2 = (silk_aim - hand).normalized().rotated(offset)
				draw_line(hand, hand + aim * 100, Color(1,0.94,0.8,0.3), 1,true)
		else:
			draw_line(hand, hand + Vector2(boss_direction * 100, 0), Color(1,0.94,0.8,0.25), 1,true)
	if phase == "battle" and boss_state in ["wrap","air_charge"]:
		if boss_state == "wrap":
			draw_arc(boss+Vector2(0,-60),24,0.3,4.8,20,Color(1,0.95,0.82,0.7),1,true)
		for i in 8:
			var dir = Vector2.from_angle(i * TAU / 8 + PI / 8)
			if boss_state == "air_charge":
				draw_line(boss + Vector2(0, -55) + dir * 65, boss + Vector2(0, -55) + dir * 98, Color(0.95, 0.93, 0.82, 0.35 + boss_time*0.3), 1,true)
	if phase == "battle" and boss_state == "dash_prepare":
		draw_line(boss+Vector2(0,-4),boss+Vector2(boss_direction*200,-4),Color(1,0.9,0.7,0.3),2,true)
	draw_hero()
	for bullet in bullets:
		draw_silk_bundle(bullet)
	world_offset = Vector2.ZERO
	world_transform(Vector2.ZERO)
	panel(Rect2(18, 16, 340, 64))
	words("CHAPTER 1 · ENDLESS THREADS", Vector2(30, 40), 18)
	words("HEALTH  " + "●".repeat(hp) + "○".repeat(6 - hp), Vector2(30, 65), 16, Color("d6b68a"))
	panel(Rect2(755, 16, 187, 64))
	words("[1] Umbrella: " + ("On" if equipped else "Off"), Vector2(770, 40))
	words("[M] Memories  " + ("1 / 1" if memory else "0 / 1"), Vector2(770, 65))
	if phase == "battle":
		words("Grandmother's Grief", Vector2(420, 34), 16)
		draw_rect(Rect2(350, 44, 260, 8), Color("273145"))
		draw_rect(Rect2(350, 44, 260 * maxf(0, resolve) / MAX_RESOLVE, 8), Color("bfbbc8"))
	if phase == "peace" and absf(player.x - boss.x) < 110:
		words("[E] Listen", boss + Vector2(-35, -136), 16, Color("efd9a0"))
	if phase == "failed":
		panel(Rect2(260, 170, 440, 165))
		words("Take a breath. Listen again.", Vector2(320, 225), 23)
		words("Press R to retry", Vector2(380, 285), 18)
	if paused:
		panel(Rect2(300, 190, 360, 120))
		words("Rainy Night, Paused", Vector2(360, 235), 24)
		words("Esc: Resume  ·  Q: Main Menu", Vector2(350, 278), 16)
	if memory_open:
		panel(Rect2(130, 120, 700, 310))
		words("MEMORY · SPRING UNSEEN" if memory else "MEMORY BOOK · EMPTY PAGES", Vector2(165, 165), 24, Color("e8d6b1"))
		var lines = ["They grew among mulberry leaves and hid in soft cocoons.", "They made cocoons to change. They wanted wings, too.", "Boiling water left her trapped in the last heat she felt.", "Xiaoyu could not explain it away. She stayed and listened.", "Tonight, Grandmother can finally hear the rain."] if memory else ["Approach the grandmother in the rain and listen.", "Calm her grief and hear her story to record this memory."]
		for i in lines.size():
			words(lines[i], Vector2(165, 210 + i * 32), 18)
		words("M / Esc Close Memory Book", Vector2(580, 402), 15)

func flight_pose() -> Dictionary:
	if phase != "battle":
		return {}
	match boss_state:
		"wrap":
			return {"kind":"ascent","index":0 if boss_time < 0.4 else 1}
		"rise":
			return {"kind":"ascent","index":mini(5,2+int(boss_time/0.225))}
		"air_charge":
			return {"kind":"ascent","index":5 if boss_time < 0.45 else 3}
		"air_fire":
			return {"kind":"ascent","index":3}
		"dive_prepare":
			return {"kind":"landing","index":0}
		"dive":
			return {"kind":"landing","index":1 if boss_time < 0.28 else 2}
		"land":
			return {"kind":"landing","index":3 if boss_time < 0.20 else 4}
		"recover":
			if boss_time < 0.35:
				return {"kind":"landing","index":5}
	return {}

# White silk ribbon. The solid front (bullet.length) is exactly the hitbox used in
# update_bullets(); the extra trailing 70% fades out and never deals damage.
const SILK_TAIL := 0.7
func draw_silk_bundle(bullet: Dictionary):
	var direction: Vector2 = bullet.velocity.normalized()
	var normal := direction.orthogonal()
	var hit_length: float = bullet.get("length",44.0)
	var total: float = hit_length * (1.0 + SILK_TAIL)
	var solid: float = 1.0 / (1.0 + SILK_TAIL)
	const N := 29
	var centre := PackedVector2Array()
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	var fade := PackedFloat32Array()
	for i in N:
		var t := i / float(N - 1)  # 0 = head, 1 = end of the fading tail
		var wave := sin(t*0.9*TAU + clock_time*6.0) * lerpf(0.0, 3.0, t*t)
		var p: Vector2 = bullet.pos - direction*total*t + normal*wave
		var half := lerpf(3.0, 1.3, t) * (0.75 + 0.25*sin(t*9.0 + clock_time*7.0))
		centre.append(p)
		top.append(p + normal*half)
		bot.append(p - normal*half)
		fade.append(1.0 if t <= solid else pow(1.0 - (t - solid)/(1.0 - solid), 1.5))
	var band := PackedVector2Array(top)
	var band_colors := PackedColorArray()
	for i in N:
		band_colors.append(Color(0.96, 0.94, 1.0, 0.95*fade[i]))
	for i in range(N - 1, -1, -1):
		band.append(bot[i])
		band_colors.append(Color(0.96, 0.94, 1.0, 0.95*fade[i]))
	var backing := PackedColorArray()
	var upper := PackedColorArray()
	var lower := PackedColorArray()
	for i in N:
		backing.append(Color(0.114, 0.094, 0.188, 0.9*fade[i]*fade[i]))
		upper.append(Color(1, 1, 1, fade[i]))
		lower.append(Color(0.725, 0.69, 0.84, 0.9*fade[i]))
	# Dark backing keeps white silk readable against the pale violet sky.
	draw_polyline_colors(centre, backing, 8.0, false)
	draw_polygon(band, band_colors)
	draw_polyline_colors(top, upper, 1.0, false)
	draw_polyline_colors(bot, lower, 1.0, false)
	# A short sheen slides along the solid part.
	var solid_points := int(solid * (N - 1))
	var s := int(fposmod(clock_time*18.0, maxf(1.0, solid_points - 4)))
	var sheen := PackedVector2Array()
	for i in range(s, s + 5):
		sheen.append(centre[i])
	draw_polyline(sheen, Color(1, 1, 1, 0.95), 1.0, false)
	draw_circle(bullet.pos, 2.0, Color("ffffff"))

# Weapon remains an independent texture; poses contain no weapon or VFX.
func umbrella_overlaps_boss() -> bool:
	return weapon_contacts(player,boss,attack)

# Both rendering and collision use the same grip, angle, tip and recoil.
func attack_weapon_pose(foot: Vector2, remaining: float) -> Dictionary:
	var extension: float = extension_at(remaining)
	var offset := Vector2(attack_facing*(extension*8-3)-attack_facing*5*recoil/0.18,0)
	var grip := Vector2(18,-57) if attack_up else Vector2(21,-38)
	if remaining > 0.28 or remaining < 0.06:
		grip = Vector2(-2,-24)
	var angle: float = lerpf(-1.0,-1.38,extension) if attack_up else lerpf(0.18,-0.12,extension)
	var pivot: Vector2 = foot+offset+Vector2(grip.x*attack_facing,grip.y)
	var aim := Vector2(cos(angle)*attack_facing,sin(angle))
	return {"pivot":pivot,"angle":angle,"base":pivot+aim*5,"tip":pivot+aim*(67 if attack_up else 51)}

func weapon_contacts(foot: Vector2, target: Vector2, remaining: float) -> bool:
	var weapon = attack_weapon_pose(foot,remaining)
	# The central cloak/body occupies this region; a small margin covers cloth edges.
	var body := Rect2(target+Vector2(-34,-125),Vector2(68,125)).grow(7)
	var a: Vector2 = weapon.base
	var b: Vector2 = weapon.tip
	if body.has_point(a):
		hit_position = a
		return true
	var corners = [body.position,Vector2(body.end.x,body.position.y),body.end,Vector2(body.position.x,body.end.y)]
	var nearest: float = INF
	for i in 4:
		var point = Geometry2D.segment_intersects_segment(a,b,corners[i],corners[(i+1)%4])
		if point != null and a.distance_squared_to(point) < nearest:
			nearest = a.distance_squared_to(point)
			hit_position = point
	return nearest < INF

func draw_hero():
	var pose: int = 0
	if player.y < FLOOR_Y - 2 or dash > 0:
		pose = 3
	if attack > 0:
		pose = 5 if attack_up else 4
		if attack > 0.28 or attack < 0.06:
			pose = 0
	if silk_guard.active():
		pose = 4
	var direction: int = attack_facing if attack > 0 else facing
	var tint := Color.WHITE
	if phase == "battle" and invulnerable > 0 and int(clock_time * 14) % 2 == 0:
		tint.a = 0.45
	# Shared scale keeps the head size stable; pose silhouettes can change height.
	# Pixel poses are already at the shared 65/442 scale; draw 1:1 on whole pixels.
	var size: Vector2 = frames[pose].get_size()
	var extension: float = thrust_extension()
	var body_offset := Vector2(direction * (extension*8 - 3) if attack > 0 else 0.0, 0)
	body_offset.x -= attack_facing * 5 * recoil/0.18
	var lean: float = direction * extension * 0.05 if attack > 0 and not attack_up else 0.0
	world_transform(Vector2.ZERO)
	walk.draw_shadow(self, player, FLOOR_Y)
	world_transform(player+body_offset, lean, Vector2(direction, 1))
	if not silk_guard.presenting():
		if pose == 0 and attack <= 0 and walk.walking and moving:
			walk.draw_body(self, frames[0], tint)
		else:
			draw_texture_rect(frames[pose], Rect2(Vector2(-floorf(size.x/2), -size.y), size), false, tint)
	world_transform(Vector2.ZERO)
	if equipped and not silk_guard.presenting():
		var walking_pose: bool = pose == 0 and attack <= 0 and walk.walking and moving
		var grip: Vector2 = walk.carry_grip() if walking_pose else Vector2(-2,-24)
		var angle := 0.18 if walking_pose else 0.38
		if pose == 1:
			grip = Vector2(12,-26)
		elif pose == 2:
			grip = Vector2(16,-28)
		elif pose == 3:
			grip = Vector2(-14,-24)
		if attack > 0:
			grip = Vector2(18,-57) if attack_up else Vector2(21,-38)
			if pose == 0:
				grip = Vector2(-2,-24)
			angle = lerpf(-1.0,-1.38,extension) if attack_up else lerpf(0.18,-0.12,extension)
		var pivot: Vector2 = player + body_offset + Vector2(grip.x * direction,grip.y)
		if attack > 0:
			var weapon = attack_weapon_pose(player,attack)
			pivot = weapon.pivot
			angle = weapon.angle
		world_transform(pivot, angle * direction, Vector2(direction, 1))
		# Grip sits at 15% of the independent umbrella; tip remains bare.
		var stretched: bool = attack > 0 and attack_up
		draw_texture_rect(umbrella_long if stretched else umbrella,Rect2(-9,-4,76 if stretched else 60,11),false,Color(1.4,1.5,1.7,tint.a))
		world_transform(Vector2.ZERO)
		# Short tapered speed traces follow the thrust, never a detached circular arc.
		if attack > 0.20 and attack < 0.28:
			var aim := Vector2(cos(angle)*direction,sin(angle))
			for i in 3:
				var side := aim.orthogonal() * (i-1)*3
				draw_line(pivot+aim*25+side,pivot+aim*47+side,Color(0.6,0.94,1,0.45),1.1,true)
	silk_guard.draw(self, player)
	if phase == "silk_reveal":
		for i in range(4):
			var t := (.95 - lesson_reveal - .18 - i * .035) / .38
			if t >= 0.0 and t < 1.0:
				var offset := Vector2(facing * (51.0 + t * 30.0), -50.0 + i * 7.0 - sin(t * PI) * 9.0)
				draw_line(player + offset, player + offset + Vector2(facing * 3.0, -2.0), Color(.8, .94, 1, 1 - t), 1.5)
	if phase == "battle" and hit_feedback > 0:
		var t: float = 1.0 - hit_feedback/0.35
		if t < 0.22:
			draw_line(hit_position-Vector2(10,0),hit_position+Vector2(10,0),Color(0.9,1,1),3,true)
			draw_line(hit_position-Vector2(0,7),hit_position+Vector2(0,7),Color(0.9,1,1),2,true)
		for i in 7:
			var ray := Vector2.from_angle(i*TAU/7)
			var point: Vector2 = hit_position + ray * (5 + t*19)
			draw_line(point,point+ray*4,Color(0.65,0.98,1,1-t),1.6,true)
			draw_circle(point+ray*4,1.3,Color(0.7,1,1,1-t),true,-1,true)



func thrust_extension() -> float:
	return extension_at(attack)

func extension_at(remaining: float) -> float:
	if remaining <= 0:
		return 0.0
	var elapsed: float = 0.34 - remaining
	if elapsed < 0.06:
		return 0.0
	if elapsed < 0.12:
		return 1.0 - pow(1.0-(elapsed-0.06)/0.06,3)
	if elapsed < 0.18:
		return 1.0
	return 1.0-smoothstep(0.18,0.34,elapsed)

func trigger_impact():
	hit_feedback = 0.35
	hit_stop = 0.065
	recoil = 0.18
	shake_time = 0.18
	combat_sounds.play("umbrella_hit")

func world_transform(origin: Vector2, angle: float = 0.0, zoom: Vector2 = Vector2.ONE):
	# Snap to whole screen pixels so NEAREST-sampled sprites never shimmer while moving.
	draw_set_transform((origin + world_offset).round(), angle, zoom)
