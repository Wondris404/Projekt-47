extends RefCounted
class ClickMap extends WorldMap:
	var clicked := Vector2.INF
	func _click_at(point: Vector2) -> void:
		clicked = point

func run(u, host: Node) -> void:
	u._new()
	var map = ClickMap.new()
	host.add_child(map)
	map.size = Vector2(800, 600)
	map.position = Vector2(300, 80)
	map._initialize_camera_frame()
	map._zoom_at(Vector2(250, 200), 20.0)
	map.pan += Vector2(27, -35)
	var world = Vector2(800, 230)
	var before = map.get_global_transform() * map._to_screen(world)
	var scale = map._fit() * map.zoom
	map.size = Vector2(1100, 600)
	map.position = Vector2(0, 80)
	map._preserve_camera_layout()
	u._chk("camera_panel_world_position", before.distance_to(map.get_global_transform() * map._to_screen(world)) < 0.01)
	u._chk("camera_panel_scale_and_lod", is_equal_approx(scale, map._fit() * map.zoom) and map.zoom == 20.0)
	map.size = Vector2(800, 600)
	map.position = Vector2(300, 80)
	map._preserve_camera_layout()
	u._chk("camera_panel_roundtrip", before.distance_to(map.get_global_transform() * map._to_screen(world)) < 0.01)
	map.size = Vector2(1000, 800)
	map._preserve_camera_layout()
	u._chk("camera_window_resize", before.distance_to(map.get_global_transform() * map._to_screen(world)) < 0.01)
	var anchor = Vector2(320, 240)
	var at_anchor = map._to_world(anchor)
	map._zoom_at(anchor, 1.0)
	u._chk("camera_zoom_one_keeps_anchor", at_anchor.distance_to(map._to_world(anchor)) < 0.001)
	map._zoom_at(anchor, 60.0)
	u._chk("camera_zoom_in_keeps_anchor", at_anchor.distance_to(map._to_world(anchor)) < 0.001)
	var roundtrip = Vector2(145, 271)
	u._chk("camera_click_transform_roundtrip", roundtrip.distance_to(map._to_world(map._to_screen(roundtrip))) < 0.001)
	var press = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(100,100)
	map._gui_input(press)
	var release = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = Vector2(103,102)
	map._gui_input(release)
	u._chk("camera_click_release_coordinate", map.clicked == release.position)
	press.button_index = MOUSE_BUTTON_RIGHT
	map._gui_input(press)
	map._cancel_drag()
	u._chk("camera_focus_loss_cancels_drag", not map.dragging)
	map.free()
