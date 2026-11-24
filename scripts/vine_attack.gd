extends Node2D
class_name VineAttack
signal tip_contact(source: Vector2)
signal cracked
const CORE_TEXTURE := preload("res://assets/chapter2/vine/vine_core.png")
const LEAF_LARGE := preload("res://assets/chapter2/vine/vine_sprig_a.png")
const LEAF_SMALL := preload("res://assets/chapter2/vine/vine_sprig_b.png")
const TIP_TEXTURE := preload("res://assets/chapter2/vine/vine_tip.png")
const FLOWER_TEXTURE := preload("res://assets/chapter2/vine/vine_flower.png")
const ROOT_TEXTURE := preload("res://assets/chapter2/vine/vine_root.png")
enum OriginMode { STAFF, GROUND }
enum Stage { WARNING, EXTENDING, HOLDING, RETRACTING, DONE, RELAXING }
@export var origin_mode: OriginMode = OriginMode.STAFF
@export_range(14,18,1) var segments := 16
@export_range(10.0,22.0,0.5) var segment_length := 18.0
@export_range(0.012,0.02,0.001) var segment_delay := 0.014
@export_range(0.3,0.5,0.01) var warning_duration := 0.35
@export_range(0.12,0.18,0.01) var extend_duration := 0.15
@export_range(0.04,0.08,0.01) var hold_duration := 0.05
@export_range(0.2,0.4,0.01) var relax_duration := 0.25
@export_range(0.2,0.45,0.01) var retract_duration := 0.3
@export_range(0.1,0.15,0.01) var overshoot_ratio := 0.12
@export_range(0.02,0.06,0.005) var tip_contact_lead := 0.035
@export_range(60.0,100.0,2.0) var held_length := 78.0
@export_range(0.05,0.2,0.01) var coil_to_windup_duration := 0.12
@export_range(0.3,1.0,0.05) var droop_strength := 0.8
@export_range(0.0,0.25,0.01) var residual_wave := 0.12
@export_range(0.01,0.1,0.01) var leaf_lag := 0.04
@export var shape_seed := 2197
@export_range(6,14,1) var leaf_count := 10
@export_range(4.0,8.0,1.0) var root_width := 6.0
@export_range(1.0,3.0,0.5) var tip_width := 2.0
@export_range(4.0,12.0,1.0) var tip_hit_radius := 7.0
@export_range(4.0,24.0,1.0) var player_hit_radius := 12.0
var max_length: float:
	get: return segments * segment_length
	set(value): segment_length = value / segments
@onready var line: Line2D = $Line2D
@onready var tip: Sprite2D = $Tip
@onready var tip_area: Area2D = $TipArea
var hand_marker: Marker2D
var stage := Stage.WARNING
var elapsed := 0.0
var direction := Vector2.LEFT
var attack_facing := -1
var hit_player := false
var cancelled := false
var crack_played := false
var tip_position := Vector2.ZERO
var previous_tip := Vector2.ZERO
var points := PackedVector2Array()
var leaf_layout: Array[Dictionary] = []
var anchor_history: Array[Dictionary] = []
var initial_anchor := Vector2.ZERO
var ground_y := 448.0
var growth := 1.0
var contact_bend := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var taper := Curve.new()
	taper.add_point(Vector2(0,1))
	taper.add_point(Vector2(1,tip_width/root_width))
	line.width = root_width
	line.width_curve = taper
	line.texture = CORE_TEXTURE
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	line.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	line.antialiased = false
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	tip.texture = TIP_TEXTURE
	tip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var shape: CollisionShape2D = $TipArea/CollisionShape2D
	shape.shape = shape.shape.duplicate()
	(shape.shape as CircleShape2D).radius = tip_hit_radius
	_make_leaf_layout()

func _make_leaf_layout() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed
	leaf_layout.clear()
	for i in leaf_count:
		var station := 0.05 + pow(rng.randf(),1.8)*0.8
		leaf_layout.append({"station":station,"side":-1.0 if rng.randf()<0.55 else 1.0,"angle":rng.randf_range(-0.28,0.25),"large":station<0.48 and rng.randf()>0.2,"flower":i<2,"phase":rng.randf()*TAU})

