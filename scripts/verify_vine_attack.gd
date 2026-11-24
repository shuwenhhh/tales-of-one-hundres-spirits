extends SceneTree
var failures := 0
func check(ok:bool,message:String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var vine = preload("res://scenes/vine_attack.tscn").instantiate()
	root.add_child(vine)
	var marker := Marker2D.new()
	root.add_child(marker)
	marker.position = Vector2(600,300)
	vine.begin(marker.position,Vector2(320,340),-1,448)
	vine.hand_marker = marker
	check(vine.line.points[-1].distance_to(vine.line.points[0]) <= vine.held_length + 1.0,"attack begins with a held coil")
	vine.seek(vine.warning_duration * 0.8)
	check(vine.line.points.size() > 2 and vine.line.points[-1].distance_to(vine.line.points[0]) > vine.held_length,"windup did not uncoil")
	check(vine.line.width == 6.0,"root must be 6px")
	check(vine.tip.texture.get_size() == Vector2(10,6),"tip must be a small bud")
	var max_error := 0.0
	var tip_speed := 0.0
	var root_speed := 0.0
	var previous:PackedVector2Array = vine.points.duplicate()
	for frame in range(150):
		var time := frame/120.0
		vine.seek(time)
		for i in range(vine.points.size()-1):
			max_error=maxf(max_error,absf(vine.points[i].distance_to(vine.points[i+1])-vine.segment_length))
		if time>vine.warning_duration and time<vine.snap_time():
			tip_speed=maxf(tip_speed,previous[-1].distance_to(vine.points[-1])*120.0)
			root_speed=maxf(root_speed,previous[1].distance_to(vine.points[1])*120.0)
		if vine.stage in [vine.Stage.WARNING,vine.Stage.RELAXING,vine.Stage.RETRACTING]:
			check(not vine.damage_active(),"damage outside late flick/crack")
		previous=vine.points.duplicate()
	check(max_error<0.001,"segment length changed")
	check(tip_speed>root_speed,"tip should outrun the first segment")
	vine.seek(vine.snap_time())
	var reach:float = (vine.points[-1]-vine.points[0]).length()
	check(absf(reach/vine.nominal_reach()-1.12)<0.01,"crack overreach must be 12% without stretching")
	vine.begin(marker.position,Vector2(320,340),-1,448)
	marker.position += Vector2(12,0)
	vine.advance(1.0/120.0,Vector2(-1000,-1000))
	check((vine.to_global(vine.points[0])-marker.global_position).length()<0.01,"root lost hand marker")
	vine.seek(vine.snap_time())
	var contacts := [0]
	vine.tip_contact.connect(func(_source): contacts[0]+=1)
	vine.advance(0.001,vine.to_global(vine.points[7]))
	check(contacts[0]==0,"middle of vine damaged player")
	vine.advance(0.001,vine.to_global(vine.tip_position))
	check(contacts[0]==1,"tip did not hit during crack")
	vine.interrupt()
	check(not vine.damage_active(),"interrupted vine still damaging")
	vine.begin(marker.position,Vector2(320,340),-1,448)
	vine.seek(vine.snap_time())
	contacts[0] = 0
	vine.advance(0.001,Vector2(-1000,-1000),vine.to_global(vine.tip_position),30.0)
	check(contacts[0]==1,"raised umbrella did not intercept tip before body contact")
	print("VINE V2: %d failures; segment error %.6f; tip speed %.1f > root %.1f" % [failures,max_error,tip_speed,root_speed])
	vine.queue_free()
	marker.queue_free()
	await process_frame
	quit(1 if failures else 0)
