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
	var failures: Array[String] = []
	if game.map_style() != "hoi" or not game.map.atlas or not game.map_style_b.visible:
		failures.append("Predvolená mapa Atlas alebo prepínač")
	var old_zoom = game.map.zoom
	var old_pan = game.map.pan
	game.map_style_b.pressed.emit()
	for i in 3: await process_frame
	if game.map_style() != "pixel" or game.map.atlas:
		failures.append("Prepnutie na pixelovú mapu")
	if game.map.zoom != old_zoom or game.map.pan != old_pan:
		failures.append("Poloha kamery sa zmenila")
	var cfg = ConfigFile.new()
	if cfg.load("user://settings.cfg") != OK or cfg.get_value("graphics", "map_style", "") != "pixel":
		failures.append("Uloženie nastavenia")
	game._map_style = "hoi"
	game._load_ui_scale()
	game._sync_map_style()
	if game.map_style() != "pixel" or game.map.atlas:
		failures.append("Obnovenie nastavenia")
	game.map_style_b.pressed.emit()
	for i in 3: await process_frame
	if game.map_style() != "hoi" or not game.map.atlas:
		failures.append("Návrat na Atlas")
	for failure in failures: print("P47_PIXEL_FAIL ", failure)
	if failures.is_empty(): print("P47_PIXEL_OK default=1 toggle=1 camera=1 save=1 restore=1")
	quit(1 if failures.size() > 0 else 0)
