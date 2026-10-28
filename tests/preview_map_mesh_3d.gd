extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = Node3D.new()
	root.add_child(world)
	var map = load("res://scripts/ui/world_map.gd").new()
	root.add_child(map)
	await process_frame
	var converter = load("res://scripts/ui/map_mesh_3d.gd")
	for shape in map.shapes:
		var mesh: ArrayMesh = converter.convert(shape.mesh)
		if mesh.get_surface_count() == 0: continue
		var node = MeshInstance3D.new()
		node.mesh = mesh
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var shade = float(absi(str(shape.iso).hash()) % 20) / 100.0
		mat.albedo_color = Color(0.25 + shade, 0.34 + shade, 0.23 + shade)
		node.material_override = mat
		world.add_child(node)
	map.queue_free()
	var camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 850.0
	world.add_child(camera)
	camera.position = Vector3(720, 1200, 360)
	camera.look_at(Vector3(720, 0, 360), Vector3.FORWARD)
	camera.current = true
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	var path = "res://audit/prebeta_3d_geometry_preview_20261028.png"
	var image = root.get_texture().get_image()
	var err = image.save_png(path)
	print("P47_3D_PREVIEW save=", err, " size=", image.get_size())
	quit(0 if err == OK else 1)
