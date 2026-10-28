extends Control

var map_view: Control
var _countries: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for shape in map_view._map.shapes:
		var country: Dictionary = DataLoader.countries.get(str(shape.iso), {})
		var name = str(country.get("name_sk", ""))
		if name != "" and not shape.main_poly.is_empty():
			_countries.append({"name": name, "pos": map_view._map._centroid(shape.main_poly)})

func _draw() -> void:
	if map_view == null or map_view._camera == null: return
	var camera: Camera3D = map_view._camera
	var occupied: Array[Rect2] = []
	var font = ThemeDB.fallback_font
	if camera.size > 150.0:
		for country in _countries:
			var wp: Vector2 = country.pos
			var screen: Vector2 = camera.unproject_position(Vector3(wp.x, 0.05, wp.y)) * size / Vector2(map_view._viewport.size)
			_draw_label(font, str(country.name), screen, occupied)
	else:
		for city in map_view._cities:
			var wp: Vector2 = city.pos
			var screen: Vector2 = camera.unproject_position(Vector3(wp.x, 1.4, wp.y)) * size / Vector2(map_view._viewport.size)
			_draw_label(font, str(city.name), screen + Vector2(0, -7), occupied)

func _draw_label(font: Font, label: String, point: Vector2, occupied: Array[Rect2]) -> void:
	if not Rect2(Vector2.ZERO, size).has_point(point): return
	var text_size = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	var box = Rect2(point - Vector2(text_size.x * 0.5, text_size.y), text_size).grow(2.0)
	if not Rect2(Vector2.ZERO, size).encloses(box): return
	for previous in occupied:
		if previous.intersects(box): return
	occupied.append(box)
	draw_string_outline(font, point - Vector2(text_size.x * 0.5, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color("1a2020"))
	draw_string(font, point - Vector2(text_size.x * 0.5, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f2ead6"))
