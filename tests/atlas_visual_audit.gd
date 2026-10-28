extends RefCounted
# Real renderer screenshots of a temporary, paused scenario. Never reads/writes saves.
var host: Node
var label_layer: Control
var caption: Label
var tag := "before"
const OUT = "res://audit/screenshots/atlas-update/"

class Crosshair extends Control:
	var point := Vector2.ZERO
	func _draw() -> void:
		draw_line(point - Vector2(16, 0), point + Vector2(16, 0), Color("FFCA55"), 2)
		draw_line(point - Vector2(0, 16), point + Vector2(0, 16), Color("FFCA55"), 2)

func _frames(n: int = 4) -> void:
	for i in n: await host.get_tree().process_frame

func _snap(name: String, title: String) -> void:
	caption.text = title
	host.map.queue_redraw()
	if host.map._traffic_layer != null: host.map._traffic_layer.queue_redraw()
	await _frames()
	await RenderingServer.frame_post_draw
	var img = host.get_viewport().get_texture().get_image()
	var path = ProjectSettings.globalize_path(OUT + name + "_" + tag + ".png")
	img.save_png(path)
	print("P47_VISUAL_SAVED ", path)

func _center(zoom: float) -> void:
	var map = host.map
	map.zoom = 1.0
	map.pan = Vector2.ZERO
	map._zoom_target = 1.0
	map._zoom_at(map._to_screen(map.capital_of("SK")), zoom)
	map.pan += map.size * 0.5 - map._to_screen(map.capital_of("SK"))
	map._zoom_target = map.zoom

func run(p_host: Node) -> void:
	host = p_host
	var args = OS.get_cmdline_user_args()
	tag = str(args[1]) if args.size() > 1 else "before"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	host._on_menu_dev()
	GameState.paused = true
	preload("res://scripts/gfx.gd")._low = 0
	await _frames(8)
	caption = Label.new()
	caption.position = Vector2(12, 8)
	caption.z_index = 100
	caption.add_theme_color_override("font_color", Color.WHITE)
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	host.add_child(caption)
	var mode = str(args[2]) if args.size() > 2 else "all"
	if mode in ["all", "camera"]: await _camera()
	if mode in ["all", "transport"]: await _transport()
	if mode in ["all", "models"]: await _models()
	print("P47_VISUAL_DONE ", tag)
	host.get_tree().quit(0)

func _camera() -> void:
	_center(24.0)
	await _frames()
	var point = host.map.capital_of("SK")
	var marker = Crosshair.new()
	marker.z_index = 90
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.point = host.map.get_global_transform() * host.map._to_screen(point)
	host.add_child(marker)
	await _snap("camera_panel_open", "Kamera: panel otvorený; kríž označuje pôvodnú polohu Bratislavy")
	host.toggle_side_panel()
	await _frames()
	var closed_point = host.map.get_global_transform() * host.map._to_screen(point)
	print("P47_CAMERA_PANEL_DRIFT_PX ", marker.point.distance_to(closed_point))
	await _snap("camera_panel_closed", "Kamera: panel zatvorený; kríž musí zostať na tom istom mieste mapy")
	host.toggle_side_panel()
	await _snap("camera_panel_reopened", "Kamera: panel znovu otvorený")
	host.get_window().size = Vector2i(1440, 900)
	await _snap("camera_window_resize", "Kamera: zmena veľkosti okna na 1440 × 900")
	print("P47_CAMERA_RESIZE_DRIFT_PX ", marker.point.distance_to(host.map.get_global_transform() * host.map._to_screen(point)))
	marker.queue_free()
	host.get_window().size = Vector2i(1280, 720)
	await _frames()

func _transport() -> void:
	if host.side_panel.visible: host.toggle_side_panel()
	await _frames()
	_center(24.0)
	GameState.firms.clear()
	GameState.banks.clear()
	Transport.st().lines.clear()
	var map = host.map
	for kind in ["rail", "pipe"]:
		var row = 0
		for load in [0.0, 0.15, 0.5, 1.0, 1.5]:
			var y = 105.0 + row * 72.0
			var a = map._to_world(Vector2(170, y))
			var b = map._to_world(Vector2(map.size.x - 150, y))
			var cap = 600.0 if kind == "rail" else 900.0
			Transport.st().lines.append({"id": "visual_%s_%d" % [kind, row], "kind": kind, "a": [a.x, a.y], "b": [b.x, b.y], "km": Transport.km(a,b), "cap": cap, "used": cap * load, "used_prev": cap * load})
			row += 1
		map.anim_time = 1.75
		await _snap("transport_" + kind, "Železnice / potrubia: vyťaženie 0 %, 15 %, 50 %, 100 %, 150 %; simulácia je pozastavená")
		map.anim_time = 4.25
		await _snap("transport_" + kind + "_motion", "Tok a doprava v neskoršom čase; údaj predstavuje vyťaženie, nie druh komodity")
		Transport.st().lines.clear()
	_center(1.0)
	await _snap("transport_distant", "Vzdialený pohľad: animácia dopravy má byť vypnutá")

func _models() -> void:
	if host.side_panel.visible: host.toggle_side_panel()
	await _frames()
	var kinds: Array = DataLoader.industry_ids.duplicate()
	kinds.append("bank")
	for zi in 3:
		var z = [6.0, 20.0, 60.0][zi]
		var view = ["region", "detail", "city"][zi]
		_center(z)
		for page in range(ceili(kinds.size() / 12.0)):
			GameState.firms.clear()
			GameState.banks.clear()
			var labels: Array = []
			for i in range(page * 12, mini((page + 1) * 12, kinds.size())):
				var ind = str(kinds[i])
				var slot = i % 12
				var screen = Vector2(130 + (slot % 4) * (host.map.size.x - 210) / 4.0, 135 + (slot / 4) * 145)
				var pos = host.map._to_world(screen)
				GameState.firms.append({"id": "visual_%d" % i, "industry": ind, "name": ind, "country": "SK", "owner": "player", "cash": 1.0e6, "closed": false, "pos": [pos.x,pos.y], "facilities": [{"recipe": str(DataLoader.industries.get(ind, {}).get("recipe", ind)), "country":"SK", "scale":1.0, "inventory":{}}]})
				var l = Label.new()
				l.position = host.map.get_global_transform() * (screen + Vector2(-70, 36))
				l.text = str(DataLoader.industries.get(ind, {}).get("name", "Banka")) + "\n" + ind
				l.add_theme_font_size_override("font_size", 12)
				l.add_theme_color_override("font_shadow_color", Color.BLACK)
				l.add_theme_constant_override("shadow_offset_x", 2)
				l.add_theme_constant_override("shadow_offset_y", 2)
				l.z_index = 90
				host.add_child(l)
				labels.append(l)
			await _frames()
			await _snap("models_%s_%02d" % [view,page+1], "Modely na Atlase: %s, strana %d; 61 odvetví + banka" % [view,page+1])
			for l in labels: l.queue_free()
