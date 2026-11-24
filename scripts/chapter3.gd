extends Node2D

const JOURNEY := preload("res://scripts/journey_state.gd")
const BACKGROUND := preload("res://assets/chapter3/backgrounds/moon_bamboo_wedding_pixel_v1.png")
const BOSS := preload("res://assets/chapter3/pixel/qingyan_idle.png")
const BOSS_WALK := [preload("res://assets/chapter3/pixel/qingyan_walk_0.png"), preload("res://assets/chapter3/pixel/qingyan_walk_1.png"), preload("res://assets/chapter3/pixel/qingyan_walk_2.png")]
const BOSS_JUMP := preload("res://assets/chapter3/pixel/qingyan_jump.png")
const BOSS_BREATH := [
	preload("res://assets/chapter3/pixel/qingyan_breath_0.png"),
	preload("res://assets/chapter3/pixel/qingyan_breath_1.png"),
	preload("res://assets/chapter3/pixel/qingyan_breath_2.png"),
	preload("res://assets/chapter3/pixel/qingyan_breath_3.png"),
	preload("res://assets/chapter3/pixel/qingyan_breath_4.png"),
	preload("res://assets/chapter3/pixel/qingyan_breath_5.png"),
]
const FIRE_PURPLE_SPRITE := preload("res://assets/chapter3/pixel/foxfire_purple_flight.png")
const FONT := preload("res://assets/chapter1/chinese.ttc")

const FLOOR := 438.0
const WALK_SPEED := 120.0
const BOSS_X := 700.0
const BOSS_MIN_X := 110.0
const BOSS_MAX_X := 850.0
const BODY_GAP := 43.0
const MAX_BOSS_HP := 8
const MAX_PLAYER_HP := 6
const WINDUP := 0.4
const FAN_SPEED := 260.0
const FAN_SHOT_GAP := 0.28
const GROUND_WARNING := 0.85
const GROUND_ACTIVE := 0.9
const FIRE_RED := Color("d94132")
const FIRE_VIOLET := Color("9c69dc")
const FIRE_LILAC := Color("dfc7ff")

var girl: Array[Texture2D] = []
var turn_frames: Array[Texture2D] = []
var turn_time := -1.0
var umbrella: Texture2D
var walk = preload("res://scripts/hero_walk.gd").new()
var silk_guard = preload("res://scripts/silk_guard.gd").new()
var inventory = preload("res://scripts/inventory_panel.gd").new()
var combat_sounds = preload("res://scripts/combat_sounds.gd").new()
var dialogue_box = preload("res://scripts/dialogue_box.gd").new()
var weather = preload("res://scripts/rain_weather.gd").new()

var player := Vector2(90.0, FLOOR)
var vy := 0.0
var facing := 1
var hp := MAX_PLAYER_HP
var boss_hp := MAX_BOSS_HP
var phase := "explore"
var paused := false
var test_mode := false
var invincible := 0.0
var dash_time := 0.0
var dash_cooldown := 0.0
var attack_time := 0.0
var attack_cooldown := 0.0
var attack_facing := 1
var hit_this_swing := false
var swing_played := false
var boss_flash := 0.0
var player_flash := 0.0
var hit_stop := 0.0
var hit_feedback := 0.0
var hit_position := Vector2.ZERO
var shake_time := 0.0
var feedback_clock := 0.0
var reduce_shake := false
var boss_x := BOSS_X
var boss_facing := -1
var boss_rise := 0.0
var boss_walk_clock := 0.0
var boss_last_motion := 0.0
var hug_time := 0.0
var forced_fan := false
var dash_start := 0.0
var dash_target := 0.0
var dash_direction := 1
var backjump_direction := -1
var boss_visible := false
var teleport_landing := 0.0
var teleport_origin := Vector2.ZERO
var teleport_direction := 1

var lines: Array[String] = []
var line_index := 0
var after_lines := "battle"

var boss_attack := "approach"
var boss_timer := 0.0
var pattern_index := 0
var foxfires: Array[Dictionary] = []
var fan_shots := 0
var fan_anchor := 0.0
var ground_fires: Array[float] = []
var ground_hit := false
var white_textures: Dictionary = {}

