extends Node2D

const JOURNEY := preload("res://scripts/journey_state.gd")
const BACKGROUND := preload("res://assets/chapter3/backgrounds/moon_bamboo_wedding_pixel_v1.png")
const BOSS := preload("res://assets/chapter3/pixel/qingyan_idle.png")
const BOSS_WALK := [preload("res://assets/chapter3/pixel/qingyan_walk_0.png"), preload("res://assets/chapter3/pixel/qingyan_walk_1.png"), preload("res://assets/chapter3/pixel/qingyan_walk_2.png")]
const BOSS_JUMP := preload("res://assets/chapter3/pixel/qingyan_jump.png")
const BOSS_CAST := preload("res://assets/chapter3/pixel/qingyan_cast.png")
const FIRE_IDLE := preload("res://assets/chapter3/pixel/foxfire_b_idle.png")
const FIRE_CHARGE := preload("res://assets/chapter3/pixel/foxfire_b_charge.png")
const FONT := preload("res://assets/chapter1/chinese.ttc")

const FLOOR := 438.0
const WALK_SPEED := 120.0
const BOSS_X := 310.0
const MAX_BOSS_HP := 8
const MAX_PLAYER_HP := 6
const WINDUP := 0.4
const FAN_SPEED := 390.0
const FIRE_RED := Color("d94132")
const FIRE_ORANGE := Color("ff8a42")
const FIRE_GOLD := Color("ffd073")

var girl: Array[Texture2D] = []
var umbrella: Texture2D
var walk = preload("res://scripts/hero_walk.gd").new()
var combat_sounds = preload("res://scripts/combat_sounds.gd").new()
var dialogue_box = preload("res://scripts/dialogue_box.gd").new()
var weather = preload("res://scripts/rain_weather.gd").new()

var player := Vector2(790.0, FLOOR)
var vy := 0.0
var facing := -1
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
var attack_facing := -1
var hit_this_swing := false
var swing_played := false
var boss_flash := 0.0
var player_flash := 0.0
var hit_stop := 0.0
var boss_x := BOSS_X
var boss_facing := 1
var boss_rise := 0.0
var boss_walk_clock := 0.0
var boss_last_motion := 0.0
var hug_time := 0.0
var forced_fan := false
var dash_start := 0.0
var dash_target := 0.0
var dash_direction := 1
var boss_visible := true

var lines: Array[String] = []
var line_index := 0
var after_lines := "battle"

var boss_attack := "approach"
var boss_timer := 0.0
var pattern_index := 0
var foxfires: Array[Dictionary] = []
var white_textures: Dictionary = {}

func _ready() -> void:
	if not test_mode:
		JOURNEY.remember_chapter("res://chapter3.tscn")
		JOURNEY.apply_preferences()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var backdrop := Sprite2D.new()
	backdrop.texture = BACKGROUND
	backdrop.centered = false
	backdrop.scale = Vector2(960.0 / BACKGROUND.get_width(), 540.0 / BACKGROUND.get_height())
	backdrop.z_index = -1
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(backdrop)
	for i in 6:
		girl.append(load("res://assets/chapter1/pixel/girl/pose_%d.png" % i))
	umbrella = load("res://assets/chapter1/pixel/girl/umbrella.png")
	weather.reset(Vector2(960, 540))
	walk.setup_audio(self)
	combat_sounds.setup(self)
	dialogue_box.mount(self)
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode
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
				_next_line()
		return
	if phase == "failed":
		if key == KEY_R:
			get_tree().reload_current_scene()
		return
	if phase not in ["explore", "battle", "peace"]:
		return
	if key == KEY_SPACE and player.y >= FLOOR - 0.1:
		vy = -355.0
	if key in [KEY_SHIFT, KEY_K] and dash_cooldown <= 0.0:
		dash_time = 0.18
		dash_cooldown = 0.9
		invincible = 0.25
	if key == KEY_J and attack_cooldown <= 0.0:
		attack_time = 0.31
		attack_cooldown = 0.43
		attack_facing = facing
		hit_this_swing = false
		swing_played = false

