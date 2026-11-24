extends SceneTree
const OUT := "res://assets/chapter2/wisteria/"
const ANIM := "res://assets/chapter2/animations/"
const HANDS := {"cast":[Vector2(70,80),Vector2(48,46),Vector2(55,30)],"leap":[Vector2(73,85),Vector2(63,69),Vector2(56,84),Vector2(56,70)],"walk":[Vector2(70,80),Vector2(70,80),Vector2(70,80),Vector2(70,80),Vector2(70,80),Vector2(70,80)]}
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	# Optional approved background input: -- --background C:/path/to/clean.png
	# Rebuilding the character does not depend on a developer's image cache.
	var args := OS.get_cmdline_user_args()
	var background_arg := args.find("--background")
	if background_arg >= 0 and background_arg + 1 < args.size():
		var background := Image.load_from_file(args[background_arg + 1])
		if background == null:
			push_error("Cannot read approved background")
			quit(1)
			return
		background.resize(960,540,Image.INTERPOLATE_NEAREST)
		background.save_png(OUT+"garden.png")
	for kind in ["cast","leap","walk"]:
		convert_vector(kind)
	var idle := Image.load_from_file(ProjectSettings.globalize_path(OUT+"cast-00.png"))
	idle.save_png(OUT+"idle.png")
	print("Wisteria vector variants and garden prepared")
	quit()
func convert_vector(kind:String) -> void:
	var parser := XMLParser.new()
	parser.open(ANIM+kind+"-vector.svg")
	var frames:Array[String]=[]
	var frame := -1
	while parser.read()==OK:
		if parser.get_node_type()!=XMLParser.NODE_ELEMENT: continue
		var tag := parser.get_node_name()
		if tag=="g":
			frame += 1
			frames.append("")
		if tag!="rect" or frame<0: continue
		var attrs := {}
		for i in parser.get_attribute_count(): attrs[parser.get_attribute_name(i)]=parser.get_attribute_value(i)
		var px := int(attrs.get("x",0))
		var py := int(attrs.get("y",0))
		var width := int(attrs.get("width",1))
		var color := Color(attrs.get("fill","#000000"))
		var hand:Vector2 = HANDS[kind][frame]
		for xx in range(px,px+width):
			var stem_y := hand.y+(hand.x-xx)*0.35
			if kind=="cast" and frame>0: stem_y=hand.y-(hand.x-xx)*(0.24 if frame==1 else 0.5)
			if kind=="leap": stem_y=hand.y+(hand.x-xx)*0.08
			if xx<hand.x-4 and absf(py-stem_y)<10.0: continue
			if kind=="cast" and frame==2 and xx<43 and py<26: continue
			var tint := color
			if (py>98 or (xx>94 and py<58)) and tint.r-tint.g>0.035:
				tint.r*=0.91
				tint.b=minf(1.0,tint.b+0.10)
				tint.g=minf(1.0,tint.g+0.015)
			# The remaining short grip becomes a flexible sage vine wrap.
			if xx>=hand.x-4 and xx<hand.x+27 and absf(py-stem_y)<2.0 and tint.r<0.62 and tint.r>tint.g:
				tint=Color("858878")
			frames[frame]+='<rect x="%d" y="%d" width="1" height="1" fill="#%s"/>' % [xx,py,tint.to_html(false)]
	for i in frames.size():
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="160" height="160" shape-rendering="crispEdges">'+frames[i]+'</svg>'
		var file := FileAccess.open(OUT+"%s-%02d.svg" % [kind,i],FileAccess.WRITE)
		file.store_string(svg)
		var image := Image.new()
		var error := image.load_svg_from_string(svg)
		if error!=OK: push_error("Vector conversion failed")
		image.save_png(OUT+"%s-%02d.png" % [kind,i])