func _ready() -> void:
	if not test_mode:
		JOURNEY.remember_chapter("res://chapter3.tscn")
		JOURNEY.apply_preferences()
		reduce_shake = bool(JOURNEY.preferences().get_value("settings", "reduce_shake", false))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var backdrop := Sprite2D.new()
	backdrop.texture = BACKGROUND
	backdrop.centered = false
	backdrop.scale = Vector2(960.0 / BACKGROUND.get_width(), 540.0 / BACKGROUND.get_height())
	backdrop.z_index = -1
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(backdrop)
	var wedding_lanterns := preload("res://scripts/wedding_lanterns.gd").new()
	wedding_lanterns.z_index = -1
	add_child(wedding_lanterns)
	for i in 6:
		girl.append(load("res://assets/chapter1/pixel/girl/pose_%d.png" % i))
	var turn_sheet := Image.load_from_file("res://assets/chapter3/concepts/xiaoyu_turn_sheet.png")
	var cell_width := turn_sheet.get_width() / 4
	for i in 4:
		var cell := turn_sheet.get_region(Rect2i(i * cell_width, 0, cell_width, turn_sheet.get_height()))
		var cropped := cell.get_region(cell.get_used_rect())
		var height := girl[0].get_height()
		cropped.resize(roundi(float(cropped.get_width()) * height / cropped.get_height()), height, Image.INTERPOLATE_NEAREST)
		turn_frames.append(ImageTexture.create_from_image(cropped))
	umbrella = load("res://assets/chapter1/pixel/girl/umbrella.png")
	weather.reset(Vector2(960, 540))
	walk.setup_audio(self)
	combat_sounds.setup(self)
	dialogue_box.mount(self)
	silk_guard.setup(JOURNEY.has_silk_guard())
	inventory.mount(self)
	queue_redraw()

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
	if key == KEY_ESCAPE:
		paused = not paused
		return
	if key == KEY_Q and paused:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	if paused:
		return
	if phase == "peace" and key == KEY_N:
		get_tree().change_scene_to_file("res://chapter4.tscn")
		return
	if phase == "dialogue":
		if key in [KEY_E, KEY_SPACE, KEY_ENTER]:
			if dialogue_box.reveal_or_continue():
				_next_line()
		return
	if phase == "failed":
		if key == KEY_R:
			get_tree().reload_current_scene()
		return
	if phase not in ["explore", "battle", "peace"]:
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
	if key == KEY_SPACE and player.y >= FLOOR - 0.1:
		vy = -355.0
	if key == KEY_SHIFT and dash_cooldown <= 0.0:
		dash_time = 0.18
		dash_cooldown = 0.9
		invincible = 0.25
	if key == KEY_J and attack_cooldown <= 0.0:
		silk_guard.interrupt_close()
		attack_time = 0.31
		attack_cooldown = 0.43
		attack_facing = facing
		hit_this_swing = false
		swing_played = false

func _start_opening() -> void:
	boss_visible = false
	facing = 1
	vy = 0.0
	dash_time = 0.0
	attack_time = 0.0
	_start_lines([
		"（雨夜，树林深处有红灯一闪。小语循着灯光走，却又回到同一棵树前。）",
		"青砚：喂，小姑娘……看得见我吗？",
		"（小语停下脚步，仍望着前方。声音却从身后传来。）",
		"小语：……谁？",
		"青砚：回头看看嘛。",
		"小语：我才不上当呢。",
		"（身后静了下来。小语犹豫片刻，还是回过头。戴白狐面具的青砚站在她身后。）",
		"青砚：怎么样？像不像人？",
		"小语：不像，不像！你是妖怪。",
		"青砚：这么快？我明明还没有摘除面具。所以，你看到那边的迎亲队伍了么？",
		"小语：看见了。怎么了？",
		"青砚：狐狸娶亲会借雨藏住行踪。人若撞见，就犯了禁忌。",
		"小语：我只是迷路了，又不是故意偷看。",
		"青砚：我知道。可你不能再往前走。",
		"（青砚抬手，狐火拦在小语面前。小语以为他要袭击自己，挥伞挡开。）",
	], "battle")

func _start_ending() -> void:
	_start_lines([
		"青砚：哎哟……我只是想拦住你。",
		"小语：你放火拦路，谁知道你想干什么？",
		"青砚：你已经看见婚礼了。队伍要是发现，会来找你。",
		"小语：那现在怎么办？",
		"（青砚从袖中拿出酒壶和两个杯子。）",
		"青砚：收下一杯喜酒，就算婚礼的客人，不算偷看。",
		"小语：所以你一开始是想请我喝酒？",
		"青砚：其实想请你去喝喜酒。轿子里的新娘，是我喜欢的人类姑娘。",
		"小语：新郎是你？",
		"青砚：可惜不是。她今天嫁给别人。",
		"小语：那你还要去？",
		"青砚：想看她一眼，也想知道她还记不记得我。",
		"小语：你很怕被忘记？",
		"青砚：只要有人记得，你就一直存在。狐狸活得久，也怕没人记得。",
		"小语：我会记得你。戴白狐面具、放火拦路的那位。",
		"青砚：……记点好事吧。我叫青砚。",
		"小语：青砚。我记住了。",
		"青砚：那就陪我走一程？",
		"小语：我不喝酒。",
		"青砚：杯子拿着就行。酒我喝。",
	], "peace")

