extends Node2D

const JOURNEY := preload("res://scripts/journey_state.gd")
const TRANSITION := preload("res://scripts/scene_transition.gd")
const NEXT_CHAPTER := "res://chapter3.tscn"
const RIGHT_EXIT_X := 925.0

const FLOOR := 448.0
const WALK_SPEED := 120.0
const MAX_GRIEF := 30
const SECOND_PHASE_HALF := MAX_GRIEF / 2
const BOSS_BAR_WIDTH := 310.0
const ARENA_LEFT := 48.0
const ARENA_RIGHT := 912.0
const OPENING_GRACE := 1.2
const OPENING_SAFE_DISTANCE := 285.0
const OPENING_RETREAT_SPEED := 330.0
const INTRO_TRIGGER_DISTANCE := 160.0
const INTRO_TREE_X := 450.0
const CALM_BREATH_FRAME_RATE := 0.75
const WHIP_WARNING_LEAD := 0.15
const WHIP_RECOVERY := 0.55
const WHIP_LONG_REACH := 340.0
const WHIP_LOW_REACH := 220.0
const WHIP_AIR_REACH := 285.0
const WHIP_AIR_STANDOFF := 170.0
const WHIP_AIR_TRAVEL_FRACTION := 0.75
const VINE_SCENE := preload("res://scenes/vine_attack.tscn")
const VINE_ORIGIN_STAFF := 0
const VINE_STAGE_DONE := 4
# One-handed redraw: 192px cells, shared scale and foot anchor. Grips are real palms.
const BOSS_FRAME_FOOT_Y := 182.0
const CAST_HAND_OFFSETS := [Vector2(27,-84), Vector2(41,-107), Vector2(49,-134), Vector2(44,-131), Vector2(70,-108), Vector2(66,-86)]
const VINE_STAFF_LONG_OFFSET := Vector2(70.0, -108.0)
const VINE_STAFF_LOW_OFFSET := Vector2(27.0, -84.0)
const VINE_STAFF_AIR_OFFSET := Vector2(24.0, -90.0)
const LEAP_HAND_OFFSETS := [Vector2(21,-81), Vector2(24,-90), Vector2(25,-83), Vector2(27,-81)]
const WALK_HAND_OFFSETS := [Vector2(21,-81), Vector2(27,-81), Vector2(26,-82), Vector2(16,-82)]
const VINE_CRACK_PAUSE := 0.035
const WHIP_APPROACH_DISTANCE := 280.0
const BODY_CONTACT_RADIUS := 32.0
const BODY_SEPARATION := 42.0
const HURT_INVINCIBILITY := 1.0
const HURT_KNOCKBACK_SPEED := 265.0
const HURT_KNOCKBACK_TIME := 0.18
const HIT_COMBO_WINDOW := 1.5
const REACTION_COOLDOWN := 3.0
const CLOSE_COUNTER_HITS := 3
const CLOSE_COUNTER_TRIGGER_RANGE := 125.0
const CLOSE_COUNTER_WINDUP := 0.35
const CLOSE_COUNTER_REACH := 108.0
const CLOSE_COUNTER_RECOVERY := 0.65
const WALL_MARGIN := 85.0
const BLOSSOM_CAST_DURATION := 0.9
const BLOSSOM_RELEASE_TIME := 0.52
const BLOSSOM_GUST_DURATION := 2.4
const BLOSSOM_BURST_COUNT := 5
const BLOSSOM_SPAWN_INTERVAL := 0.18
const BLOSSOM_CAST_RECOVERY := 0.65
const BOSS_HIT_FLASH := 0.10
const BOSS_FLASH_BLEND := 0.65
const GIRL_HIT_FLASH := 0.10
const HIT_PAUSE := 0.065
const HIT_SPARK_DURATION := 0.35
const HIT_SHAKE_DURATION := 0.18
const SETTLE_PLAYER_GAP := 112.0
const SETTLE_REPOSITION_SPEED := 100.0
const PLAYER_GRAVITY := 950.0
const PLAYER_FALL_SPEED := 600.0
const BOSS_HIT_KNOCKBACK_SPEED := 230.0
const BOSS_HIT_KNOCKBACK_TIME := 0.18
const BOSS_HURT_STAGGER := 1.0
const OPEN_WINDOW_MIN := 2.5
const OPEN_WINDOW_MAX := 3.5
const BOSS_WALK_FRAME_DISTANCE := 16.0
const BOSS_BACKHOP_DURATION := 0.34
const BOSS_VAULT_DURATION := 0.58
const SAVE := "user://chapter2_memory.cfg"
const FLOWER := preload("res://assets/chapter2/wisteria/single_hand/idle.png")
const GARDEN := preload("res://assets/chapter2/wisteria/garden.png")
const FONT := preload("res://assets/chapter1/chinese.ttc")
const HELD_VINE_LEAF := preload("res://assets/chapter2/vine/vine_sprig_b.png")
const HELD_VINE_TIP := preload("res://assets/chapter2/vine/vine_tip.png")
const HELD_VINE_ROOT := preload("res://assets/chapter2/vine/vine_root.png")
const HELD_VINE_POINTS := [Vector2(0, 0), Vector2(12, 8), Vector2(25, 18), Vector2(38, 30), Vector2(42, 42), Vector2(36, 47), Vector2(27, 43)]

var girl: Array[Texture2D] = []
var girl_flash_frames: Array[Texture2D] = []
var boss_idle_frame: Texture2D
var boss_idle_flash_frame: Texture2D
var boss_dance_frames: Array[Texture2D] = []
var boss_dance_flash_frames: Array[Texture2D] = []
var boss_walk_frames: Array[Texture2D] = []
var boss_walk_flash_frames: Array[Texture2D] = []
var boss_leap_frames: Array[Texture2D] = []
var boss_leap_flash_frames: Array[Texture2D] = []
var boss_cast_frames: Array[Texture2D] = []
var boss_cast_flash_frames: Array[Texture2D] = []
var boss_held_hit_frame: Texture2D
var boss_held_hit_flash_frame: Texture2D
var boss_held_hit_animated := false
var umbrella: Texture2D
var x := 155.0
var y := FLOOR
var vy := 0.0
var facing := 1
var walk = preload("res://scripts/hero_walk.gd").new()
var silk_guard = preload("res://scripts/silk_guard.gd").new()
var inventory = preload("res://scripts/inventory_panel.gd").new()
var combat_sounds = preload("res://scripts/combat_sounds.gd").new()
var swing_played: bool = false
var hp := 6
var grief := MAX_GRIEF
var phase := "explore"
var settle_time := 0.0
var settle_player_x := 0.0
const SETTLE_DURATION := 1.6
var lines: Array[String] = []
var dialogue_box = preload("res://scripts/dialogue_box.gd").new()
var line := 0
var after_lines := "battle"
var attack_time := 0.0
var attack_cooldown := 0.0
var hit_this_swing := false
var attack_up := false
var dash_time := 0.0
var dash_cooldown := 0.0
var invincible := 0.0
var knockback_time := 0.0
var knockback_velocity := 0.0
var battle_elapsed := 0.0
var boss_time := 0.0
var boss_state := "rest"
var boss_walk_distance := 0.0
var boss_is_walking := false
var last_attack := ""
var branch_mode := ""
var vines: Array = []
var current_vine
var boss_air_y := 0.0
var boss_target_x := 0.0
var boss_apex_x := 0.0
var boss_takeoff_x := 0.0
var opening_goal_x := 0.0
var warning_played := false
var cast_released := false
var ultimate_pending := false
var hit_streak := 0
var last_hit_at := -10.0
var reaction_cooldown := 0.0
var recovery_duration := 0.36
var open_window_time := 0.0
var boss_knockback_time := 0.0
var boss_knockback_velocity := 0.0
var boss_flash := 0.0
var girl_flash := 0.0
var impact_pause := 0.0
var boss_spark := 0.0
var girl_spark := 0.0
var boss_spark_position := Vector2.ZERO
var girl_spark_position := Vector2.ZERO
var shake_time := 0.0
var feedback_clock := 0.0
var reduce_shake := false
var leap_height := 76.0
var leap_rise_duration := 0.31
var leap_dive_duration := 0.31
var shots: Array[Dictionary] = []
var hazard_blossoms: Array[Texture2D] = []
var boss_x := INTRO_TREE_X
var boss_facing := -1
var wind_clock := 0.0
var wind_time := 0.0
var rain_clock := 0.0
var flower_bob := 0.0
var paused := false
var memory := false
var weather = preload("res://scripts/rain_weather.gd").new()
var backdrop: Sprite2D
var test_mode := false

