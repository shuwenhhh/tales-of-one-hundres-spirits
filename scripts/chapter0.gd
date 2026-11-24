extends Node2D

const BACKGROUND := preload("res://assets/chapter0/concepts/old_manor_road_moonlit_v3.png")
const CHEST := preload("res://assets/chapter0/encounter/chest.png")
const PLATE := preload("res://assets/chapter0/encounter/chest_backplate.png")
const SPIRIT := preload("res://assets/chapter0/encounter/spirit.png")
const GIRL := preload("res://assets/chapter1/pixel/girl/pose_0.png")
const FONT := preload("res://assets/chapter1/chinese.ttc")
const BOX := Rect2(565, 352, 103, 65)
const FLOOR_Y := 435.0
const JOURNEY := preload("res://scripts/journey_state.gd")
const CANOPY := preload("res://assets/chapter0/encounter/sky_canopy.png")
const TRANSITION := preload("res://scripts/scene_transition.gd")
const LINES: Array[String] = [
	"伞妖：哎哟。多谢！我这只脚都坐麻了。",
	"小语：你只有一只脚，还能把箱子晃得这么响？",
	"伞妖：我敲了半天呢。雨这么好，错过多可惜。",
	"小语：你一直在里面等下雨吗？",
	"伞妖：从前那家的姑娘，下雨就带我出门。搬家那天，她把我收进箱子里……我以为，只是等下一个雨天。",
	"伞妖：你看，空地上落雨了。能再撑我一次吗？",
	"小语：好。可要是下一滴在很远的地方呢？",
	"伞妖：朝那边走，按一下 Shift 就能冲刺。握紧我，别光顾着自己跑！",
	"伞妖：我来数。天上那十滴亮亮的雨，全接住才算一轮。漏了一滴，我们就从头再数。"
]

enum Phase { WAITING, OPENING, JUMPING, TALKING, UNFURL, RAIN, REJOICE, ENDING, FINISHED }
var phase := Phase.WAITING
var elapsed := 0.0
var x := 125.0
var facing := 1
var spirit_x := 0.0
var line := 0
const END_LINES: Array[String] = [
	"伞妖：嗒，嗒，嗒！一滴都没漏！我还记得这个声音！",
	"伞妖：以前她跑起来，雨就在我头顶上唱。刚才有那么一会儿……我又听见了。",
	"小语：下回下雨，还一起听吗？",
	"伞妖：下回？我现在就跟你走！天晴了也带上我，好不好？",
	"小语：好。晴天也一起走。"
]
const SKY_X := [497.0, 339.0, 172.0, 409.0, 561.0, 305.0, 130.0, 363.0, 540.0, 325.0]
var dash_left := 0.0
var dash_cooldown := 0.0
var dash_dir := 1
var leaving := false
var caught := 0
var drop_time := 0.0
var result_time := 0.0
var missed := false
var impact := Vector2.ZERO
var walk := preload("res://scripts/hero_walk.gd").new()
var dialogue := preload("res://scripts/dialogue_box.gd").new()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	JOURNEY.remember_chapter(scene_file_path)
	JOURNEY.apply_preferences()
	walk.setup_audio(self)
	dialogue.mount(self)

func in_reach() -> bool:
	return absf(x - BOX.get_center().x) <= 105

func _unhandled_input(event: InputEvent) -> void:
	var click: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var key: bool = event is InputEventKey and event.pressed and not event.echo
	if phase == Phase.RAIN and key and event.physical_keycode == KEY_SHIFT and dash_cooldown <= 0:
		dash_dir = facing
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			dash_dir = -1
		elif Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			dash_dir = 1
		dash_left = 0.18
		dash_cooldown = 0.8
	elif phase == Phase.WAITING and in_reach() and click and BOX.grow(4).has_point(make_input_local(event).position):
		phase = Phase.OPENING
		elapsed = 0
		walk.advance(0, true)
		spirit_x = BOX.get_center().x + (66 if x < BOX.get_center().x else -66)
		facing = 1 if spirit_x > x else -1
	elif phase in [Phase.TALKING, Phase.ENDING] and (click or (key and event.physical_keycode in [KEY_E, KEY_SPACE])):
		if dialogue.reveal_or_continue():
			next_line()
	elif phase == Phase.FINISHED and key and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()

