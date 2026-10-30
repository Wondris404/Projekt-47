extends RefCounted
const Urban = preload("res://scripts/ui/atlas_urban_layer.gd")

func covered(layer, point: Vector2) -> bool:
	for tile in layer._tiles:
		if not tile.bounds.has_point(point): continue
		var arrays: Array = layer.mesh_for(tile).surface_get_arrays(0)
		var vertices: PackedVector2Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for i in range(0,indices.size(),3):
			if Geometry2D.is_point_in_polygon(point,PackedVector2Array([vertices[indices[i]],vertices[indices[i+1]],vertices[indices[i+2]]])): return true
	return false

func run(u, host: Node) -> void:
	u._new()
	Empire.st()
	var before := JSON.stringify(GameState.to_dict())
	var rng = GameState.rng.state
	var map := WorldMap.new()
	host.add_child(map)
	map.size = Vector2(800,600)
	map.atlas = true
	var layer = Urban.new()
	layer.map = map
	map.add_child(layer)
	layer.load_data()
	for city in [["bratislava",48.1482,17.1067],["vienna",48.2082,16.3738],["paris",48.8566,2.3522],["tokyo",35.6895,139.6917]]:
		u._chk("urban_real_"+city[0],covered(layer,map.project(city[1],city[2])))
	u._chk("urban_rural_gap",not covered(layer,map.project(48.3,16.8)))
	var audit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/atlas/urban_footprints_audit.json"))
	u._chk("urban_bratislava_extent_km",audit.samples.Bratislava.width_km > 20.0 and audit.samples.Bratislava.width_km < 25.0 and audit.samples.Bratislava.height_km < 25.0)
	u._chk("urban_holes_and_area",audit.holes_preserved==228 and absf(audit.area_ratio_after_simplification-1.0)<0.005 and audit.max_triangulation_area_error_degrees2<1e-8)
	map.atlas = false
	layer._process(0)
	u._chk("urban_atlas_only",not layer.visible)
	map.atlas = true
	map._zoom_at(map.size*.5,10)
	layer._process(0)
	var a := map.project(48.15,17.0)
	var b := map.project(48.15,17.3)
	var first := map._to_screen(a).distance_to(map._to_screen(b))
	map._zoom_at(map.size*.5,20)
	var second := map._to_screen(a).distance_to(map._to_screen(b))
	u._chk("urban_geographic_scale",is_equal_approx(second/first,2.0) and layer.visible)
	u._chk("urban_save_and_rng_unchanged",JSON.stringify(GameState.to_dict())==before and GameState.rng.state==rng)
	map.free()
