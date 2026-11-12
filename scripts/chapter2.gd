extends Node2D

const JOURNEY := preload("res://scripts/journey_state.gd")

const FLOOR := 448.0
const WALK_SPEED := 120.0
const MAX_GRIEF := 8
const ARENA_LEFT := 48.0
const ARENA_RIGHT := 912.0
const OPENING_GRACE := 1.2
const OPENING_SAFE_DISTANCE := 285.0
const OPENING_RETREAT_SPEED := 330.0
const COUNTER_WINDUP := 0.25
const THRUST_WARNING_LEAD := 0.15
const THRUST_ACTIVE_START := 0.08
const THRUST_ACTIVE_END := 0.18
const BODY_CONTACT_RADIUS := 32.0
const HURT_INVINCIBILITY := 1.0
const HURT_KNOCKBACK_SPEED := 265.0
const HURT_KNOCKBACK_TIME := 0.18
const HIT_COMBO_WINDOW := 1.5
const REACTION_COOLDOWN := 3.0
const PARRY_DURATION := 0.6
const WALL_MARGIN := 85.0
const BLOSSOM_CAST_DURATION := 0.9
const BLOSSOM_RELEASE_TIME := 0.52
const BLOSSOM_GUST_DURATION := 2.4
const BLOSSOM_BURST_COUNT := 5
const BLOSSOM_SPAWN_INTERVAL := 0.18
const SAVE := "user://chapter2_memory.cfg"
const FLOWER := preload("res://assets/chapter2/peach-spirit-idle.png")
const WINDUP := preload("res://assets/chapter2/peach-spirit-windup.png")
const SWING := preload("res://assets/chapter2/peach-spirit-swing.png")
const LUNGE := preload("res://assets/chapter2/peach-spirit-lunge.png")
const LEAP := preload("res://assets/chapter2/peach-spirit-leap.png")
const CAST := preload("res://assets/chapter2/peach-spirit-cast.png")
const GARDEN := preload("res://assets/chapter2/background_candidates/peach_orchard_c_960x540.png")
const FONT := preload("res://assets/chapter1/chinese.ttc")

@export_range(0.45, 0.6, 0.01) var thrust_windup := 0.5
@export_range(0.4, 0.6, 0.01) var thrust_recovery := 0.5

var girl: Array[Texture2D] = []
var boss_frames: Array[Texture2D] = []
var umbrella: Texture2D
var x := 155.0
var y := FLOOR
var vy := 0.0
var facing := 1
var walk = preload("res://scripts/hero_walk.gd").new()
var combat_sounds = preload("res://scripts/combat_sounds.gd").new()
var swing_played: bool = false
var hp := 6
var grief := MAX_GRIEF
var phase := "explore"
var settle_time := 0.0
const SETTLE_DURATION := 1.6
var lines: Array[String] = []
var dialogue_box = preload("res://scripts/dialogue_box.gd").new()
var line := 0
var after_lines := "battle"
var attack_time := 0.0
var attack_cooldown := 0.0
var hit_this_swing := false
var dash_time := 0.0
var dash_cooldown := 0.0
var invincible := 0.0
var knockback_time := 0.0
var knockback_velocity := 0.0
var battle_elapsed := 0.0
var boss_time := 0.0
var boss_state := "rest"
var pattern := 0
var branch_mode := "sweep"
var boss_air_y := 0.0
var boss_target_x := 0.0
var boss_takeoff_x := 0.0
var opening_goal_x := 0.0
var warning_played := false
var cast_released := false
var ultimate_pending := false
var hit_streak := 0
var last_hit_at := -10.0
var reaction_cooldown := 0.0
var recovery_duration := 0.36
var shots: Array[Dictionary] = []
var boss_x := 700.0
var boss_facing := -1
var freeze_time := 0.0
var wind_clock := 0.0
var wind_time := 0.0
var rain_clock := 0.0
var flower_bob := 0.0
var paused := false
var memory := false
var weather = preload("res://scripts/rain_weather.gd").new()
var test_mode := false