func next_line() -> void:
	line += 1
	var lines := END_LINES if phase == Phase.ENDING else LINES
	if line < lines.size():
		dialogue.show_line(lines[line])
	else:
		dialogue.hide()
		elapsed = 0
		phase = Phase.FINISHED if phase == Phase.ENDING else Phase.UNFURL
		if phase == Phase.FINISHED:
			JOURNEY.complete_chapter(scene_file_path, END_LINES)

func _physics_process(delta: float) -> void:
	if phase not in [Phase.WAITING, Phase.RAIN, Phase.FINISHED]:
		return
	var left := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
	var right := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	var old_x := x
	var speed := (int(right) - int(left)) * 158.0
	dash_cooldown = maxf(0, dash_cooldown - delta)
	if dash_left > 0:
		speed = dash_dir * 470.0
		dash_left = maxf(0, dash_left - delta)
	x = clampf(x + speed * delta, 20, 940)
	walk.advance(x - old_x, true)
	if phase == Phase.FINISHED:
		spirit_x = move_toward(spirit_x, x - facing * 44, 180 * delta)
	if phase == Phase.FINISHED and x >= 936 and not leaving:
		leaving = TRANSITION.start(get_tree(), "res://scenes/chapter_intro.tscn") == OK
	if phase == Phase.RAIN:
		advance_rain(delta)
	if x != old_x:
		facing = 1 if x > old_x else -1

func drop_position() -> Vector2:
	return Vector2(SKY_X[caught], -8 + 98 * drop_time + 76 * drop_time * drop_time)

func advance_rain(delta: float) -> void:
	if result_time > 0:
		result_time -= delta
		if result_time <= 0:
			drop_time = 0
			if caught == SKY_X.size():
				phase = Phase.REJOICE
				walk.advance(0, true)
				spirit_x = x + 52 if x < 880 else x - 52
				facing = 1 if spirit_x > x else -1
				elapsed = 0
		return
	var previous := drop_position()
	drop_time += delta
	var pos := drop_position()
	var dx := absf(pos.x - x)
	var roof_y := FLOOR_Y - 87 + 19 * dx / 36
	if dx <= 36 and previous.y <= roof_y and pos.y >= roof_y:
		caught += 1
		missed = false
		impact = Vector2(pos.x, roof_y)
	elif pos.y >= FLOOR_Y:
		missed = true
		caught = 0
		impact = Vector2(pos.x, FLOOR_Y)
	else:
		return
	result_time = 1.0 if missed else 0.53

