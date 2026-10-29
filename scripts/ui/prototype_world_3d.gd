extends SubViewportContainer

signal country_selected(iso: String)
signal city_selected(iso: String, city: String)
signal firm_selected(id: String)

const INDUSTRIAL_TYPES = ["steel_mill", "chem_plant", "textile_mill", "electronics_plant", "auto_plant", "arms_plant", "chip_fab", "aircraft_plant", "oil_refinery", "gas_works", "warehouse", "logistics_hub"]

var _map: Control
var _camera: Camera3D
var _viewport: SubViewport
var _dragging := false
var _moved := false
var _cities: Array = []
var _firms: Array = []
var _firm_key: Array = []
var _firm_layer: MultiMeshInstance3D
var _industrial_layer: MultiMeshInstance3D
var _city_layer: MultiMeshInstance3D
var _countries_ready := false
var _labels: Control

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
	var lighting = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("16263a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 1.0
	lighting.environment = environment
	world.add_child(lighting)
	_build_countries.call_deferred(world)
	_add_cities(world)
	_add_firms(world)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.far = 5000.0
	world.add_child(_camera)
	sync_from_map()
	_camera.current = true
	_labels = load("res://scripts/ui/map_3d_labels.gd").new()
	_labels.map_view = self
	add_child(_labels)
	resized.connect(_labels.queue_redraw)
	gui_input.connect(_input_3d)

func _build_countries(world: Node3D) -> void:
	var converter = load("res://scripts/ui/map_mesh_3d.gd")
	var world_texture: Texture2D = preload("res://scripts/ui/tex_util.gd").load_tex("res://assets/atlas/world.jpg")
	var border_vertices = PackedVector3Array()
	var started = Time.get_ticks_usec()
	for shape in _map.shapes:
		if not is_instance_valid(world) or is_queued_for_deletion(): return
		var mesh: ArrayMesh = converter.convert(shape.mesh)
		if mesh.get_surface_count() == 0: continue
		var item = MeshInstance3D.new()
		item.mesh = mesh
		var material = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		var shade = float(absi(str(shape.iso).hash()) % 20) / 100.0
		if world_texture != null:
			material.albedo_texture = world_texture
			material.albedo_color = Color(0.84 + shade * 0.5, 0.84 + shade * 0.5, 0.84 + shade * 0.5)
		else:
			material.albedo_color = Color(0.25 + shade, 0.34 + shade, 0.23 + shade)
		item.material_override = material
		world.add_child(item)
		for polygon in shape.polys:
			if polygon.size() < 2: continue
			for i in polygon.size():
				var a: Vector2 = polygon[i]
				var b: Vector2 = polygon[(i + 1) % polygon.size()]
				border_vertices.append(Vector3(a.x, 0.03, a.y))
				border_vertices.append(Vector3(b.x, 0.03, b.y))
		if Time.get_ticks_usec() - started >= 2000:
			await get_tree().process_frame
			started = Time.get_ticks_usec()
	if not border_vertices.is_empty() and is_instance_valid(world) and not is_queued_for_deletion():
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = border_vertices
		var borders = ArrayMesh.new()
		borders.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
		var outline = MeshInstance3D.new()
		outline.mesh = borders
		var border_material = StandardMaterial3D.new()
		border_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		border_material.albedo_color = Color("1a2020")
		outline.material_override = border_material
		world.add_child(outline)
	_countries_ready = true

func _add_firms(world: Node3D) -> void:
	var building = BoxMesh.new()
	building.size = Vector3(1.2, 1.8, 1.2)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color("efad43")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	building.material = material
	var instances = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = building
	_firm_layer = MultiMeshInstance3D.new()
	_firm_layer.multimesh = instances
	world.add_child(_firm_layer)
	_load_industrial.call_deferred(world)
	refresh_firms()

func _load_industrial(world: Node3D) -> void:
	var path = "res://assets/models/industrial_kenney/building-a.glb"
	if not ResourceLoader.exists(path) or ResourceLoader.load_threaded_request(path, "PackedScene", false) != OK: return
	var status = ResourceLoader.load_threaded_get_status(path)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		if not is_instance_valid(world) or is_queued_for_deletion(): return
		status = ResourceLoader.load_threaded_get_status(path)
	if status != ResourceLoader.THREAD_LOAD_LOADED: return
	var scene: PackedScene = ResourceLoader.load_threaded_get(path)
	if scene == null or not is_instance_valid(world) or is_queued_for_deletion(): return
	var model = scene.instantiate()
	var parts = model.find_children("*", "MeshInstance3D", true, false)
	if not parts.is_empty() and parts[0].mesh != null:
		var industrial = MultiMesh.new()
		industrial.transform_format = MultiMesh.TRANSFORM_3D
		industrial.mesh = parts[0].mesh
		_industrial_layer = MultiMeshInstance3D.new()
		_industrial_layer.multimesh = industrial
		world.add_child(_industrial_layer)
	model.free()
	_firm_key.clear()
	refresh_firms()

func refresh_firms() -> void:
	var entries: Array = []
	for firm in GameState.player_firms():
		entries.append({"id": str(firm.id), "pos": _map.firm_world_pos(firm), "industry": str(firm.get("industry", ""))})
	if entries == _firm_key: return
	_firm_key = entries.duplicate(true)
	_firms = entries
	var mesh = _firm_layer.multimesh
	mesh.instance_count = entries.size()
	var industrial_entries: Array = []
	for i in entries.size():
		var p: Vector2 = entries[i].pos
		if _industrial_layer != null and entries[i].industry in INDUSTRIAL_TYPES:
			industrial_entries.append(entries[i])
			mesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(0.25, 0.25, 0.25)), Vector3(p.x, 1.8, p.y)))
		else:
			mesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(p.x, 0.9, p.y)))
	if _industrial_layer != null:
		var factories = _industrial_layer.multimesh
		factories.instance_count = industrial_entries.size()
		for i in industrial_entries.size():
			var p: Vector2 = industrial_entries[i].pos
			factories.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(p.x, 0.0, p.y)))

