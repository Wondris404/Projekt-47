class_name RegionView
extends Control

const CAFE = preload("res://assets/sprites/cafe.png")
const FACTORY = preload("res://assets/sprites/factory.png")
const BANK = preload("res://assets/sprites/bank.png")
const ARMS = preload("res://assets/sprites/arms_plant.png")
const CHEM = preload("res://assets/sprites/chem_plant.png")
const MapScript = preload("res://scripts/ui/world_map.gd")

const CAFE_ANIM_PATH = "res://assets/sprites/cafe_anim.png"
const FACTORY_ANIM_PATH = "res://assets/sprites/factory_anim.png"
const BANK_ANIM_PATH = "res://assets/sprites/bank_anim.png"

const ANIM_FRAMES = 24
const ANIM_SPEED = 6.0

signal zone_picked(zone: String)

var label_font
signal city_picked(iso: String, city_name: String)  # JUAN4
var overlay = false
var _org = Vector2.ZERO
var _fitv = 1.0
var anim_time: float = 0.0
var _anim_acc: float = 0.0
var _cafe_anim: Texture2D
var _factory_anim: Texture2D
var _bank_anim: Texture2D

func _ready() -> void:
	clip_contents = true
	custom_minimum_size = Vector2(340, 210)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label_font = load("res://assets/fonts/NotoSans-Regular.ttf")
	if ResourceLoader.exists(CAFE_ANIM_PATH):
		_cafe_anim = load(CAFE_ANIM_PATH)
	if ResourceLoader.exists(FACTORY_ANIM_PATH):
		_factory_anim = load(FACTORY_ANIM_PATH)
	if ResourceLoader.exists(BANK_ANIM_PATH):
		_bank_anim = load(BANK_ANIM_PATH)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and visible:
		queue_redraw()

func _process(delta: float) -> void:
	if not visible or OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		return
	if _cafe_anim == null and _factory_anim == null and _bank_anim == null:
		return
	_anim_acc += delta
	if _anim_acc < 0.1:
		return
	anim_time += _anim_acc
	_anim_acc = 0.0
	queue_redraw()

func _zone_at(x: int, y: int) -> String:
	var h = absi(int(GameState.selected_iso.hash()) + x * 17 + y * 9) % 10
	if y >= 8:
		return "port"
	if h < 3:
		return "commercial"
	if h < 7:
		return "industrial"
	return "residential"

func _regions(iso: String) -> Array:
	var arr: Array = DataLoader.map.get("countries", [])
	for c in arr:
		if str(c.get("iso2", "")) == iso:
			var rows = c.get("regions", [])
			return rows if typeof(rows) == TYPE_ARRAY else []
	return []

func _outline(iso: String) -> PackedVector2Array:
	var arr: Array = DataLoader.map.get("countries", [])
	for c in arr:
		if str(c.get("iso2", "")) != iso:
			continue
		for ring in c.get("polys", []):
			var pk = PackedVector2Array()
			for p in ring:
				if typeof(p) == TYPE_ARRAY and p.size() >= 2:
					pk.append(Vector2(float(p[0]), float(p[1])))
			if pk.size() >= 3:
				return pk
	return PackedVector2Array()

