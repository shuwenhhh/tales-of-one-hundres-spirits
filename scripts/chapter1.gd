extends Node2D

const JOURNEY := preload("res://scripts/journey_state.gd")

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
var hp = 6
var resolve = MAX_RESOLVE
var phase = "explore"
var clock_time = 0.0
var dash = 0.0
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
var battle_bgm = preload("res://scripts/bgm.gd").new()
var hit_fx = preload("res://scripts/hit_spark.gd").new()
const BLOOM := preload("res://scripts/bloom_burst.gd")
var bloom = BLOOM.new()
const FX_LAYER := preload("res://scripts/fx_layer.gd")
var fx_layer = FX_LAYER.new()
var juice = preload("res://scripts/impact_juice.gd").new()
var cotton = preload("res://scripts/cotton_burst.gd").new()
# Holding L / S / Down opens the umbrella as a shield against hits from the
# front or above. Opening it just before the hit lands is a perfect guard.
const CANOPY := preload("res://assets/chapter0/encounter/sky_canopy.png")
const PERFECT_GUARD := 0.2
const GUARD_FLASH_TIME := 0.2
const BOSS_HURT_TIME := 0.42
var guarding := false
var guard_time := 0.0
var guard_flash := 0.0
var boss_hurt := 0.0
var motion = preload("res://scripts/actor_motion.gd").new()
var boss_flash_layer = preload("res://scripts/flash_layer.gd").new()
var boss_silhouette: Array = []
# Floating damage numbers: {"at": Vector2, "text": String, "age": float}
const POPUP_TIME := 0.7
var popups: Array[Dictionary] = []
const SCREEN_FLASH_TIME := 0.1
var screen_flash := 0.0
var recovery_hit = false
var hit_feedback = 0.0
var boss_state = "rest"
var boss_time = 0.0
var boss_direction = -1
var boss_origin := Vector2.ZERO
var boss_target := Vector2.ZERO
var impact_time := 0.0
var attack_number = 0
var volley_shots: int = 0
var silk_aim := Vector2.ZERO
var bullets: Array[Dictionary] = []
var rain: Array[Vector2] = []
var weather = preload("res://scripts/rain_weather.gd").new()
var dialogue: Array[String] = []
var dialogue_box = preload("res://scripts/dialogue_box.gd").new()
var line_index = 0
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

func cropped_texture(image: Image) -> Texture2D:
	var bounds = image.get_used_rect()
	if bounds.size.x > 0 and bounds.size.y > 0:
		image = image.get_region(bounds)
	return ImageTexture.create_from_image(image)

# Character art is pre-reduced to its on-screen size (tools/pixelize_sprites.py):
# one art pixel == one screen pixel, sampled NEAREST so every character shares
# the background's pixel grid. Text and UI keep the node's LINEAR filter.
static func pixel_texture(path: String) -> Texture2D:
	var tex := CanvasTexture.new()
	tex.diffuse_texture = load(path)
	tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return tex

func _ready():
	if not test_mode:
		JOURNEY.remember_chapter("res://chapter1.tscn")
		JOURNEY.apply_preferences()
		reduce_shake = bool(JOURNEY.preferences().get_value("settings", "reduce_shake", false))
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	walk.setup_audio(self)
	background = pixel_texture("res://assets/chapter1/backgrounds/rain_town_pixel_v1.png")
	combat_sounds.setup(self)
	battle_bgm.setup(self, "res://assets/audio/music/silk_battle.mp3", -8.0)
	boss_flash_layer.painter = draw_boss_silhouette
	add_child(boss_flash_layer)
	fx_layer.painter = draw_fx
	add_child(fx_layer)
	dialogue_box.mount(self)
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
	if phase == "dialogue":
		if key in [KEY_E, KEY_ENTER, KEY_SPACE]:
			if dialogue_box.reveal_or_continue():
				next_line()
		return
	if key == KEY_E and absf(player.x - boss.x) < 110 and phase in ["explore", "peace"]:
		interact()
	if key == KEY_1:
		equipped = not equipped
		attack = 0
		buffered_attack = 0
	if key == KEY_SPACE and player.y >= FLOOR_Y - 1:
		vy = -355
	if key in [KEY_SHIFT, KEY_K] and dash_cd <= 0:
		dash = 0.18
		dash_cd = 0.9
		invulnerable = maxf(invulnerable, 0.23)
	if key == KEY_J:
		begin_attack()