func _firm_at(local_pos: Vector2) -> String:
	if _camera.size > 150.0: return ""
	var best = ""
	var distance = 12.0
	for firm in _firms:
		var pos: Vector2 = firm.pos
		var screen = _camera.unproject_position(Vector3(pos.x, 0.9, pos.y)) * size / Vector2(_viewport.size)
		var d = screen.distance_to(local_pos)
		if d < distance:
			distance = d
			best = firm.id
	return best

func _add_cities(world: Node3D) -> void:
	for iso in DataLoader.country_ids:
		for city in TerrainSystem.cities(str(iso)):
			_cities.append(city)
	if _cities.is_empty(): return
	var building = BoxMesh.new()
	building.size = Vector3(1.1, 0.9, 1.1)
	var instances = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = building
	instances.instance_count = _cities.size()
	for i in _cities.size():
		var p: Vector2 = _cities[i].pos
		instances.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(p.x, 0.0, p.y)))
	var layer = MultiMeshInstance3D.new()
	layer.multimesh = instances
	_city_layer = layer
	world.add_child(layer)
	_load_city_model.call_deferred(world)

func _load_city_model(world: Node3D) -> void:
	var path = "res://assets/models/city_kenney/building-a.glb"
	if not ResourceLoader.exists(path) or ResourceLoader.load_threaded_request(path, "PackedScene", false) != OK: return
	var status = ResourceLoader.load_threaded_get_status(path)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		if not is_instance_valid(world) or is_queued_for_deletion(): return
		status = ResourceLoader.load_threaded_get_status(path)
	if status != ResourceLoader.THREAD_LOAD_LOADED: return
	var scene: PackedScene = ResourceLoader.load_threaded_get(path)
	if scene == null or not is_instance_valid(world) or is_queued_for_deletion(): return
	var model = scene.instantiate()
	var parts = model.find_children("*", "MeshInstance3D", true, false)
	if not parts.is_empty() and parts[0].mesh != null and is_instance_valid(_city_layer):
		_city_layer.multimesh.mesh = parts[0].mesh
	model.free()

func _city_at(local_pos: Vector2) -> Dictionary:
	if _camera.size > 150.0: return {}
	var best: Dictionary = {}
	var distance = 12.0
	for city in _cities:
		var pos: Vector2 = city.pos
		var screen = _camera.unproject_position(Vector3(pos.x, 0.45, pos.y)) * size / Vector2(_viewport.size)
		var d = screen.distance_to(local_pos)
		if d < distance:
			distance = d
			best = city
	return best

func sync_from_map() -> void:
	if _map.size.x <= 0.0 or _map.size.y <= 0.0:
		_camera.size = 850.0
		_camera.position = Vector3(720, 1200, 960)
		_camera.look_at(Vector3(720, 0, 360), Vector3.FORWARD)
		return
	var center: Vector2 = _map._to_world(_map.size * 0.5)
	_camera.size = _map.size.y / maxf(_map._fit() * _map.zoom, 0.0001)
	_camera.position = Vector3(center.x, 1200, center.y + 600)
	_camera.look_at(Vector3(center.x, 0, center.y), Vector3.FORWARD)

func restore_map_camera() -> void:
	if _map.size.y <= 0.0 or size.x <= 0.0 or size.y <= 0.0: return
	var center = _ground(size * 0.5)
	if not is_finite(center.x) or not is_finite(center.y): return
	var fit: float = _map._fit()
	_map.zoom = clampf(_map.size.y / (maxf(fit, 0.0001) * _camera.size), 1.0, _map.MAX_ZOOM)
	_map._zoom_target = _map.zoom
	var map_size = Vector2(float(DataLoader.map.get("w", 1440)), float(DataLoader.map.get("h", 720)))
	var scale: float = fit * _map.zoom
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
			_labels.queue_redraw()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_camera.size = minf(1500.0, _camera.size * 1.25)
			_labels.queue_redraw()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_moved = false
			else:
				_dragging = false
				if not _moved:
					var point = _ground(event.position)
					var iso = _map.region_at_world(point)
					var city = _city_at(event.position)
					var firm = _firm_at(event.position)
					if firm != "":
						firm_selected.emit(firm)
					elif not city.is_empty():
						city_selected.emit(str(city.iso), str(city.name))
					elif iso != "": country_selected.emit(iso)
	elif event is InputEventMouseMotion and _dragging:
		var delta: Vector2 = event.relative
		if delta.length() > 0.1: _moved = true
		var move = delta * (_camera.size / maxf(size.y, 1.0))
		_camera.position.x -= move.x
		_camera.position.z -= move.y / 0.89442719
		_labels.queue_redraw()