func _ready() -> void:
	if not test_mode:
		JOURNEY.remember_chapter("res://chapter2.tscn")
		JOURNEY.apply_preferences()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var backdrop := Sprite2D.new()
	backdrop.texture = GARDEN
	backdrop.centered = false
	backdrop.scale = Vector2(960.0 / GARDEN.get_width(), 540.0 / GARDEN.get_height())
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backdrop.z_index = -1
	var wind_shader := Shader.new()
	wind_shader.code = "shader_type canvas_item; uniform float gust = 0.0; void fragment() { vec2 uv = UV; float canopy = (1.0 - smoothstep(0.08, 0.56, uv.y)) * (1.0 - smoothstep(0.34, 0.54, uv.x)); uv.x += canopy * gust * (0.002 + 0.002 * sin(TIME * 3.5 + uv.y * 13.0)); COLOR = texture(TEXTURE, uv); }"
	var wind_material := ShaderMaterial.new()
	wind_material.shader = wind_shader
	backdrop.material = wind_material
	add_child(backdrop)
	weather.reset(Vector2(960, 540))
	walk.setup_audio(self)
	combat_sounds.setup(self)
	dialogue_box.mount(self)
	for i in 6:
		girl.append(load("res://assets/chapter1/pixel/girl/pose_%d.png" % i))
	# Reduce every pose once to its exact on-screen size: one texture pixel = one screen pixel.
	# The standing poses share one scale; the lower strike uses the same scale
	# but a shorter canvas, keeping her head the same size while she crouches.
	for spec in [[FLOWER, 148], [WINDUP, 148], [SWING, 116], [LUNGE, 92], [LEAP, 104], [CAST, 148]]:
		var source: Texture2D = spec[0]
		var height: int = spec[1]
		var image := source.get_image()
		var width := maxi(1, roundi(height * source.get_width() / float(source.get_height())))
		image.resize(width, height, Image.INTERPOLATE_NEAREST)
		image.convert(Image.FORMAT_RGBA8)
		for py in height:
			for px in width:
				var color := image.get_pixel(px, py)
				color.a = 1.0 if color.a >= 0.5 else 0.0
				image.set_pixel(px, py, color)
		boss_frames.append(ImageTexture.create_from_image(image))
	umbrella = load("res://assets/chapter1/pixel/girl/umbrella.png")
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		memory = cfg.get_value("story", "hibiscus", false)
	if not test_mode:
		memory = memory or "res://chapter2.tscn" in JOURNEY.completed_chapters()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode
	if phase == "settling":
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
	if freeze_time > 0.0:
		return
	if key == KEY_N and phase == "peace":
		get_tree().change_scene_to_file("res://chapter3.tscn")
		return
	if key == KEY_E and absf(x - boss_x) < 115.0 and phase in ["explore", "peace"]:
		if phase == "explore":
			start_lines([
				"Xiaoyu: I think there's someone in the well.",
				"Peach Spirit: Shh... Don't wrinkle the water.",
				"Xiaoyu: Is that his reflection?",
				"Peach Spirit: He used to come here every day to read poetry.",
				"Xiaoyu: Did you ever speak to him?",
				"Peach Spirit: No. I kept waiting for the blossoms to look a little lovelier.",
				"Xiaoyu: But he isn't coming back, is he?",
				"Peach Spirit: Just a little longer. When the water settles, he'll be here.",
				"(The flowering branches quietly close the garden gate.)",
			], "battle")
		else:
			start_lines(["Peach Spirit: Do the blossoms look lovely today?", "Xiaoyu: Very lovely.", "Peach Spirit: Good. Next time you come, I'll look up."], "peace")
		return
	if key == KEY_SPACE and y >= FLOOR - 0.1:
		vy = -355.0
	if key in [KEY_SHIFT, KEY_K] and dash_cooldown <= 0.0:
		dash_time = 0.18
		dash_cooldown = 0.9
		invincible = maxf(invincible, 0.25)
	if key == KEY_J and attack_cooldown <= 0.0 and phase in ["battle", "explore", "peace"]:
		attack_time = 0.31
		attack_cooldown = 0.43
		hit_this_swing = false
		swing_played = false

func start_lines(text: Array[String], next: String) -> void:
	walk.stop_audio()
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
	battle_elapsed = 0.0
	boss_time = 0.0
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
	queue_redraw()
	dialogue_box.visible = phase == "dialogue" and not paused
	if dialogue_box.visible and dialogue_box.advance_time(delta, Input.is_physical_key_pressed(KEY_CTRL)):
		next_line()