func _start_opening() -> void:
	_start_lines([
		"小语：请问，前面有能避雨的地方吗？",
		"青砚：有。你先别往前走。",
		"小语：……到底是哪边？",
		"青砚：这一带很不安全。你怎么到这里来的？",
		"小语：我想……我迷路了。",
		"青砚：迷路能迷到这里，也算有本事。",
		"小语：我只想找个屋檐。你指个方向，我马上走。",
		"青砚：这一带可不是你这样的小姑娘能随便走近的。对神明大人，要有敬畏之心。",
		"小语：我连祂的门在哪儿都没看见。",
		"（雨水将一根红线冲到小语鞋边。）",
		"青砚：你已经踩在门槛上了。",
		"小语：这是门槛？",
		"青砚：我也觉得太细了。可祂喜欢这样。",
		"小语：我没有碰它。是雨把它冲过来的。",
		"青砚：我知道。所以你别动。我得先把你送出去。",
		"（红线绷紧。小语撑伞挡下第一击。）",
	], "battle")

func _start_lines(text: Array[String], next_phase: String) -> void:
	lines = dialogue_box.merge_lines(text)
	line_index = 0
	after_lines = next_phase
	phase = "dialogue"
	walk.stop_audio()
	dialogue_box.show_line(lines[0])
	if not test_mode and next_phase == "battle":
		JOURNEY.meet_chapter("res://chapter3.tscn", lines)

func _next_line() -> void:
	line_index += 1
	if line_index < lines.size():
		dialogue_box.show_line(lines[line_index])
	else:
		dialogue_box.hide()
		phase = after_lines
		boss_attack = "approach"
		boss_timer = 0.0