func begin_attack(upward: bool = false):
	if guarding:
		return
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
			"Xiaoyu: Yes. It hasn't stopped.",
			"Grandmother: Good. Please tell it I was wrong.",
			"Xiaoyu: You can tell it yourself.",
			"Grandmother: I tried. It's very loud.",
		], "peace")
	else:
		start_dialogue([
			"Grandmother: AAAAAH! HOT! HOT! HOT!",
			"Xiaoyu: Did you spill hot water?",
			"Grandmother: I don't own a kettle!",
			"Xiaoyu: Then what's hot?",
			"Grandmother: An excellent question. Could you ask it less loudly?",
			"Xiaoyu: You're sitting in the rain.",
			"Grandmother: Then the rain is doing a terrible job.",
			"Xiaoyu: It's freezing!",
			"Grandmother: Tell it to try harder.",
			"Xiaoyu: ...Rain? Please try harder.",
			"Grandmother: Thank you.",
			"(She waits. The rain keeps falling.)",
			"Grandmother: It didn't work.",
			"Xiaoyu: I don't think it heard me.",
			"Grandmother: N-no... It's getting hotter. I can hear the water.",
			"Xiaoyu: You mean the rain?",
			"Grandmother: Not that water! S-someone's trying to boil me!",
			"Xiaoyu: What?! Who is?",
			"Grandmother: I don't know! I can't see them! I—I think I'm melting!",
			"(White silk bursts from beneath her cloak.)",
			"(The spinning wheel turns on its own.)",
			"Grandmother: Please... make it stop!",
			"(The silk lashes toward Xiaoyu.)",
		], "battle")

func start_dialogue(lines: Array[String], next_phase: String):
	walk.stop_audio()
	combat_sounds.stop("silk_charge")
	dialogue = dialogue_box.merge_lines(lines, 2 if next_phase == "battle" and not granny_stood else 0)
	line_index = 0
	after_dialogue = next_phase
	phase = "dialogue"
	moving = false
	hit_stop = 0
	buffered_attack = 0
	attack = 0
	dash = 0
	vy = 0
	player.y = FLOOR_Y
	dialogue_box.show_line(dialogue[0])
	if not test_mode:
		if next_phase == "battle":
			JOURNEY.meet_chapter("res://chapter1.tscn", dialogue)
		elif next_phase == "peace" and resolve <= 0:
			JOURNEY.complete_chapter("res://chapter1.tscn", dialogue)

func next_line():
	line_index += 1
	if line_index < dialogue.size():
		dialogue_box.show_line(dialogue[line_index])
	if after_dialogue == "battle" and not granny_stood and line_index == 2:
		phase = "standing"
		dialogue_box.hide()
		rise_time = 0.0
		queue_redraw()
		return
	if line_index >= dialogue.size():
		dialogue_box.hide()
		phase = after_dialogue
		if phase == "battle":
			boss_state = "rest"
			boss_time = 0
			toast_time = 0
		elif phase == "peace" and resolve <= 0:
			unlock_memory()

func enter_next_chapter() -> void:
	var error := get_tree().change_scene_to_file(NEXT_CHAPTER)
	if error != OK:
		push_error("Could not enter chapter two: %s" % error)
		phase = "peace"
		toast = "Could not load the Peach Blossom Garden."
		toast_time = 12.0

func unlock_memory():
	memory = true
	if not test_mode:
		var cfg = ConfigFile.new()
		cfg.set_value("story", "silkworm", true)
		var error = cfg.save(save_path)
		if error != OK:
			push_warning("Could not save memory: " + str(error))