func begin(staff_position:Vector2,target:Vector2,facing:int,floor_y:float) -> void:
	ground_y = floor_y
	global_position = staff_position
	if origin_mode == OriginMode.GROUND:
		global_position = Vector2(clampf(target.x-facing*45.0,32.0,928.0),floor_y)
	initial_anchor = global_position
	attack_facing = facing
	direction = (target-global_position).normalized()
	if direction.length_squared()<0.01: direction = Vector2(facing,0)
	anchor_history = [{"t":-2.0,"p":initial_anchor},{"t":0.0,"p":initial_anchor}]
	elapsed = 0.0
	stage = Stage.WARNING
	hit_player = false
	cancelled = false
	crack_played = false
	# A balanced S bend lets the tip pass through the aimed point, then overreach.
	# Changing angles consumes slack; link lengths never stretch.
	var low := 0.0
	var high := PI * 0.5
	for iteration in 16:
		var bend := (low + high) * 0.5
		var projected := 0.0
		for i in segments:
			projected += cos(bend * sin(TAU * (i + 0.5) / segments)) / segments
		if projected > 1.0 / (1.0 + overshoot_ratio): low = bend
		else: high = bend
	contact_bend = (low + high) * 0.5
	_make_leaf_layout()
	_render_vine()
	previous_tip = global_position+tip_position

func propagation_time() -> float:
	return (segments-1)*segment_delay
func snap_time() -> float:
	return warning_duration+extend_duration+propagation_time()
func end_time() -> float:
	return snap_time()+hold_duration+relax_duration+retract_duration
func damage_active() -> bool:
	return not cancelled and elapsed>=snap_time()-extend_duration*0.5 and elapsed<snap_time()+hold_duration
func nominal_reach() -> float:
	return max_length/(1.0+overshoot_ratio)

func advance(delta:float,player_center:Vector2,guard_center:Vector2 = Vector2(INF, INF),guard_radius:float = 0.0) -> void:
	if stage == Stage.DONE: return
	var remaining := delta
	while remaining>0.000001:
		var step := minf(remaining,1.0/120.0)
		previous_tip = global_position+tip_position
		elapsed += step
		var anchor := initial_anchor
		if is_instance_valid(hand_marker) and origin_mode == OriginMode.STAFF: anchor = hand_marker.global_position
		anchor_history.append({"t":elapsed,"p":anchor})
		while anchor_history.size()>2 and anchor_history[1].t<elapsed-1.0: anchor_history.pop_front()
		_update_stage()
		if stage == Stage.DONE:
			queue_free()
			return
		_render_vine()
		if damage_active() and not hit_player:
			var guard_contact := Vector2(INF, INF)
			if not is_inf(guard_center.x):
				guard_contact = contact_on_vine(guard_center, guard_radius)
			var body_contact := contact_on_vine(player_center, player_hit_radius)
			if not is_inf(guard_contact.x) or not is_inf(body_contact.x):
				hit_player = true
				tip_contact.emit(guard_contact if not is_inf(guard_contact.x) else body_contact)
		if stage == Stage.HOLDING and not crack_played:
			crack_played = true
			cracked.emit()
		remaining -= step

func contact_on_vine(center: Vector2, radius: float) -> Vector2:
	# Match the visible, tapered Line2D rather than treating only the fast tip as a weapon.
	var visible: PackedVector2Array = line.points
	for i in range(visible.size() - 1):
		var start := to_global(visible[i])
		var end := to_global(visible[i + 1])
		var contact := Geometry2D.get_closest_point_to_segment(center, start, end)
		var width := lerpf(root_width, tip_width, float(i) / maxf(1.0, visible.size() - 1.0))
		if center.distance_to(contact) <= radius + width * 0.5:
			return contact
	var tip_world := global_position + tip_position
	var tip_contact := Geometry2D.get_closest_point_to_segment(center, previous_tip, tip_world)
	if center.distance_to(tip_contact) <= radius + tip_hit_radius:
		return tip_contact
	return Vector2(INF, INF)

