extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var map = load("res://scripts/ui/world_map.gd").new()
	root.add_child(map)
	await process_frame
	var converter = load("res://scripts/ui/map_mesh_3d.gd")
	var tested = 0
	var failed = 0
	for shape in map.shapes:
		var source: ArrayMesh = shape.mesh
		if source.get_surface_count() == 0:
			continue
		var before = source.surface_get_arrays(0)
		var output: ArrayMesh = converter.convert(source)
		if output.get_surface_count() != 1:
			failed += 1
			continue
		var after = output.surface_get_arrays(0)
		var pts: PackedVector2Array = before[Mesh.ARRAY_VERTEX]
		var vs: PackedVector3Array = after[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = after[Mesh.ARRAY_TEX_UV]
		if pts.size() != vs.size() or pts.size() != uv.size() or before[Mesh.ARRAY_INDEX] != after[Mesh.ARRAY_INDEX]:
			failed += 1
			continue
		for i in pts.size():
			var want_uv = Vector2(pts[i].x / maxf(1.0, float(root.get_node("DataLoader").map.get("w", 1440)) - 1.0), pts[i].y / maxf(1.0, float(root.get_node("DataLoader").map.get("h", 720)) - 1.0))
			if vs[i] != Vector3(pts[i].x, 0.0, pts[i].y) or not uv[i].is_equal_approx(want_uv):
				failed += 1
				break
		tested += 1
	if tested == 0: failed += 1
	print("P47_3D_MESH polygons=%d failed=%d" % [tested, failed])
	map.queue_free()
	await process_frame
	quit(1 if failed else 0)