func _ready() -> void:
	if not test_mode:
		JOURNEY.remember_chapter("res://chapter2.tscn")
		JOURNEY.apply_preferences()
		reduce_shake = bool(JOURNEY.preferences().get_value("settings", "reduce_shake", false))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backdrop = Sprite2D.new()
	backdrop.texture = GARDEN
	backdrop.centered = false
	backdrop.scale = Vector2(960.0 / GARDEN.get_width(), 540.0 / GARDEN.get_height())
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backdrop.z_index = -1
	var wind_shader := Shader.new()
	wind_shader.code = "shader_type canvas_item; uniform float gust = 0.0; void fragment() { vec2 uv = UV; float canopy = (1.0 - smoothstep(0.08, 0.56, uv.y)) * (1.0 - smoothstep(0.34, 0.54, uv.x)); uv.x += canopy * gust * (0.001 + 0.001 * sin(TIME * 3.5 + uv.y * 13.0)); COLOR = texture(TEXTURE, uv); COLOR.rgb *= 1.0 - 0.42 * (1.0 - smoothstep(0.07, 0.18, UV.y)); }"
	var wind_material := ShaderMaterial.new()
	wind_material.shader = wind_shader
	backdrop.material = wind_material
	add_child(backdrop)
	weather.reset(Vector2(960, 540))
	walk.setup_audio(self)
	combat_sounds.setup(self)
	dialogue_box.mount(self)
	# Chapter Two follows the silk-umbrella lesson; direct chapter launches need it too.
	silk_guard.setup(true)
	inventory.mount(self)
	for i in 6:
		var pose_texture: Texture2D = load("res://assets/chapter1/pixel/girl/pose_%d.png" % i)
		girl.append(pose_texture)
		girl_flash_frames.append(make_flash_texture(pose_texture.get_image()))
	# Idle and motion now use the same native pixel scale; never resize between poses.
	var idle_image := FLOWER.get_image()
	idle_image.convert(Image.FORMAT_RGBA8)
	boss_idle_frame = ImageTexture.create_from_image(idle_image)
	boss_idle_flash_frame = make_flash_texture(idle_image, BOSS_FLASH_BLEND)
	boss_held_hit_frame = boss_idle_frame
	boss_held_hit_flash_frame = boss_idle_flash_frame
	for frame in 4:
		var dance_texture: Texture2D = load("res://assets/chapter2/wisteria/dance/dance-%02d.png" % frame)
		boss_dance_frames.append(dance_texture)
		boss_dance_flash_frames.append(make_flash_texture(dance_texture.get_image(), BOSS_FLASH_BLEND))
	for frame in 4:
		var walk_texture: Texture2D = load("res://assets/chapter2/wisteria/single_hand/walk-%02d.png" % frame)
		boss_walk_frames.append(walk_texture)
		boss_walk_flash_frames.append(make_flash_texture(walk_texture.get_image(), BOSS_FLASH_BLEND))
	for frame in 6:
		var cast_texture: Texture2D = load("res://assets/chapter2/wisteria/single_hand/cast-%02d.png" % frame)
		boss_cast_frames.append(cast_texture)
		boss_cast_flash_frames.append(make_flash_texture(cast_texture.get_image(), BOSS_FLASH_BLEND))
	for frame in 4:
		var leap_texture: Texture2D = load("res://assets/chapter2/wisteria/single_hand/leap-%02d.png" % frame)
		boss_leap_frames.append(leap_texture)
		boss_leap_flash_frames.append(make_flash_texture(leap_texture.get_image(), BOSS_FLASH_BLEND))
	umbrella = load("res://assets/chapter1/pixel/girl/umbrella.png")
	for tint in 3:
		hazard_blossoms.append(make_hazard_blossom(tint))
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		memory = cfg.get_value("story", "hibiscus", false)
	if not test_mode:
		memory = memory or "res://chapter2.tscn" in JOURNEY.completed_chapters()

func make_flash_texture(source: Image, blend: float = 1.0) -> Texture2D:
	var image := source.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	for py in image.get_height():
		for px in image.get_width():
			var color := image.get_pixel(px, py)
			image.set_pixel(px, py, Color(lerpf(color.r, 1.0, blend), lerpf(color.g, 1.0, blend), lerpf(color.b, 1.0, blend), color.a))
	return ImageTexture.create_from_image(image)

func _exit_tree() -> void:
	get_viewport().canvas_transform = Transform2D.IDENTITY

func make_hazard_blossom(tint: int) -> Texture2D:
	# Detached pea-shaped wisteria flowers, with a dark silhouette and bright lip.
	var rows: Array[String] = [
		".............", ".....dd......", "...ddhhdd....", "..dphhhhpd...",
		"..dpphhppd...", "...dppppd....", "....dgcdd....",
		"...dphhpd....", "...dpppppd...", "....dpppd....",
		".....dpd.....", "......d......", "............."
	]
	var palettes := [
		[Color("36243f"), Color("af88d4"), Color("dfc4f1")],
		[Color("3c294c"), Color("bca0e0"), Color("ead4f2")],
		[Color("392543"), Color("9771c0"), Color("d5b7ea")]
	]
	var palette: Array = palettes[tint]
	var image := Image.create_empty(13, 13, false, Image.FORMAT_RGBA8)
	for py in rows.size():
		for px in 13:
			var mark: String = rows[py].substr(px, 1)
			var color := Color.TRANSPARENT
			match mark:
				"d": color = palette[0]
				"p": color = palette[1]
				"h": color = palette[2]
				"c": color = Color("f1c8a0")
				"g": color = Color("fff0c5")
			image.set_pixel(px, py, color)
	return ImageTexture.create_from_image(image)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode
	if event.is_action_pressed(&"open_inventory") and not paused and phase in ["explore", "battle", "peace"]:
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
	if phase in ["settling", "leaving"]:
		return
	if key == KEY_ESCAPE:
		paused = not paused
		return
	if key == KEY_Q and paused:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	if paused:
		return
	if phase == "dialogue":
		if key in [KEY_E, KEY_SPACE, KEY_ENTER]:
			if dialogue_box.reveal_or_continue():
				next_line()
		return
	if phase == "failed":
		if key == KEY_R:
			get_tree().reload_current_scene()
		return
	if key == KEY_N and phase == "peace":
		enter_next_chapter()
		return
	if silk_guard.handle_input(event, facing):
		if silk_guard.active():
			attack_time = 0
			dash_time = 0
			walk.stop_audio()
			combat_sounds.play("umbrella_swing")
		return
	if silk_guard.active():
		return
	if key in [KEY_SPACE, KEY_SHIFT]:
		silk_guard.interrupt_close()
	if key == KEY_E and absf(x - boss_x) < 115.0 and phase == "peace":
		start_lines(["Wisteria Spirit: Do the blossoms look lovely today?", "Xiaoyu: Very lovely.", "Wisteria Spirit: Good. Next time you come, I'll look up."], "peace")
		return
	if key == KEY_SPACE and y >= FLOOR - 0.1:
		vy = -355.0
	if key == KEY_SHIFT and dash_cooldown <= 0.0:
		dash_time = 0.18
		dash_cooldown = 0.9
		invincible = maxf(invincible, 0.25)
	if key == KEY_J and attack_cooldown <= 0.0 and phase in ["battle", "explore", "peace"]:
		silk_guard.interrupt_close()
		attack_time = 0.31
		attack_cooldown = 0.43
		attack_up = Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
		hit_this_swing = false
		swing_played = false