func _update_stage() -> void:
	if elapsed<warning_duration: stage=Stage.WARNING
	elif elapsed<snap_time(): stage=Stage.EXTENDING
	elif elapsed<snap_time()+hold_duration: stage=Stage.HOLDING
	elif elapsed<snap_time()+hold_duration+relax_duration: stage=Stage.RELAXING
	elif elapsed<end_time(): stage=Stage.RETRACTING
	else: stage=Stage.DONE

func interrupt() -> void:
	cancelled = true
	if stage == Stage.WARNING:
		# Even a cancelled coil relaxes and reels in visibly.
		elapsed = snap_time()+hold_duration
	elif stage in [Stage.EXTENDING,Stage.HOLDING]: elapsed=snap_time()+hold_duration
	_update_stage()
	_render_vine()

func seek(time:float) -> void:
	# Deterministic pose sampling used by the review scene and captures.
	elapsed = clampf(time,0.0,end_time()-0.0001)
	_update_stage()
	_render_vine()

func sync_hand() -> void:
	if is_instance_valid(hand_marker) and origin_mode == OriginMode.STAFF:
		anchor_history[-1].p = hand_marker.global_position
		_render_vine()

func _root_angle(time:float) -> float:
	if time<warning_duration:
		return lerpf(-1.45,-2.35,smoothstep(0.0,warning_duration,time))
	if time<warning_duration+extend_duration:
		return lerpf(-2.35,0.0,smoothstep(warning_duration,warning_duration+extend_duration,time))
	return 0.0

func segment_angle(index:int,time:float) -> float:
	var k := float(index)/maxf(1.0,segments-1.0)
	var local_time := time-index*segment_delay
	var curl := 1.0-smoothstep(warning_duration,warning_duration+extend_duration,local_time)
	var offset := _root_angle(local_time)+k*k*3.9*curl
	if origin_mode == OriginMode.STAFF and time < coil_to_windup_duration:
		var link := float(index)
		var held_offset := minf(3.4, 0.3 + 0.1 * link + 0.06 * link * link + 0.025 * link * link * link)
		offset = lerpf(held_offset, offset, smoothstep(0.0, coil_to_windup_duration, time))
	var contact_time := snap_time() - tip_contact_lead
	var align := smoothstep(snap_time() - extend_duration * 0.65, contact_time, time)
	var slack := 1.0 - smoothstep(contact_time, snap_time(), time)
	offset = lerpf(offset, contact_bend * sin(TAU * (index + 0.5) / segments) * slack, align)
	var relax_start := snap_time()+hold_duration
	var relax := smoothstep(relax_start,relax_start+relax_duration,time)
	# Fixed-length angles give the crack its extra reach; rebound consumes that reach in curvature.
	var rebound := acos(1.0/(1.0+overshoot_ratio))*sin(clampf((time-snap_time())/maxf(0.01,hold_duration+relax_duration),0,1)*PI)
	offset += rebound*k + residual_wave*k*sin((time-relax_start)*20.0-index*0.7)*relax*exp(-maxf(0,time-relax_start)*4.0)
	var angle := direction.angle()+attack_facing*offset
	return lerp_angle(angle,PI*0.5,droop_strength*k*relax)

func _anchor_at(time:float) -> Vector2:
	for i in range(anchor_history.size()-1,0,-1):
		if time>=anchor_history[i-1].t:
			var p := inverse_lerp(anchor_history[i-1].t,anchor_history[i].t,time)
			return (anchor_history[i-1].p as Vector2).lerp(anchor_history[i].p,clampf(p,0,1))
	return initial_anchor

