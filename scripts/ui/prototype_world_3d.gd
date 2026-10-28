extends SubViewportContainer

signal country_selected(iso: String)

var _map: Control
var _camera: Camera3D
var _viewport: SubViewport
var _dragging := false
var _moved := false

func setup(source_map: Control) -> void:
	_map = source_map
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1280, 720)
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_viewport)
	var world = Node3D.new()
	_viewport.add_child(world)
	var converter = load("res://scripts/ui/map_mesh_3d.gd")
	for shape in _map.shapes:
		var mesh: ArrayMesh = converter.convert(shape.mesh)
		if mesh.get_surface_count() == 0: continue
		var item = MeshInstance3D.new()
		item.mesh = mesh
		var material = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		var shade = float(absi(str(shape.iso).hash()) % 20) / 100.0
		material.albedo_color = Color(0.25 + shade, 0.34 + shade, 0.23 + shade)
		item.material_override = material
		world.add_child(item)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.far = 5000.0
	world.add_child(_camera)
	sync_from_map()
	_camera.current = true
	gui_input.connect(_input_3d)

func sync_from_map() -> void:
	var center: Vector2 = _map._to_world(_map.size * 0.5)
	_camera.size = _map.size.y / maxf(_map._fit() * _map.zoom, 0.0001)
	_camera.position = Vector3(center.x, 1200, center.y)
	_camera.look_at(Vector3(center.x, 0, center.y), Vector3.FORWARD)

func restore_map_camera() -> void:
	if _map.size.y <= 0.0: return
	var fit: float = _map._fit()
	_map.zoom = clampf(_map.size.y / (maxf(fit, 0.0001) * _camera.size), 1.0, _map.MAX_ZOOM)
	_map._zoom_target = _map.zoom
	var map_size = Vector2(float(DataLoader.map.get("w", 1440)), float(DataLoader.map.get("h", 720)))
	var scale: float = fit * _map.zoom
	var center = Vector2(_camera.position.x, _camera.position.z)
	_map.pan = _map.size * 0.5 - ( _map.size - map_size * scale) * 0.5 - center * scale
	_map.queue_redraw()

func _ground(local_pos: Vector2) -> Vector2:
	if size.x <= 0.0 or size.y <= 0.0: return Vector2(INF, INF)
	var p = local_pos * Vector2(_viewport.size) / size
	var origin = _camera.project_ray_origin(p)
	var direction = _camera.project_ray_normal(p)
	if absf(direction.y) < 0.0001: return Vector2(INF, INF)
	var hit = origin - direction * (origin.y / direction.y)
	return Vector2(hit.x, hit.z)

func _input_3d(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_camera.size = maxf(20.0, _camera.size * 0.8)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_camera.size = minf(1500.0, _camera.size * 1.25)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_moved = false
			else:
				_dragging = false
				if not _moved:
					var point = _ground(event.position)
					var iso = _map.region_at_world(point)
					if iso != "": country_selected.emit(iso)
	elif event is InputEventMouseMotion and _dragging:
		var delta: Vector2 = event.relative
		if delta.length() > 0.1: _moved = true
		var move = delta * (_camera.size / maxf(size.y, 1.0))
		_camera.position.x -= move.x
		_camera.position.z -= move.y