func meet_wisteria() -> void:
	if phase != "explore":
		return
	dash_time = 0.0
	attack_time = 0.0
	start_lines([
		"Xiaoyu: I think there's someone in the well.",
		"Wisteria Spirit: Shh... Don't wrinkle the water.",
		"Xiaoyu: Is that his reflection?",
		"Wisteria Spirit: He used to come here every day to read poetry.",
		"Xiaoyu: Did you ever speak to him?",
		"Wisteria Spirit: No. I kept waiting for the blossoms to look a little lovelier.",
		"Xiaoyu: But he isn't coming back, is he?",
		"Wisteria Spirit: Just a little longer. When the water settles, he'll be here.",
	], "battle")

func start_lines(text: Array[String], next: String) -> void:
	silk_guard.cancel()
	walk.advance(0.0, false)
	lines = dialogue_box.merge_lines(text)
	line = 0
	after_lines = next
	phase = "dialogue"
	shots.clear()
	dialogue_box.show_line(lines[0])
	if not test_mode:
		if next == "battle":
			JOURNEY.meet_chapter("res://chapter2.tscn", lines)
		elif next == "peace" and grief <= 0:
			JOURNEY.complete_chapter("res://chapter2.tscn", lines)

func next_line() -> void:
	line += 1
	if line < lines.size():
		dialogue_box.show_line(lines[line])
	else:
		dialogue_box.hide()
		phase = after_lines
		if phase == "battle":
			begin_battle()
		if phase == "peace":
			memory = true
			var cfg := ConfigFile.new()
			cfg.set_value("story", "hibiscus", true)
			if not test_mode:
				cfg.save(SAVE)

func begin_battle() -> void:
	clear_vines()
	battle_elapsed = 0.0
	boss_time = 0.0
	boss_walk_distance = 0.0
	boss_is_walking = false
	last_attack = ""
	branch_mode = ""
	open_window_time = 0.0
	boss_state = "opening_retreat"
	boss_air_y = 0.0
	reaction_cooldown = OPENING_GRACE + 0.4
	boss_facing = -1 if x < boss_x else 1
	var away := -boss_facing
	var gap := maxf(0.0, OPENING_SAFE_DISTANCE - absf(x - boss_x))
	opening_goal_x = clampf(boss_x + away * gap, ARENA_LEFT, ARENA_RIGHT)
	if absf(opening_goal_x - x) < OPENING_SAFE_DISTANCE:
		opening_goal_x = clampf(x - away * OPENING_SAFE_DISTANCE, ARENA_LEFT, ARENA_RIGHT)

func _process(delta: float) -> void:
	weather.advance(delta)
	feedback_clock += delta
	shake_time = maxf(0.0, shake_time - delta)
	var strength := pow(shake_time / HIT_SHAKE_DURATION, 2.0) if not reduce_shake else 0.0
	var offset := Vector2(sin(feedback_clock * 95.0) * 3.0, cos(feedback_clock * 113.0) * 1.7) * strength
	get_viewport().canvas_transform = Transform2D(0.0, offset.round())
	queue_redraw()
	dialogue_box.visible = phase == "dialogue" and not paused and not inventory.opened
	if dialogue_box.visible and dialogue_box.advance_time(delta, Input.is_physical_key_pressed(KEY_CTRL)):
		next_line()