func _render_vine() -> void:
	points = PackedVector2Array([to_local(_anchor_at(elapsed))])
	for i in segments:
		var vector := Vector2.from_angle(segment_angle(i,elapsed))*segment_length
		# Translation also travels down the chain instead of moving a rigid shape.
		var anchor_delta := _anchor_at(elapsed-(i+1)*segment_delay)-_anchor_at(elapsed-i*segment_delay)
		vector += anchor_delta.limit_length(segment_length * 0.2)
		var next := points[-1]+vector.normalized()*segment_length
		var floor_local := ground_y-global_position.y
		if next.y>floor_local and points[-1].y<=floor_local:
			var dy := floor_local-points[-1].y
			next = points[-1]+Vector2(attack_facing*sqrt(maxf(0.0,segment_length*segment_length-dy*dy)),dy)
		points.append(next)
	var visible_length := max_length
	var coiled_length := minf(held_length, max_length)
	if stage == Stage.WARNING:
		visible_length = lerpf(coiled_length, max_length, smoothstep(0.0, warning_duration * 0.8, elapsed))
	elif stage == Stage.RETRACTING:
		visible_length = lerpf(max_length, coiled_length, smoothstep(end_time()-retract_duration,end_time(),elapsed))
	growth = visible_length/max_length
	var display := PackedVector2Array([points[0]])
	var whole := mini(segments,int(visible_length/segment_length))
	for i in range(1,whole+1): display.append(points[i])
	if whole<segments:
		display.append(points[whole].lerp(points[whole+1],fmod(visible_length,segment_length)/segment_length))
	line.points = display
	tip_position = display[-1]
	tip.position = tip_position.round()
	var tangent := display[-1]-display[maxi(0,display.size()-2)]
	tip.rotation = snappedf(tangent.angle(),PI/12.0)
	tip.visible = visible_length>5.0
	tip_area.position = tip_position
	tip_area.monitoring = damage_active()
	queue_redraw()

func _draw() -> void:
	if points.size()<2: return
	for leaf in leaf_layout:
		if leaf.station>growth: continue
		var f:float = leaf.station*segments
		var i := mini(int(f),segments-1)
		var p := points[i].lerp(points[i+1],f-i)
		var tangent := (points[i+1]-points[i]).angle()
		var lag := angle_difference(segment_angle(i,elapsed),segment_angle(i,elapsed-leaf_lag))
		var angle: float = tangent+lag*0.65+leaf.angle
		angle += sin(elapsed*13.0+leaf.phase)*0.09*leaf.station
		angle = snappedf(angle,PI/12.0)
		var texture:Texture2D = LEAF_LARGE if leaf.large else LEAF_SMALL
		draw_set_transform(p.round(),angle,Vector2(1,leaf.side))
		draw_texture(texture,Vector2(-1,-texture.get_height()+1))
		if leaf.flower:
			# Wisteria racemes hang down under gravity and lag behind the stem's flick.
			var sway := snappedf(clampf(lag*0.8,-0.5,0.5),PI/12.0)
			draw_set_transform(p.round(),sway)
			draw_texture(FLOWER_TEXTURE,Vector2(-3,0))
	draw_set_transform(points[0].round(),snappedf(segment_angle(0,elapsed),PI/12.0))
	draw_texture(ROOT_TEXTURE,Vector2(-3,-5))
	draw_set_transform(Vector2.ZERO)
	if stage == Stage.WARNING:
		var pulse := 0.55+0.45*sin(elapsed*25.0)
		draw_arc(points[0],8.0+2.0*pulse,0,TAU,16,Color(1,0.85,0.7,pulse),1.0)
	if stage == Stage.HOLDING:
		var p := clampf((elapsed-snap_time())/hold_duration,0,1)
		draw_line(tip_position-Vector2(5,0),tip_position+Vector2(5,0),Color("fff0d8"),2)
		draw_line(tip_position-Vector2(0,5),tip_position+Vector2(0,5),Color("fff0d8"),2)
		for i in range(3):
			var v := Vector2.from_angle(i*TAU/3.0+0.3)*(4.0+p*10.0)
			draw_rect(Rect2((tip_position+v).round(),Vector2(3,2)),Color("d9c5f1"))