func retry():
	combat_sounds.stop_all()
	hit_fx.clear()
	bloom.clear()
	cotton.clear()
	motion.clear()
	juice.clear()
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
	attack = 0
	attack_cd = 0
	attack_up = false
	equipped = true
	invulnerable = 1.5
	bullets.clear()
	boss_state = "rest"
	boss_time = 0
	attack_number = 0
	battle_time = 0
	phase = "battle"

func _process(delta: float) -> void:
	weather.advance(delta)
	battle_bgm.update(phase == "battle", delta, paused or memory_open)
	if not paused and not memory_open:
		hit_fx.advance(delta)
		bloom.advance(delta)
		cotton.advance(delta)
		juice.advance(delta)
		screen_flash = maxf(0.0, screen_flash - delta)
		guard_flash = maxf(0.0, guard_flash - delta)
		boss_hurt = maxf(0.0, boss_hurt - delta)
		for i in range(popups.size() - 1, -1, -1):
			popups[i].age += delta
			if popups[i].age >= POPUP_TIME:
				popups.remove_at(i)
		var moved: String = motion.advance(delta, player.round(), facing, player.y < FLOOR_Y - 1, dash > 0)
		if moved != "":
			cotton.dust(Vector2(player.x, FLOOR_Y), -facing if moved == "dash" else 0.0)
	juice.apply(self, reduce_shake)
	queue_redraw()
	dialogue_box.visible = phase == "dialogue" and not paused and not memory_open
	if dialogue_box.visible and dialogue_box.advance_time(delta, Input.is_physical_key_pressed(KEY_CTRL)):
		next_line()

