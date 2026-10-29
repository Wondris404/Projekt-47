extends RefCounted
## Actual Godot Compatibility renderer captures. Run with Xvfb + llvmpipe.
const Models = preload("res://scripts/ui/atlas_models.gd")
const OUT := "res://docs/atlas-levels/"
var host: Node
var panel: ReviewPanel

class ReviewPanel extends Control:
	var kind := ""
	var title := ""
	var font: Font = preload("res://assets/fonts/NotoSans-Regular.ttf")
	func _draw() -> void:
		draw_rect(Rect2(0,0,960,360),Color("182c35"))
		for level in range(1,4):
			var x := float((level-1)*320)
			draw_rect(Rect2(x+8,8,304,344),Color("263e45"))
			draw_string(font,Vector2(x+20,32),title,HORIZONTAL_ALIGNMENT_LEFT,280,17,Color.WHITE)
			draw_string(font,Vector2(x+20,54),"Úroveň %d · %s" % [level,kind],HORIZONTAL_ALIGNMENT_LEFT,280,13,Color("b9ccd0"))
			Models.draw_model(self,kind,Vector2(x+160,212),32.0,level)
			draw_string(font,Vector2(x+22,233),"Zväčšený pohľad · pevná mierka",HORIZONTAL_ALIGNMENT_LEFT,280,12,Color("b9ccd0"))
			for i in 3:
				var width: int = [24,32,48][i]
				var px := x+60.0+i*96.0
				Models.draw_model(self,kind,Vector2(px,300),float(width)/4.0,level)
				draw_string(font,Vector2(px-18,328),"%d px" % width,HORIZONTAL_ALIGNMENT_LEFT,80,12,Color.WHITE)

func _frames(n: int = 3) -> void:
	for i in n: await host.get_tree().process_frame

func run(main: Node) -> void:
	host = main
	host._on_menu_dev()
	GameState.paused = true
	if host.map._traffic_layer != null: host.map._traffic_layer.set_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+"individual"))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960,360)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	host.add_child(viewport)
	panel = ReviewPanel.new()
	panel.size = Vector2(960,360)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.add_child(panel)
	var kinds: Array = DataLoader.industry_ids + ["bank","hq","port","highway"]
	var labels := {"bank":"Banka","hq":"Centrála","port":"Prístavný žeriav","highway":"Diaľnica"}
	for kind in kinds:
		panel.kind = str(kind)
		panel.title = str(DataLoader.industries.get(str(kind),{}).get("name",labels.get(str(kind),str(kind))))
		panel.queue_redraw()
		await _frames(2)
		await RenderingServer.frame_post_draw
		var img := viewport.get_texture().get_image()
		if img.save_png(ProjectSettings.globalize_path(OUT+str(kind)+".png")) != OK:
			push_error("Cannot write screenshot: "+str(kind))
			host.get_tree().quit(1)
			return
		for level in range(1,4):
			img.get_region(Rect2i((level-1)*320,0,320,360)).save_png(ProjectSettings.globalize_path(OUT+"individual/%s_L%d.png" % [kind,level]))
	viewport.queue_free()
	await _frames()
	await _map_pages(kinds,labels)
	if not await _upgrade_frames():
		host.get_tree().quit(1)
		return
	print("P47_ATLAS_CAPTURE_OK types=65 levels=195 sizes=24,32,48 renderer=",RenderingServer.get_video_adapter_name())
	host.get_tree().quit(0)

func _map_pages(kinds: Array, labels: Dictionary) -> void:
	if host.side_panel.visible: host.toggle_side_panel()
	await _frames()
	var map = host.map
	map.atlas = true
	map.zoom = 1.0
	map.pan = Vector2.ZERO
	map._zoom_target = 1.0
	map._zoom_at(map._to_screen(map.capital_of("SK")), minf(300.0,28.0/maxf(map._fit(),0.001)))
	map.pan += map.size*.5-map._to_screen(map.capital_of("SK"))
	print("P47_ATLAS_CAPTURE_CAMERA zoom=",map.zoom," fit=",map._fit()," size=",map.size)
	for page in range(ceili(kinds.size()/5.0)):
		GameState.firms.clear()
		GameState.banks.clear()
		var captions: Array = []
		for row in range(5):
			var index := page*5+row
			if index >= kinds.size(): break
			var kind := str(kinds[index])
			for level in range(1,4):
				var point := Vector2(200+(level-1)*300,115+row*115)
				var pos = map._to_world(point)
				GameState.firms.append({"id":"capture_%s_%d" % [kind,level],"industry":kind,"name":kind,"country":"SK","owner":"player","level":level,"cash":1e6,"closed":false,"pos":[pos.x,pos.y],"facilities":[]})
				var label := Label.new()
				label.position = map.get_global_transform()*(point+Vector2(-100,20))
				label.text = "%s · úroveň %d" % [str(DataLoader.industries.get(kind,{}).get("name",labels.get(kind,kind))),level]
				label.add_theme_font_size_override("font_size",12)
				label.add_theme_color_override("font_shadow_color",Color.BLACK)
				label.add_theme_constant_override("shadow_offset_x",2)
				label.add_theme_constant_override("shadow_offset_y",2)
				label.z_index = 100
				host.add_child(label)
				captions.append(label)
		map._ms_f = -1
		map._ainfra_key = -1
		map.queue_redraw()
		await _frames()
		await RenderingServer.frame_post_draw
		host.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+"atlas_%02d.png" % [page+1]))
		for label in captions: label.queue_free()
		await _frames(1)

func _upgrade_frames() -> bool:
	GameState.firms.clear()
	GameState.config.dev = true
	GameState.player.cash = 1e10
	GameState.found_firm("nuclear_plant","","SK")
	var firms = GameState.player_firms()
	if firms.is_empty():
		push_error("Upgrade capture could not create plant")
		return false
	var firm: Dictionary = firms[0]
	var map = host.map
	var wp = map._to_world(map.size*.5)
	firm.pos = [wp.x,wp.y]
	map._ms_f = -1
	map._ainfra_key = -1
	map.queue_redraw()
	await _frames()
	# Freeze only presentation updates to capture reproducible blend fractions.
	map.set_process(false)
	for target in [2,3]:
		var err = IndustrySystem.upgrade_firm(str(firm.id))
		if err != "":
			push_error(err)
			return false
		for step in range(5):
			if step > 0: map._atlas_upgrades.advance(0.55/4.0)
			map.queue_redraw()
			await _frames(2)
			await RenderingServer.frame_post_draw
			host.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+"upgrade_to_%d_%d.png" % [target,step]))
	return true
