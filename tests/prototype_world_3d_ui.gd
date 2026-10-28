extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 5: await process_frame
	game._end_splash()
	game._on_menu_dev()
	for i in 8: await process_frame
	var gs = root.get_node("GameState")
	gs.paused = true
	var day = gs.day_index
	var map_center = game.map._to_world(game.map.size * 0.5)
	var button: Button = game.find_child("Prototype3DButton", true, false)
	var fails: Array[String] = []
	if button == null:
		print("P47_3D_UI_FAIL button")
		quit(1)
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://audit/prototype_3d_city_pred_20261028b.png")
	button.pressed.emit()
	for i in 8: await process_frame
	var view = game._prototype_3d
	if view == null or not view.visible or game.map.visible:
		fails.append("open")
	else:
		var cam: Camera3D = view._camera
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://audit/prototype_3d_city_po_20261028b.png")
		if Vector2(cam.position.x, cam.position.z).distance_to(map_center) > 0.1:
			fails.append("camera_in")
		var origin: Vector2 = view._ground(view.size * 0.5)
		if origin.distance_to(Vector2(cam.position.x, cam.position.z)) > 0.1:
			fails.append("projection")
		var city = root.get_node("TerrainSystem").cities("SK")[0]
		gs.selected_iso = "CZ"
		cam.position = Vector3(city.pos.x, 1200, city.pos.y)
		cam.size = 40.0
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://audit/prototype_3d_city_detail_20261028b.png")
		var local = cam.unproject_position(Vector3(city.pos.x, 0, city.pos.y)) * view.size / Vector2(view._viewport.size)
		var picked = []
		view.country_selected.connect(func(iso): picked.append(iso))
		var picked_city = []
		view.city_selected.connect(func(iso, name): picked_city.append([iso, name]))
		for down in [true, false]:
			var e = InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_LEFT
			e.pressed = down
			e.position = local
			view.gui_input.emit(e)
		if picked_city.is_empty() or picked_city[0] != ["SK", city.name] or gs.selected_iso != "SK" or not game.city_panel.visible: fails.append("city")
		var terrain = root.get_node("TerrainSystem")
		var inland: Vector2 = terrain.project(48.7, 19.6)
		local = cam.unproject_position(Vector3(inland.x, 0, inland.y)) * view.size / Vector2(view._viewport.size)
		for down in [true, false]:
			var e = InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_LEFT
			e.pressed = down
			e.position = local
			view.gui_input.emit(e)
		if picked.is_empty() or picked[0] != "SK": fails.append("country")
		var old_size = cam.size
		var wheel = InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP
		wheel.pressed = true
		view.gui_input.emit(wheel)
		if cam.size >= old_size: fails.append("zoom")
	button.pressed.emit()
	if game._prototype_3d != null or not game.map.visible: fails.append("close")
	var restored = game.map._to_world(game.map.size * 0.5)
	if restored.distance_to(Vector2(view._camera.position.x, view._camera.position.z)) > 0.2: fails.append("camera_out")
	if gs.day_index != day: fails.append("simulation")
	for failure in fails: print("P47_3D_UI_FAIL ", failure)
	if fails.is_empty(): print("P47_3D_UI_OK open projection country zoom close simulation")
	quit(0 if fails.is_empty() else 1)
