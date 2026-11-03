extends SceneTree

# Benchmark only. Does not touch the strategic map, saves, or ship data.
# Map ships are 2D billboards in atlas_traffic.gd, not this live fleet.

const MODEL_PATH := "res://assets/models/ships/cargo.glb"
const INSTANCES := 100
const GRID := 10
const SPACING := 16.0
const DRAW_FRAMES := 4

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var packed := _load_model()
	if packed == null:
		print("P47_SHIP_BENCH missing")
	else:
		var holder := _spawn(packed)
		await _draw_if_possible(holder)
		var counts := _count_meshes(holder)
		print("P47_SHIP_BENCH %d %d" % [counts.x, counts.y])
	quit()

func _load_model() -> PackedScene:
	if not ResourceLoader.exists(MODEL_PATH) and not FileAccess.file_exists(MODEL_PATH):
		return null
	var res = load(MODEL_PATH)
	if res is PackedScene:
		return res
	return null

func _spawn(packed: PackedScene) -> Node3D:
	var holder := Node3D.new()
	holder.name = "BenchFleet"
	root.add_child(holder)
	for i in INSTANCES:
		var node := packed.instantiate()
		if node == null:
			continue
		if node is Node3D:
			var col := i % GRID
			var row := i / GRID
			(node as Node3D).position = Vector3(col * SPACING, 0.0, row * SPACING)
		holder.add_child(node)
	return holder

func _draw_if_possible(holder: Node3D) -> void:
	# Headless has a root Window, but it cannot present. Still count meshes.
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		return
	if root == null:
		return
	var vp := root.get_viewport()
	if vp == null:
		return
	var span := float(GRID - 1) * SPACING
	var cam := Camera3D.new()
	cam.name = "BenchCamera"
	cam.position = Vector3(span * 0.5, span * 0.85 + 10.0, span + 18.0)
	cam.look_at(Vector3(span * 0.5, 0.0, span * 0.5))
	cam.current = true
	holder.add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -30.0, 0.0)
	holder.add_child(sun)
	for _frame in DRAW_FRAMES:
		await process_frame

func _count_meshes(node: Node) -> Vector2i:
	var instances := 0
	var surfaces := 0
	if node is MeshInstance3D:
		instances += 1
		var mesh := (node as MeshInstance3D).mesh
		if mesh != null:
			surfaces += mesh.get_surface_count()
	for child in node.get_children():
		var sub := _count_meshes(child)
		instances += sub.x
		surfaces += sub.y
	return Vector2i(instances, surfaces)
