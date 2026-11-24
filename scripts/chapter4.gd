extends Node2D

const JOURNEY := preload("res://scripts/journey_state.gd")
const BACKGROUND := preload("res://assets/chapter4/rain_market.png")
const FONT := preload("res://assets/chapter1/chinese.ttc")

const FLOOR := 438.0
const WALK_SPEED := 120.0
const BOSS_X := 828.0
const MAX_BOSS_HP := 8
const MAX_PLAYER_HP := 6
const FIRE_RED := Color("d94132")
var girl: Array[Texture2D] = []
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
var candy_offered := false
var battle_quote := ""

var boss_rise := 0.0
var lines: Array[String] = []
var line_index := 0
var after_lines := "battle"
var mood := 0
var stage := "warning"
var elapsed := 0.0
var direction := -1
var spin := 0.0
var rush_length := 0.0
var white_textures: Dictionary = {}
const FACES := [preload("res://assets/chapter4/paper_stand.png"), preload("res://assets/chapter4/paper_sad.png"), preload("res://assets/chapter4/paper_tuck.png")]
const HAPPY_BALL := preload("res://assets/chapter4/paper_roll.png")
const ANGRY_BALL := preload("res://assets/chapter4/paper_rush.png")
const ACTIVE_TIME := [2.25, 2.4, 0.9]

func _ready() -> void:
	if not test_mode:
		JOURNEY.remember_chapter("res://chapter4.tscn")
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
	for i in 6:
		girl.append(load("res://assets/chapter1/pixel/girl/pose_%d.png" % i))
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
	_start_lines([
		"（糖葫芦车已经收了幌子。车旁有盏米白的纸灯，见小语走近，竟把两只袖子揣好了。）",
		"小语：你一直看最上面那颗。想吃吗？",
		"纸灯妖：先说说你喜欢甜的还是酸的。",
		"小语：酸的。",
		"（它赶紧皱起脸。小语笑了一声，它又赶紧笑了。）",
		"小语：你为什么一直在换脸？",
		"纸灯妖：因为我想被人喜欢。",
		"纸灯妖：我学着别人说话，学着别人微笑，喜欢他们喜欢的东西。",
		"纸灯妖：每到一个新的地方，我就换上一张新的脸。",
		"纸灯妖：后来，所有人都喜欢我了。",
		"纸灯妖：可是……我忘记了曾经的朋友，也忘记了自己喜欢什么。",
		"小语：那你喜欢现在的自己吗？",
		"纸灯妖：当然！我终于变成了所有人都喜欢的样子！",
		"小语：可是……你自己呢？",
		"纸灯妖：……闭嘴！"
	], "battle")

func _start_ending() -> void:
	boss_x = BOSS_X
	player = Vector2(BOSS_X - 57, FLOOR)
	facing = 1
	vy = 0
	boss_rise = 0
	spin = 0
	mood = 0
	_start_lines([
		"（纸灯妖滚回糖车边。小语伸手去扶，不小心撞了它一下。）",
		"纸灯妖：……被撞到的话，应该生气吧。",
		"（它正准备换上愤怒的表情。）",
		"小语：对不起！这个给你！",
		"（小语笑着递来一根棒棒糖。）",
		"纸灯妖：糖？可是……我不能摄入太多糖分。",
		"（它犹豫着尝了一口。）",
		"纸灯妖：……好甜。",
		"纸灯妖：以前我们分糖葫芦，我总挑糖衣裂开的那颗。",
		"小语：为什么？",
		"纸灯妖：裂开的先酸一下，再甜。那颗他们都给我留着。",
		"纸灯妖：我想起来了……",
		"纸灯妖：那时候，我不用变成任何人，也有人喜欢我。",
		"（咔嚓。咔嚓。心中的面具一面面破碎。）",
		"小语：你怎么哭了？",
		"纸灯妖：原来……我已经这么久没有做过自己了。",
		"小语：那你现在喜欢自己吗？",
		"纸灯妖：……",
		"纸灯妖：嗯。",
		"纸灯妖：我很喜欢现在的自己。",
		"（它露出了一个不属于任何面具的微笑。）"
	], "peace")

