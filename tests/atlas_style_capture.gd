extends RefCounted
## Fixed-camera before/after captures of a disposable paused world.
var OUT := "res://docs/atlas-map-style/"
var views := [["svet",15.0,10.0,0.8],["afrika",18.0,10.0,2.6],["europa",15.0,50.0,5.0],["slovensko",19.5,48.5,22.0],["bratislava",17.1,48.15,42.0]]
var host: Node

func frames(n: int = 3) -> void:
	for i in n: await host.get_tree().process_frame

func run(main: Node) -> void:
	host = main
	host._on_menu_dev()
	GameState.paused = true
	GameState.firms.clear()
	GameState.banks.clear()
	if host.side_panel.visible: host.toggle_side_panel()
	await frames(4)
	var map = host.map
	map.atlas = true
	map.hover = ""
	map._camera_initialized = false
	map._initialize_camera_frame()
	map._traffic_layer.set_process(false)
	var origin = map.project(48.15,17.1)
	var ids := ["hotel","casino","bank","nuclear_plant"]
	var offsets := [Vector2(-2,-1),Vector2(2,-1),Vector2(0,2),Vector2(5,3)]
	for i in ids.size():
		var p: Vector2 = origin+offsets[i]
		GameState.firms.append({"id":"style_"+ids[i],"industry":ids[i],"name":ids[i],"country":"SK","owner":"player","level":3 if ids[i]!="bank" else 1,"cash":1e6,"pos":[p.x,p.y],"facilities":[],"closed":false})
	map._ms_f = -1
	map._ainfra_key = -1
	map._atlas_layer.preload_all()
	for i in 240:
		if map._atlas_layer._pending.is_empty(): break
		await frames(1)
	var tag := "after"
	var args := OS.get_cmdline_user_args()
	if args.size()>1: tag = str(args[1])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var caption := Label.new()
	caption.position = map.get_global_transform()*Vector2(18,12)
	caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x",2)
	caption.add_theme_constant_override("shadow_offset_y",2)
	caption.z_index = 100
	host.add_child(caption)
	var results := []
	for view in views:
		var scale := float(view[3])
		map._zoom_at(map.size*.5,scale/map._fit())
		map.pan += map.size*.5-map._to_screen(map.project(float(view[2]),float(view[1])))
		caption.text = "Atlas · %s · %s" % [str(view[0]),"pred úpravou" if tag=="before" else "po úprave"]
		map.queue_redraw()
		await frames(5)
		await RenderingServer.frame_post_draw
		var image := host.get_viewport().get_texture().get_image()
		if image.save_png(ProjectSettings.globalize_path(OUT+str(view[0])+"_"+tag+".png"))!=OK:
			host.get_tree().quit(1)
			return
		results.append({"view":view[0],"scale":map._fit()*map.zoom,"draw_ms":map.last_draw_ms,"camera_zoom":map.zoom})
	var file := FileAccess.open(OUT+"capture_"+tag+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"renderer":RenderingServer.get_video_adapter_name(),"views":results},"\t")+"\n")
	print("P47_ATLAS_STYLE_CAPTURE_OK ",tag," ",results)
	host.get_tree().quit(0)