func _physics_process(delta: float) -> void:
	if paused:
		queue_redraw()
		walk.stop_audio()
		combat_sounds.stop_all()
		return
	flower_bob += delta
	if phase == "settling":
		settle_time += delta
		boss_facing = -1 if x < boss_x else 1
		if settle_time >= SETTLE_DURATION:
			start_lines([
				"Peach Spirit: The water's stirred... This time, I can't make him stay.",
				"Xiaoyu: What did you want to tell him?",
				"Peach Spirit: Please come again tomorrow night.",
				"Peach Spirit: But I always stayed behind the tree.",
				"Xiaoyu: I can sit with you for a while.",
				"Peach Spirit: ...What's your name?",
				"Xiaoyu: Xiaoyu.",
				"Peach Spirit: Take care on the road, Xiaoyu.",
			], "peace")
		queue_redraw()
		return
	var previous_x := x
	freeze_time = maxf(0.0, freeze_time - delta)
	if phase not in ["dialogue", "failed"] and freeze_time <= 0.0:
		if knockback_time > 0.0:
			x = clampf(x + knockback_velocity * delta, 32.0, 925.0)
			knockback_time = maxf(0.0, knockback_time - delta)
		else:
			var direction := int(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
			if direction != 0:
				facing = direction
			x = clampf(x + direction * (410.0 if dash_time > 0 else WALK_SPEED) * delta, 32.0, 925.0)
		vy = minf(vy + 950.0 * delta, 600.0)
		y = minf(FLOOR, y + vy * delta)
		if y >= FLOOR:
			vy = 0.0
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
		update_boss(delta)
		if battle_elapsed >= OPENING_GRACE and not dash_active and boss_air_y > -30.0 and absf(x - boss_x) < BODY_CONTACT_RADIUS and y > FLOOR - 100.0:
			if invincible <= 0.0:
				damage_player(false)
			else:
				x = boss_x - BODY_CONTACT_RADIUS if x <= boss_x else boss_x + BODY_CONTACT_RADIUS
		if attack_time > 0.09 and attack_time < 0.25 and not hit_this_swing and battle_elapsed >= OPENING_GRACE and boss_air_y > -35.0 and (boss_x - x) * facing > 0 and absf(x - boss_x) < 85.0 and y > FLOOR - 100.0:
			apply_boss_hit()
	queue_redraw()

func apply_boss_hit() -> void:
	hit_this_swing = true
	if boss_state == "parry":
		boss_state = "counter_prepare"
		boss_time = 0.0
		warning_played = false
		branch_mode = "counter"
		return
	grief -= 1
	combat_sounds.play("umbrella_hit")
	boss_air_y = 0.0
	if grief <= 0:
		if not test_mode:
			JOURNEY.complete_chapter("res://chapter2.tscn")
		phase = "settling"
		settle_time = 0.0
		wind_time = 0.0
		walk.stop_audio()
		return
	if grief == 4:
		ultimate_pending = true
	if battle_elapsed - last_hit_at <= HIT_COMBO_WINDOW:
		hit_streak += 1
	else:
		hit_streak = 1
	last_hit_at = battle_elapsed
	if hit_streak >= 3 and reaction_cooldown <= 0.0:
		hit_streak = 0
		reaction_cooldown = REACTION_COOLDOWN
		boss_facing = -1 if x < boss_x else 1
		var room_behind := boss_x - ARENA_LEFT if boss_facing > 0 else ARENA_RIGHT - boss_x
		if room_behind > 125.0 and randi() % 2 == 0:
			start_boss_escape("backhop", clampf(boss_x - boss_facing * 120.0, ARENA_LEFT, ARENA_RIGHT))
		else:
			boss_state = "parry"
			boss_time = 0.0
	else:
		boss_state = "ouch"
		boss_time = 0.0
	shots.clear()

func start_boss_escape(kind: String, target: float) -> void:
	boss_state = kind
	boss_time = 0.0
	boss_takeoff_x = boss_x
	boss_target_x = target

func update_boss(delta: float) -> void:
	var elapsed_before := battle_elapsed
	battle_elapsed += delta
	reaction_cooldown = maxf(0.0, reaction_cooldown - delta)
	boss_time += delta
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
	var fierce := grief <= 4
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
			boss_time = 0.0
			cast_released = false
			ultimate_pending = false
		elif absf(boss_x - x) > 65.0:
			boss_x = move_toward(boss_x, x - boss_facing * 65.0, (185.0 if fierce else 145.0) * delta)
		var next_mode := "leap" if fierce and pattern % 3 == 2 else ("thrust" if pattern % 2 == 0 else "sweep")
		var start_range := 150.0 if next_mode != "sweep" else 77.0
		if boss_state == "rest" and boss_time >= (0.18 if fierce else 0.28) and absf(boss_x - x) <= start_range:
			branch_mode = next_mode
			pattern += 1
			boss_time = 0.0
			warning_played = false
			if branch_mode == "leap":
				boss_state = "leap_rise"
				boss_takeoff_x = boss_x
			else:
				boss_state = "branch_prepare"
	elif boss_state in ["branch_prepare", "counter_prepare"]:
		if branch_mode == "thrust" and absf(boss_x - x) < 93.0:
			boss_x = move_toward(boss_x, x - boss_facing * 93.0, 150.0 * delta)
		var windup := COUNTER_WINDUP if boss_state == "counter_prepare" else (thrust_windup if branch_mode == "thrust" else (0.25 if fierce else 0.34))
		if branch_mode in ["thrust", "counter"] and not warning_played and boss_time >= windup - THRUST_WARNING_LEAD:
			warning_played = true
			combat_sounds.play("silk_charge")
		if boss_time >= windup:
			boss_state = "branch_swing" if branch_mode == "sweep" else "branch_lunge"
			boss_time = 0.0
			boss_target_x = clampf(x - boss_facing * 48.0, ARENA_LEFT, ARENA_RIGHT)
			combat_sounds.stop("silk_charge")
	elif boss_state == "branch_lunge":
		boss_x = move_toward(boss_x, boss_target_x, (460.0 if fierce else 385.0) * delta)
		if boss_time >= 0.27:
			boss_state = "recover"
			boss_time = 0.0
			recovery_duration = thrust_recovery
	elif boss_state == "branch_swing" and boss_time >= 0.24:
		boss_state = "recover"
		boss_time = 0.0
		recovery_duration = 0.25 if fierce else 0.36
	elif boss_state == "blossom_cast":
		if not cast_released and boss_time >= BLOSSOM_RELEASE_TIME:
			cast_released = true
			wind_time = BLOSSOM_GUST_DURATION
			wind_clock = 0.0
			rain_clock = 0.0
			for blossom in BLOSSOM_BURST_COUNT:
				spawn_tree_petal(float(blossom) * 9.0)
		if boss_time >= BLOSSOM_CAST_DURATION:
			boss_state = "rest"
			boss_time = 0.0
	elif boss_state == "parry" and boss_time >= PARRY_DURATION:
		boss_state = "rest"
		boss_time = 0.0
	elif boss_state in ["backhop", "vault"]:
		var duration := 0.34 if boss_state == "backhop" else 0.58
		var escape := clampf(boss_time / duration, 0.0, 1.0)
		boss_x = lerpf(boss_takeoff_x, boss_target_x, escape)
		boss_air_y = -(48.0 if boss_state == "backhop" else 105.0) * sin(PI * escape)
		if escape >= 1.0:
			boss_air_y = 0.0
			boss_state = "recover"
			boss_time = 0.0
			recovery_duration = 0.2
	elif boss_state == "leap_rise":
		var rise := clampf(boss_time / 0.31, 0.0, 1.0)
		boss_air_y = -76.0 * sin(rise * PI * 0.5)
		boss_x = lerpf(boss_takeoff_x, boss_takeoff_x - boss_facing * 36.0, rise)
		if rise >= 1.0:
			boss_state = "leap_dive"
			boss_time = 0.0
			boss_takeoff_x = boss_x
			boss_target_x = clampf(x - boss_facing * 52.0, 52.0, 908.0)
	elif boss_state == "leap_dive":
		var dive := clampf(boss_time / 0.31, 0.0, 1.0)
		boss_air_y = -76.0 * pow(1.0 - dive, 2.0)
		boss_x = lerpf(boss_takeoff_x, boss_target_x, dive)
		if dive >= 1.0:
			boss_air_y = 0.0
			boss_state = "recover"
			boss_time = 0.0
			recovery_duration = 0.25 if fierce else 0.36
	elif boss_state in ["recover", "ouch"]:
		boss_air_y = 0.0
		if boss_time >= (0.27 if boss_state == "ouch" else recovery_duration):
			boss_state = "rest"
			boss_time = 0.0
	if invincible <= 0.0:
		var reach := 0.0
		var body_overlap := false
		if boss_state == "branch_swing" and boss_time >= 0.03 and boss_time <= 0.21:
			reach = 74.0
		elif boss_state == "branch_lunge" and boss_time >= THRUST_ACTIVE_START and boss_time <= THRUST_ACTIVE_END:
			reach = 104.0
			body_overlap = true
		elif boss_state == "leap_dive" and boss_air_y > -35.0:
			reach = 84.0
		var forward := (x - boss_x) * boss_facing
		if reach > 0.0 and forward < reach and (forward >= -BODY_CONTACT_RADIUS if body_overlap else forward > 0.0) and absf((y - 35.0) - (FLOOR - 44.0)) < 31.0:
			damage_player(false)
	# Summoned petals continue falling while she resumes close-range attacks.
	if grief <= 4:
		if wind_time <= 0.0 and boss_state != "blossom_cast":
			wind_clock += delta
		wind_time = maxf(0.0, wind_time - delta)
		if wind_time > 0.0:
			rain_clock += delta
			if rain_clock >= BLOSSOM_SPAWN_INTERVAL:
				rain_clock = 0.0
				spawn_tree_petal(0.0)
	var backdrop := get_child(0) as Sprite2D
	(backdrop.material as ShaderMaterial).set_shader_parameter("gust", 1.0 if wind_time > 0.0 else 0.18 * sin(flower_bob * 1.4))
	for i in range(shots.size() - 1, -1, -1):
		var s := shots[i]
		s.x += s.vx * delta
		if s.kind == "rain":
			s.y += s.vy * delta
			s.angle += delta * 2.8
		s.life -= delta
		if s.life <= 0 or s.x < -20 or s.y > FLOOR + 12.0:
			shots.remove_at(i)
			continue
		if invincible <= 0.0 and absf(x - s.x) < 16.0 and absf((y - 28.0) - s.y) < 28.0:
			damage_player(true)
			if phase == "failed":
				break
			shots.remove_at(i)

func spawn_tree_petal(x_offset: float) -> void:
	shots.append({"x": randf_range(35.0, 390.0) + x_offset, "y": randf_range(10.0, 145.0), "vx": randf_range(130.0, 225.0), "vy": randf_range(105.0, 160.0), "angle": randf_range(0.0, TAU), "life": 5.0, "kind": "rain"})

func damage_player(from_rain: bool) -> void:
	if phase == "battle" and battle_elapsed < OPENING_GRACE:
		return
	if invincible > 0.0:
		return
	if not from_rain:
		hp -= 1
		var away := -1.0 if x <= boss_x else 1.0
		knockback_velocity = away * HURT_KNOCKBACK_SPEED
		knockback_time = HURT_KNOCKBACK_TIME
		x = clampf(x + away * 12.0, 32.0, 925.0)
	invincible = HURT_INVINCIBILITY
	if from_rain:
		freeze_time = 1.0
		vy = 0.0
	if hp <= 0:
		phase = "failed"
		shots.clear()

func label(text: String, at: Vector2, size := 16, color := Color("e8e5ea")) -> void:
	draw_string(FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	weather.draw(self)
	var boss_index := 0
	if boss_state in ["branch_prepare", "counter_prepare", "parry"]:
		boss_index = 1
	elif boss_state == "branch_swing":
		boss_index = 2
	elif boss_state == "branch_lunge":
		boss_index = 3
	elif boss_state in ["leap_rise", "leap_dive", "backhop", "vault", "opening_retreat"]:
		boss_index = 4
	elif boss_state == "blossom_cast":
		boss_index = 5
	var boss_tex: Texture2D = boss_frames[boss_index]
	var boss_h := float(boss_tex.get_height())
	var boss_w := float(boss_tex.get_width())
	var hop := -3.0 * absf(sin(flower_bob * 8.0)) if phase == "battle" else 0.0
	var foot_offset := 9.0 if boss_index == 2 else (5.0 if boss_index >= 3 else 3.0)
	var boss_top := roundf(FLOOR - boss_h + foot_offset + hop + boss_air_y)
	# The striking body sits right of its long branch in the source image.
	# Offset that pose so her feet stay planted as the branch reaches forward.
	var pose_shift := 14.0 if boss_index == 2 else (21.0 if boss_index == 3 else (13.0 if boss_index == 4 else (8.0 if boss_index == 5 else 0.0)))
	draw_set_transform(Vector2(roundf(boss_x), 0), 0.0, Vector2(-boss_facing, 1))
	draw_texture_rect(boss_tex, Rect2(roundf(-boss_w / 2 - pose_shift), boss_top, boss_w, boss_h), false)
	draw_set_transform(Vector2.ZERO)
	if boss_state in ["branch_prepare", "counter_prepare"] and warning_played:
		var branch_tip := Vector2(roundf(boss_x - boss_facing * 46.0), roundf(FLOOR - 135.0 + boss_air_y))
		draw_circle(branch_tip, 10.0, Color(1.0, 0.86, 0.62, 0.32))
		draw_circle(branch_tip, 4.0, Color(1.0, 0.99, 0.88, 0.95))
	if phase in ["explore", "peace"] and absf(x - boss_x) < 115.0:
		label("[E] Listen", Vector2(boss_x - 40, 292), 16, Color("ffe7bb"))
	if phase in ["battle", "settling"]:
		for s in shots:
			var a: float = s.angle
			var axis := Vector2(cos(a), sin(a))
			var side := axis.orthogonal()
			var center := Vector2(s.x, s.y)
			var petal := PackedVector2Array([center + axis * 10.0 + side * 2.0, center + axis * 7.0 + side * 7.0, center + side * 8.0, center - axis * 9.0, center - side * 8.0, center + axis * 7.0 - side * 7.0, center + axis * 10.0 - side * 2.0, center + axis * 6.0])
			draw_colored_polygon(petal, Color("ffc4a1"))
			for edge in petal.size():
				draw_line(petal[edge], petal[(edge + 1) % petal.size()], Color("71334b"), 2.0)
			draw_circle(center - axis * 3.0, 2.5, Color("ef806f"))
	if phase == "settling":
		var calm := clampf(settle_time / SETTLE_DURATION, 0.0, 1.0)
		for ring in 2:
			var radius := (30.0 - ring * 11.0) * (1.0 - calm)
			if radius > 1.0:
				draw_arc(Vector2(877, 416), radius, 0.0, TAU, 28, Color(0.87, 0.92, 1.0, 0.55 * (1.0 - calm)), 1.0)
	var pose := 3 if y < FLOOR or dash_time > 0 else (4 if attack_time > 0 else 0)
	var tex := girl[pose]
	var foot := Vector2(roundf(x), roundf(y))
	walk.draw_shadow(self, foot, FLOOR)
	if invincible <= 0.0 or int(invincible * 12) % 2 == 0:
		# Mirror body and weapon together around the same foot anchor.
		draw_set_transform(foot, 0.0, Vector2(facing, 1))
		if pose == 0 and walk.walking:
			walk.draw_body(self, girl[0])
		else:
			var size := tex.get_size()
			draw_texture_rect(tex, Rect2(Vector2(-floorf(size.x / 2), -size.y), size), false)
		var grip := Vector2(21, -38) if attack_time > 0 else Vector2(-2, -24)
		var angle := -0.08 if attack_time > 0 else 0.38
		draw_set_transform(foot + Vector2(grip.x * facing, grip.y), angle * facing, Vector2(facing, 1))
		draw_texture_rect(umbrella, Rect2(-9, -4, 60, 11), false)
		draw_set_transform(Vector2.ZERO)
	label("CHAPTER 2 · PEACH BLOSSOM RAIN", Vector2(28, 35), 17)
	label("HEALTH  " + "●".repeat(hp) + "○".repeat(6 - hp), Vector2(28, 61), 16, Color("eec9aa"))
	if phase == "battle":
		label("Peach Spirit's Grief", Vector2(430, 34), 16)
		draw_rect(Rect2(350, 44, 260, 8), Color("384055"))
		draw_rect(Rect2(350, 44, 260.0 * grief / MAX_GRIEF, 8), Color("d89bb8"))
	if phase == "failed":
		label("Petals cover the path... Press R to retry", Vector2(270, 270), 22)
	if freeze_time > 0.0 and phase == "battle":
		label("Caught in the petals!", Vector2(clampf(x - 65, 10, 800), y - 88), 14, Color("fff1cf"))
	if phase == "peace":
		label("Memory recorded · N: Chapter Three · Esc: Pause", Vector2(290, 95), 16, Color("ffe0b0"))
	if paused:
		label("Paused · Esc: Resume · Q: Main Menu", Vector2(275, 255), 22)