func _start_lines(text: Array[String], next_phase: String) -> void:
	silk_guard.cancel()
	lines = text
	line_index = 0
	after_lines = next_phase
	phase = "dialogue"
	walk.stop_audio()
	dialogue_box.show_line(lines[0])
	if not test_mode and next_phase == "battle":
		JOURNEY.meet_chapter("res://chapter4.tscn", lines)


func _next_line() -> void:
	line_index += 1
	if line_index < lines.size():
		dialogue_box.show_line(lines[line_index])
		if "递来一根棒棒糖" in lines[line_index]:
			candy_offered = true
		if after_lines == "battle":
			if "酸的。" in lines[line_index]:
				mood = 2
			elif "赶紧笑" in lines[line_index]:
				mood = 0
			elif "忘记了" in lines[line_index]:
				mood = 1
			elif "当然！" in lines[line_index]:
				mood = 0
			elif "闭嘴" in lines[line_index]:
				mood = 2
		elif "哭" in lines[line_index]:
			mood = 1
		elif "生气" in lines[line_index]:
			mood = 2
		elif "甜" in lines[line_index] or "喜欢现在" in lines[line_index]:
			mood = 0
		return
	dialogue_box.hide()
	phase = after_lines
	mood = 0
	if phase == "battle":
		_warn()
	elif not test_mode:
		JOURNEY.complete_chapter("res://chapter4.tscn", lines)
func _process(delta: float) -> void:
	weather.advance(delta)
	if not paused and not inventory.opened:
		feedback_clock += delta
		hit_feedback = maxf(0.0, hit_feedback - delta)
		shake_time = maxf(0.0, shake_time - delta)
	var shake_strength := pow(shake_time / 0.18, 2) if not reduce_shake else 0.0
	position = (Vector2(sin(feedback_clock * 95) * 3.0, cos(feedback_clock * 113) * 1.7) * shake_strength).round()
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
		if phase == "explore" and boss_x - player.x <= 84.0 and player.y >= FLOOR:
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
		if _umbrella_active() and not hit_this_swing and (boss_x - player.x) * attack_facing > 0.0 and absf(boss_x - player.x) < 86.0 and absf(player.y - 34 - (FLOOR - boss_rise - 26)) < 39:
			hit_this_swing = true
			_hit_boss(1)
	queue_redraw()

func _umbrella_active() -> bool:
	return attack_time > 0.08 and attack_time < 0.25


func _warn() -> void:
	stage = "warning"
	elapsed = 0
	direction = 1 if player.x > boss_x else -1
	if mood == 2:
		direction = [-1, 1].pick_random()
		if boss_x < 200 or boss_x > 760:
			direction = 1 if boss_x < 480 else -1
		rush_length = randf_range(390, 550)

func _update_attacks(delta: float) -> void:
	elapsed += delta
	if stage == "recover":
		if elapsed >= 1.15:
			mood = (mood + 1) % 3
			battle_quote = ["", "这张脸不好吗？！", "我明明已经变得这么完美了！"][mood]
			_warn()
		return
	if stage == "warning":
		if elapsed >= 0.65:
			stage = "active"
			elapsed = 0
		return
	var speed := [260.0, 145.0, rush_length][mood] as float
	boss_x += direction * speed * delta
	if boss_x < 58 or boss_x > 902:
		boss_x = clampf(boss_x, 58, 902)
		direction *= -1
	if mood != 1:
		spin += direction * speed * delta / 31
	elif mood == 1:
		boss_rise = absf(sin(elapsed * PI / 0.8)) * 106
	var center := Vector2(boss_x, FLOOR - boss_rise - 27)
	if absf(player.x - center.x) < 41 and absf(player.y - 31 - center.y) < 51:
		_damage_player(center)
	if elapsed >= float(ACTIVE_TIME[mood]):
		stage = "recover"
		elapsed = 0
		spin = 0
		boss_rise = 0

func _hit_boss(amount: int) -> void:
	if phase != "battle":
		return
	boss_hp = maxi(0, boss_hp - amount)
	boss_flash = 0.15
	_trigger_impact(Vector2(boss_x, FLOOR - boss_rise - 27))
	boss_x = clampf(boss_x + (1 if boss_x >= player.x else -1) * 17.0, 58, 902)
	if boss_hp <= 0:
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
		walk.stop_audio()

