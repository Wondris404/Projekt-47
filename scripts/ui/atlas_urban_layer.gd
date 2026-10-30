extends Node2D
## Geographic built-up land, separate from the game's city service radius.
## Vertices already use WorldMap's equirectangular projection; never inflate them.
const DATA_PATH := "res://data/atlas/urban_footprints.json"
var map: Control
var _tiles: Array = []
var _loaded := false
var _last: Array = []
var visible_tiles := 0

func _ready() -> void:
	show_behind_parent = true
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/ui/atlas_urban.gdshader")
	material = mat

func _process(_delta: float) -> void:
	if map == null: return
	var scale: float = map._fit()*map.zoom
	visible = map.atlas and scale >= 3.0
	var state := [visible,map.pan,map.size,scale]
	if state != _last:
		_last = state
		(material as ShaderMaterial).set_shader_parameter("map_scale",scale)
		queue_redraw()

func load_data() -> void:
	if _loaded: return
	_loaded = true
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	for row in data.tiles:
		var b: Array = row.bounds
		_tiles.append({"bounds":Rect2(b[0],b[1],b[2],b[3]),"row":row})

func mesh_for(tile: Dictionary) -> ArrayMesh:
	if tile.has("mesh"): return tile.mesh
	var coords: Array = tile.row.vertices
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	var bounds: Rect2 = tile.bounds
	var latitude := deg_to_rad(90.0-bounds.get_center().y/719.0*180.0)
	for i in range(0,coords.size(),2):
		var vertex := Vector2(coords[i],coords[i+1])
		vertices.append(vertex)
		# Local coordinates avoid precision loss and latitude-dependent shearing.
		uv.append((vertex-bounds.position)*Vector2(maxf(.1,cos(latitude)),1.0)/.016)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(tile.row.indices)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	tile["mesh"] = mesh
	return mesh

func _draw() -> void:
	visible_tiles = 0
	if map == null or not map.atlas: return
	var scale: float = map._fit()*map.zoom
	if scale < 3.0: return
	load_data()
	var a: Vector2 = map._to_world(Vector2.ZERO)
	var view := Rect2(a,map._to_world(map.size)-a)
	draw_set_transform(map._origin(),0,Vector2(scale,scale))
	for tile in _tiles:
		if view.intersects(tile.bounds):
			draw_mesh(mesh_for(tile),null)
			visible_tiles += 1
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