func _physics_process(dt):
	if paused or memory_open:
		walk.stop_audio()
		combat_sounds.stop_all()
		return
	if phase == "leaving":
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
	if phase in ["dialogue", "failed"]:
		queue_redraw()
		return
	dash_cd = maxf(0, dash_cd - dt)
	invulnerable = maxf(0, invulnerable - dt)
	attack_cd = maxf(0, attack_cd - dt)
	hit_feedback = maxf(0, hit_feedback - dt)
	var previous_attack: float = attack
	var previous_player: Vector2 = player
	var previous_boss: Vector2 = boss
	attack = maxf(0, attack - dt)
	if attack > 0 and attack <= 0.28 and not swing_played:
		swing_played = true
		combat_sounds.play("umbrella_swing")
		hit_fx.swing(player + Vector2(attack_facing * 14, -40), attack_facing, attack_up, motion.swings)
		motion.swings += 1
		motion.kick(Vector2(0.9, 1.14) if attack_up else Vector2(1.16, 0.9))
	if buffered_attack > 0 and attack_cd <= 0:
		buffered_attack = 0
		begin_attack(buffered_up)
		previous_attack = attack
	var axis = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var wants_guard: bool = equipped and phase in ["battle", "explore", "peace"] and player.y >= FLOOR_Y - 1 and attack <= 0 and dash <= 0 and (
		Input.is_physical_key_pressed(KEY_L) or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
	if wants_guard and not guarding:
		guard_time = 0.0
		motion.kick(Vector2(1.12, 0.88))
		combat_sounds.play("umbrella_open")
	guarding = wants_guard
	if guarding:
		guard_time += dt
		if axis != 0:
			facing = int(axis)
		axis = 0.0
	moving = axis != 0
	if dash > 0:
		player.x += facing * 490 * dt
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
		resolve_body_overlap(previous_player, previous_boss)
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
					separate_after_hit()
					if resolve <= 0:
						win_battle()
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

func resolve_body_overlap(previous_player: Vector2, previous_boss: Vector2) -> void:
	# Only an active enemy blocks the road. Once calmed, she must not gate the exit.
	if phase != "battle" or not bodies_overlap_vertically():
		return
	# Fast boss attacks retain their swept damage and can cross the player.
	# Their recovery/landing restores ordinary body spacing on the next frame.
	if boss_state in ["dash", "dive"] and phase == "battle":
		return
	var side := signf(previous_player.x - previous_boss.x)
	if side == 0.0:
		side = -float(facing)
	separate_bodies(BODY_GAP, side, 1.0)

func separate_after_hit() -> void:
	if not bodies_overlap_vertically() or absf(player.y - boss.y) > 45.0:
		return
	var side := signf(player.x - boss.x)
	if side == 0.0:
		side = -float(attack_facing)
	# Stop adding distance once both actors are clearly separated, so combos reach.
	separate_bodies(HIT_GAP, side, 0.65)

func update_boss(dt):
	boss_time += dt
	match boss_state:
		"rest":
			if absf(player.x - boss.x) > 155:
				boss.x = move_toward(boss.x, player.x, 42 * dt)
			boss_direction = -1 if player.x < boss.x else 1
			if boss_time >= 1.2:
				boss_direction = -1 if player.x < boss.x else 1
				enter_boss_state(["diagonal_cast", "cast", "dash_prepare", "wrap"][attack_number % 4])
		"diagonal_cast":
			if boss_time >= 0.85:
				combat_sounds.play("silk_shot")
				for offset in [-0.32, 0.0, 0.32]:
					var origin: Vector2 = boss + Vector2(boss_direction * 55, -78)
					var direction: Vector2 = (silk_aim - origin).normalized().rotated(offset)
					spawn_silk(origin, direction * 230, 38.0)
					bloom.burst(origin, BLOOM.SILK, 8, 300.0, direction)
				enter_boss_state("release")
		"cast":
			if boss_time >= 0.85:
				enter_boss_state("volley")
		"volley":
			# A full jump fits between shots; aim stays committed for the volley.
			while volley_shots < 3 and boss_time >= volley_shots * 0.85:
				combat_sounds.play("silk_shot")
				spawn_silk(boss + Vector2(boss_direction * 55, -34), Vector2(boss_direction * 260, 0), 42.0)
				bloom.burst(boss + Vector2(boss_direction * 55, -34), BLOOM.SILK, 14, 320.0, Vector2(boss_direction, 0))
				volley_shots += 1
			if boss_time >= 1.95:
				enter_boss_state("release")
		"release":
			if boss_time >= 0.3:
				enter_boss_state("recover")
		"wrap":
			if boss_time >= 0.7:
				boss_target = Vector2([240.0,480.0,720.0][int(attack_number / 4) % 3],245)
				enter_boss_state("rise")
		"rise":
			boss = boss_origin.lerp(boss_target, smoothstep(0.0,1.0,minf(boss_time/0.9,1.0)))
			if boss_time >= 0.9:
				enter_boss_state("air_charge")
		"air_charge":
			if boss_time >= 1.0:
				combat_sounds.play("silk_burst")
				bloom.burst(boss + Vector2(0, -55), BLOOM.SILK, 56, 520.0)
				bloom.burst(boss + Vector2(0, -55), BLOOM.SILK, 24, 240.0)
				juice.punch(boss + Vector2(0, -55), 0.8, false)
				cotton.scatter(boss + Vector2(0, -55), 5, Vector2(230, 90), 62.0)
				screen_flash = SCREEN_FLASH_TIME
				shake_time = 0.18
				for i in 8:
					var direction = Vector2.from_angle(i * TAU / 8 + PI / 8)
					spawn_silk(boss + Vector2(0, -55) + direction * 52, direction * 170, 44.0)
				enter_boss_state("air_fire")
		"air_fire":
			if boss_time >= 0.8:
				boss_target = Vector2(clampf(player.x + (110 if player.x < boss.x else -110),100,860),FLOOR_Y)
				enter_boss_state("dive_prepare")
		"dive_prepare":
			if boss_time >= 0.65:
				enter_boss_state("dive")
		"dive":
			var old: Vector2 = boss
			boss = boss_origin.lerp(boss_target, pow(minf(boss_time/0.45,1.0),2))
			var near: Vector2 = Geometry2D.get_closest_point_to_segment(player + Vector2(0,-30), old + Vector2(0,-30), boss + Vector2(0,-30))
			if near.distance_to(player + Vector2(0,-30)) < 30:
				damage_player(old.x)
			if boss_time >= 0.45:
				impact_time = 0.4
				combat_sounds.play("boss_slam")
				bloom.burst(boss + Vector2(0, -6), BLOOM.SILK, 44, 480.0, Vector2.UP)
				juice.punch(boss + Vector2(0, -20), 0.9, false)
				cotton.scatter(boss + Vector2(0, -40), 5, Vector2(210, 40), 56.0)
				screen_flash = SCREEN_FLASH_TIME
				shake_time = 0.18
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
				damage_player(old.x)
			if boss_time >= 0.65:
				enter_boss_state("land")
		"land":
			if boss_time >= 0.4:
				enter_boss_state("recover")
		"recover":
			if boss_time >= 1.6:
				enter_boss_state("rest")
				attack_number += 1

func enter_boss_state(state: String):
	boss_state = state
	boss_time = 0.0
	boss_origin = boss
	if state in ["cast", "diagonal_cast", "air_charge"]:
		combat_sounds.play("silk_charge")
	if state in ["dash", "dive"]:
		combat_sounds.play("boss_lunge")
		# Silk blossoms kick out behind her as she launches.
		var launch: Vector2 = (boss_target - boss).normalized()
		bloom.burst(boss + Vector2(0, -40), BLOOM.SILK, 26, 380.0, -launch)
	if state == "rise":
		bloom.burst(boss + Vector2(0, -20), BLOOM.SILK, 20, 300.0, Vector2.DOWN)
	if state == "volley":
		volley_shots = 0
	if state == "diagonal_cast":
		silk_aim = player + Vector2(0,-30)
	if state in ["recover", "air_fire"]:
		recovery_hit = false

func block_hit() -> void:
	var perfect := guard_time <= PERFECT_GUARD
	var at: Vector2 = player + Vector2(facing * 32, -44)
	invulnerable = 0.3
	hit_stop = 0.12 if perfect else 0.06
	guard_flash = GUARD_FLASH_TIME
	motion.kick(Vector2(0.86, 1.1))
	shake_time = 0.18
	combat_sounds.play("umbrella_block")
	hit_fx.burst(at, facing, perfect, true)
	cotton.burst(at, 34.0 if perfect else 24.0)
	juice.punch(at, 1.2 if perfect else 0.7, false)
	if not perfect:
		player.x = clampf(player.x - facing * 16, 30, 930)

# `source_x` is where the hit came from; leave it out for an unblockable hit.
func damage_player(source_x: float = INF, from_above: bool = false):
	if invulnerable > 0 or phase != "battle":
		return
	if guarding and (from_above or (source_x != INF and (source_x - player.x) * facing > 0)):
		block_hit()
		return
	hp -= 1
	invulnerable = 1.2
	motion.flinch()
	shake_time = 0.18
	bloom.burst(player + Vector2(0, -32), BLOOM.SILK, 14, 280.0)
	juice.punch(player + Vector2(0, -32), 0.7, false)
	if hp <= 0:
		phase = "failed"
		combat_sounds.stop_all()
		bullets.clear()

func spawn_silk(pos: Vector2, velocity: Vector2, length: float = 44.0):
	bullets.append({"pos": pos, "velocity": velocity, "life": 5.0,"length":length})

func update_bullets(dt):
	for i in range(bullets.size() - 1, -1, -1):
		var b = bullets[i]
		var old: Vector2 = b.pos
		b.pos += b.velocity * dt
		b.life -= dt
		var body = player + Vector2(0, -30)
		var tail = old - b.velocity.normalized() * b.get("length",44.0)
		var closest = Geometry2D.get_closest_point_to_segment(body, tail, b.pos)
		if closest.distance_to(body) < 19 and invulnerable <= 0:
			bullets.remove_at(i)
			damage_player(player.x - signf(b.velocity.x) * 10.0, b.velocity.y > absf(b.velocity.x))
			if phase == "failed":
				return
		elif b.life <= 0 or b.pos.y > FLOOR_Y or b.pos.x < -30 or b.pos.x > 990 or b.pos.y < -40:
			bullets.remove_at(i)

func win_battle():
	bullets.clear()
	boss.y = FLOOR_Y
	boss_state = "rest"
	start_dialogue([
		"Grandmother: It's stopped.",
		"Xiaoyu: The spinning wheel?",
		"Grandmother: The water.",
		"Xiaoyu: There's only rain.",
		"Grandmother: I know. I can hear the difference now.",
		"Xiaoyu: You said someone was trying to boil you.",
		"Grandmother: They did. A long time ago.",
		"Grandmother: I was a silkworm, then. I made a cocoon.",
		"Grandmother: I thought it was a waiting room for wings.",
		"Xiaoyu: Did you ever get them?",
		"Grandmother: No. Humans dropped the cocoon into boiling water.",
		"Grandmother: They took the silk. I never saw the sky outside it.",
		"(Xiaoyu can't find anything to say.)",
		"Grandmother: You don't need to find the right words.",
		"Xiaoyu: I don't know how to make it fair.",
		"Grandmother: Neither do I. You listened anyway.",
		"Grandmother: Please remember the others. They were waiting, too.",
		"Xiaoyu: I will.",
		"Grandmother: Can you hear the rain?",
		"Xiaoyu: Yes.",
		"Grandmother: I think it's finally doing its job.",
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

func _draw():
	var strength: float = pow(shake_time / 0.18, 2) if not reduce_shake else 0.0
	world_offset = Vector2(sin(feedback_clock*95)*6.5,cos(feedback_clock*113)*4.0)*strength
	fx_layer.position = world_offset
	fx_layer.visible = not paused and not memory_open
	boss_flash_layer.flash(Color.RED, 0.0)
	world_transform(Vector2.ZERO)
	var source_size := background.get_size()
	var source_floor := source_size.y * BACKGROUND_ROAD_Y
	# Keep the full illustration while aligning the stone surface with actors and
	# the spinning wheel. Both regions meet on the same source row, without a seam.
	draw_texture_rect_region(background, Rect2(0, 0, 960, FLOOR_Y), Rect2(0, 0, source_size.x, source_floor))
	draw_texture_rect_region(background, Rect2(0, FLOOR_Y, 960, 540 - FLOOR_Y), Rect2(0, source_floor, source_size.x, source_size.y - source_floor))
	weather.draw(self)
	if juice.dim() > 0.0 and not reduce_shake:
		draw_rect(Rect2(-60, -60, 1080, 660), Color(0.05, 0.02, 0.13, juice.dim()))
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
		elif boss_state in ["wrap","rise","dash_prepare","dive_prepare"]:
			pose = 3
		elif boss_state in ["air_charge","air_fire"]:
			pose = 2
		elif boss_state in ["dash","dive"]:
			pose = 4
		elif boss_state == "land" or (boss_state == "recover" and boss_time < 0.5):
			pose = 5
	# Her body breathes with the fight: it swells while she gathers silk, flattens
	# on landing and snaps back and thin when struck.
	var boss_shape := Vector2.ONE
	if phase == "battle":
		if boss_state in ["cast", "diagonal_cast", "air_charge", "wrap", "dash_prepare", "dive_prepare"]:
			var swell := 0.04 * sin(clock_time * 20.0)
			boss_shape = Vector2(1.0 + swell, 1.0 - swell)
		elif boss_state == "land" and boss_time < 0.18:
			boss_shape = Vector2(1.22, 0.8).lerp(Vector2.ONE, boss_time / 0.18)
		if recoil > 0:
			boss_shape = boss_shape.lerp(Vector2(0.86, 1.12), recoil / 0.18)
	# A struck boss turns solid red and shudders, then settles.
	var hurt: float = clampf(boss_hurt / BOSS_HURT_TIME, 0.0, 1.0)
	var shudder := Vector2(sin(juice.clock * 120.0) * 8.0, cos(juice.clock * 93.0) * 3.0) * hurt
	var boss_origin_now: Vector2 = boss + Vector2(attack_facing * 18 * recoil / 0.18, bob) + shudder
	var boss_angle: float = -attack_facing * 0.12 * recoil/0.18
	var boss_zoom := Vector2((-1 if boss_direction > 0 else 1) * boss_shape.x, boss_shape.y)
	world_transform(boss_origin_now, boss_angle, boss_zoom)
	# One shared scale preserves the head size while dash/landing change the silhouette.
	# Pixel poses are already at the shared 0.32 scale; draw 1:1 on whole pixels.
	var size: Vector2 = boss_frames[pose].get_size()
	var flight = flight_pose()
	var tint = Color.WHITE
	if show_worker:
		tint.a = 0.0
	var boss_texture: Texture2D = boss_frames[pose]
	var boss_rect := Rect2(Vector2(-floorf(size.x/2),-size.y), size)
	if not flight.is_empty():
		boss_texture = ascent_frames[flight.index] if flight.kind == "ascent" else landing_frames[flight.index]
		boss_rect = Rect2(Vector2(-128,-240),Vector2(256,300))
	draw_texture_rect(boss_texture, boss_rect, false, tint)
	world_transform(Vector2.ZERO)
	# The red silhouette is redrawn over her on its own layer: full red at first, then fading.
	boss_silhouette = [(boss_origin_now + world_offset).round(), boss_angle, boss_zoom, boss_texture, boss_rect]
	boss_flash_layer.flash(Color(1.0, 0.1, 0.08), 0.0 if show_worker else minf(1.0, hurt * 1.8) * 0.92)
	if phase == "battle" and boss_state in ["cast","diagonal_cast","volley"]:
		var hand = boss + Vector2(boss_direction * 55, -34)
		if boss_state == "diagonal_cast":
			hand = boss + Vector2(boss_direction * 55, -78)
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
	if phase == "battle" and boss_state in ["dive_prepare","dive"]:
		draw_arc(boss_target,27,PI,TAU,16,Color(1,0.9,0.7,0.5),1,true)
	if impact_time > 0:
		draw_arc(boss,25+(0.4-impact_time)*110,PI,TAU,20,Color(0.9,0.9,1,impact_time),2,true)
	draw_hero()
	for bullet in bullets:
		draw_silk_bundle(bullet)
	cotton.draw(self)
	for popup in popups:
		# Damage numbers pop up large, then float upward and fade.
		var floated: float = popup.age / POPUP_TIME
		var popup_at: Vector2 = popup.at + Vector2(0, -46.0 * (1.0 - pow(1.0 - floated, 2.0)))
		var popup_size: int = 34 if popup.age < 0.08 else 26
		words(popup.text, popup_at + Vector2(2, 2), popup_size, Color(0.15, 0.02, 0.05, 1.0 - floated))
		words(popup.text, popup_at, popup_size, Color(1.0, 0.32, 0.26, 1.0 - floated * floated))
	world_offset = Vector2.ZERO
	world_transform(Vector2.ZERO)
	if screen_flash > 0.0 and not reduce_shake:
		draw_rect(Rect2(0, 0, 960, 540), Color(1, 1, 1, 0.16 * screen_flash / SCREEN_FLASH_TIME))
	panel(Rect2(18, 16, 340, 64))
	words("CHAPTER 1 · ENDLESS THREADS", Vector2(30, 40), 18)
	words("HEALTH  " + "●".repeat(hp) + "○".repeat(6 - hp), Vector2(30, 65), 16, Color("d6b68a"))
	panel(Rect2(755, 16, 187, 64))
	words("[1] Umbrella: " + ("On" if equipped else "Off") + "  [L] Guard", Vector2(770, 40), 13)
	words("[M] Memories  " + ("1 / 1" if memory else "0 / 1"), Vector2(770, 65))
	if phase == "battle":
		words("Grandmother's Grief", Vector2(420, 34), 16)
		draw_rect(Rect2(350, 44, 260, 8), Color("273145"))
		draw_rect(Rect2(350, 44, 260 * maxf(0, resolve) / MAX_RESOLVE, 8), Color("bfbbc8").lerp(Color(1.0, 0.25, 0.2), clampf(boss_hurt / BOSS_HURT_TIME, 0.0, 1.0)))
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
	var direction: int = attack_facing if attack > 0 else facing
	var tint := Color.WHITE
	if invulnerable > 0 and int(clock_time * 14) % 2 == 0:
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
	for ghost in motion.ghosts:
		# Fading afterimages trail behind a dash.
		var ghost_size: Vector2 = frames[3].get_size()
		world_transform(ghost.foot, 0.0, Vector2(ghost.facing, 1))
		draw_texture_rect(frames[3], Rect2(Vector2(-floorf(ghost_size.x/2), -ghost_size.y), ghost_size), false, motion.ghost_color(ghost))
	# Squash, stretch and the hurt lean are visual only; the weapon keeps its exact pose.
	world_transform(player+body_offset, lean + motion.lean() * direction, Vector2(direction * motion.squash.x, motion.squash.y))
	var body_tint: Color = motion.tint(tint)
	if pose == 0 and attack <= 0 and walk.walking and moving:
		walk.draw_body(self, frames[0], body_tint)
	else:
		draw_texture_rect(frames[pose], Rect2(Vector2(-floorf(size.x/2), -size.y), size), false, body_tint)
	world_transform(Vector2.ZERO)
	if equipped and guarding:
		# Open canopy held out in front; it pops open and flashes when it stops a hit.
		var hub: Vector2 = player + Vector2(facing * 22, -40)
		draw_line(player + Vector2(facing * 4, -34), hub, Color("765338"), 3)
		world_transform(hub, facing * PI / 2, Vector2(maxf(0.15, minf(1.0, guard_time / 0.08)), 1))
		var shine := 1.0 + 1.4 * guard_flash / GUARD_FLASH_TIME
		draw_texture_rect(CANOPY, Rect2(-42, -10, 84, 30), false, Color(shine, shine, shine, tint.a))
		world_transform(Vector2.ZERO)
	elif equipped:
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

func draw_boss_silhouette(canvas: CanvasItem) -> void:
	if boss_silhouette.is_empty():
		return
	canvas.draw_set_transform(boss_silhouette[0], boss_silhouette[1], boss_silhouette[2])
	canvas.draw_texture_rect(boss_silhouette[3], boss_silhouette[4], false)

# Glowing combat effects, drawn on the additive layer above the scene.
func draw_fx(canvas: CanvasItem) -> void:
	if phase == "battle":
		for bullet in bullets:
			FX_LAYER.glow(canvas, bullet.pos, 20.0, Color(0.75, 0.88, 1.0, 0.75))
		if boss_state in ["cast", "diagonal_cast", "volley", "air_charge", "wrap", "dash_prepare", "dive_prepare"]:
			var pulse := 0.75 + 0.25 * sin(clock_time * 22.0)
			FX_LAYER.glow(canvas, boss + Vector2(0, -62), 95.0 * pulse, Color(0.7, 0.82, 1.0, 0.7))
	bloom.draw(canvas)
	hit_fx.draw(canvas)



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
	var final_blow: bool = resolve <= 0
	hit_feedback = 0.35
	hit_stop = 0.22 if final_blow else 0.083
	recoil = 0.18
	boss_hurt = BOSS_HURT_TIME
	popups.append({"at": boss + Vector2(randf_range(-18.0, 18.0), -128.0), "text": "-1", "age": 0.0})
	juice.punch(hit_position, 1.6 if final_blow else 1.0, false)
	# Every blow knocks cotton out of her: one puff at the contact point, more off her body.
	cotton.burst(hit_position + Vector2(attack_facing * 10, 0), 58.0 if final_blow else 34.0)
	cotton.scatter(boss + Vector2(attack_facing * 20, -62), 6 if final_blow else 2, Vector2(46, 44), 24.0)
	shake_time = 0.18
	hit_fx.burst(hit_position, attack_facing, resolve <= 0)
	# Shreds of silk fly off her with every landed strike.
	bloom.burst(hit_position, BLOOM.SILK, 26 if resolve <= 0 else 12, 360.0, Vector2(attack_facing, -0.45))
	screen_flash = SCREEN_FLASH_TIME
	combat_sounds.play("umbrella_hit")

func world_transform(origin: Vector2, angle: float = 0.0, zoom: Vector2 = Vector2.ONE):
	# Snap to whole screen pixels so NEAREST-sampled sprites never shimmer while moving.
	draw_set_transform((origin + world_offset).round(), angle, zoom)