func _label(value: String, at: Vector2, size := 16, color := Color("eee4d0")) -> void:
	draw_string(FONT, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _trigger_impact(at: Vector2) -> void:
	hit_position = at
	hit_feedback = 0.35
	hit_stop = 0.065
	shake_time = 0.18
	combat_sounds.play("umbrella_hit")

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

func _draw() -> void:
	weather.draw(self)
	if inventory.opened:
		return

	var sprite: Texture2D = FACES[mood]
	if phase == "battle" and stage == "active" and mood != 1:
		sprite = HAPPY_BALL if mood == 0 else ANGRY_BALL
	if boss_flash > 0:
		sprite = _white_texture(sprite)
	var squash := Vector2.ONE
	if phase == "battle" and stage == "warning":
		squash = Vector2(1.16, 0.82)
	if mood == 2 and stage == "warning" and phase == "battle":
		draw_line(Vector2(boss_x, FLOOR-3), Vector2(boss_x+direction*75, FLOOR-3), Color.SALMON, 3)
	var height := float(sprite.get_height()) * squash.y
	var center := Vector2(boss_x, FLOOR - boss_rise - height / 2)
	draw_set_transform(center, spin, squash)
	draw_texture_rect(sprite, Rect2(-sprite.get_size() / 2, sprite.get_size()), false)
	draw_set_transform(Vector2.ZERO)
	if phase == "dialogue" and after_lines == "peace" and candy_offered:
		var candy := center + Vector2(-31, 4)
		draw_line(candy, candy + Vector2(-5, 13), Color.IVORY, 2)
		draw_circle(candy, 6, Color.HOT_PINK)
	var pose := 3 if player.y < FLOOR or dash_time > 0.0 else (4 if attack_time > 0.0 else 0)
	if silk_guard.active():
		pose = 4
	var texture := girl[pose]
	walk.draw_shadow(self, player, FLOOR)
	if player_flash > 0.0 or invincible <= 0.0 or int(invincible * 12.0) % 2 == 0:
		draw_set_transform(Vector2(roundf(player.x), roundf(player.y)), 0.0, Vector2(facing, 1))
		if not silk_guard.presenting():
			if pose == 0 and walk.walking and player_flash <= 0.0:
				walk.draw_body(self, girl[0])
			else:
				var body_texture := _white_texture(texture) if player_flash > 0.0 else texture
				draw_texture_rect(body_texture, Rect2(Vector2(-floorf(body_texture.get_width() / 2.0), -body_texture.get_height()), body_texture.get_size()), false)
		if not silk_guard.presenting():
			var grip := Vector2(21, -38) if attack_time > 0.0 else Vector2(-2, -24)
			var angle := -0.08 if attack_time > 0.0 else 0.38
			draw_set_transform(player + Vector2(grip.x * facing, grip.y), angle * facing, Vector2(facing, 1))
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
	if phase == "battle" and stage == "warning":
		_label(battle_quote, Vector2(clampf(boss_x - 72, 20, 710), FLOOR - 90), 15)
	_label("CHAPTER 4 · BORROWED SMILES", Vector2(25, 34), 18)
	_label("HEALTH  " + "●".repeat(hp) + "○".repeat(MAX_PLAYER_HP - hp), Vector2(25, 61), 16, Color("eec9aa"))
	if phase == "battle":
		_label(["开心 · 滚动", "伤心 · 弹跳", "生气 · 冲刺"][mood], Vector2(405, 33), 16)
		draw_rect(Rect2(350, 43, 260, 8), Color("382b3c"))
		draw_rect(Rect2(350, 43, 260.0 * boss_hp / MAX_BOSS_HP, 8), FIRE_RED)
	if phase == "explore":
		_label("走近糖葫芦车旁的纸灯妖", Vector2(280, 91), 16)
	if phase == "failed":
		_label("按 R 重新挑战", Vector2(285, 253), 21)
	if phase == "peace":
		_label("已记录纸灯妖的回忆 · Esc 暂停", Vector2(315, 92), 16)
	if paused:
		_label("Paused · Esc: Resume · Q: Main Menu", Vector2(275, 258), 22)