func _draw() -> void:
	var iso = str(GameState.selected_iso)
	var poly = _outline(iso)
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.WATER)
	if poly.size() < 3:
		return
	var min_p = poly[0]
	var max_p = poly[0]
	for p in poly:
		min_p.x = min(min_p.x, p.x)
		min_p.y = min(min_p.y, p.y)
		max_p.x = max(max_p.x, p.x)
		max_p.y = max(max_p.y, p.y)
	var span = max_p - min_p
	var fit = min((size.x - 24.0) / max(span.x, 1.0), (size.y - 24.0) / max(span.y, 1.0))
	var origin = Vector2(12, 12) - min_p * fit
	_org = origin
	_fitv = fit
	var screen = PackedVector2Array()
	for p2 in poly:
		screen.append(origin + p2 * fit)
	var hue = float(absi(iso.hash()) % 360) / 360.0
	var fill = Color.from_hsv(hue, 0.4, 0.5)
	draw_colored_polygon(screen, fill)
	var hatch = fill.lightened(0.08)
	var y = 0.0
	while y < size.y:
		var hits: Array = []
		var prev = screen.size() - 1
		for i in screen.size():
			var a: Vector2 = screen[i]
			var b: Vector2 = screen[prev]
			if (a.y > y) != (b.y > y):
				hits.append(a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y))
			prev = i
		hits.sort()
		var k = 0
		while k + 1 < hits.size():
			draw_line(Vector2(hits[k], y), Vector2(hits[k + 1], y), hatch, 1.0, false)
			k += 2
		y += 12.0
	draw_polyline(screen, UiPalette.LAND_BORDER, 2.0, false)
	draw_polyline(screen, UiPalette.BORDER_HI, 1.0, false)
	for region in _regions(iso):
		for ring in region.get("polys", []):
			var line = PackedVector2Array()
			for p3 in ring:
				if typeof(p3) == TYPE_ARRAY and p3.size() >= 2:
					line.append(origin + Vector2(float(p3[0]), float(p3[1])) * fit)
			if line.size() >= 2:
				draw_polyline(line, UiPalette.BORDER_HI, 1.0, false)
			if label_font and line.size() > 0:
				draw_string_outline(label_font, line[0], str(region.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, UiPalette.OUTLINE)
				draw_string(label_font, line[0], str(region.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiPalette.TEXT)
	var cap = origin + MapScript.project(float(DataLoader.countries.get(iso, {}).get("capital_lat", 0.0)), float(DataLoader.countries.get(iso, {}).get("capital_lon", 0.0))) * fit
	draw_rect(Rect2(cap - Vector2(2, 2), Vector2(4, 4)), UiPalette.ACCENT)
	if label_font:
		var cap_name = str(DataLoader.countries.get(iso, {}).get("capital", iso))
		draw_string_outline(label_font, cap + Vector2(8, 4), cap_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, UiPalette.OUTLINE)
		draw_string(label_font, cap + Vector2(8, 4), cap_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiPalette.TEXT)
	for site in GameState.sites:
		if str(site.get("iso", "")) != iso:
			continue
		var sp = origin + MapScript.project(float(site.get("lat", 0.0)), float(site.get("lon", 0.0))) * fit
		var mark = UiPalette.TEXT_DIM
		if bool(site.get("damaged", false)):
			mark = UiPalette.BAD
		elif str(site.get("kind", "")) == "port":
			mark = UiPalette.BORDER_HI
		elif str(site.get("kind", "")) == "energy":
			mark = UiPalette.WARN
		elif str(site.get("kind", "")) == "region":
			mark = UiPalette.TEXT
		draw_rect(Rect2(sp - Vector2(3, 3), Vector2(6, 6)), mark)
	_draw_cities(iso, origin, fit)
	# Draw building icons for firms in this country
	_draw_firm_icons(iso, origin, fit)

func _anim_frame() -> int:
	return int(anim_time * ANIM_SPEED) % ANIM_FRAMES

func _draw_anim(strip: Texture2D, pos: Vector2, sz: float) -> void:
	var frame = _anim_frame()
	var src = Rect2(float(frame) * 32.0, 0.0, 32.0, 32.0)
	draw_texture_rect_region(strip, Rect2(pos - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)), src)

func _building_anim(kind: String) -> Texture2D:
	match kind:
		"cafe": return _cafe_anim
		"factory": return _factory_anim
		"bank": return _bank_anim
	return null

func _building_icon(kind: String) -> Texture2D:
	match kind:
		"cafe": return CAFE
		"factory": return FACTORY
		"bank": return BANK
		"arms_plant", "arms": return ARMS
		"chem_plant", "chemicals": return CHEM
	return null

func _draw_firm_icons(iso: String, origin: Vector2, fit: float) -> void:
	var offset_idx = 0
	for firm in GameState.firms:
		if str(firm.get("country", "")) != iso or bool(firm.get("closed", false)):
			continue
		var industry = str(firm.get("industry", ""))
		var icon = _building_icon(industry)
		if icon == null:
			offset_idx += 1
			continue
		var cap = origin + MapScript.project(float(DataLoader.countries.get(iso, {}).get("capital_lat", 0.0)), float(DataLoader.countries.get(iso, {}).get("capital_lon", 0.0))) * fit
		var pos = cap + Vector2(float(offset_idx) * 18.0 + 20.0, 4.0)
		var anim = _building_anim(industry)
		if anim != null:
			_draw_anim(anim, pos, 14.0)
		else:
			draw_texture_rect(icon, Rect2(pos - Vector2(7, 7), Vector2(14, 14)), false)
		offset_idx += 1

func _inside_poly(pt: Vector2, poly: PackedVector2Array) -> bool:
	var inside = false
	var j = poly.size() - 1
	for i in poly.size():
		var pi: Vector2 = poly[i]
		var pj: Vector2 = poly[j]
		var denom = pj.y - pi.y
		if abs(denom) < 0.00001:
			j = i
			continue
		if ((pi.y > pt.y) != (pj.y > pt.y)) and (pt.x < (pj.x - pi.x) * (pt.y - pi.y) / denom + pi.x):
			inside = not inside
		j = i
	return inside

func city_at(p: Vector2) -> String:
	var iso = str(GameState.selected_iso)
	for c in TerrainSystem.cities(iso):
		if (_org + c.pos * _fitv).distance_to(p) <= max(8.0, float(c.r) * _fitv):
			return str(c.name)
	return ""

func city_screen_pos(nm: String) -> Vector2:
	var c = TerrainSystem.city_named(str(GameState.selected_iso), nm)
	return _org + c.pos * _fitv if not c.is_empty() else Vector2(-1, -1)

func _draw_cities(iso: String, origin: Vector2, fit: float) -> void:
	if overlay:
		for d in TerrainSystem.deposits(iso):
			var sp = origin + d.pos * fit
			draw_circle(sp, max(4.0, float(d.r) * fit), TerrainSystem.RES_COLORS[d.res])
			if label_font:
				draw_string_outline(label_font, sp + Vector2(6, 4), str(TerrainSystem.RES_NAMES[d.res]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, UiPalette.OUTLINE)
				draw_string(label_font, sp + Vector2(6, 4), str(TerrainSystem.RES_NAMES[d.res]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UiPalette.TEXT)
	for c in TerrainSystem.cities(iso):
		var cp = origin + c.pos * fit
		var r = max(5.0, float(c.r) * fit)
		draw_circle(cp, r, Color(UiPalette.ACCENT, 0.22))
		draw_arc(cp, r, 0.0, TAU, 20, UiPalette.ACCENT, 1.5)
		draw_rect(Rect2(cp - Vector2(3, 3), Vector2(6, 6)), UiPalette.ACCENT if bool(c.capital) else UiPalette.TEXT)
		if label_font:
			draw_string_outline(label_font, cp + Vector2(8, -6), str(c.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, UiPalette.OUTLINE)
			draw_string(label_font, cp + Vector2(8, -6), str(c.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiPalette.TEXT)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var p = (event as InputEventMouseButton).position
		var cn = city_at(p)
		if cn != "":
			city_picked.emit(str(GameState.selected_iso), cn)
			accept_event()
			return
		var x = int(p.x / 21.0)
		var y = int(p.y / 21.0)
		if x >= 0 and x < 16 and y >= 0 and y < 10:
			zone_picked.emit(_zone_at(x, y))
			accept_event()