func _physics_process(delta: float) -> void:
	if paused or phase == "leaving" or inventory.opened:
		queue_redraw()
		walk.stop_audio()
		combat_sounds.stop_all()
		return
	silk_guard.advance(delta, phase in ["explore", "battle", "peace"])
	if impact_pause > 0.0:
		impact_pause = maxf(0.0, impact_pause - delta)
		queue_redraw()
		return
	boss_flash = maxf(0.0, boss_flash - delta)
	girl_flash = maxf(0.0, girl_flash - delta)
	boss_spark = maxf(0.0, boss_spark - delta)
	girl_spark = maxf(0.0, girl_spark - delta)
	flower_bob += delta
	if phase == "settling":
		settle_time += delta
		# The last umbrella strike may land in midair. Let Xiaoyu finish the fall
		# and step clear before the dialogue freezes her pose.
		vy = minf(vy + PLAYER_GRAVITY * delta, PLAYER_FALL_SPEED)
		y = minf(FLOOR, y + vy * delta)
		if y >= FLOOR:
			vy = 0.0
		var step_from := x
		x = move_toward(x, settle_player_x, SETTLE_REPOSITION_SPEED * delta)
		walk.advance(x - step_from, y >= FLOOR)
		facing = 1 if x < boss_x else -1
		boss_facing = -1 if x < boss_x else 1
		if settle_time >= SETTLE_DURATION and y >= FLOOR and absf(x - settle_player_x) <= 1.0:
			walk.advance(0.0, false)
			start_lines([
				"Wisteria Spirit: The water's stirred... This time, I can't make him stay.",
				"Xiaoyu: What did you want to tell him?",
				"Wisteria Spirit: Please come again tomorrow night.",
				"Wisteria Spirit: But I always stayed behind the tree.",
				"Xiaoyu: I can sit with you for a while.",
				"Wisteria Spirit: ...What's your name?",
				"Xiaoyu: Xiaoyu.",
				"Wisteria Spirit: Take care on the road, Xiaoyu.",
			], "peace")
		queue_redraw()
		return
	var previous_x := x
	if phase not in ["dialogue", "failed"]:
		if knockback_time > 0.0:
			x = clampf(x + knockback_velocity * delta, 32.0, 925.0)
			knockback_time = maxf(0.0, knockback_time - delta)
		else:
			var direction := int(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
			if silk_guard.active():
				direction = 0
				facing = silk_guard.facing
			elif direction != 0:
				silk_guard.interrupt_close()
			if direction != 0:
				facing = direction
			x = clampf(x + direction * (410.0 if dash_time > 0 else WALK_SPEED) * delta, 32.0, 925.0)
		vy = minf(vy + PLAYER_GRAVITY * delta, PLAYER_FALL_SPEED)
		y = minf(FLOOR, y + vy * delta)
		if y >= FLOOR:
			vy = 0.0
	if phase == "peace" and grief <= 0 and x >= RIGHT_EXIT_X and (Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or (dash_time > 0 and facing > 0)):
		enter_next_chapter()
		return
	if phase == "explore" and absf(x - boss_x) < INTRO_TRIGGER_DISTANCE and y >= FLOOR - 1.0:
		facing = 1 if x < boss_x else -1
		meet_wisteria()
		queue_redraw()
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	attack_time = maxf(0.0, attack_time - delta)
	if attack_time > 0.0 and attack_time <= 0.25 and not swing_played:
		swing_played = true
		combat_sounds.play("umbrella_swing")
	var dash_active := dash_time > 0.0
	dash_time = maxf(0.0, dash_time - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	invincible = maxf(0.0, invincible - delta)
	walk.advance(x - previous_x, y >= FLOOR and attack_time <= 0.0 and dash_time <= 0.0)
	if phase == "battle":
		# A landed umbrella hit cancels the pending attack before its hitbox runs.
		if attack_time > 0.09 and attack_time < 0.25 and not hit_this_swing and battle_elapsed >= OPENING_GRACE and (boss_x - x) * facing > 0 and absf(x - boss_x) < (58.0 if attack_up else 85.0) and (boss_air_y > -105.0 if attack_up else boss_air_y > -35.0) and y > FLOOR - 100.0:
			apply_boss_hit()
		if phase != "battle":
			queue_redraw()
			return
		update_boss(delta)
		if not dash_active and boss_air_y > -55.0 and y > FLOOR - 95.0 and absf(x - boss_x) < BODY_SEPARATION:
			if boss_state in ["rest", "whip_release", "leap_dive", "vault"] and battle_elapsed >= OPENING_GRACE and invincible <= 0.0 and absf(x - boss_x) < BODY_CONTACT_RADIUS:
				damage_player(false)
			x = clampf(boss_x - BODY_SEPARATION if x <= boss_x else boss_x + BODY_SEPARATION, 32.0, 925.0)
	queue_redraw()

func enter_next_chapter() -> void:
	if phase == "leaving" or grief > 0:
		return
	phase = "leaving"
	silk_guard.cancel()
	walk.stop_audio()
	combat_sounds.stop_all()
	var error := TRANSITION.start(get_tree(), NEXT_CHAPTER, _chapter_transition_failed)
	if error != OK:
		_chapter_transition_failed(error)

func _chapter_transition_failed(error: Error) -> void:
	phase = "peace"
	push_warning("Chapter transition failed: %s" % error)

func apply_boss_hit() -> void:
	hit_this_swing = true
	var armored: bool = branch_mode == "close" and is_instance_valid(current_vine) and current_vine.stage in [current_vine.Stage.WARNING, current_vine.Stage.EXTENDING, current_vine.Stage.HOLDING]
	boss_held_hit_frame = current_boss_pose()
	boss_held_hit_flash_frame = flash_frame_for_boss_pose(boss_held_hit_frame)
	boss_held_hit_animated = boss_state != "rest" or boss_is_walking
	boss_is_walking = false
	# An interrupted spell retracts immediately and can no longer hit Xiaoyu.
	if not armored:
		for vine in vines:
			if is_instance_valid(vine):
				vine.interrupt()
	warning_played = false
	combat_sounds.stop("silk_charge")
	grief -= 1
	combat_sounds.play("umbrella_hit")
	boss_flash = BOSS_HIT_FLASH
	boss_spark = HIT_SPARK_DURATION
	boss_spark_position = umbrella_hit_position() if attack_time > 0.0 and not silk_guard.active() else silk_guard.center(Vector2(x, y))
	impact_pause = HIT_PAUSE
	shake_time = HIT_SHAKE_DURATION
	if not armored:
		boss_air_y = 0.0
	if grief <= 0:
		clear_vines()
		if not test_mode:
			JOURNEY.complete_chapter("res://chapter2.tscn")
		phase = "settling"
		settle_time = 0.0
		var preferred_side := -1.0 if x <= boss_x else 1.0
		settle_player_x = boss_x + preferred_side * SETTLE_PLAYER_GAP
		if settle_player_x < 32.0 or settle_player_x > 925.0:
			settle_player_x = boss_x - preferred_side * SETTLE_PLAYER_GAP
		settle_player_x = clampf(settle_player_x, 32.0, 925.0)
		boss_state = "rest"
		boss_time = 0.0
		boss_facing = -1 if x < boss_x else 1
		attack_time = 0.0
		attack_up = false
		dash_time = 0.0
		knockback_time = 0.0
		silk_guard.cancel()
		walk.advance(0.0, false)
		warning_played = false
		cast_released = false
		open_window_time = 0.0
		boss_knockback_time = 0.0
		shots.clear()
		wind_time = 0.0
		(backdrop.material as ShaderMaterial).set_shader_parameter("gust", 0.0)
		walk.stop_audio()
		return
	if grief == SECOND_PHASE_HALF - 1:
		ultimate_pending = true
	# The counter has poise: extra hits still hurt, but cannot erase its warning or sweep.
	if armored:
		return
	if battle_elapsed - last_hit_at <= HIT_COMBO_WINDOW:
		hit_streak += 1
	else:
		hit_streak = 1
	last_hit_at = battle_elapsed
	if hit_streak >= CLOSE_COUNTER_HITS and absf(boss_x - x) <= CLOSE_COUNTER_TRIGGER_RANGE:
		hit_streak = 0
		reaction_cooldown = REACTION_COOLDOWN
		boss_knockback_time = 0.0
		boss_facing = -1 if x < boss_x else 1
		clear_vines()
		start_ground_whip("close")
	elif hit_streak >= CLOSE_COUNTER_HITS and reaction_cooldown <= 0.0:
		hit_streak = 0
		reaction_cooldown = REACTION_COOLDOWN
		boss_knockback_time = 0.0
		boss_facing = -1 if x < boss_x else 1
		var room_behind := boss_x - ARENA_LEFT if boss_facing > 0 else ARENA_RIGHT - boss_x
		if room_behind <= 125.0:
			start_boss_escape("vault", clampf(x + boss_facing * 80.0, ARENA_LEFT, ARENA_RIGHT))
		else:
			start_boss_escape("backhop", clampf(boss_x - boss_facing * 120.0, ARENA_LEFT, ARENA_RIGHT))
	else:
		boss_state = "ouch"
		branch_mode = ""
		boss_time = 0.0
		boss_target_x = boss_x
		boss_knockback_time = BOSS_HIT_KNOCKBACK_TIME
		boss_knockback_velocity = BOSS_HIT_KNOCKBACK_SPEED * (1.0 if boss_x >= x else -1.0)

func current_boss_pose() -> Texture2D:
	if boss_state == "ouch":
		return boss_held_hit_frame
	if boss_state == "rest":
		if boss_is_walking:
			return boss_walk_frames[int(boss_walk_distance / BOSS_WALK_FRAME_DISTANCE) % boss_walk_frames.size()]
		return boss_idle_frame
	if boss_state in ["whip_prepare", "whip_release", "leap_whip"]:
		return boss_cast_frames[vine_pose_frame()]
	if boss_state in ["leap_rise", "leap_dive", "backhop", "vault", "opening_retreat"]:
		var frame := 0
		if boss_state == "leap_rise":
			frame = 1
		elif boss_state == "leap_dive":
			frame = 2 if boss_time < leap_dive_duration * 0.75 else 3
		else:
			var duration := 0.8 if boss_state == "opening_retreat" else (BOSS_BACKHOP_DURATION if boss_state == "backhop" else BOSS_VAULT_DURATION)
			frame = mini(int(boss_time / duration * 4.0), 3)
		return boss_leap_frames[frame]
	if boss_state == "blossom_cast":
		return boss_cast_frames[mini(int(boss_time / BLOSSOM_CAST_DURATION * 3.0), 2)]
	return boss_idle_frame

func flash_frame_for_boss_pose(pose: Texture2D) -> Texture2D:
	var index := boss_walk_frames.find(pose)
	if index >= 0:
		return boss_walk_flash_frames[index]
	index = boss_cast_frames.find(pose)
	if index >= 0:
		return boss_cast_flash_frames[index]
	index = boss_leap_frames.find(pose)
	if index >= 0:
		return boss_leap_flash_frames[index]
	return boss_idle_flash_frame

func start_boss_escape(kind: String, target: float) -> void:
	boss_state = kind
	branch_mode = "vault" if kind == "vault" else ""
	boss_time = 0.0
	boss_takeoff_x = boss_x
	boss_target_x = target
	# A corner escape only repositions her. Every attack originates in her hand.

func start_boss_leap() -> void:
	boss_state = "leap_rise"
	branch_mode = "air"
	last_attack = "air"
	boss_time = 0.0
	boss_takeoff_x = boss_x
	boss_facing = -1 if x < boss_x else 1
	leap_height = randf_range(70.0, 96.0)
	leap_rise_duration = randf_range(0.28, 0.38)
	leap_dive_duration = randf_range(0.28, 0.38)
	boss_target_x = clampf(x - boss_facing * WHIP_AIR_STANDOFF + randf_range(-22.0, 22.0), ARENA_LEFT, ARENA_RIGHT)
	boss_target_x = clampf(boss_target_x, boss_x - 215.0, boss_x + 215.0)
	boss_apex_x = lerpf(boss_takeoff_x, boss_target_x, WHIP_AIR_TRAVEL_FRACTION)
	# Commit once to the player's body and the planned apex palm. No homing in flight.
	var apex_hand := Vector2(boss_apex_x + boss_facing * VINE_STAFF_LONG_OFFSET.x, FLOOR - leap_height + VINE_STAFF_LONG_OFFSET.y)
	spawn_vine(VINE_ORIGIN_STAFF, WHIP_AIR_REACH, Vector2(x, y - 35.0), VINE_STAFF_AIR_OFFSET, apex_hand)

func start_ground_whip(kind: String) -> void:
	boss_state = "whip_prepare"
	branch_mode = kind
	last_attack = kind
	boss_time = 0.0
	boss_facing = -1 if x < boss_x else 1
	warning_played = false
	var reach := WHIP_LOW_REACH if kind == "low" else WHIP_LONG_REACH
	if kind == "close":
		reach = CLOSE_COUNTER_REACH
	spawn_vine(VINE_ORIGIN_STAFF, reach, Vector2(x, y - 35.0), CAST_HAND_OFFSETS[0])
	if kind == "close":
		current_vine.warning_duration = CLOSE_COUNTER_WINDUP

func spawn_vine(mode: int, reach: float, target: Vector2, staff_offset: Vector2, planned_release: Vector2 = Vector2(INF, INF)) -> void:
	var marker: Marker2D = $VineOrigin
	marker.position = Vector2(boss_x + boss_facing * staff_offset.x, FLOOR + boss_air_y + staff_offset.y)
	var vine: Variant = VINE_SCENE.instantiate()
	vine.origin_mode = mode
	vine.max_length = reach
	var release_origin := Vector2(boss_x + boss_facing * VINE_STAFF_LONG_OFFSET.x, FLOOR + boss_air_y + VINE_STAFF_LONG_OFFSET.y)
	if not is_inf(planned_release.x):
		release_origin = planned_release
	if mode == VINE_ORIGIN_STAFF:
		# Pick the length once, before motion: reaching past the locked target never stretches a segment.
		vine.max_length = minf(reach, maxf(80.0, release_origin.distance_to(target) * (1.0 + vine.overshoot_ratio)))
	add_child(vine)
	vine.begin(marker.global_position, target, boss_facing, FLOOR)
	if mode == VINE_ORIGIN_STAFF:
		vine.hand_marker = marker
		vine.direction = (target - release_origin).normalized()
	vine.tip_contact.connect(_on_vine_tip_contact)
	vine.cracked.connect(_on_vine_crack)
	vines.append(vine)
	current_vine = vine

func _on_vine_tip_contact(source: Vector2) -> void:
	if phase == "battle" and invincible <= 0.0:
		damage_player(false, source)

func _on_vine_crack() -> void:
	combat_sounds.play("silk_shot")
	impact_pause = maxf(impact_pause, VINE_CRACK_PAUSE)

func vine_pose_frame() -> int:
	if is_instance_valid(current_vine):
		if current_vine.stage == current_vine.Stage.WARNING:
			if current_vine.elapsed < current_vine.warning_duration * 0.25:
				return 0
			if current_vine.elapsed < current_vine.warning_duration * 0.55:
				return 1
			return 2
		if current_vine.stage == current_vine.Stage.EXTENDING:
			return 3 if current_vine.elapsed < current_vine.warning_duration + current_vine.extend_duration * 0.6 else 4
		if current_vine.stage == current_vine.Stage.HOLDING:
			return 4
		if current_vine.stage == current_vine.Stage.RELAXING:
			var relax_at: float = current_vine.snap_time() + current_vine.hold_duration
			return 5 if current_vine.elapsed < relax_at + current_vine.relax_duration * 0.7 else 0
		if current_vine.stage == current_vine.Stage.RETRACTING:
			return 0
	return 0

func boss_hand_offset() -> Vector2:
	var offset := VINE_STAFF_LOW_OFFSET
	if boss_state == "ouch":
		var cast_frame := boss_cast_frames.find(boss_held_hit_frame)
		var leap_frame := boss_leap_frames.find(boss_held_hit_frame)
		var walk_frame := boss_walk_frames.find(boss_held_hit_frame)
		if cast_frame >= 0:
			offset = CAST_HAND_OFFSETS[cast_frame]
		elif leap_frame >= 0:
			offset = LEAP_HAND_OFFSETS[leap_frame]
		elif walk_frame >= 0:
			offset = WALK_HAND_OFFSETS[walk_frame]
	elif boss_state in ["whip_prepare", "whip_release", "leap_whip"]:
		var frame := vine_pose_frame()
		offset = CAST_HAND_OFFSETS[frame]
	elif boss_state == "blossom_cast":
		offset = CAST_HAND_OFFSETS[mini(int(boss_time / BLOSSOM_CAST_DURATION * 3.0), 2)]
	elif boss_state == "rest" and boss_is_walking:
		offset = WALK_HAND_OFFSETS[int(boss_walk_distance / BOSS_WALK_FRAME_DISTANCE) % boss_walk_frames.size()]
	elif boss_state in ["leap_rise", "leap_dive", "backhop", "vault", "opening_retreat"]:
		var frame := boss_leap_frames.find(current_boss_pose())
		if frame >= 0:
			offset = LEAP_HAND_OFFSETS[frame]
	return offset

func update_vine_marker() -> void:
	var offset := boss_hand_offset()
	$VineOrigin.position = Vector2(boss_x + boss_facing * offset.x, FLOOR + boss_air_y + offset.y)

func clear_vines() -> void:
	for vine in vines:
		if is_instance_valid(vine):
			vine.queue_free()
	vines.clear()
	current_vine = null

func advance_vines(delta: float) -> void:
	update_vine_marker()
	for i in range(vines.size() - 1, -1, -1):
		if not is_instance_valid(vines[i]) or vines[i].stage == VINE_STAGE_DONE:
			vines.remove_at(i)
		else:
			var guard_center := Vector2(INF, INF)
			if silk_guard.blocks_body(Vector2(x, y), Vector2(boss_x, FLOOR + boss_air_y - 50.0)):
				guard_center = silk_guard.center(Vector2(x, y))
			vines[i].advance(delta, Vector2(x, y - 35.0), guard_center, 30.0)
	update_vine_marker()
	for vine in vines:
		if is_instance_valid(vine) and vine.stage != VINE_STAGE_DONE:
			vine.sync_hand()

func choose_boss_attack(distance: float, player_airborne: bool, fierce: bool) -> String:
	var options := ["long", "low", "air"]
	var weights := [4.5 if distance >= 135.0 else 1.6, 4.0 if distance < 185.0 else 0.25, 3.6 if player_airborne else (2.2 if distance >= 170.0 else 1.0)]
	if fierce:
		weights[2] *= 1.25
	var total := 0.0
	for i in options.size():
		if options[i] == last_attack:
			weights[i] *= 0.12
		total += weights[i]
	var roll := randf() * total
	for i in options.size():
		roll -= weights[i]
		if roll < 0.0 and weights[i] > 0.0:
			return options[i]
	return "long"

func update_boss(delta: float) -> void:
	var elapsed_before := battle_elapsed
	boss_is_walking = false
	battle_elapsed += delta
	reaction_cooldown = maxf(0.0, reaction_cooldown - delta)
	open_window_time = maxf(0.0, open_window_time - delta)
	boss_time += delta
	if boss_knockback_time > 0.0:
		boss_x = clampf(boss_x + boss_knockback_velocity * delta, ARENA_LEFT, ARENA_RIGHT)
		boss_knockback_time = maxf(0.0, boss_knockback_time - delta)
	if elapsed_before < OPENING_GRACE:
		if boss_state == "opening_retreat":
			boss_x = move_toward(boss_x, opening_goal_x, OPENING_RETREAT_SPEED * minf(delta, OPENING_GRACE - elapsed_before))
			boss_air_y = -38.0 * sin(PI * clampf(boss_time / 0.8, 0.0, 1.0))
		if battle_elapsed >= OPENING_GRACE:
			boss_state = "rest"
			boss_time = 0.0
			boss_air_y = 0.0
		return
	if boss_state == "opening_retreat":
		boss_state = "rest"
		boss_time = 0.0
		boss_air_y = 0.0
	var fierce := grief < SECOND_PHASE_HALF
	if boss_state == "rest":
		boss_facing = -1 if x < boss_x else 1
		var cornered_left := boss_x < ARENA_LEFT + WALL_MARGIN and x > boss_x
		var cornered_right := boss_x > ARENA_RIGHT - WALL_MARGIN and x < boss_x
		if reaction_cooldown <= 0.0 and (cornered_left or cornered_right):
			var landing := x + 80.0 if cornered_left else x - 80.0
			start_boss_escape("vault", clampf(landing, ARENA_LEFT, ARENA_RIGHT))
			reaction_cooldown = REACTION_COOLDOWN
		elif fierce and (ultimate_pending or wind_clock >= 6.0):
			boss_state = "blossom_cast"
			branch_mode = "blossom"
			boss_time = 0.0
			cast_released = false
			ultimate_pending = false
		elif absf(boss_x - x) > WHIP_APPROACH_DISTANCE:
			var walk_from := boss_x
			boss_x = move_toward(boss_x, x - boss_facing * WHIP_APPROACH_DISTANCE, (155.0 if fierce else 130.0) * delta)
			var walked := absf(boss_x - walk_from)
			boss_is_walking = walked > 0.0
			boss_walk_distance += walked
		if boss_state == "rest" and boss_time >= (0.38 if fierce else 0.52) and absf(boss_x - x) <= WHIP_LONG_REACH:
			var next_mode := choose_boss_attack(absf(boss_x - x), y < FLOOR - 35.0, fierce)
			if next_mode == "air":
				start_boss_leap()
			else:
				start_ground_whip(next_mode)
	elif boss_state == "whip_prepare":
		# The aim is committed; the root follows the currently drawn hand pose.
		if not warning_played:
			if is_instance_valid(current_vine) and boss_time >= current_vine.warning_duration - WHIP_WARNING_LEAD:
				warning_played = true
				combat_sounds.play("silk_charge")
		if is_instance_valid(current_vine) and boss_time >= current_vine.warning_duration:
			boss_state = "whip_release"
			boss_time = 0.0
			combat_sounds.stop("silk_charge")
			combat_sounds.play("silk_shot")
	elif boss_state == "whip_release" and (not is_instance_valid(current_vine) or current_vine.stage == VINE_STAGE_DONE):
		boss_state = "recover"
		boss_time = 0.0
		recovery_duration = CLOSE_COUNTER_RECOVERY if branch_mode == "close" else WHIP_RECOVERY
	elif boss_state == "blossom_cast":
		if not cast_released and boss_time >= BLOSSOM_RELEASE_TIME:
			cast_released = true
			wind_time = BLOSSOM_GUST_DURATION
			wind_clock = 0.0
			rain_clock = 0.0
			for blossom in BLOSSOM_BURST_COUNT:
				spawn_tree_petal(float(blossom) * 9.0)
		if boss_time >= BLOSSOM_CAST_DURATION:
			boss_state = "recover"
			boss_time = 0.0
			open_window_time = 0.0
			recovery_duration = BLOSSOM_CAST_RECOVERY
	elif boss_state in ["backhop", "vault"]:
		var duration := BOSS_BACKHOP_DURATION if boss_state == "backhop" else BOSS_VAULT_DURATION
		var escape := clampf(boss_time / duration, 0.0, 1.0)
		boss_x = lerpf(boss_takeoff_x, boss_target_x, escape)
		boss_air_y = -(48.0 if boss_state == "backhop" else 105.0) * sin(PI * escape)
		if escape >= 1.0:
			boss_air_y = 0.0
			boss_state = "recover"
			boss_time = 0.0
			recovery_duration = 0.2
	elif boss_state == "leap_rise":
		var rise := clampf(boss_time / leap_rise_duration, 0.0, 1.0)
		boss_air_y = -leap_height * sin(rise * PI * 0.5)
		boss_x = lerpf(boss_takeoff_x, boss_apex_x, sin(rise * PI * 0.5))
		if rise >= 1.0:
			boss_state = "leap_whip"
			boss_time = 0.0
			boss_takeoff_x = boss_x
	elif boss_state == "leap_whip":
		# The arc reaches the locked target before the landing animation starts.
		boss_air_y = -leap_height
		if not is_instance_valid(current_vine) or current_vine.stage in [current_vine.Stage.RELAXING, current_vine.Stage.RETRACTING, VINE_STAGE_DONE]:
			boss_state = "leap_dive"
			boss_time = 0.0
	elif boss_state == "leap_dive":
		var dive := clampf(boss_time / leap_dive_duration, 0.0, 1.0)
		boss_air_y = -leap_height * pow(1.0 - dive, 2.0)
		boss_x = lerpf(boss_takeoff_x, boss_target_x, dive)
		if dive >= 1.0:
			boss_air_y = 0.0
			boss_state = "recover"
			boss_time = 0.0
			open_window_time = randf_range(OPEN_WINDOW_MIN, OPEN_WINDOW_MAX)
			recovery_duration = open_window_time
	elif boss_state in ["recover", "ouch"]:
		boss_air_y = 0.0
		if boss_state == "ouch" and boss_time >= BOSS_HURT_STAGGER and open_window_time > 0.0:
			boss_state = "recover"
			boss_time = 0.0
		elif (boss_state == "ouch" and boss_time >= BOSS_HURT_STAGGER) or (boss_state == "recover" and open_window_time <= 0.0 and (recovery_duration >= OPEN_WINDOW_MIN or boss_time >= recovery_duration)):
			boss_state = "rest"
			boss_time = 0.0
	advance_vines(delta)
	# Summoned petals continue falling while she resumes close-range attacks.
	if fierce:
		if wind_time <= 0.0 and boss_state != "blossom_cast":
			wind_clock += delta
		wind_time = maxf(0.0, wind_time - delta)
		if wind_time > 0.0:
			rain_clock += delta
			if rain_clock >= BLOSSOM_SPAWN_INTERVAL:
				rain_clock = 0.0
				spawn_tree_petal(0.0)
	(backdrop.material as ShaderMaterial).set_shader_parameter("gust", 1.0 if wind_time > 0.0 else 0.12 * sin(flower_bob * 1.4))
	for i in range(shots.size() - 1, -1, -1):
		var s := shots[i]
		var old := Vector2(s.x, s.y)
		s.x += s.vx * delta
		if s.kind == "rain" or s.get("reflected", false):
			s.y += s.vy * delta
			s.angle += delta * 2.8
		s.life -= delta
		var current := Vector2(s.x, s.y)
		if s.get("reflected", false):
			var target := Vector2(boss_x, FLOOR + boss_air_y - 70)
			if Geometry2D.get_closest_point_to_segment(target, old, current).distance_to(target) < 35:
				shots.remove_at(i)
				if s.get("guard_damage", false):
					apply_boss_hit()
					return
				continue
		elif silk_guard.intercepts(old, current, Vector2(x, y)):
			var velocity := (Vector2(boss_x, FLOOR + boss_air_y - 70) - current).normalized() * 340.0
			s.reflected = true
			s.guard_damage = silk_guard.claim_counter()
			s.vx = velocity.x
			s.vy = velocity.y
			silk_guard.deflect()
			combat_sounds.play("umbrella_hit")
			continue
		if s.life <= 0 or s.x < -20 or s.y > FLOOR + 12.0:
			shots.remove_at(i)
			continue
		if not s.get("reflected", false) and absf(x - s.x) < 16.0 and absf((y - 28.0) - s.y) < 28.0:
			if invincible <= 0.0:
				damage_player(true, old)
			if phase == "failed":
				break
			shots.remove_at(i)

func spawn_tree_petal(x_offset: float) -> void:
	var start_x := randf_range(35.0, 390.0) + x_offset
	var start_y := randf_range(10.0, 145.0)
	var fall_speed := randf_range(120.0, 170.0)
	var landing_x := clampf(x + randf_range(-55.0, 55.0), 36.0, 920.0)
	var flight_time := (FLOOR - start_y - 28.0) / fall_speed
	shots.append({"x": start_x, "y": start_y, "vx": clampf((landing_x - start_x) / flight_time, -150.0, 260.0), "vy": fall_speed, "angle": randf_range(0.0, TAU), "life": 5.0, "kind": "rain", "variant": randi_range(0, 2)})

func damage_player(from_flower: bool, source: Vector2 = Vector2(INF, INF)) -> void:
	if phase == "battle" and battle_elapsed < OPENING_GRACE:
		return
	# A vine can cross Xiaoyu's body before its tip callback runs. Guard against its
	# caster's side, not the tip's final position behind the umbrella.
	var guard_threat := Vector2(boss_x, FLOOR + boss_air_y - 50) if not from_flower or is_inf(source.x) else source
	if phase == "battle" and silk_guard.blocks_body(Vector2(x, y), guard_threat):
		silk_guard.deflect()
		combat_sounds.play("umbrella_hit")
		if silk_guard.claim_counter():
			apply_boss_hit()
		return
	if invincible > 0.0:
		return
	silk_guard.cancel()
	hp -= 1
	girl_flash = GIRL_HIT_FLASH
	girl_spark = HIT_SPARK_DURATION
	var hit_from := boss_x if is_inf(source.x) else source.x
	girl_spark_position = Vector2(x + (8.0 if hit_from > x else -8.0), y - 38.0)
	impact_pause = HIT_PAUSE
	shake_time = HIT_SHAKE_DURATION
	combat_sounds.play("silk_burst")
	var away := 1.0 if from_flower else (-1.0 if x <= boss_x else 1.0)
	knockback_velocity = away * HURT_KNOCKBACK_SPEED
	knockback_time = HURT_KNOCKBACK_TIME
	x = clampf(x + away * 12.0, 32.0, 925.0)
	invincible = HURT_INVINCIBILITY
	if hp <= 0:
		phase = "failed"
		shots.clear()

func label(text: String, at: Vector2, size := 16, color := Color("e8e5ea")) -> void:
	draw_string(FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func umbrella_pose() -> Dictionary:
	var grip := Vector2(8, -55) if attack_up else Vector2(21, -38)
	var angle := -1.05 if attack_up else -0.08
	var pivot := Vector2(x + grip.x * facing, y + grip.y)
	var aim := Vector2(cos(angle) * facing, sin(angle))
	return {"pivot": pivot, "angle": angle, "tip": pivot + aim * 51.0}

func umbrella_hit_position() -> Vector2:
	var weapon := umbrella_pose()
	var start: Vector2 = weapon.pivot
	var tip: Vector2 = weapon.tip
	var body := Rect2(Vector2(boss_x - 40.0, FLOOR + boss_air_y - 132.0), Vector2(80.0, 132.0))
	if body.has_point(start):
		return start
	var corners := [body.position, Vector2(body.end.x, body.position.y), body.end, Vector2(body.position.x, body.end.y)]
	var nearest := INF
	var contact := tip
	for i in 4:
		var point: Variant = Geometry2D.segment_intersects_segment(start, tip, corners[i], corners[(i + 1) % 4])
		if point != null and start.distance_squared_to(point) < nearest:
			nearest = start.distance_squared_to(point)
			contact = point
	if nearest < INF:
		return contact
	return Vector2(clampf(tip.x, body.position.x, body.end.x), clampf(tip.y, body.position.y, body.end.y))

func draw_hit_spark(center: Vector2, time_left: float, color: Color) -> void:
	var t := 1.0 - clampf(time_left / HIT_SPARK_DURATION, 0.0, 1.0)
	var outline := Color(0.23, 0.28, 0.42, 0.75 * (1.0 - t))
	if t < 0.22:
		draw_line(center - Vector2(10, 0), center + Vector2(10, 0), outline, 5.0, true)
		draw_line(center - Vector2(0, 7), center + Vector2(0, 7), outline, 4.0, true)
		draw_line(center - Vector2(10, 0), center + Vector2(10, 0), color, 3.0, true)
		draw_line(center - Vector2(0, 7), center + Vector2(0, 7), color, 2.0, true)
	for i in 7:
		var ray := Vector2.from_angle(i * TAU / 7.0)
		var point := center + ray * (5.0 + t * 19.0)
		var faded := Color(color.r, color.g, color.b, color.a * (1.0 - t))
		draw_line(point, point + ray * 4.0, outline, 3.0, true)
		draw_line(point, point + ray * 4.0, faded, 1.6, true)
		draw_circle(point + ray * 4.0, 1.3, faded, true, -1.0, true)

func held_vine_visible() -> bool:
	if phase != "battle" or grief <= 0:
		return false
	for vine in vines:
		if is_instance_valid(vine) and vine.stage != VINE_STAGE_DONE:
			return false
	return true

func draw_held_vine() -> void:
	if not held_vine_visible():
		return
	var hand := boss_hand_offset()
	var root := Vector2(roundf(boss_x + boss_facing * hand.x), roundf(FLOOR + boss_air_y + hand.y))
	var points := PackedVector2Array()
	for i in HELD_VINE_POINTS.size():
		var bend: Vector2 = HELD_VINE_POINTS[i]
		var sway := sin(flower_bob * 2.8 - i * 0.4) * 1.7 * float(i) / float(HELD_VINE_POINTS.size() - 1)
		points.append((root + Vector2(boss_facing * (bend.x + sway), bend.y)).round())
	for i in range(points.size() - 1):
		var weight := 1.0 - float(i) / float(points.size() - 1)
		draw_line(points[i], points[i + 1], Color("494451"), 2.0 + 4.0 * weight, false)
		draw_line(points[i], points[i + 1], Color("858878"), 1.0 + 2.5 * weight, false)
	for station in [2, 4]:
		var tangent := points[station + 1] - points[station]
		draw_set_transform(points[station], snappedf(tangent.angle(), PI / 12.0))
		draw_texture(HELD_VINE_LEAF, Vector2(-1, -8))
	var tail := points[-1] - points[-2]
	draw_set_transform(points[-1], snappedf(tail.angle(), PI / 12.0))
	draw_texture(HELD_VINE_TIP, Vector2(0, -3))
	draw_set_transform(root, 0.0)
	draw_texture(HELD_VINE_ROOT, Vector2(-3, -5))
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if grief > 0:
		weather.draw(self)
	if inventory.opened:
		return
	var boss_tex: Texture2D = boss_idle_flash_frame if boss_flash > 0.0 else boss_idle_frame
	var animated_pose := false
	var calm_pose := phase in ["explore", "dialogue", "settling", "peace", "leaving"]
	if calm_pose:
		var calm_frame := 0 if int(floor(flower_bob * CALM_BREATH_FRAME_RATE)) % 2 == 0 else 3
		boss_tex = boss_dance_flash_frames[calm_frame] if boss_flash > 0.0 else boss_dance_frames[calm_frame]
		animated_pose = true
	elif boss_state == "ouch":
		boss_tex = boss_held_hit_flash_frame if boss_flash > 0.0 else boss_held_hit_frame
		animated_pose = boss_held_hit_animated
	elif boss_state == "rest" and boss_is_walking:
		var walk_frame := int(boss_walk_distance / BOSS_WALK_FRAME_DISTANCE) % boss_walk_frames.size()
		boss_tex = boss_walk_flash_frames[walk_frame] if boss_flash > 0.0 else boss_walk_frames[walk_frame]
		animated_pose = true
	elif boss_state in ["whip_prepare", "whip_release", "leap_whip"]:
		var cast_frame := vine_pose_frame()
		boss_tex = boss_cast_flash_frames[cast_frame] if boss_flash > 0.0 else boss_cast_frames[cast_frame]
		animated_pose = true
	elif boss_state in ["leap_rise", "leap_dive", "backhop", "vault", "opening_retreat"]:
		var leap_frame := 0
		if boss_state == "leap_rise":
			leap_frame = 1
		elif boss_state == "leap_dive":
			leap_frame = 2 if boss_time < leap_dive_duration * 0.75 else 3
		else:
			var hop_duration := 0.8 if boss_state == "opening_retreat" else (BOSS_BACKHOP_DURATION if boss_state == "backhop" else BOSS_VAULT_DURATION)
			leap_frame = mini(int(boss_time / hop_duration * 4.0), 3)
		boss_tex = boss_leap_flash_frames[leap_frame] if boss_flash > 0.0 else boss_leap_frames[leap_frame]
		animated_pose = true
	elif boss_state == "blossom_cast":
		var cast_frame := mini(int(boss_time / BLOSSOM_CAST_DURATION * 3.0), 2)
		boss_tex = boss_cast_flash_frames[cast_frame] if boss_flash > 0.0 else boss_cast_frames[cast_frame]
		animated_pose = true
	var boss_h := float(boss_tex.get_height())
	var boss_w := float(boss_tex.get_width())
	var boss_top := roundf(FLOOR - BOSS_FRAME_FOOT_Y + boss_air_y)
	draw_set_transform(Vector2(roundf(boss_x), FLOOR + 1.0), 0.0, Vector2(1.0, 0.24))
	draw_circle(Vector2.ZERO, 22.0 if boss_air_y > -12.0 else 13.0, Color(0.13, 0.1, 0.21, 0.33))
	draw_set_transform(Vector2.ZERO)
	draw_held_vine()
	var breath := sin(flower_bob * 2.1) if calm_pose else 0.0
	var breeze := sin(flower_bob * 1.3) if calm_pose else 0.0
	draw_set_transform(Vector2(roundf(boss_x), FLOOR), breeze * 0.006, Vector2(-boss_facing * (1.0 + breath * 0.004), 1.0 + breath * 0.006))
	draw_texture_rect(boss_tex, Rect2(roundf(-boss_w / 2), boss_top - FLOOR, boss_w, boss_h), false)
	draw_set_transform(Vector2.ZERO)
	if phase == "peace" and absf(x - boss_x) < 115.0:
		label("[E] Listen", Vector2(boss_x - 40, 292), 16, Color("ffe7bb"))
	if phase in ["battle", "settling"]:
		for s in shots:
			var blossom: Texture2D = hazard_blossoms[int(s.get("variant", 0)) % hazard_blossoms.size()]
			var scale_size := 1.65 + float(int(s.get("variant", 0))) * 0.12
			draw_set_transform(Vector2(roundf(s.x), roundf(s.y)), snappedf(s.angle, PI / 12.0), Vector2(scale_size, scale_size))
			draw_texture(blossom, Vector2(-6.5, -6.5))
		draw_set_transform(Vector2.ZERO)
	if phase == "settling":
		var calm := clampf(settle_time / SETTLE_DURATION, 0.0, 1.0)
		for ring in 2:
			var radius := (30.0 - ring * 11.0) * (1.0 - calm)
			if radius > 1.0:
				draw_arc(Vector2(774, 388), radius, 0.0, TAU, 28, Color(0.87, 0.92, 1.0, 0.55 * (1.0 - calm)), 1.0)
	var pose := 3 if y < FLOOR or dash_time > 0 else (4 if attack_time > 0 else 0)
	if silk_guard.active():
		pose = 4
	var tex := girl[pose]
	var foot := Vector2(roundf(x), roundf(y))
	walk.draw_shadow(self, foot, FLOOR)
	if girl_flash > 0.0 or invincible <= 0.0 or int(invincible * 14) % 2 == 0:
		# Mirror body and weapon together around the same foot anchor.
		draw_set_transform(foot, 0.0, Vector2(facing, 1))
		if not silk_guard.presenting():
			if pose == 0 and walk.walking and girl_flash <= 0.0:
				walk.draw_body(self, girl[0])
			else:
				var body_tex: Texture2D = girl_flash_frames[pose] if girl_flash > 0.0 else tex
				var size := body_tex.get_size()
				draw_texture_rect(body_tex, Rect2(Vector2(-floorf(size.x / 2), -size.y), size), false)
		if not silk_guard.presenting():
			var weapon := umbrella_pose() if attack_time > 0.0 else {"pivot": foot + Vector2(-2 * facing, -24), "angle": 0.38}
			draw_set_transform((weapon.pivot as Vector2).round(), weapon.angle * facing, Vector2(facing, 1))
			draw_texture_rect(umbrella, Rect2(-9, -4, 60, 11), false)
		draw_set_transform(Vector2.ZERO)
		if attack_time > 0.20 and attack_time < 0.28 and not silk_guard.presenting():
			var thrust := umbrella_pose()
			var aim := (thrust.tip as Vector2) - (thrust.pivot as Vector2)
			for i in 3:
				var side := aim.normalized().orthogonal() * float(i - 1) * 3.0
				draw_line(thrust.pivot + aim.normalized() * 25.0 + side, thrust.pivot + aim.normalized() * 47.0 + side, Color(0.68, 0.94, 1.0, 0.5), 1.1, true)
	silk_guard.draw(self, foot)
	if boss_spark > 0.0:
		draw_hit_spark(boss_spark_position, boss_spark, Color(0.9, 1.0, 1.0))
	if girl_spark > 0.0:
		draw_hit_spark(girl_spark_position, girl_spark, Color("f9c4d4"))
	label("CHAPTER 2 · WISTERIA RAIN", Vector2(28, 35), 17)
	if grief > 0:
		label("HEALTH  " + "●".repeat(hp) + "○".repeat(6 - hp), Vector2(28, 61), 16, Color("eec9aa"))
	if phase == "battle":
		label("Wisteria Spirit's Grief", Vector2(430, 34), 16)
		draw_rect(Rect2(350, 44, BOSS_BAR_WIDTH, 8), Color("384055"))
		draw_rect(Rect2(350, 44, BOSS_BAR_WIDTH * grief / MAX_GRIEF, 8), Color("d89bb8"))
	if phase == "failed":
		label("Petals cover the path... Press R to retry", Vector2(270, 270), 22)
	if phase == "peace":
		label("Memory recorded · N: Chapter Three · Esc: Pause", Vector2(290, 95), 16, Color("ffe0b0"))
	if paused:
		label("Paused · Esc: Resume · Q: Main Menu", Vector2(275, 255), 22)