func _process(delta: float) -> void:
	elapsed += delta
	if phase == Phase.OPENING and elapsed >= 0.30:
		phase = Phase.JUMPING
		elapsed = 0
	elif phase == Phase.JUMPING and elapsed >= 0.82:
		phase = Phase.TALKING
		elapsed = 0
		JOURNEY.meet_chapter(scene_file_path, LINES)
		dialogue.show_line(LINES[0])
	elif phase == Phase.UNFURL and elapsed >= 0.65:
		phase = Phase.RAIN
		elapsed = 0
	elif phase == Phase.REJOICE and elapsed >= 1.0:
		phase = Phase.ENDING
		line = 0
		dialogue.show_line(END_LINES[0])
	elif phase in [Phase.TALKING, Phase.ENDING] and dialogue.advance_time(delta, Input.is_physical_key_pressed(KEY_CTRL)):
		next_line()
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(BACKGROUND, Rect2(0, 0, 960, 540), false)
	for i in 96:
		var y := fposmod(i * 57.3 + elapsed * (202 + i % 7 * 13), 448.0)
		var px := fposmod(i * 313.9 - y * 0.035, 960.0)
		draw_line(Vector2(px,y),Vector2(px+0.35,y-6-i%5),Color(.79,.83,.94,.12),1,true)
	draw_texture_rect(PLATE, BOX, false)
	var pivot := Vector2(BOX.get_center().x, BOX.end.y)
	if phase == Phase.WAITING:
		var angle := sin(elapsed * 20) * (0.028 + 0.018 * sin(elapsed * 4))
		draw_set_transform(pivot, angle)
		draw_texture_rect(CHEST, Rect2(-BOX.size.x / 2, -BOX.size.y, BOX.size.x, BOX.size.y), false)
		draw_set_transform(Vector2.ZERO)
	else:
		var opening := smoothstep(0.0, 0.30, elapsed) if phase == Phase.OPENING else 1.0
		var lid_height := 14 + 20 * opening
		var lid := Rect2(BOX.position.x + 2, BOX.position.y + 14 - lid_height, 99, lid_height)
		draw_texture_rect_region(CHEST, lid, Rect2(2, 0, 174, 25))
		draw_rect(Rect2(lid.position + Vector2(6, 4), Vector2(87, maxf(1, lid_height - 8))), Color("422f34").darkened(0.15))
		draw_rect(Rect2(BOX.position + Vector2(3, 9), Vector2(97, 10)), Color("2c2230"))
		if phase == Phase.JUMPING:
			var t := clampf(elapsed / 0.82, 0, 1)
			var foot := Vector2(lerpf(pivot.x, spirit_x, t), lerpf(BOX.position.y + 63, FLOOR_Y, t) - 102 * sin(PI * t))
			draw_spirit(foot, t)
		draw_texture_rect_region(CHEST, Rect2(BOX.position + Vector2(0, 17), Vector2(103, 48)), Rect2(0, 30, 179, 84))
		if phase == Phase.TALKING or phase >= Phase.REJOICE:
			var hop := 22 * absf(sin(2 * PI * elapsed)) if phase == Phase.REJOICE else 0.0
			draw_spirit(Vector2(spirit_x, FLOOR_Y - hop), 1)
	walk.draw_shadow(self, Vector2(x, FLOOR_Y), FLOOR_Y)
	draw_set_transform(Vector2(roundf(x), FLOOR_Y), 0, Vector2(facing, 1))
	if walk.walking:
		walk.draw_body(self, GIRL)
	else:
		draw_texture(GIRL, Vector2(-16, -65))
	draw_set_transform(Vector2.ZERO)
	if phase in [Phase.UNFURL, Phase.RAIN]:
		draw_rain_game()
	if phase == Phase.WAITING or phase == Phase.FINISHED:
		var hint := "A / D 或 ← →  走近木箱"
		if phase == Phase.FINISHED:
			hint = "伞妖加入同行   ·   向右进入第一章"
		elif in_reach():
			hint = "点击晃动的木箱"
		draw_string(FONT, Vector2(0, 507), hint, HORIZONTAL_ALIGNMENT_CENTER, 960, 16, Color("efdfc6"))

func draw_spirit(foot: Vector2, progress: float) -> void:
	var emerging := smoothstep(0, 0.18, progress)
	draw_set_transform(foot, 0, Vector2(1 if spirit_x >= x else -1, 1))
	draw_texture_rect(SPIRIT, Rect2(-26, -62 * emerging, 52, 62 * emerging), false)
	draw_set_transform(Vector2.ZERO)


func draw_rain_game() -> void:
	var spread := smoothstep(0.0, 0.55, elapsed) if phase == Phase.UNFURL else 1.0
	draw_set_transform(Vector2(roundf(x), FLOOR_Y - 87))
	draw_line(Vector2.ZERO, Vector2(facing * 8, 52), Color("765338"), 3)
	draw_set_transform(Vector2(roundf(x), FLOOR_Y - 87), 0, Vector2(maxf(.1, spread), 1))
	draw_texture_rect(CANOPY, Rect2(-42,-2,84,30), false)
	draw_set_transform(Vector2.ZERO)
	if phase != Phase.RAIN:
		return
	if result_time > 0:
		var t := 1 - result_time / (1.0 if missed else 0.53)
		for i in 5:
			var offset := Vector2((i-2)*12*t, -40*t + 65*t*t - sin(i)*4*t)
			draw_circle(impact + offset, 2.1-t, Color(.77,.90,1,1-t))
	else:
		var pos := drop_position()
		var tail := Vector2(1.2, -9.0 - drop_time * 6)
		draw_line(pos, pos + tail * 1.6, Color(.75,.84,.99,.22), 1.2, true)
		draw_colored_polygon(PackedVector2Array([pos+tail,pos+Vector2(2.7,-2),pos+Vector2(1,2),pos+Vector2(-2,1),pos+Vector2(-2.5,-3)]),Color(.71,.8,.96,.65))
		draw_line(pos+Vector2(-1,-5),pos+Vector2(-1,0),Color(.98,.89,.68),1.5,true)
	var hint := "左右移动   ·   Shift 冲刺"
	if result_time > 0 and missed:
		hint = "漏接了，再来一轮！"
	draw_string(FONT, Vector2(0, 507), "%s     %d / %d" % [hint,caught,SKY_X.size()], HORIZONTAL_ALIGNMENT_CENTER, 960, 16, Color("efdfc6"))