func _start_lines(text: Array[String], next_phase: String) -> void:
	silk_guard.cancel()
	lines = dialogue_box.merge_lines(text)
	line_index = 0
	after_lines = next_phase
	phase = "dialogue"
	walk.stop_audio()
	dialogue_box.show_line(lines[0])
	if not test_mode and next_phase == "battle":
		JOURNEY.meet_chapter("res://chapter3.tscn", lines)

func _next_line() -> void:
	if turn_time >= 0.0:
		return
	line_index += 1
	if line_index < lines.size():
		dialogue_box.show_line(lines[line_index])
		if lines[line_index].begins_with("（身后静了下来"):
			boss_x = clampf(player.x - 185.0, BOSS_MIN_X, BOSS_MAX_X)
			boss_facing = 1
			turn_time = 0.0
	else:
		dialogue_box.hide()
		phase = after_lines
		if phase == "battle":
			boss_visible = true
			boss_attack = "approach"
			boss_timer = 0.0
		elif phase == "peace" and not test_mode:
			JOURNEY.complete_chapter("res://chapter3.tscn")

func _process(delta: float) -> void:
	weather.advance(delta)
	if not paused and not inventory.opened:
		feedback_clock += delta
		if hit_stop <= 0.0:
			hit_feedback = maxf(0.0, hit_feedback - delta)
		shake_time = maxf(0.0, shake_time - delta)
	var shake_strength := pow(shake_time / 0.18, 2) if not reduce_shake else 0.0
	position = (Vector2(sin(feedback_clock * 95) * 3.0, cos(feedback_clock * 113) * 1.7) * shake_strength).round()
	if turn_time >= 0.0 and not paused and not inventory.opened:
		turn_time += delta
		if turn_time >= 0.55:
			facing = -1
			boss_visible = true
		if turn_time >= 1.0:
			turn_time = -1.0
	dialogue_box.visible = phase == "dialogue" and not paused and not inventory.opened
	if dialogue_box.visible and dialogue_box.advance_time(delta, Input.is_physical_key_pressed(KEY_CTRL)):
		_next_line()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if paused or inventory.opened:
		walk.stop_audio()
		combat_sounds.stop_all()
		return
	silk_guard.advance(delta, phase in ["explore", "battle", "peace"])
	if hit_stop > 0.0:
		hit_stop = maxf(0.0, hit_stop - delta)
		queue_redraw()
		return
	var old_x := player.x
	if phase in ["explore", "battle", "peace"]:
		var axis := int(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		if silk_guard.active():
			axis = 0
			facing = silk_guard.facing
		elif axis != 0:
			silk_guard.interrupt_close()
		if axis != 0:
			facing = axis
		player.x = clampf(player.x + axis * (410.0 if dash_time > 0.0 else WALK_SPEED) * delta, 35.0, 925.0)
		vy = minf(vy + 950.0 * delta, 600.0)
		player.y = minf(FLOOR, player.y + vy * delta)
		if player.y >= FLOOR:
			vy = 0.0
		if phase == "battle":
			_keep_player_out_of_boss(old_x)
		if phase == "explore" and player.x >= 350.0 and player.y >= FLOOR:
			_start_opening()
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	attack_time = maxf(0.0, attack_time - delta)
	if attack_time > 0.0 and attack_time <= 0.25 and not swing_played:
		swing_played = true
		combat_sounds.play("umbrella_swing")
	dash_time = maxf(0.0, dash_time - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	invincible = maxf(0.0, invincible - delta)
	boss_flash = maxf(0.0, boss_flash - delta)
	player_flash = maxf(0.0, player_flash - delta)
	walk.advance(player.x - old_x, player.y >= FLOOR and attack_time <= 0.0 and dash_time <= 0.0 and phase in ["explore", "battle", "peace"])
	if phase == "battle":
		_update_attacks(delta)
		if _umbrella_active() and not hit_this_swing and boss_visible:
			var contact := _umbrella_contact()
			if contact.is_finite():
				hit_this_swing = true
				_hit_boss(1, contact)
	queue_redraw()

func _umbrella_active() -> bool:
	return attack_time > 0.08 and attack_time < 0.25

func _attack_grip() -> Vector2:
	return player + Vector2(21 * attack_facing, -38)

func _umbrella_contact() -> Vector2:
	var base := _attack_grip()
	var tip := base + Vector2(51 * attack_facing, 0).rotated(-0.08 * attack_facing)
	var body := Rect2(boss_x - 16, FLOOR - boss_rise - 155, 32, 155)
	if body.has_point(base):
		return base
	var corners := [body.position, Vector2(body.end.x, body.position.y), body.end, Vector2(body.position.x, body.end.y)]
	var nearest := Vector2.INF
	for i in 4:
		var point = Geometry2D.segment_intersects_segment(base, tip, corners[i], corners[(i + 1) % 4])
		if point != null and base.distance_squared_to(point) < base.distance_squared_to(nearest):
			nearest = point
	return nearest

func _windup() -> float:
	return WINDUP * (0.7 if boss_hp <= MAX_BOSS_HP / 2 else 1.0)

func _set_boss_state(state: String) -> void:
	boss_attack = state
	boss_timer = 0.0
	if state == "teleport_vanish":
		teleport_origin = Vector2(boss_x, FLOOR - 80)
		teleport_landing = player.x - facing * 130.0
		if teleport_landing < BOSS_MIN_X or teleport_landing > BOSS_MAX_X:
			teleport_landing = player.x + facing * 130.0
		teleport_landing = clampf(teleport_landing, BOSS_MIN_X, BOSS_MAX_X)
		boss_visible = false
		boss_flash = 0.0

func _start_next_attack() -> void:
	if forced_fan:
		forced_fan = false
		_set_boss_state("fan_windup")
		return
	var attacks := ["dash_windup", "fan_windup", "ground_windup"] if boss_hp <= MAX_BOSS_HP / 2 else ["dash_windup", "fan_windup", "teleport_vanish"]
	_set_boss_state(attacks[pattern_index % attacks.size()])
	if boss_attack == "ground_windup":
		_start_ground_fires()
	if boss_attack == "teleport_vanish":
		boss_visible = false
	pattern_index += 1

func _start_backjump(anti_hug := false) -> void:
	forced_fan = anti_hug
	hug_time = 0.0
	boss_facing = 1 if player.x >= boss_x else -1
	backjump_direction = -boss_facing
	if boss_x <= BOSS_MIN_X + 1.0:
		backjump_direction = 1
	elif boss_x >= BOSS_MAX_X - 1.0:
		backjump_direction = -1
	_set_boss_state("backjump")

func _hand_position() -> Vector2:
	return Vector2(boss_x + boss_facing * 48.0, FLOOR - boss_rise - 140.0)

func _fire_fan_shot() -> void:
	var start := _hand_position()
	var target := player + Vector2(0, -38)
	var aim := (target - start).normalized()
	if aim.length_squared() < 0.1:
		aim = Vector2(boss_facing, 0)
	var spread: float = [-0.14, 0.0, 0.14][fan_shots]
	foxfires.append({"pos": start, "velocity": aim.rotated(spread) * FAN_SPEED, "reflected": false})
	fan_shots += 1

func _ground_height() -> float:
	return 161.0 * smoothstep(0.0, 0.28, boss_timer) * (1.0 - smoothstep(0.55, GROUND_ACTIVE, boss_timer))

func _draw_ground_jet(base: Vector2) -> void:
	var h := _ground_height()
	if h < 1.0:
		return
	var sway := sin(boss_timer * 12 + base.x) * 4
	for layer in 2:
		var w := 16.0 if layer == 0 else 8.0
		var tip := h if layer == 0 else h * 0.72
		var points := PackedVector2Array()
		for offset in [Vector2(-w, 0), Vector2(-w * 0.8, -tip * 0.35), Vector2(-w, -tip * 0.66), Vector2(-w * 0.3, -tip * 0.53), Vector2(sway, -tip), Vector2(w * 0.55, -tip * 0.45), Vector2(w, -tip * 0.62), Vector2(w * 0.8, -tip * 0.2), Vector2(w, 0)]:
			points.append((base + offset).round())
		draw_colored_polygon(points, FIRE_VIOLET if layer == 0 else FIRE_LILAC)

func _start_ground_fires() -> void:
	ground_fires.clear()
	var center := clampf(player.x, 175.0, 785.0)
	for offset in [-110.0, 0.0, 110.0]:
		ground_fires.append(center + offset)
	ground_hit = false
	_set_boss_state("ground_windup")

func _update_attacks(delta: float) -> void:
	_update_foxfires(delta)
	if phase != "battle":
		return
	var old_boss_x := boss_x
	if absf(player.x - boss_x) < 78.0 and player.y > FLOOR - 65.0:
		hug_time += delta
	else:
		hug_time = 0.0
	if hug_time >= 1.5 and boss_attack in ["approach", "recover"]:
		_start_backjump(true)
	boss_timer += delta
	match boss_attack:
		"approach":
			boss_facing = 1 if player.x >= boss_x else -1
			if absf(player.x - boss_x) > 155.0:
				boss_x = clampf(boss_x + boss_facing * 118.0 * delta, BOSS_MIN_X, BOSS_MAX_X)
			if boss_timer >= 0.45:
				if absf(player.x - boss_x) < 155.0:
					_start_backjump()
				else:
					_start_next_attack()
		"backjump":
			boss_x = clampf(boss_x + backjump_direction * 225.0 * delta, BOSS_MIN_X, BOSS_MAX_X)
			boss_rise = sin(minf(1.0, boss_timer / 0.42) * PI) * 54.0
			if boss_timer >= 0.42:
				boss_rise = 0.0
				_start_next_attack()
		"dash_windup":
			boss_facing = 1 if player.x >= boss_x else -1
			if boss_timer >= _windup():
				dash_direction = boss_facing
				dash_start = boss_x
				dash_target = clampf(boss_x + dash_direction * 440.0, BOSS_MIN_X, BOSS_MAX_X)
				_set_boss_state("dash")
		"dash":
			boss_x = move_toward(boss_x, dash_target, 700.0 * delta)
			if _stop_boss_at_player(old_boss_x):
				_damage_player(Vector2(old_boss_x, FLOOR - 50.0))
				_set_boss_state("recover")
			elif is_equal_approx(boss_x, dash_target):
				_set_boss_state("recover")
		"fan_windup":
			boss_facing = 1 if player.x >= boss_x else -1
			if boss_timer >= _windup():
				fan_shots = 0
				fan_anchor = boss_x
				_fire_fan_shot()
				_set_boss_state("fan_firing")
		"fan_firing":
			if boss_timer >= FAN_SHOT_GAP * fan_shots:
				_fire_fan_shot()
				if fan_shots == 3:
					_set_boss_state("fan_wait")
		"fan_wait":
			boss_x = clampf(fan_anchor + sin(boss_timer * 2.2) * 18.0, BOSS_MIN_X, BOSS_MAX_X)
			if foxfires.is_empty():
				_set_boss_state("recover")
		"ground_windup":
			if boss_timer >= GROUND_WARNING:
				_set_boss_state("ground_burn")
		"ground_burn":
			if not ground_hit and player.y > FLOOR - _ground_height():
				for fire_x in ground_fires:
					if absf(player.x - fire_x) < 16.0:
						ground_hit = true
						_damage_player(Vector2(fire_x, FLOOR))
						break
			if boss_timer >= GROUND_ACTIVE:
				ground_fires.clear()
				_set_boss_state("recover")
		"teleport_vanish":
			if boss_timer >= 0.3:
				_set_boss_state("teleport_preview")
		"teleport_preview":
			if boss_timer >= 0.6:
				boss_x = teleport_landing
				boss_facing = 1 if player.x >= boss_x else -1
				teleport_direction = boss_facing
				boss_visible = true
				_set_boss_state("teleport_pause")
		"teleport_pause":
			if boss_timer >= 0.6:
				foxfires.append({"pos": Vector2(boss_x + teleport_direction * 48, FLOOR - 32), "velocity": Vector2(teleport_direction * 220, 0), "reflected": false, "wave": true})
				_set_boss_state("teleport_recover")
		"teleport_recover":
			if boss_timer >= 0.9 and foxfires.is_empty():
				_set_boss_state("approach")
		"recover":
			if boss_timer >= 0.6:
				_set_boss_state("approach")
	_keep_boss_out_of_player(old_boss_x)
	if absf(boss_x - old_boss_x) > 0.01:
		boss_walk_clock += delta
		boss_last_motion = 0.0
	else:
		boss_last_motion += delta

func _keep_player_out_of_boss(old_player_x: float) -> void:
	if not boss_visible or player.y < FLOOR - 65.0 or absf(player.x - boss_x) >= BODY_GAP:
		return
	var side := -1.0 if old_player_x < boss_x else 1.0
	player.x = clampf(boss_x + side * BODY_GAP, 35.0, 925.0)

func _keep_boss_out_of_player(old_boss_x: float) -> void:
	if not boss_visible or player.y < FLOOR - 65.0 or absf(player.x - boss_x) >= BODY_GAP:
		return
	var side := -1.0 if old_boss_x <= player.x else 1.0
	var target := player.x + side * BODY_GAP
	if target < BOSS_MIN_X or target > BOSS_MAX_X:
		target = player.x - side * BODY_GAP
	boss_x = clampf(target, BOSS_MIN_X, BOSS_MAX_X)

func _stop_boss_at_player(old_boss_x: float) -> bool:
	if not boss_visible or player.y < FLOOR - 65.0:
		return false
	if old_boss_x < player.x and boss_x >= player.x - BODY_GAP:
		boss_x = maxf(BOSS_MIN_X, player.x - BODY_GAP)
		return true
	if old_boss_x > player.x and boss_x <= player.x + BODY_GAP:
		boss_x = minf(BOSS_MAX_X, player.x + BODY_GAP)
		return true
	return false

func _update_foxfires(delta: float) -> void:
	for i in range(foxfires.size() - 1, -1, -1):
		var fire: Dictionary = foxfires[i]
		var pos: Vector2 = fire["pos"]
		var old := pos
		var velocity: Vector2 = fire["velocity"]
		pos += velocity * delta
		fire["pos"] = pos
		if pos.x < 0.0 or pos.x > 960.0 or pos.y < 20.0 or pos.y > 500.0:
			foxfires.remove_at(i)
			continue
		if bool(fire["reflected"]):
			var to_boss := Vector2(boss_x, FLOOR - 85.0) - pos
			if to_boss.length_squared() > 0.01:
				fire["velocity"] = to_boss.normalized() * FAN_SPEED * 1.25
			if pos.distance_to(Vector2(boss_x, FLOOR - 85.0)) < 32.0 and boss_visible:
				foxfires.remove_at(i)
				if fire.get("guard_damage", true):
					_hit_boss(1 if fire.get("silk_guard", false) else 2, pos)
				if phase != "battle":
					return
		else:
			var umbrella_center := player + Vector2(attack_facing * 36.0, -38.0)
			if silk_guard.intercepts(old, pos, player):
				fire["reflected"] = true
				fire["silk_guard"] = true
				fire["guard_damage"] = silk_guard.claim_counter()
				fire["velocity"] = (Vector2(boss_x, FLOOR - 85.0) - pos).normalized() * FAN_SPEED * 1.25
				silk_guard.deflect()
				combat_sounds.play("umbrella_hit")
			elif _umbrella_active() and not hit_this_swing and attack_facing * velocity.x < 0.0 and pos.distance_to(umbrella_center) < 30.0:
				fire["reflected"] = true
				fire["velocity"] = (Vector2(boss_x, FLOOR - 85.0) - pos).normalized() * FAN_SPEED * 1.25
				hit_this_swing = true
				combat_sounds.play("umbrella_hit")
			elif pos.distance_to(player + Vector2(0, -38)) < 22.0:
				foxfires.remove_at(i)
				_damage_player(old)

func _hit_boss(amount: int, contact := Vector2.INF) -> void:
	if phase != "battle":
		return
	boss_hp = maxi(0, boss_hp - amount)
	boss_flash = 0.15
	_trigger_impact(contact if contact.is_finite() else Vector2(boss_x, FLOOR - 65))
	boss_x = clampf(boss_x + (1 if boss_x >= player.x else -1) * 17.0, BOSS_MIN_X, BOSS_MAX_X)
	if boss_hp <= 0:
		foxfires.clear()
		ground_fires.clear()
		walk.stop_audio()
		boss_attack = "recover"
		boss_timer = 0.0
		boss_rise = 0.0
		boss_visible = true
		_start_ending()

func _damage_player(source: Vector2 = Vector2(INF, INF)) -> void:
	if phase != "battle" or invincible > 0.0:
		return
	if silk_guard.blocks_body(player, Vector2(boss_x, FLOOR - 50) if is_inf(source.x) else source):
		silk_guard.deflect()
		combat_sounds.play("umbrella_hit")
		if silk_guard.claim_counter():
			_hit_boss(1)
		return
	silk_guard.cancel()
	hp -= 1
	player_flash = 0.15
	_trigger_impact(player + Vector2(0, -38))
	player.x = clampf(player.x + (1 if player.x >= boss_x else -1) * 24.0, 35.0, 925.0)
	invincible = 1.0
	if hp <= 0:
		phase = "failed"
		foxfires.clear()
		ground_fires.clear()
		walk.stop_audio()

func _label(value: String, at: Vector2, size := 16, color := Color("eee4d0")) -> void:
	draw_string(FONT, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _trigger_impact(at: Vector2) -> void:
	hit_position = at
	hit_feedback = 0.35
	hit_stop = 0.065
	shake_time = 0.18
	combat_sounds.play("umbrella_hit")

func _purple_fire(at: Vector2, direction: float, scale := 1.0) -> void:
	# The extracted orb points left; mirror it when flying to the right.
	draw_set_transform(at, 0.0, Vector2((-1.0 if direction >= 0.0 else 1.0) * scale, scale))
	draw_texture_rect(FIRE_PURPLE_SPRITE, Rect2(-15, -10, 30, 20), false)
	draw_set_transform(Vector2.ZERO)

func _white_texture(source: Texture2D) -> Texture2D:
	if white_textures.has(source):
		return white_textures[source]
	var image := source.get_image()
	image.convert(Image.FORMAT_RGBA8)
	for py in image.get_height():
		for px in image.get_width():
			var color := image.get_pixel(px, py)
			if color.a > 0.0:
				image.set_pixel(px, py, Color(1.0, 1.0, 1.0, color.a))
	var result := ImageTexture.create_from_image(image)
	white_textures[source] = result
	return result

func _boss_texture() -> Texture2D:
	if phase != "battle":
		return BOSS
	if boss_attack in ["backjump", "dash"]:
		return BOSS_JUMP
	if boss_attack == "fan_windup":
		return BOSS_BREATH[0 if boss_timer < _windup() * 0.5 else 1]
	if boss_attack == "fan_firing":
		return BOSS_BREATH[2 if boss_timer < FAN_SHOT_GAP else 3]
	if boss_attack == "fan_wait":
		return BOSS_BREATH[4 if boss_timer < 0.35 else 5]
	if boss_attack == "ground_windup":
		return BOSS_BREATH[5 if boss_timer < 0.3 else 0]
	if boss_attack == "ground_burn":
		return BOSS_BREATH[4 if boss_timer < 0.55 else 5]
	if boss_attack in ["teleport_pause", "teleport_recover"] or boss_attack == "recover" and not foxfires.is_empty() and boss_timer < 0.18:
		return BOSS_BREATH[4]
	if boss_attack == "approach":
		return BOSS_WALK[int(boss_walk_clock * 8.0) % 3]
	return BOSS

func _draw() -> void:
	weather.draw(self)
	if inventory.opened:
		return
	if boss_attack == "teleport_vanish":
		for i in 12:
			var angle := i * TAU / 12.0
			var offset := Vector2(cos(angle), sin(angle)) * (12 + boss_timer * 140)
			draw_circle(teleport_origin + offset, 3.0, Color(FIRE_VIOLET, 1.0 - boss_timer / 0.3))
	if boss_attack == "teleport_preview":
		var marker := Vector2(teleport_landing, FLOOR - 3)
		draw_line(marker - Vector2(30, 0), marker + Vector2(30, 0), Color(FIRE_VIOLET, 0.7), 4)
		for i in 5:
			draw_circle(marker + Vector2(i * 12 - 24, -4 - sin(boss_timer * 8 + i) * 3), 2, FIRE_LILAC)
	if phase == "battle" and boss_attack == "teleport_pause" and boss_timer < 0.4:
		var trail_pose := _white_texture(BOSS_BREATH[4])
		var travel := teleport_landing - teleport_origin.x
		if absf(travel) > 1.0:
			var rect := Rect2(-trail_pose.get_width() * 0.5, -trail_pose.get_height(), trail_pose.get_width(), trail_pose.get_height())
			for i in 5:
				var along := i / 5.0
				var opacity := (0.13 + 0.24 * along) * (1.0 - smoothstep(0.0, 0.22 + along * 0.22, boss_timer))
				draw_set_transform(Vector2(roundf(teleport_origin.x + travel * along), FLOOR), 0, Vector2(signf(travel), 1))
				draw_texture_rect(trail_pose, rect, false, Color(0.48, 0.9, 0.8, opacity))
			draw_set_transform(Vector2.ZERO)
	if boss_visible:
		var boss_texture := _boss_texture()
		if boss_attack == "dash":
			var streak_y := FLOOR - boss_rise - 84.0
			draw_line(Vector2(boss_x - boss_facing * 61.0, streak_y), Vector2(boss_x - boss_facing * 18.0, streak_y), Color(1.0, 0.88, 0.78, 0.5), 3.0)
		if boss_flash > 0.0:
			boss_texture = _white_texture(boss_texture)
		draw_set_transform(Vector2(roundf(boss_x), roundf(FLOOR - boss_rise)), 0.0, Vector2(boss_facing, 1))
		draw_texture_rect(boss_texture, Rect2(-boss_texture.get_width() / 2.0, -boss_texture.get_height(), boss_texture.get_width(), boss_texture.get_height()), false)
		draw_set_transform(Vector2.ZERO)
	if boss_attack == "fan_windup":
		var hand := _hand_position()
		_purple_fire(hand, boss_facing, 0.5 + 0.5 * boss_timer / _windup())
		draw_arc(hand, 16.0, 0, TAU, 18, Color(FIRE_LILAC, 0.35 + 0.5 * boss_timer / _windup()), 2.0)
	if boss_attack == "dash_windup":
		var from := Vector2(boss_x, FLOOR - 5)
		var to := from + Vector2(boss_facing * 90, 0)
		draw_line(from, to, Color(FIRE_VIOLET, 0.65), 3)
		draw_line(to, to + Vector2(-boss_facing * 12, -7), FIRE_VIOLET, 3)
	if boss_attack == "teleport_pause":
		_purple_fire(_hand_position(), teleport_direction, 0.7 + boss_timer * 1.8)
		var wave_start := Vector2(boss_x + teleport_direction * 48, FLOOR - 32)
		draw_line(wave_start, wave_start + Vector2(teleport_direction * 170, 0), Color(FIRE_VIOLET, 0.16), 32)
	if boss_attack == "teleport_recover" and boss_timer < 0.2:
		draw_line(_hand_position(), Vector2(boss_x + teleport_direction * 48, FLOOR - 32), Color(FIRE_VIOLET, (0.2 - boss_timer) * 2), 5)
	if boss_attack in ["ground_windup", "ground_burn"]:
		for fire_x in ground_fires:
			var at := Vector2(fire_x, FLOOR - 4.0)
			if boss_attack == "ground_windup":
				draw_arc(at, 18.0, 0.0, TAU, 24, Color(FIRE_VIOLET, 0.55 + 0.4 * boss_timer / (GROUND_WARNING)), 2.0)
				draw_circle(at + Vector2(-7, -3), 2.0, FIRE_LILAC)
				draw_circle(at + Vector2(7, -5), 2.0, FIRE_VIOLET)
			else:
				draw_arc(at, 21.0, 0.0, TAU, 24, Color(FIRE_VIOLET, 0.65), 3.0)
				_draw_ground_jet(Vector2(fire_x, FLOOR))
	for fire in foxfires:
		_purple_fire(fire["pos"], signf((fire["velocity"] as Vector2).x), 2.8 if fire.get("wave", false) else 2.0)
		if bool(fire["reflected"]):
			draw_circle(fire["pos"] + Vector2(-8, -7), 2.5, FIRE_LILAC)
	var pose := 3 if player.y < FLOOR or dash_time > 0.0 else (4 if attack_time > 0.0 else 0)
	if silk_guard.active():
		pose = 4
	var texture := girl[pose]
	if turn_time >= 0.0:
		texture = turn_frames[mini(3, int(turn_time * 4.0))]
	walk.draw_shadow(self, player, FLOOR)
	if player_flash > 0.0 or invincible <= 0.0 or int(invincible * 12.0) % 2 == 0:
		draw_set_transform(Vector2(roundf(player.x), roundf(player.y)), 0.0, Vector2(1 if turn_time >= 0.0 else facing, 1))
		if not silk_guard.presenting():
			if pose == 0 and walk.walking and player_flash <= 0.0:
				walk.draw_body(self, girl[0])
			else:
				var body_texture := _white_texture(texture) if player_flash > 0.0 else texture
				draw_texture_rect(body_texture, Rect2(Vector2(-floorf(body_texture.get_width() / 2.0), -body_texture.get_height()), body_texture.get_size()), false)
		if not silk_guard.presenting():
			var grip := _attack_grip() if attack_time > 0.0 else player + Vector2(-2 * facing, -24)
			var weapon_facing := attack_facing if attack_time > 0.0 else facing
			var angle := -0.08 if attack_time > 0.0 else 0.38
			draw_set_transform(grip, angle * weapon_facing, Vector2(weapon_facing, 1))
			draw_texture_rect(umbrella, Rect2(-9, -4, 60, 11), false)
		draw_set_transform(Vector2.ZERO)
	silk_guard.draw(self, player)
	if hit_feedback > 0.0:
		var t := 1.0 - hit_feedback / 0.35
		if t < 0.22:
			draw_line(hit_position - Vector2(10, 0), hit_position + Vector2(10, 0), Color(0.9, 1, 1), 3, true)
			draw_line(hit_position - Vector2(0, 7), hit_position + Vector2(0, 7), Color(0.9, 1, 1), 2, true)
		for i in 7:
			var ray := Vector2.from_angle(i * TAU / 7)
			var point := hit_position + ray * (5 + t * 19)
			draw_line(point, point + ray * 4, Color(0.65, 0.98, 1, 1 - t), 1.6, true)
			draw_circle(point + ray * 4, 1.3, Color(0.7, 1, 1, 1 - t), true, -1, true)
	_label("CHAPTER 3 · FOX WEDDING", Vector2(25, 34), 18)
	_label("HEALTH  " + "●".repeat(hp) + "○".repeat(MAX_PLAYER_HP - hp), Vector2(25, 61), 16, Color("eec9aa"))
	if phase == "battle":
		_label("Foxfire", Vector2(405, 33), 16)
		draw_rect(Rect2(350, 43, 260, 8), Color("382b3c"))
		draw_rect(Rect2(350, 43, 260.0 * boss_hp / MAX_BOSS_HP, 8), FIRE_RED)
	if phase == "explore":
		_label("Follow the red lantern into the rain", Vector2(280, 91), 16)
	if phase == "failed":
		_label("Lost in the foxfire... Press R to retry", Vector2(285, 253), 21)
	if phase == "peace":
		_label("N: Chapter Four · Esc: Pause", Vector2(315, 92), 16)
	if paused:
		_label("Paused · Esc: Resume · Q: Main Menu", Vector2(275, 258), 22)
