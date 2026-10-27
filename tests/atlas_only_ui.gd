extends RefCounted

func run(host: Node) -> void:
	host._on_start({"country": "SK", "year": 2024, "seed": 47, "starter": false, "tutorial": false, "dev": false})
	await host.get_tree().process_frame
	await host.get_tree().process_frame
	var errors: Array[String] = []
	if not host.map.atlas or host.map_style() != "hoi" or host.map_style_b.visible:
		errors.append("normal game did not start with Atlas only")
	host.set_map_style("pixel")
	if not host.map.atlas or host.map_style() != "hoi":
		errors.append("old pixel setting changed the map")
	var saved: Dictionary = GameState.to_dict()
	var load_error = GameState.from_dict(saved)
	if load_error != "":
		errors.append("v3 save failed: " + load_error)
	host.map.atlas = false
	host._refresh_label()
	if not host.map.atlas:
		errors.append("loaded game did not return to Atlas")
	GameState.config.dev = true
	host._refresh_label()
	if not host.map.atlas or host.map_style_b.visible:
		errors.append("DEV game exposes the old map switch")
	var terrain: Button = host.find_child("TerrainToggle", true, false)
	terrain.button_pressed = true
	if not host.map.overlay:
		errors.append("terrain overlay did not toggle")
	var customers: Button = host.find_child("CustomersMapToggle", true, false)
	customers.button_pressed = true
	if not host.map.cust_mode:
		errors.append("customer map mode did not toggle")
	await host.get_tree().process_frame
	await RenderingServer.frame_post_draw
	host.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/atlas_only_ui.png"))
	if errors.is_empty():
		print("P47_ATLAS_ONLY_OK normal=1 saved=1 dev=1 overlays=1")
	else:
		for error in errors:
			print("P47_ATLAS_ONLY_FAIL ", error)
	host.get_tree().quit(0 if errors.is_empty() else 1)
