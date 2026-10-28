extends RefCounted

# Convert the already cleaned and triangulated strategic map geometry to the
# same coordinates in the X/Z plane. This does not own or modify game state.
static func convert(source: ArrayMesh) -> ArrayMesh:
	var result = ArrayMesh.new()
	if source == null or source.get_surface_count() == 0:
		return result
	var source_arrays = source.surface_get_arrays(0)
	var points: PackedVector2Array = source_arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = source_arrays[Mesh.ARRAY_INDEX]
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	vertices.resize(points.size())
	normals.resize(points.size())
	uvs.resize(points.size())
	var width = maxf(1.0, float(DataLoader.map.get("w", 1440)) - 1.0)
	var height = maxf(1.0, float(DataLoader.map.get("h", 720)) - 1.0)
	for i in points.size():
		vertices[i] = Vector3(points[i].x, 0.0, points[i].y)
		normals[i] = Vector3.UP
		uvs[i] = Vector2(points[i].x / width, points[i].y / height)
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices.duplicate()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result