func _process(delta: float) -> void:
	weather.advance(delta)
	dialogue_box.visible = phase == "dialogue" and not paused
	if dialogue_box.visible and dialogue_box.advance_time(delta, Input.is_physical_key_pressed(KEY_CTRL)):
		_next_line()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if paused:
		walk.stop_audio()
		return
	if hit_stop > 0.0:
		hit_stop = maxf(0.0, hit_stop - delta)
		queue_redraw()
		return
	var old_x := player.x
	if phase in ["explore", "battle", "peace"]:
		var axis := int(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		if axis != 0:
			facing = axis
		player.x = clampf(player.x + axis * (410.0 if dash_time > 0.0 else WALK_SPEED) * delta, 35.0, 925.0)
		vy = minf(vy + 950.0 * delta, 600.0)
		player.y = minf(FLOOR, player.y + vy * delta)
		if player.y >= FLOOR:
			vy = 0.0
		if phase == "explore" and player.x <= 560.0:
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
		if _umbrella_active() and not hit_this_swing and (boss_x - player.x) * attack_facing > 0.0 and absf(boss_x - player.x) < 86.0 and player.y > FLOOR - 90.0 and boss_visible:
			hit_this_swing = true
			_hit_boss(1)
	queue_redraw()

func _umbrella_active() -> bool:
	return attack_time > 0.08 and attack_time < 0.25

func _windup() -> float:
	return WINDUP * (0.7 if boss_hp <= MAX_BOSS_HP / 2 else 1.0)

func _set_boss_state(state: String) -> void:
	boss_attack = state
	boss_timer = 0.0

func _start_next_attack() -> void:
	if forced_fan:
		forced_fan = false
		_set_boss_state("fan_windup")
		return
	var attacks := ["dash_windup", "fan_windup", "teleport_vanish"]
	_set_boss_state(attacks[pattern_index % attacks.size()])
	if boss_attack == "teleport_vanish":
		boss_visible = false
	pattern_index += 1

func _start_backjump(anti_hug := false) -> void:
	forced_fan = anti_hug
	hug_time = 0.0
	boss_facing = 1 if player.x >= boss_x else -1
	_set_boss_state("backjump")

func _hand_position() -> Vector2:
	return Vector2(boss_x + boss_facing * 48.0, FLOOR - boss_rise - 140.0)

func _fire_fan() -> void:
	var start := _hand_position()
	var target := player + Vector2(0, -38)
	var aim := (target - start).normalized()
	if aim.length_squared() < 0.1:
		aim = Vector2(boss_facing, 0)
	for spread in [-0.18, 0.0, 0.18]:
		foxfires.append({"pos": start, "velocity": aim.rotated(spread) * FAN_SPEED, "reflected": false})
	_set_boss_state("recover")

func _update_attacks(delta: float) -> void:
	_update_foxfires(delta)
	if phase != "battle":
		return
	var old_boss_x := boss_x
	if absf(player.x - boss_x) < 78.0 and player.y > FLOOR - 65.0:
		hug_time += delta
	else:
		hug_time = 0.0
	if hug_time >= 1.5 and boss_attack not in ["backjump", "teleport_vanish", "teleport_pause", "teleport_strike", "dash"]:
		_start_backjump(true)
	boss_timer += delta
	match boss_attack:
		"approach":
			boss_facing = 1 if player.x >= boss_x else -1
			if absf(player.x - boss_x) > 155.0:
				boss_x = clampf(boss_x + boss_facing * 118.0 * delta, 55.0, 905.0)
			if boss_timer >= 0.45:
				if absf(player.x - boss_x) < 155.0:
					_start_backjump()
				else:
					_start_next_attack()
		"backjump":
			var away := -1 if player.x >= boss_x else 1
			if boss_x <= 56.0:
				away = 1
			elif boss_x >= 904.0:
				away = -1
			boss_x = clampf(boss_x + away * 225.0 * delta, 55.0, 905.0)
			boss_rise = sin(minf(1.0, boss_timer / 0.42) * PI) * 54.0
			if boss_timer >= 0.42:
				boss_rise = 0.0
				_start_next_attack()
		"dash_windup":
			boss_facing = 1 if player.x >= boss_x else -1
			if boss_timer >= _windup():
				dash_direction = boss_facing
				dash_start = boss_x
				dash_target = clampf(boss_x + dash_direction * 440.0, 55.0, 905.0)
				_set_boss_state("dash")
		"dash":
			boss_x = move_toward(boss_x, dash_target, 700.0 * delta)
			if _dash_hits_player(old_boss_x, boss_x):
				_damage_player()
			if is_equal_approx(boss_x, dash_target):
				_set_boss_state("recover")
		"fan_windup":
			boss_facing = 1 if player.x >= boss_x else -1
			if boss_timer >= _windup():
				_fire_fan()
		"teleport_vanish":
			if boss_timer >= 0.18 * (0.7 if boss_hp <= 4 else 1.0):
				boss_visible = false
				boss_x = clampf(player.x - facing * 90.0, 55.0, 905.0)
				boss_facing = 1 if player.x >= boss_x else -1
				boss_visible = true
				_set_boss_state("teleport_pause")
		"teleport_pause":
			if boss_timer >= 0.3 * (0.7 if boss_hp <= 4 else 1.0):
				_set_boss_state("teleport_strike")
		"teleport_strike":
			boss_x = clampf(boss_x + boss_facing * 580.0 * delta, 55.0, 905.0)
			if _dash_hits_player(old_boss_x, boss_x):
				_damage_player()
			if boss_timer >= 0.2:
				_set_boss_state("recover")
		"recover":
			if boss_timer >= 0.6:
				_set_boss_state("approach")
	if absf(boss_x - old_boss_x) > 0.01:
		boss_walk_clock += delta
		boss_last_motion = 0.0
	else:
		boss_last_motion += delta

func _dash_hits_player(from_x: float, to_x: float) -> bool:
	if player.y < FLOOR - 65.0 or invincible > 0.0:
		return false
	return player.x >= minf(from_x, to_x) - 26.0 and player.x <= maxf(from_x, to_x) + 26.0

func _update_foxfires(delta: float) -> void:
	for i in range(foxfires.size() - 1, -1, -1):
		var fire: Dictionary = foxfires[i]
		var pos: Vector2 = fire["pos"]
		var velocity: Vector2 = fire["velocity"]
		pos += velocity * delta
		fire["pos"] = pos
		if pos.x < 0.0 or pos.x > 960.0 or pos.y < 20.0 or pos.y > 500.0:
			foxfires.remove_at(i)
			continue
		if bool(fire["reflected"]):
			if pos.distance_to(Vector2(boss_x, FLOOR - 85.0)) < 32.0 and boss_visible:
				foxfires.remove_at(i)
				_hit_boss(2)
		else:
			var umbrella_center := player + Vector2(attack_facing * 36.0, -38.0)
			if _umbrella_active() and not hit_this_swing and attack_facing * velocity.x < 0.0 and pos.distance_to(umbrella_center) < 30.0:
				fire["reflected"] = true
				fire["velocity"] = (Vector2(boss_x, FLOOR - 85.0) - pos).normalized() * FAN_SPEED * 1.25
				hit_this_swing = true
				combat_sounds.play("umbrella_hit")
			elif pos.distance_to(player + Vector2(0, -38)) < 22.0:
				foxfires.remove_at(i)
				_damage_player()

func _hit_boss(amount: int) -> void:
	if phase != "battle":
		return
	boss_hp = maxi(0, boss_hp - amount)
	boss_flash = 0.15
	hit_stop = 0.06
	boss_x = clampf(boss_x + (1 if boss_x >= player.x else -1) * 17.0, 55.0, 905.0)
	combat_sounds.play("umbrella_hit")
	if boss_hp <= 0:
		if not test_mode:
			JOURNEY.complete_chapter("res://chapter3.tscn")
		phase = "peace"
		foxfires.clear()
		walk.stop_audio()

func _damage_player() -> void:
	if phase != "battle" or invincible > 0.0:
		return
	hp -= 1
	player_flash = 0.15
	hit_stop = 0.06
	player.x = clampf(player.x + (1 if player.x >= boss_x else -1) * 24.0, 35.0, 925.0)
	invincible = 1.0
	if hp <= 0:
		phase = "failed"
		foxfires.clear()
		walk.stop_audio()

func _label(value: String, at: Vector2, size := 16, color := Color("eee4d0")) -> void:
	draw_string(FONT, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _fire(at: Vector2, charged := false, reflected := false) -> void:
	var texture := FIRE_CHARGE if charged else FIRE_IDLE
	draw_texture_rect(texture, Rect2(at - Vector2(9, 9), Vector2(18, 18)), false)
	if reflected:
		draw_circle(at + Vector2(-8, -7), 2.5, Color("fff2cf"))
		draw_line(at + Vector2(-8, -12), at + Vector2(-8, -2), Color.WHITE, 1.0)

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
	if boss_attack == "backjump":
		return BOSS_JUMP
	if boss_attack in ["fan_windup", "teleport_pause", "teleport_strike"] or boss_attack == "recover" and not foxfires.is_empty() and boss_timer < 0.18:
		return BOSS_CAST
	if boss_attack in ["approach", "dash"]:
		return BOSS_WALK[int(boss_walk_clock * 8.0) % 3]
	return BOSS

func _draw() -> void:
	weather.draw(self)
	if boss_visible:
		var boss_texture := _boss_texture()
		if boss_flash > 0.0 or boss_attack == "dash_windup" and fmod(boss_timer, 0.11) < 0.055:
			boss_texture = _white_texture(boss_texture)
		draw_set_transform(Vector2(roundf(boss_x), roundf(FLOOR - boss_rise)), 0.0, Vector2(boss_facing, 1))
		draw_texture_rect(boss_texture, Rect2(-boss_texture.get_width() / 2.0, -boss_texture.get_height(), boss_texture.get_width(), boss_texture.get_height()), false)
		draw_set_transform(Vector2.ZERO)
	if boss_attack == "fan_windup":
		var hand := _hand_position()
		_fire(hand, true)
		draw_arc(hand, 16.0, 0, TAU, 18, Color(FIRE_GOLD, 0.4 + 0.5 * boss_timer / _windup()), 2.0)
	if boss_attack == "teleport_pause":
		draw_arc(Vector2(boss_x, FLOOR - 80), 37, 0, TAU, 24, Color(FIRE_ORANGE, 0.7), 2)
	for fire in foxfires:
		_fire(fire["pos"], false, bool(fire["reflected"]))
	var pose := 3 if player.y < FLOOR or dash_time > 0.0 else (4 if attack_time > 0.0 else 0)
	var texture := girl[pose]
	walk.draw_shadow(self, player, FLOOR)
	if player_flash > 0.0 or invincible <= 0.0 or int(invincible * 12.0) % 2 == 0:
		draw_set_transform(Vector2(roundf(player.x), roundf(player.y)), 0.0, Vector2(facing, 1))
		if pose == 0 and walk.walking and player_flash <= 0.0:
			walk.draw_body(self, girl[0])
		else:
			var body_texture := _white_texture(texture) if player_flash > 0.0 else texture
			draw_texture_rect(body_texture, Rect2(Vector2(-floorf(body_texture.get_width() / 2.0), -body_texture.get_height()), body_texture.get_size()), false)
		var grip := Vector2(21, -38) if attack_time > 0.0 else Vector2(-2, -24)
		var angle := -0.08 if attack_time > 0.0 else 0.38
		draw_set_transform(player + Vector2(grip.x * facing, grip.y), angle * facing, Vector2(facing, 1))
		draw_texture_rect(umbrella, Rect2(-9, -4, 60, 11), false)
		draw_set_transform(Vector2.ZERO)
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
		_label("The foxfire has gone out · Esc: Pause", Vector2(315, 92), 16)
	if paused:
		_label("Paused · Esc: Resume · Q: Main Menu", Vector2(275, 258), 22)
	_label("A/D Move  ·  Space Jump  ·  J Strike / Reflect  ·  Shift Dash", Vector2(180, 515), 15)
