class_name WorldMap
extends Control

const CAFE = preload("res://assets/sprites/cafe.png")
const FACTORY = preload("res://assets/sprites/factory.png")
const BANK = preload("res://assets/sprites/bank.png")
const ARMS = preload("res://assets/sprites/arms_plant.png")
const CHEM = preload("res://assets/sprites/chem_plant.png")

const CAFE_ANIM_PATH = "res://assets/sprites/cafe_anim.png"
const FACTORY_ANIM_PATH = "res://assets/sprites/factory_anim.png"
const BANK_ANIM_PATH = "res://assets/sprites/bank_anim.png"

const ANIM_FRAMES = 24
const ANIM_SPEED = 6.0

signal country_selected(iso: String)
signal place_requested(iso: String, world_pos: Vector2, inside: bool)  # JUAN3
signal firm_clicked(firm_id: String)  # JUAN3
signal country_firms(iso: String)  # JUAN9: klik na krajinu -> zoznam mojich firiem
signal line_requested(kind: String, a: Vector2, b: Vector2)  # JUAN19
signal hq_clicked(corp_id: String)  # JUAN15
signal city_clicked(iso: String, city_name: String)  # JUAN9: klik na mesto pri priblizeni
const DETAIL_ZOOM = 3.0  # JUAN9: od tohto priblizenia vidno mesta a jednotlive budovy
const CITY_ZOOM = 30.0   # JUAN12: od tohto priblizenia vidno okraj mesta, ulice a bloky
const MAX_ZOOM = 300.0
var _zoom_target = 1.0
var _zoom_anchor = Vector2.ZERO
var _city_geo: Dictionary = {}  # cache obrysu mesta
var _icons: Dictionary = {}
var _marker_isos: Dictionary = {}
var product_firm := ""  # JUAN21: zobraz kam sa predali vozidla firmy
var atlas: bool = false  # JUAN20: Atlas mapa (len DEV)
var _atlas_layer: Node2D
var _ainfra: Dictionary = {}
var _ainfra_key := -1
var _ainfra_layout: Array = []
var _ainfra_static: Dictionary = {}
var last_draw_ms := 0.0
const AD = preload("res://scripts/ui/atlas_draw.gd")
var infra: bool = false  # JUAN10: dialnice, letiska, pristavy, namorne trasy
var _infra_cache: Dictionary = {}
var place_mode: bool = false  # JUAN3: dalsi klik vyberie miesto na stavbu
var place_iso: String = ""
var place_industry: String = ""  # JUAN4: pre zvyraznenie platnych miest
var overlay: bool = false  # JUAN4: teren + suroviny

var zoom = 1.0
var pan = Vector2.ZERO
var dragging = false
var _drag_moved = 0.0
var _drag_start = Vector2.ZERO
var shapes: Array = []
var hover = ""
var label_font
var anim_time: float = 0.0
var _anim_acc: float = 0.0
var _cafe_anim: Texture2D
var _factory_anim: Texture2D
var _bank_anim: Texture2D
var _traffic_layer: Node2D
var _camera_initialized := false
var _camera_fit := 1.0
var _camera_size := Vector2.ZERO
var _camera_transform := Transform2D.IDENTITY
var _drag_button := MOUSE_BUTTON_NONE

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label_font = load("res://assets/fonts/NotoSans-Regular.ttf")
	if ResourceLoader.exists(CAFE_ANIM_PATH):
		_cafe_anim = load(CAFE_ANIM_PATH)
	if ResourceLoader.exists(FACTORY_ANIM_PATH):
		_factory_anim = load(FACTORY_ANIM_PATH)
	if ResourceLoader.exists(BANK_ANIM_PATH):
		_bank_anim = load(BANK_ANIM_PATH)
	_atlas_layer = preload("res://scripts/ui/atlas_layer.gd").new()
	_atlas_layer.map = self
	add_child(_atlas_layer)
	_traffic_layer = preload("res://scripts/ui/atlas_traffic.gd").new()
	_traffic_layer.map = self
	add_child(_traffic_layer)
	draw.connect(_traffic_layer.queue_redraw)
	_build()
	item_rect_changed.connect(_preserve_camera_layout)
	set_notify_transform(true)
	get_window().focus_exited.connect(_cancel_drag)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
	elif what == NOTIFICATION_TRANSFORM_CHANGED:
		_preserve_camera_layout()

func _initialize_camera_frame() -> void:
	if _camera_initialized or size.x <= 1.0 or size.y <= 1.0:
		return
	_camera_fit = _fit()
	_camera_size = size
	_camera_transform = get_global_transform()
	_camera_initialized = true

# A panel changes both the map rectangle and its canvas position. Preserve
# world -> canvas; resizing reveals more map, without changing zoom or LOD.
func _preserve_camera_layout() -> void:
	if not _camera_initialized or size.x <= 1.0 or size.y <= 1.0:
		return
	var transform = get_global_transform()
	if size == _camera_size and transform == _camera_transform:
		return
	var world_size = Vector2(float(DataLoader.map.get("w", 1440)), float(DataLoader.map.get("h", 720)))
	var old_origin = (_camera_size - world_size * _camera_fit * zoom) * 0.5 + pan
	var into_new = transform.affine_inverse() * _camera_transform
	var desired_origin = into_new * old_origin
	_camera_fit *= _camera_transform.x.length() / maxf(transform.x.length(), 0.0001)
	pan = desired_origin - (size - world_size * _camera_fit * zoom) * 0.5
	_zoom_anchor = into_new * _zoom_anchor
	_drag_start = into_new * _drag_start
	_camera_size = size
	_camera_transform = transform
	queue_redraw()

func _cancel_drag() -> void:
	dragging = false
	_drag_button = MOUSE_BUTTON_NONE

func _process(delta: float) -> void:
	if absf(_zoom_target - zoom) > 0.0005 * zoom:  # JUAN12: plynuly zoom ku kurzoru
		var nz = exp(lerpf(log(zoom), log(_zoom_target), clampf(delta * 14.0, 0.0, 1.0)))
		if absf(nz - _zoom_target) < 0.002 * _zoom_target:
			nz = _zoom_target
		_zoom_at(_zoom_anchor, nz, true)
		queue_redraw()
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		return
	if not _anim_live():
		return
	_anim_acc += delta
	if _anim_acc < 0.1:
		return
	anim_time += _anim_acc
	_anim_acc = 0.0
	queue_redraw()

const GFX = preload("res://scripts/gfx.gd")
func _anim_live() -> bool:
	if atlas: return false # Atlas models are static; traffic redraws its own layer.
	if GFX.low():  # JUAN23: nizka grafika = bez animacii (mapa sa neprekresluje 10x za sekundu)
		return false
	for firm in GameState.firms:
		if bool(firm.get("closed", false)):
			continue
		if _building_anim(str(firm.get("industry", ""))) != null:
			return true
	return false

func _build() -> void:
	shapes.clear()
	var arr: Array = DataLoader.map.get("countries", [])
	for c in arr:
		if typeof(c) != TYPE_DICTIONARY:
			continue
		var polys: Array = []
		var area = 0.0
		var min_p = Vector2(INF, INF)
		var max_p = Vector2(-INF, -INF)
		var main_poly = PackedVector2Array()
		var main_area = -1.0
		for ring in c.get("polys", []):
			var pk = PackedVector2Array()
			for p in ring:
				if typeof(p) != TYPE_ARRAY or p.size() < 2:
					continue
				var point = Vector2(float(p[0]), float(p[1]))
				pk.append(point)
				min_p.x = min(min_p.x, point.x)
				min_p.y = min(min_p.y, point.y)
				max_p.x = max(max_p.x, point.x)
				max_p.y = max(max_p.y, point.y)
			for pk2 in _clean_ring(pk):  # JUAN5: opravene polygony (nove krajiny maju samoprieniky)
				polys.append(pk2)
				var ring_area = _poly_area(pk2)
				area += ring_area
				if ring_area > main_area:
					main_area = ring_area
					main_poly = pk2
		if polys.is_empty():
			continue
		shapes.append({
			"iso": str(c.get("iso2", "")),
			"polys": polys,
			"area": area,
			"bb": Rect2(min_p, max_p - min_p),
			"main_poly": main_poly,
		})
	shapes.sort_custom(func(a, b): return float(a.area) > float(b.area))
	for sh in shapes:  # JUAN23: predpocitana triangulacia krajiny do meshu (pamat za rychlost) - kreslenie bez prepoctu bodov
		sh["mesh"] = _country_mesh(sh.polys)

func _country_mesh(polys: Array) -> ArrayMesh:
	var verts = PackedVector2Array()
	var idx = PackedInt32Array()
	for poly in polys:
		if poly.size() < 3:
			continue
		var tri = Geometry2D.triangulate_polygon(poly)
		if tri.is_empty():
			continue
		var base = verts.size()
		verts.append_array(poly)
		for t in tri:
			idx.append(base + t)
	var m = ArrayMesh.new()
	if idx.is_empty():
		return m
	var a = []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = verts
	a[Mesh.ARRAY_INDEX] = idx
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	return m

# JUAN23: rychle kreslenie krajiny - mesh + hranice vo svetovych suradniciach cez transformaciu (bez GDScript slucky po bodoch)
func _paint_fast(sh: Dictionary, col: Color, view: Rect2, sc: float) -> void:
	var bb: Rect2 = sh.bb
	if not view.intersects(bb.grow(1.0)):
		return
	var iso = str(sh.iso)
	var o = _origin()
	draw_set_transform(o, 0.0, Vector2(sc, sc))
	var m: ArrayMesh = sh.get("mesh")
	var tri_ok = m != null and m.get_surface_count() > 0
	if tri_ok:
		draw_mesh(m, null, Transform2D.IDENTITY, col)
	var inv = 1.0 / maxf(sc, 0.0001)
	var bcol = Color(0.12, 0.1, 0.08, 0.75) if atlas else Color(col.darkened(0.45), 0.9)
	for poly in sh.polys:
		if not tri_ok and poly.size() >= 3:
			draw_colored_polygon(poly, col)
		if poly.size() < 2:
			continue
		draw_polyline(poly, bcol, (1.4 if atlas else 1.6) * inv, false)
		if iso == hover:
			draw_polyline(poly, UiPalette.ACCENT, 2.0 * inv, false)
		if iso == GameState.selected_iso:
			draw_polyline(poly, UiPalette.ACCENT, 3.0 * inv, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if iso == hover or iso == GameState.selected_iso:
		_paint_poly(PackedVector2Array(), col, iso)

func _poly_area(poly: PackedVector2Array) -> float:
	var total = 0.0
	var j = poly.size() - 1
	for i in poly.size():
		total += poly[j].x * poly[i].y - poly[i].x * poly[j].y
		j = i
	return abs(total) * 0.5

func _centroid(poly: PackedVector2Array) -> Vector2:
	if poly.is_empty():
		return Vector2.ZERO
	var sum = Vector2.ZERO
	for point in poly:
		sum += point
	return sum / float(poly.size())

func _fit() -> float:
	if _camera_initialized:
		return _camera_fit
	var mw = float(DataLoader.map.get("w", 1440))
	var mh = float(DataLoader.map.get("h", 720))
	return min(size.x / mw, size.y / mh)

func _origin() -> Vector2:
	var mw = float(DataLoader.map.get("w", 1440))
	var mh = float(DataLoader.map.get("h", 720))
	var fit = _fit() * zoom
	return (size - Vector2(mw, mh) * fit) * 0.5 + pan

func _to_screen(p: Vector2) -> Vector2:
	return _origin() + p * _fit() * zoom

func _to_world(s: Vector2) -> Vector2:
	return (s - _origin()) / max(_fit() * zoom, 0.0001)

static func project(lat: float, lon: float) -> Vector2:
	var w = float(DataLoader.map.get("w", 1440))
	var h = float(DataLoader.map.get("h", 720))
	return Vector2((lon + 180.0) / 360.0 * (w - 1.0), (90.0 - lat) / 180.0 * (h - 1.0))

var _cap_c := {}
func capital_of(iso: String) -> Vector2:  # JUAN23: cache
	if _cap_c.has(iso):
		return _cap_c[iso]
	var r = _capital_of0(iso)
	_cap_c[iso] = r
	return r

func _capital_of0(iso: String) -> Vector2:
	var c: Dictionary = DataLoader.countries.get(iso, {})
	return project(float(c.get("capital_lat", c.get("lat", 0.0))), float(c.get("capital_lon", c.get("lon", 0.0))))

func _site_rows() -> Array:
	if GameState.sites.size() > 0:
		return GameState.sites
	return DataLoader.sites

func sites_for(iso: String) -> Array:
	var out: Array = []
	for site in _site_rows():
		if str(site.get("iso", "")) == iso:
			out.append(site)
	return out

func sites_of_kind(iso: String, kind: String) -> Array:
	var out: Array = []
	for site in sites_for(iso):
		if str(site.get("kind", "")) == kind:
			out.append(site)
	return out

func site_at(p: Vector2, radius: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d = radius
	for site in _site_rows():
		var sp = project(float(site.get("lat", 0.0)), float(site.get("lon", 0.0)))
		var d = sp.distance_to(p)
		if d <= best_d:
			best_d = d
			best = site
	return best

var prof := {}
func _draw() -> void:
	_initialize_camera_frame()
	var t0 = Time.get_ticks_usec()
	if not atlas:
		_draw_water()  # JUAN16: hlbka vody
		_draw_graticule()
		if not GFX.low():  # JUAN23
			_draw_shallows()
	var _tp = Time.get_ticks_usec()
	var _sc = _fit() * zoom
	var _view = Rect2(_to_world(Vector2.ZERO), size / maxf(_sc, 0.0001))
	for sh in shapes:
		var iso = str(sh.iso)
		var col = _color(iso)
		if iso == hover:
			col = col.lightened(0.15)
		_paint_fast(sh, col, _view, _sc)
	prof["polys"] = Time.get_ticks_usec() - _tp; _tp = Time.get_ticks_usec()
	_draw_player_glow()
	prof["glow"] = Time.get_ticks_usec() - _tp; _tp = Time.get_ticks_usec()
	_draw_names()
	prof["names"] = Time.get_ticks_usec() - _tp; _tp = Time.get_ticks_usec()
	_draw_building_icons()
	prof["icons"] = Time.get_ticks_usec() - _tp; _tp = Time.get_ticks_usec()
	_draw_cust_legend()  # JUAN17
	_draw_lines()  # JUAN19
	_draw_products()  # JUAN21
	prof["rest"] = Time.get_ticks_usec() - _tp
	last_draw_ms = float(Time.get_ticks_usec() - t0) / 1000.0

func _draw_graticule() -> void:
	var mw = float(DataLoader.map.get("w", 1440))
	var mh = float(DataLoader.map.get("h", 720))
	var lon = -180.0
	while lon <= 180.0:
		var x = (lon + 180.0) / 360.0 * (mw - 1.0)
		draw_line(_to_screen(Vector2(x, 0.0)), _to_screen(Vector2(x, mh - 1.0)), UiPalette.GRATICULE, 1.0, false)
		lon += 30.0
	var lat = -90.0
	while lat <= 90.0:
		var y = (90.0 - lat) / 180.0 * (mh - 1.0)
		draw_line(_to_screen(Vector2(0.0, y)), _to_screen(Vector2(mw - 1.0, y)), UiPalette.GRATICULE, 1.0, false)
		lat += 30.0

var capitals_drawn: int = 0

var _tsz := {}
func _draw_names() -> void:
	capitals_drawn = 0
	_marker_isos = country_markers() if zoom < DETAIL_ZOOM else {}
	for sh in shapes:
		if (sh.main_poly as PackedVector2Array).is_empty():
			continue
		if zoom < DETAIL_ZOOM and _marker_isos.has(str(sh.iso)):
			continue  # JUAN10: bodka hlavneho mesta by sa prekryvala s ikonkou krajiny
		_draw_capital(str(sh.iso))
	if label_font == null:
		return
	var font_size = 13
	var scale = _fit() * zoom
	var name_a = 1.0
	if atlas:  # JUAN20: nazvy krajin miznu s priblizenim (neprekryvaju infrastrukturu)
		name_a = clampf(1.0 - (zoom - 2.5) / 5.0, 0.0, 1.0)
		font_size = int(clampf(11.0 + zoom * 2.0, 12.0, 20.0))
		if name_a <= 0.02:
			return
	for sh in shapes:
		var iso = str(sh.iso)
		var poly: PackedVector2Array = sh.main_poly
		if poly.is_empty():
			continue
		var meta: Dictionary = DataLoader.countries.get(iso, {})
		var world: Dictionary = GameState.world.get(iso, {})
		var title = str(world.get("name_sk", meta.get("name_sk", iso)))
		var bb: Rect2 = sh.bb
		var tk = title + str(font_size)
		if not _tsz.has(tk):
			_tsz[tk] = label_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var text_size: Vector2 = _tsz[tk]
		if text_size.x > bb.size.x * scale:
			continue
		if not sh.has("cent"):  # JUAN23: tazisko raz
			sh["cent"] = _centroid(poly)
		var pos = _to_screen(sh.cent) - Vector2(text_size.x * 0.5, font_size * 0.35)
		if pos.x > size.x or pos.y > size.y + 20.0 or pos.x + text_size.x < 0.0 or pos.y < -20.0:
			continue
		if atlas:
			title = title.to_upper()
		draw_string_outline(label_font, pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color(UiPalette.OUTLINE, name_a))
		draw_string(label_font, pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(UiPalette.TEXT if not atlas else Color("F2EAD6"), name_a))

func _draw_capital(iso: String) -> void:
	var cap = _to_screen(capital_of(iso))
	if not _vis(cap, 4.0):
		return
	draw_circle(cap, 2.2, Color(0.97, 0.92, 0.8, 0.85))  # JUAN16
	draw_arc(cap, 2.6, 0.0, TAU, 10, Color(0, 0, 0, 0.5), 1.0)
	capitals_drawn += 1

func _anim_frame() -> int:
	return int(anim_time * ANIM_SPEED) % ANIM_FRAMES

func _draw_anim(strip: Texture2D, pos: Vector2, sz: float) -> void:
	var frame = _anim_frame()
	var src = Rect2(float(frame) * 32.0, 0.0, 32.0, 32.0)
	draw_texture_rect_region(strip, Rect2(pos - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)), src)

func _building_icon(kind: String) -> Texture2D:
	match kind:
		"cafe": return CAFE
		"factory": return FACTORY
		"bank": return BANK
		"arms_plant", "arms": return ARMS
		"chem_plant", "chemicals": return CHEM
	return null

func _building_anim(kind: String) -> Texture2D:
	match kind:
		"cafe": return _cafe_anim
		"factory": return _factory_anim
		"bank": return _bank_anim
	return null

# JUAN3: poloha ikony vo svetovych suradniciach (ulozena pozicia alebo pri hlavnom meste)
func firm_world_pos(firm: Dictionary) -> Vector2:
	var p = firm.get("pos", null)
	if typeof(p) == TYPE_ARRAY and p.size() >= 2:
		return Vector2(float(p[0]), float(p[1]))
	return Transport.default_pos(firm, capital_of(str(firm.get("country", ""))))  # JUAN19: spirala okolo hlavneho mesta

func _icon_kind(industry: String) -> String:
	if industry in ["cafe", "arms_plant", "chem_plant", "bank"]:
		return industry
	return "factory"

# JUAN9: ikonka pre kazdy typ firmy (assets/icons/<typ>.png)
func type_icon(ind: String) -> Texture2D:
	if not _icons.has(ind):
		var p = "res://assets/icons/%s.png" % ind
		_icons[ind] = preload("res://scripts/ui/tex_util.gd").load_tex(p) if FileAccess.file_exists(p) else null
	return _icons[ind]

var _ms_f := -1
var _ms_revision := -1
var _ms_c: Array = []
func _my_sites() -> Array:  # JUAN23: raz za snimok
	var fr = Engine.get_process_frames()
	if fr == _ms_f and _ms_revision == GameState.state_revision:
		return _ms_c
	_ms_c = _my_sites0()
	_ms_f = fr
	_ms_revision = GameState.state_revision
	return _ms_c

func _my_sites0() -> Array:
	var out: Array = []
	for firm in GameState.player_firms():
		if not bool(firm.get("closed", false)):
			out.append({"id": str(firm.id), "ind": str(firm.get("industry", "")), "iso": str(firm.get("country", "")), "wp": firm_world_pos(firm), "name": str(firm.get("name", ""))})
	for cid in Empire.st().hq.keys():  # JUAN10: centraly korporacii
		var h = Empire.hq(str(cid))
		var hp: Array = h.get("pos", [])
		if hp.size() >= 2:
			out.append({"id": "hq:" + str(cid), "ind": "hq", "iso": str(h.iso), "wp": Vector2(float(hp[0]), float(hp[1])), "name": "HQ"})
	for bank in BankingSystem.player_banks():
		out.append({"id": str(bank.id), "ind": "bank", "iso": str(bank.get("country", "")), "wp": bank_world_pos(bank), "name": str(bank.get("name", ""))})
	return out

func country_markers() -> Dictionary:
	var agg: Dictionary = {}
	for s in _my_sites():
		var a: Dictionary = agg.get(s.iso, {"n": 0, "types": {}})
		a.n += 1
		a.types[s.ind] = int(a.types.get(s.ind, 0)) + 1
		agg[s.iso] = a
	return agg

func country_marker_at(sp: Vector2) -> String:
	if zoom >= DETAIL_ZOOM:
		return ""
	for iso in country_markers().keys():
		if _to_screen(capital_of(iso)).distance_to(sp) <= 12.0:
			return str(iso)
	return ""

func city_at_screen(sp: Vector2) -> Dictionary:
	if zoom < DETAIL_ZOOM:
		return {}
	var wp = _to_world(sp)
	var iso = region_at_world(wp)
	if iso == "":
		return {}
	var c = TerrainSystem.urban_at(iso, wp)
	return {} if c.is_empty() else {"iso": iso, "name": str(c.name)}

func _is_coastal(c: Dictionary) -> bool:
	for k in 8:
		var a = TAU * float(k) / 8.0
		if region_at_world(c.pos + Vector2(cos(a), sin(a)) * (float(c.r) + 1.2)) == "":
			return true
	return false

func infra_data() -> Dictionary:
	if not _infra_cache.is_empty():
		return _infra_cache
	var roads: Array = []
	var ports: Array = []
	var airports: Array = []
	for iso in DataLoader.country_ids:
		var cs: Array = TerrainSystem.cities(str(iso)).duplicate()
		cs.sort_custom(func(a, b): return float(a.pop) > float(b.pop))
		cs = cs.slice(0, 6)
		for i in range(1, cs.size()):
			var best = cs[0]
			var bd = 1e9
			for j in i:
				var dd = (cs[i].pos as Vector2).distance_to(cs[j].pos)
				if dd < bd:
					bd = dd
					best = cs[j]
			if bd < 40.0:
				roads.append([cs[i].pos, best.pos])
		for c in cs:
			if float(c.pop) >= 1500000.0:
				airports.append(c.pos)
			if float(c.pop) >= 400000.0 and _is_coastal(c):
				ports.append(c.pos)
	var lanes: Array = []
	for i in ports.size():
		var near: Array = []
		for j in ports.size():
			if i != j:
				near.append([(ports[i] as Vector2).distance_to(ports[j]), j])
		near.sort_custom(func(a, b): return a[0] < b[0])
		for k in mini(2, near.size()):
			if near[k][0] > 8.0 and near[k][0] < 120.0 and int(near[k][1]) > i:
				lanes.append([ports[i], ports[int(near[k][1])]])
	_infra_cache = {"roads": roads, "ports": ports, "airports": airports, "lanes": lanes}
	return _infra_cache

func _draw_infra() -> void:
	var d = infra_data()
	for l in d.lanes:
		var a = _to_screen(l[0])
		var b = _to_screen(l[1])
		var n = maxi(2, int(a.distance_to(b) / 8.0))
		for i in range(0, n, 2):
			draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), Color(0.35, 0.65, 1.0, 0.7), 1.0)
	for r in d.roads:
		draw_line(_to_screen(r[0]), _to_screen(r[1]), Color(0.85, 0.8, 0.6, 0.75), 2.0 if zoom >= DETAIL_ZOOM else 1.0)
	var pi = type_icon("port")
	var ai = type_icon("airport")
	var s = 10.0 if zoom < DETAIL_ZOOM else 14.0
	for p in d.ports:
		if pi:
			draw_texture_rect(pi, Rect2(_to_screen(p) + Vector2(2, 2), Vector2(s, s)), false)
	for p2 in d.airports:
		if ai:
			draw_texture_rect(ai, Rect2(_to_screen(p2) + Vector2(-s - 2, 2), Vector2(s, s)), false)

# JUAN12: obrys mesta (velkost podla obyvatelov) + ulice a bloky, deterministicky podla mena
func city_outline(c: Dictionary) -> PackedVector2Array:
	var key = str(c.iso) + "|" + str(c.name)
	if _city_geo.has(key):
		return _city_geo[key]
	var r = RandomNumberGenerator.new()
	r.seed = absi(key.hash())
	var base = urban_radius(c)
	var pts = PackedVector2Array()
	var n = 28
	var ph = r.randf() * TAU
	for i in n:
		var a = TAU * float(i) / n
		var k = 1.05 + 0.1 * sin(a * 3.0 + ph) + 0.05 * sin(a * 5.0 + ph * 2.0) + (r.randf() - 0.5) * 0.06
		pts.append(c.pos + Vector2(cos(a), sin(a)) * base * k)
	_city_geo[key] = pts
	return pts

func urban_radius(c: Dictionary) -> float:
	# zastavana plocha: ~ odmocnina z obyvatelov (1 mil. ~ 0.55 jednotky mapy ~ 15 km)
	return float(c.r) * 0.8  # zhodne s oblastou mesta pre stavanie (TerrainSystem.urban_at)

func _draw_city_detail_old(c: Dictionary, sc: float) -> void:
	var ol = city_outline(c)
	var spts = PackedVector2Array()
	for p in ol:
		spts.append(_to_screen(p))
	var tri = Geometry2D.triangulate_polygon(spts)
	if tri.size() >= 3:
		draw_colored_polygon(spts, Color(0.55, 0.52, 0.48, 0.55))
	spts.append(spts[0])
	draw_polyline(spts, Color(UiPalette.ACCENT, 0.95), 2.0)
	# ulice: mriezka otocena podla mesta, orezana na obrys
	var key = str(c.iso) + "|" + str(c.name)
	var ang = float(absi(key.hash()) % 90) * PI / 180.0
	var ux = Vector2(cos(ang), sin(ang))
	var uy = Vector2(-ux.y, ux.x)
	var R = urban_radius(c) * 1.35
	var step = 0.05 if zoom >= 100.0 else 0.4  # blizko bloky (~1,4 km), dalej len hlavne triedy
	var n = int(R / step)
	var vis = Rect2(Vector2.ZERO, size).grow(20)
	var col_s = Color(0.92, 0.9, 0.85, 0.55)
	var col_m = Color(1.0, 0.85, 0.5, 0.85)
	for axis in 2:
		var u = ux if axis == 0 else uy
		var v = uy if axis == 0 else ux
		for i in range(-n, n + 1):
			var o = c.pos + u * (float(i) * step)
			var a = _to_screen(o - v * R)
			var b = _to_screen(o + v * R)
			var seg = Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([a, b]), spts)
			for sg in seg:
				var s2: PackedVector2Array = sg
				if s2.size() >= 2 and vis.intersects(Rect2(s2[0], Vector2.ZERO).expand(s2[s2.size() - 1])):
					var main = i % 5 == 0 or step > 0.1
					draw_polyline(s2, col_m if main else col_s, 3.0 if main else 1.0)
	if label_font and zoom >= CITY_ZOOM * 2.0:
		draw_string(label_font, _to_screen(c.pos) + Vector2(-20, -8), "centrum", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UiPalette.TEXT_DIM)

func icon_px() -> float:
	return clampf(4.0 * zoom, 12.0, 28.0) if zoom < CITY_ZOOM else clampf(zoom * 0.15, 20.0, 40.0)

func zoom_level_name() -> String:
	if zoom < DETAIL_ZOOM:
		return "krajiny"
	if zoom < CITY_ZOOM:
		return "regióny a mestá"
	return "detail mesta"

func _draw_building_icons() -> void:
	var sc = _fit() * zoom
	if infra:
		_draw_infra()
	if zoom < DETAIL_ZOOM:
		# daleko: jedna malá ikonka na krajinu + pocet
		var agg = _marker_isos
		for iso in agg.keys():
			var a: Dictionary = agg[iso]
			var best = ""
			for t in a.types.keys():
				if best == "" or int(a.types[t]) > int(a.types[best]):
					best = str(t)
			var sp = _to_screen(capital_of(iso))
			var tex = type_icon(best)
			if tex:
				draw_texture_rect(tex, Rect2(sp - Vector2(8, 8), Vector2(16, 16)), false)
			draw_rect(Rect2(sp - Vector2(9, 9), Vector2(18, 18)), UiPalette.ACCENT, false, 1.0)
			if label_font:
				var t2 = str(a.n)
				draw_circle(sp + Vector2(9, -9), 6.0, UiPalette.ACCENT)
				draw_string(label_font, sp + Vector2(6 - (3 if a.n > 9 else 0), -5), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.BLACK)
	if atlas and zoom >= DETAIL_ZOOM:
		_draw_atlas_near(sc)
	elif zoom >= DETAIL_ZOOM:
		# blizko: mesta (kruhy + nazvy) a jednotlive budovy s ikonou typu
		if _allc.is_empty():
			_allc = _all_cities(0.0)
		for _one in [0]:
			for c in _visible_items("allc", _allc, false, 300.0):
				var cp = _to_screen(c.pos)
				var rr = maxf(3.0, float(c.r) * sc)
				if cp.x < -rr - 40 or cp.y < -rr - 40 or cp.x > size.x + rr + 40 or cp.y > size.y + rr + 40:
					continue
				if zoom >= CITY_ZOOM:
					_draw_city_detail(c, sc)
				else:
					draw_circle(cp, rr, Color(0.86, 0.82, 0.72, 0.10))  # JUAN16: mesto ako zastavana plocha
					draw_circle(cp, maxf(1.5, rr * 0.3), Color(0.95, 0.9, 0.78, 0.35))
					draw_arc(cp, rr, 0.0, TAU, 24, Color(1, 1, 1, 0.16), 1.0, true)
				if label_font and (float(c.pop) > 300000.0 or zoom >= 12.0):
					draw_string_outline(label_font, cp + Vector2(4, -4), str(c.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, UiPalette.OUTLINE)
					draw_string(label_font, cp + Vector2(4, -4), str(c.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UiPalette.TEXT)
		var isz = icon_px()
		for s in _my_sites():
			var p2 = _to_screen(s.wp)
			if not _vis(p2, isz * 2.0 + 5.0):
				continue
			var tex2 = type_icon(str(s.ind))
			draw_circle(p2, isz * 0.95, Color(UiPalette.ACCENT, 0.18))  # JUAN16: zvyraznenie tvojich budov
			draw_circle(p2 + Vector2(2, 3), isz * 0.62, Color(0, 0, 0, 0.35))
			draw_rect(Rect2(p2 - Vector2(isz, isz) * 0.62, Vector2(isz, isz) * 1.24), UiPalette.BG_0)
			if tex2:
				draw_texture_rect(tex2, Rect2(p2 - Vector2(isz, isz) * 0.5, Vector2(isz, isz)), false)
			draw_rect(Rect2(p2 - Vector2(isz, isz) * 0.62, Vector2(isz, isz) * 1.24), UiPalette.ACCENT, false, 2.0)
			_logo_badge(s, p2, isz)
	_draw_juan4_overlay()
	if place_mode:
		var mp0 = get_local_mouse_position()
		var t3 = type_icon(place_industry)
		if t3:
			draw_texture_rect(t3, Rect2(mp0 - Vector2(10, 10), Vector2(20, 20)), false, Color(1, 1, 1, 0.8))
		else:
			draw_circle(mp0, 6.0, UiPalette.ACCENT)

func _draw_building_icons_old() -> void:
	for firm in GameState.firms:
		if bool(firm.get("closed", false)):
			continue
		var industry = str(firm.get("industry", ""))
		if str(firm.get("owner", "")) == "player":
			industry = _icon_kind(industry)
		var icon = _building_icon(industry)
		if icon == null:
			continue
		_draw_icon_at(_to_screen(firm_world_pos(firm)), industry, icon, str(firm.get("owner", "")) == "player")
	for bank in GameState.banks:
		if str(bank.get("owner", "")) != "player" or bool(bank.get("failed", false)):
			continue
		var bp = bank.get("pos", null)
		var wp = capital_of(str(bank.get("country", ""))) + Vector2(-12.0, 6.0)
		if typeof(bp) == TYPE_ARRAY and bp.size() >= 2:
			wp = Vector2(float(bp[0]), float(bp[1]))
		_draw_icon_at(_to_screen(wp), "bank", BANK, true)
	_draw_juan4_overlay()
	if place_mode:
		var mp = get_local_mouse_position()
		draw_circle(mp, 6.0, UiPalette.ACCENT)

func _draw_icon_at(screen_pos: Vector2, kind: String, icon: Texture2D, mine: bool) -> void:
	var icon_sz = 14.0 * zoom
	if mine:
		draw_rect(Rect2(screen_pos - Vector2(icon_sz * 0.6, icon_sz * 0.6), Vector2(icon_sz * 1.2, icon_sz * 1.2)), UiPalette.ACCENT, false, 1.0)
	var anim = _building_anim(kind)
	if anim != null:
		_draw_anim(anim, screen_pos, icon_sz)
	else:
		draw_texture_rect(icon, Rect2(screen_pos - Vector2(icon_sz * 0.5, icon_sz * 0.5), Vector2(icon_sz, icon_sz)), false)

# JUAN3: hracova firma pod kurzorom (screen suradnice), "" ak ziadna
func firm_at_screen(sp: Vector2) -> String:
	var best = ""
	var best_d = icon_px() * 0.6 + 2.0  # JUAN14: len skutocny polomer ikonky, nie "najblizsia firma"
	for cid in Empire.st().hq.keys():  # JUAN15: centrala ma prednost (klik -> Portfolio)
		var hp: Array = Empire.st().hq[cid].get("pos", [])
		if hp.size() == 2 and _to_screen(Vector2(float(hp[0]), float(hp[1]))).distance_to(sp) <= best_d:
			return "hq:" + str(cid)
	for firm in GameState.player_firms():
		var d = _to_screen(firm_world_pos(firm)).distance_to(sp)
		if d <= best_d:
			best_d = d
			best = str(firm.get("id", ""))
	# JUAN4: aj hracova banka
	for bank in GameState.banks:
		if str(bank.get("owner", "")) != "player" or bool(bank.get("failed", false)):
			continue
		var d2 = _to_screen(bank_world_pos(bank)).distance_to(sp)
		if d2 <= best_d:
			best_d = d2
			best = str(bank.get("id", ""))
	return best

func bank_world_pos(bank: Dictionary) -> Vector2:
	var bp = bank.get("pos", null)
	if typeof(bp) == TYPE_ARRAY and bp.size() >= 2:
		return Vector2(float(bp[0]), float(bp[1]))
	return capital_of(str(bank.get("country", ""))) + Vector2(-12.0, 6.0)

func start_place(iso: String) -> void:
	place_mode = true
	place_iso = iso
	queue_redraw()

func cancel_place() -> void:
	place_mode = false
	place_industry = ""
	place_iso = ""
	queue_redraw()

# JUAN3: klik v rezime stavby (volane aj z testov)
func click_place(screen_pos: Vector2) -> void:
	var wp = _to_world(screen_pos)
	var iso = place_iso
	var inside = iso != "" and regions_containing(wp).has(iso)
	place_requested.emit(iso, wp, inside)
	if inside:
		cancel_place()

# JUAN5: odstrani duplicitne body; ak sa polygon neda triangulovat (samoprienik), rozlozi ho cez Clipper
func _clean_ring(pk: PackedVector2Array) -> Array:
	if pk.size() >= 3 and not Geometry2D.triangulate_polygon(pk).is_empty():
		return [pk]
	var out = PackedVector2Array()
	for pt in pk:
		if out.is_empty() or out[out.size() - 1].distance_squared_to(pt) > 1e-6:
			out.append(pt)
	if out.size() > 1 and out[0].distance_squared_to(out[out.size() - 1]) <= 1e-6:
		out.remove_at(out.size() - 1)
	if out.size() < 3:
		return []
	if not Geometry2D.triangulate_polygon(out).is_empty():
		return [out]
	var res: Array = []
	for q in Geometry2D.merge_polygons(out, PackedVector2Array()):
		if q.size() >= 3 and not Geometry2D.triangulate_polygon(q).is_empty():
			res.append(q)
	return res

func _paint_poly(poly: PackedVector2Array, col: Color, iso: String) -> void:
	var screen_poly = PackedVector2Array()
	for p2 in poly:
		screen_poly.append(_to_screen(p2))
	if screen_poly.size() >= 3:
		draw_colored_polygon(screen_poly, col)
	if screen_poly.size() >= 2:
		if atlas:
			draw_polyline(screen_poly, Color(0.12, 0.1, 0.08, 0.75), 1.4, true)
		else:
			draw_polyline(screen_poly, Color(col.darkened(0.45), 0.9), 1.6, true)  # JUAN16: jemnejsie hranice
		draw_polyline(screen_poly, Color(1, 1, 1, 0.07), 1.0, true)
		if iso == hover:
			draw_polyline(screen_poly, UiPalette.ACCENT, 2.0, false)
		if iso == GameState.selected_iso:
			draw_polyline(screen_poly, UiPalette.ACCENT, 3.0, false)
	if iso == hover or iso == GameState.selected_iso:
		for site in sites_for(iso):
			var ss = _to_screen(project(float(site.get("lat", 0.0)), float(site.get("lon", 0.0))))
			var mark = UiPalette.TEXT_DIM
			if bool(site.get("damaged", false)):
				mark = UiPalette.BAD
			elif str(site.get("kind", "")) == "port":
				mark = UiPalette.BORDER_HI
			elif str(site.get("kind", "")) == "energy":
				mark = UiPalette.WARN
			elif str(site.get("kind", "")) == "road":
				mark = UiPalette.TEXT_DIM
			draw_rect(Rect2(ss - Vector2(2, 2), Vector2(4, 4)), mark)

func _color(iso: String) -> Color:
	var c: Dictionary = GameState.world.get(iso, DataLoader.countries.get(iso, {}))
	var pc = float(c.get("gdp_pc_usd", 8000.0))
	var t = EconMath.cl(log(max(pc, 400.0)) / log(80000.0), 0.0, 1.0)
	var col = _terrain_tint(iso, t)  # JUAN16: terenna paleta + jemny politicky odtien
	if atlas:  # JUAN20: priesvitna politicka vrstva nad zapecenym terenom
		if cust_mode:
			return Color(cust_color(iso), 0.62)
		var pc2 = Color.from_hsv(float(absi(iso.hash()) % 360) / 360.0, 0.5, 0.9, lerpf(0.30, 0.12, clampf((zoom - 1.0) / 8.0, 0.0, 1.0)))
		if GameState.running and GeopoliticsSystem.at_war(iso):
			pc2 = Color(UiPalette.BAD, 0.4)
		return pc2
	if cust_mode:
		return cust_color(iso)
	if GameState.running and GeopoliticsSystem.at_war(iso):
		col = col.lerp(UiPalette.BAD, 0.35)
	return col

func _hover_tip(iso: String) -> void:
	if iso == "":
		tooltip_text = ""
		return
	var meta: Dictionary = DataLoader.countries.get(iso, {})
	var world: Dictionary = GameState.world.get(iso, {})
	var title = str(world.get("name_sk", meta.get("name_sk", iso)))
	var gdp = float(world.get("gdp_pc_usd", meta.get("gdp_pc_usd", 0.0)))
	var war = "vojna" if GameState.running and GeopoliticsSystem.at_war(iso) else "mier"
	tooltip_text = "%s\nHDP/obyv. %.0f USD\n%s" % [title, gdp, war]
	if cust_mode:
		tooltip_text += "\n" + cust_tip(iso)

func _click_at(sp: Vector2) -> void:
	# JUAN14: jedno miesto pre vyhodnotenie kliku (aj pre testy)
	if line_mode != "":  # JUAN19: stavba trate - 1. klik zaciatok, 2. klik koniec
		if not _line_has_a:
			_line_a = _to_world(sp)
			_line_has_a = true
		else:
			var k = line_mode
			line_mode = ""
			_line_has_a = false
			line_requested.emit(k, _line_a, _to_world(sp))
		queue_redraw()
	elif place_mode:
		click_place(sp)
	elif country_marker_at(sp) != "":
		GameState.selected_iso = country_marker_at(sp)
		country_selected.emit(GameState.selected_iso)
		country_firms.emit(GameState.selected_iso)
	elif zoom >= DETAIL_ZOOM and firm_at_screen(sp).begins_with("hq:"):
		hq_clicked.emit(firm_at_screen(sp).substr(3))
	elif zoom >= DETAIL_ZOOM and firm_at_screen(sp) != "":
		firm_clicked.emit(firm_at_screen(sp))
	else:
		var iso = _pick(sp)
		var cty = (city_at_screen(sp) if zoom >= 12.0 else {})
		if iso != "":
			GameState.selected_iso = iso
			_hover_tip(iso)
			country_selected.emit(iso)
			if not cty.is_empty():
				city_clicked.emit(str(cty.iso), str(cty.name))
			else:
				country_firms.emit(iso)


func _zoom_at(mouse: Vector2, new_zoom: float, smooth: bool = false) -> void:
	new_zoom = clampf(new_zoom, 1.0, MAX_ZOOM)
	if not smooth:
		_zoom_target = new_zoom
		_zoom_anchor = mouse
	# JUAN-FIX: zoom k bodu pod kurzorom (berie do úvahy pan)
	var fz_old = max(_fit() * zoom, 0.0001)
	var w = (mouse - _origin()) / fz_old
	zoom = new_zoom
	var after = _origin() + w * _fit() * zoom
	pan += mouse - after

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_target = minf(MAX_ZOOM, maxf(_zoom_target, zoom) * 1.25)
			_zoom_anchor = mb.position
			queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_target = maxf(1.0, minf(_zoom_target, zoom) / 1.25)
			_zoom_anchor = mb.position
			queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				dragging = true
				_drag_button = MOUSE_BUTTON_LEFT
				_drag_moved = 0.0
				_drag_start = mb.position
			elif _drag_button == MOUSE_BUTTON_LEFT:
				_cancel_drag()
				if _drag_moved < 6.0:
					_click_at(mb.position)
				queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				dragging = true
				_drag_button = MOUSE_BUTTON_RIGHT
			elif _drag_button == MOUSE_BUTTON_RIGHT:
				_cancel_drag()
			queue_redraw()
	elif event is InputEventPanGesture:
		pan -= (event as InputEventPanGesture).delta * 20.0
		queue_redraw()
	elif event is InputEventMouseMotion:
		if dragging:
			var rel = (event as InputEventMouseMotion).relative
			pan += rel
			_drag_moved += rel.length()
		var hv = _pick((event as InputEventMouseMotion).position)
		if hv != hover or dragging or place_mode:
			hover = hv
			_hover_tip(hover)
			queue_redraw()

func region_at_world(p: Vector2) -> String:
	var hits = regions_containing(p)
	if hits.is_empty():
		return ""
	return str(hits[hits.size() - 1])

func regions_containing(p: Vector2) -> Array:
	var ids: Array = []
	for sh in shapes:
		var bb: Rect2 = sh.bb
		if not bb.has_point(p):
			continue
		for poly in sh.polys:
			if Geometry2D.is_point_in_polygon(p, poly):
				ids.append(str(sh.iso))
				break
	return ids

func _pick(screen_pos: Vector2) -> String:
	return region_at_world(_to_world(screen_pos))

# JUAN4: prekrytie terenu (vybrana krajina), nalezisk, mestskych zon; v rezime stavby zvyrazni platne miesta
func _draw_juan4_overlay() -> void:
	var sc = _fit() * zoom
	if overlay:
		var iso = GameState.selected_iso
		var box = Rect2()
		var first = true
		for pk in TerrainSystem.polys(iso):
			for p in pk:
				box = Rect2(p, Vector2.ZERO) if first else box.expand(p)
				first = false
		var vis = Rect2(_to_world(Vector2.ZERO), Vector2.ZERO).expand(_to_world(size))
		box = box.intersection(vis) if not first else box
		var step = max(1.0, 5.0 / max(sc, 0.01))
		while not first and (box.size.x / step) * (box.size.y / step) > 12000.0:
			step *= 1.5
		var y = box.position.y
		while y <= box.end.y and not first:
			var x = box.position.x
			while x <= box.end.x:
				var wp = Vector2(x, y)
				if TerrainSystem.inside(iso, wp):
					var col: Color = TerrainSystem.TERRAIN_COLORS[TerrainSystem.terrain_at(wp, iso)]
					col.a = 0.55
					draw_rect(Rect2(_to_screen(wp), Vector2(step * sc, step * sc)), col)
				x += step
			y += step
		for iso2 in DataLoader.country_ids:
			for d in TerrainSystem.deposits(str(iso2)):
				var spd = _to_screen(d.pos)
				var r = max(3.0, float(d.r) * sc)
				draw_circle(spd, r, TerrainSystem.RES_COLORS[d.res])
				draw_arc(spd, r, 0.0, TAU, 12, UiPalette.TEXT, 1.0)
			for c in TerrainSystem.cities(str(iso2)):
				draw_arc(_to_screen(c.pos), max(3.0, float(c.r) * sc), 0.0, TAU, 16, UiPalette.ACCENT, 1.5)
		if label_font and zoom >= 2.0:
			for d2 in TerrainSystem.deposits(iso):
				draw_string(label_font, _to_screen(d2.pos) + Vector2(6, 4), str(TerrainSystem.RES_NAMES[d2.res]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UiPalette.TEXT)
	if place_mode and place_industry != "":
		var pulse = 0.5 + 0.5 * sin(anim_time * 4.0)
		for spot in TerrainSystem.valid_spots(place_industry, place_iso):
			var r2 = max(5.0, float(spot.r) * sc)
			draw_circle(_to_screen(spot.pos), r2, Color(UiPalette.ACCENT, 0.25 + 0.2 * pulse))
			draw_arc(_to_screen(spot.pos), r2, 0.0, TAU, 16, UiPalette.ACCENT, 2.0)


# ===================== JUAN16: krajsia mapa =====================
const WATER_DEEP = Color("0E1A28")
const WATER_SHALLOW = Color("2C5168")
var _tint_cache: Dictionary = {}
var _city_cells: Dictionary = {}

func _draw_water() -> void:
	# vertikalny gradient hlbky (tmavsie k polom) - 2 polygony s farbami vrcholov
	var top = WATER_DEEP
	var mid = Color("16293B")
	var w = size.x
	var h = size.y
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.5), Vector2(0, h * 0.5)]), PackedColorArray([top, top, mid, mid]))
	draw_polygon(PackedVector2Array([Vector2(0, h * 0.5), Vector2(w, h * 0.5), Vector2(w, h), Vector2(0, h)]), PackedColorArray([mid, mid, top, top]))

func _draw_shallows() -> void:
	# pobrezne plytciny: siroke polopriehladne obrysy pod pevninou
	# JUAN23: kreslene vo svetovych suradniciach cez transformaciu + orezanie podla predpocitaneho bb (bez slucky po bodoch)
	var wd = clampf(3.0 * sqrt(zoom), 3.0, 22.0)
	var sc = _fit() * zoom
	var inv = 1.0 / maxf(sc, 0.0001)
	var view = Rect2(_to_world(Vector2.ZERO), size * inv).grow(wd * 2.0 * inv)
	draw_set_transform(_origin(), 0.0, Vector2(sc, sc))
	var c1 = Color(WATER_SHALLOW, 0.3)
	var c2 = Color("9EC9D9", 0.25)
	for sh in shapes:
		if not view.intersects(sh.bb):
			continue
		if not sh.has("closed"):
			var cl: Array = []
			for poly in sh.polys:
				if poly.size() >= 3:
					var c = poly.duplicate()
					c.append(poly[0])
					cl.append(c)
			sh["closed"] = cl
		for sp in sh.closed:
			draw_polyline(sp, c1, wd * inv, false)
			draw_polyline(sp, c2, 1.2 * inv, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _terrain_tint(iso: String, t: float) -> Color:
	if _tint_cache.has(iso):
		return _tint_cache[iso]
	var lat = 45.0
	for sh in shapes:
		if str(sh.iso) == iso and not (sh.main_poly as PackedVector2Array).is_empty():
			var mh = float(DataLoader.map.get("h", 720))
			lat = absf(90.0 - _centroid(sh.main_poly).y / maxf(mh - 1.0, 1.0) * 180.0)
			break
	var base: Color
	if lat < 12.0:
		base = Color("3F6B3A")  # trópy
	elif lat < 33.0:
		base = Color("9B8A5A").lerp(Color("5E7A45"), clampf((lat - 12.0) / 21.0 * 0.4 + (0.3 if iso.hash() % 3 == 0 else 0.0), 0.0, 1.0))  # púšte/savany
	elif lat < 55.0:
		base = Color("5F7F4A")  # mierne pásmo
	else:
		base = Color("7C8670")  # tundra/tajga
	var hue = float(absi(iso.hash()) % 360) / 360.0
	var pol = Color.from_hsv(hue, 0.45, 0.62)
	var col = base.lerp(pol, 0.32).lightened(lerpf(-0.06, 0.06, t))
	_tint_cache[iso] = col
	return col

func _player_isos() -> Dictionary:
	var out = {}
	if not GameState.running:
		return out
	for f in GameState.player_firms():
		out[str(f.get("country", ""))] = true
	for iso in Empire.st().states:
		out[str(iso)] = true
	return out

func _draw_player_glow() -> void:
	var mine = _player_isos()
	if mine.is_empty():
		return
	var inv = 1.0 / maxf(_fit() * zoom, 0.0001)
	var view = Rect2(_to_world(Vector2.ZERO), size * inv).grow(8.0 * inv)
	for sh in shapes:
		if not mine.has(str(sh.iso)):
			continue
		if not view.intersects(sh.bb):
			continue
		for poly in sh.polys:
			var sp = PackedVector2Array()
			for p in poly:
				sp.append(_to_screen(p))
			if sp.size() < 3:
				continue
			sp.append(sp[0])
			draw_polyline(sp, Color(UiPalette.ACCENT, 0.12), 7.0, true)
			draw_polyline(sp, Color(UiPalette.ACCENT, 0.25), 3.5, true)
			draw_polyline(sp, Color(UiPalette.ACCENT, 0.75), 1.2, true)

# --- mesto zhora (procedurálne, ziadne realne snimky) ---
const ROOFS = [Color("8E4A3A"), Color("A65A42"), Color("6E6E72"), Color("85878C"), Color("C9C4B8"), Color("4F5257"), Color("9B7B5B"), Color("B7B0A3")]
const FIELDS = [Color("6E8B3D"), Color("8FA350"), Color("B8A85E"), Color("5C7A3A"), Color("A39A5A")]

func _cells_for(c: Dictionary, lod: int) -> Array:
	var key = "%s|%s|%d" % [str(c.iso), str(c.name), lod]
	if _city_cells.has(key):
		return _city_cells[key]
	var r = RandomNumberGenerator.new()
	r.seed = absi(key.hash())
	var ol = city_outline(c)
	var base = urban_radius(c)
	var ck = str(c.iso) + "|" + str(c.name)
	var ang = float(absi(ck.hash()) % 90) * PI / 180.0
	var ux = Vector2(cos(ang), sin(ang))
	var uy = Vector2(-ux.y, ux.x)
	var step = [0.4, 0.12, 0.05][lod]
	var R = base * 1.7
	var n = int(R / step) + 1
	var has_river = absi(ck.hash()) % 3 != 0
	var rv_off = (r.randf() - 0.5) * base * 0.6
	var out: Array = []
	for i in range(-n, n + 1):
		for j in range(-n, n + 1):
			var p: Vector2 = c.pos + ux * (i * step) + uy * (j * step)
			var dn = p.distance_to(c.pos) / maxf(base, 0.0001)
			if dn > 1.3:
				continue
			var inside = Geometry2D.is_point_in_polygon(p, ol)
			# rieka: pas pozdlz osi uy s miernym meandrom
			var rv = has_river and dn < 1.2 and absf(i * step - rv_off - sin(j * step / base * 3.0) * base * 0.15) < base * 0.06
			var ph = absi(hash(Vector2i(floori(i / 4.0), floori(j / 3.0))) + absi(ck.hash()))
			var fa = clampf((1.3 - dn) / 0.35, 0.0, 1.0) * 0.75
			var cell = {"p": p, "kind": 0, "col": Color(FIELDS[ph % FIELDS.size()].darkened(float(ph % 7) * 0.012), fa), "b": []}
			if rv:
				cell.kind = 3
				cell.col = Color("2E5A73")
			elif inside and r.randf() > clampf((dn - 0.75) * 2.5, 0.0, 0.85):
				if r.randf() < 0.09:
					cell.kind = 2
					cell.col = Color("4C7A3C")
					if lod >= 1:
						for _t in 5:
							cell.b.append([r.randf_range(-0.35, 0.35), r.randf_range(-0.35, 0.35), r.randf_range(0.08, 0.16)])
				else:
					cell.kind = 1
					cell.col = Color("3A3C40")
					var dens = 1 if lod == 0 else (2 if dn > 0.6 else 3)
					var cw = 0.8 / dens
					for a in dens:
						for b in dens:
							if r.randf() < 0.12:
								continue
							var hgt = r.randf_range(0.3, 1.0) * (1.6 - dn)
							cell.b.append([-0.4 + cw * (a + 0.5), -0.4 + cw * (b + 0.5), cw * r.randf_range(0.36, 0.46), cw * r.randf_range(0.36, 0.46), ROOFS[r.randi() % ROOFS.size()].lightened(r.randf_range(-0.08, 0.08)), hgt])
			elif not inside and dn < 1.0 and r.randf() < 0.3:
				cell.col = Color("7A8452", fa)  # predmestie / zahrady
			if int(cell.kind) == 0 and lod == 0:
				continue  # zdaleka bez poli
			out.append(cell)
	var meta = {"ux": ux, "uy": uy, "step": step}
	out.push_front(meta)
	_city_cells[key] = out
	return out

var _city_mesh: Dictionary = {}

func _mesh_for(c: Dictionary, lod: int) -> ArrayMesh:
	var key = "%s|%s|%d" % [str(c.iso), str(c.name), lod]
	if _city_mesh.has(key):
		return _city_mesh[key]
	var cells = _cells_for(c, lod)
	var meta: Dictionary = cells[0]
	var du: Vector2 = meta.ux * float(meta.step)
	var dv: Vector2 = meta.uy * float(meta.step)
	var step = float(meta.step)
	var vt = PackedVector2Array()
	var cl = PackedColorArray()
	var road = 0.08 if lod > 0 else 0.03
	var sh = (meta.ux + meta.uy * 1.4).normalized() * step * 0.12
	var addq = func(q: Array, col: Color):
		for k in [0, 1, 2, 0, 2, 3]:
			vt.append(q[k])
			cl.append(col)
	var wq = func(cc: Vector2, hu: float, hv: float) -> Array:
		return [cc - du * hu - dv * hv, cc + du * hu - dv * hv, cc + du * hu + dv * hv, cc - du * hu + dv * hv]
	for ci in range(1, cells.size()):
		var cell: Dictionary = cells[ci]
		var hs = 0.5 - (road if int(cell.kind) == 1 else 0.0)
		addq.call(wq.call(cell.p, hs, hs), cell.col)
		if int(cell.kind) == 1:
			for b in cell.b:
				var cc = cell.p + du * float(b[0]) + dv * float(b[1])
				addq.call(wq.call(cc + sh * float(b[5]), float(b[2]), float(b[3])), Color(0, 0, 0, 0.35))
				addq.call(wq.call(cc, float(b[2]), float(b[3])), b[4])
				if lod == 2:
					var rc: Color = b[4]
					addq.call(wq.call(cc, float(b[2]), float(b[3]) * 0.12), rc.lightened(0.15))  # hreben strechy
		elif int(cell.kind) == 2:
			for t in cell.b:
				var tc = cell.p + du * float(t[0]) + dv * float(t[1])
				var rr = float(t[2])
				addq.call(wq.call(tc + sh * 0.6, rr, rr), Color(0, 0, 0, 0.22))
				addq.call(wq.call(tc, rr, rr), Color("3E6B30"))
	var m = ArrayMesh.new()
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vt
	arr[Mesh.ARRAY_COLOR] = cl
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_city_mesh[key] = m
	return m

func _draw_city_detail(c: Dictionary, sc: float) -> void:
	var lod = 0 if zoom < 25.0 else (1 if zoom < 100.0 else 2)
	var cells = _cells_for(c, lod)
	var meta: Dictionary = cells[0]
	var ux: Vector2 = meta.ux
	var uy: Vector2 = meta.uy
	var step = float(meta.step)
	draw_set_transform(_origin(), 0.0, Vector2(sc, sc))  # JUAN16: mesh v svetovych suradniciach, cache na mesto+LOD
	draw_mesh(_mesh_for(c, lod), null)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# hlavne tepny (siroke, svetle)
	if lod >= 1:
		var R = urban_radius(c) * 1.1
		var ol = PackedVector2Array()
		for p in city_outline(c):
			ol.append(_to_screen(p))
		var main_step = step * 5.0
		var wmain = clampf(step * sc * 0.18, 2.0, 14.0)
		for axis in 2:
			var u = ux if axis == 0 else uy
			var v = uy if axis == 0 else ux
			var m = int(R / main_step)
			for i in range(-m, m + 1):
				var o = c.pos + u * (i * main_step + step * 0.5)
				var seg = Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([_to_screen(o - v * R), _to_screen(o + v * R)]), ol)
				for sg in seg:
					draw_polyline(sg, Color("5B5E63"), wmain + 2.0)
					draw_polyline(sg, Color("8C8F94"), wmain)
					if lod == 2:
						draw_polyline(sg, Color("E8D9A0", 0.6), 1.0)

func _quad(center: Vector2, du: Vector2, dv: Vector2, ou: float, ov: float, hu: float, hv: float) -> PackedVector2Array:
	var cc = center + du * ou + dv * ov
	return PackedVector2Array([_to_screen(cc - du * hu - dv * hv), _to_screen(cc + du * hu - dv * hv), _to_screen(cc + du * hu + dv * hv), _to_screen(cc - du * hu + dv * hv)])


# ===================== JUAN17: mapovy mod Odberatelia =====================
var cust_mode := false
var _cust_day := -99
var _cust: Dictionary = {}
var _cust_max := 0.0

func cust_data() -> Dictionary:
	if _cust_day != GameState.day_index:
		_cust_day = GameState.day_index
		_cust = Empire.customers_by_iso() if GameState.running else {}
		_cust_max = 0.0
		for v in _cust.values():
			_cust_max = maxf(_cust_max, float(v.eur))
	return _cust

func cust_level(iso: String) -> float:
	# logaritmicka skala: 0 = nic, (0..1] = podiel log(eur) / log(max); minimum 0.08 aby aj maly odberatel nebol cerveny
	var d = cust_data()
	var e = float(d.get(iso, {}).get("eur", 0.0))
	if e <= 0.0 or _cust_max <= 0.0:
		return 0.0
	return clampf(0.08 + 0.92 * log(1.0 + e) / log(1.0 + _cust_max), 0.08, 1.0)

const CUST_STOPS = [[0.0, Color("7A1A16")], [0.08, Color("E0705F")], [0.3, Color("F0A15A")], [0.45, Color("E8D24A")], [0.6, Color("C4DB5E")], [0.75, Color("86C96A")], [0.88, Color("3E9A48")], [1.0, Color("1B5E2A")]]

static func cust_ramp(t: float) -> Color:
	# JUAN17: tmavocervena = nic, svetlocervena -> oranzova -> zlta -> svetlozelena -> tmavozelena = najviac
	if t <= 0.0:
		return CUST_STOPS[0][1]
	for k in range(1, CUST_STOPS.size()):
		var a = CUST_STOPS[k - 1]
		var b = CUST_STOPS[k]
		if t <= float(b[0]):
			if k == 1:
				return b[1]
			return (a[1] as Color).lerp(b[1], (t - float(a[0])) / (float(b[0]) - float(a[0])))
	return CUST_STOPS[CUST_STOPS.size() - 1][1]

func cust_color(iso: String) -> Color:
	var c = cust_ramp(cust_level(iso))
	return c.darkened(0.12) if iso != hover else c

func cust_tip(iso: String) -> String:
	var v: Dictionary = cust_data().get(iso, {})
	if v.is_empty():
		return "Odberatelia: od teba nič nekupuje."
	var gs: Array = v.goods.keys()
	gs.sort_custom(func(a, b): return float(v.goods[a]) > float(v.goods[b]))
	var top = ", ".join(gs.slice(0, 3).map(func(g): return "%s %s" % [g, EconMath.eur(float(v.goods[g]))]))
	return "Nakupuje od teba %s/mes.\nTop: %s" % [EconMath.eur(float(v.eur)), top]

func _cust_eur_at(t: float) -> float:
	# inverz k cust_level
	return exp(clampf((t - 0.08) / 0.92, 0.0, 1.0) * log(1.0 + _cust_max)) - 1.0

func _draw_cust_legend() -> void:
	if not cust_mode or label_font == null:
		return
	cust_data()
	var steps = [0.0, 0.08, 0.3, 0.45, 0.6, 0.75, 0.88, 1.0]
	var bw = 64.0
	var o = Vector2(10, size.y - 58)
	draw_rect(Rect2(o - Vector2(6, 22), Vector2(bw * steps.size() + 12, 58)), Color(0.05, 0.06, 0.08, 0.88))
	draw_string(label_font, o + Vector2(0, -6), "Odberatelia – koľko od teba krajina kupuje (€/mesiac)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiPalette.TEXT)
	for i in steps.size():
		var t = float(steps[i])
		var r = Rect2(o + Vector2(i * bw, 0), Vector2(bw - 3, 14))
		draw_rect(r, cust_ramp(t))
		var lab = "nič" if t <= 0.0 else ("≥" + EconMath.eur(_cust_eur_at(t)))
		draw_string(label_font, o + Vector2(i * bw, 28), lab, HORIZONTAL_ALIGNMENT_LEFT, bw - 3, 10, UiPalette.TEXT_DIM)


# ===================== JUAN19: zeleznice a ropovody =====================
var line_mode := ""
var _line_a := Vector2.ZERO
var _line_has_a := false

func start_line(kind: String) -> void:
	line_mode = kind
	_line_has_a = false
	place_mode = false
	queue_redraw()

func _draw_lines() -> void:
	var w = clampf(1.5 + zoom * 0.25, 2.0, 7.0)
	for l in Transport.lines():
		var a = _to_screen(Transport._pt(l.a))
		var b = _to_screen(Transport._pt(l.b))
		var clipped = preload("res://scripts/ui/atlas_traffic.gd").clipped(a, b, Rect2(Vector2.ZERO, size).grow(20))
		if clipped.is_empty(): continue
		var detail_a = clipped[0]
		var detail_b = clipped[1]
		var u = Transport.utilization(l)
		if str(l.kind) == "rail":
			draw_line(a, b, Color(0.08, 0.08, 0.09), w + 2.0, true)
			draw_line(a, b, Color(0.55, 0.55, 0.58), w * 0.5, true)
			var n = mini(256, int(detail_a.distance_to(detail_b) / maxf(6.0, w * 2.2)))
			var dir = (b - a).normalized()
			var nrm = Vector2(-dir.y, dir.x) * (w * 0.9)
			for i in n:
				var p = detail_a.lerp(detail_b, (i + 0.5) / maxf(n, 1))
				draw_line(p - nrm, p + nrm, Color(0.32, 0.24, 0.16), 1.5)
		else:
			draw_line(a, b, Color(0.12, 0.08, 0.04), w + 3.0, true)
			draw_line(a, b, Color(0.78, 0.5, 0.18), w, true)
			var m = mini(128, int(detail_a.distance_to(detail_b) / 26.0))
			for i in range(1, m):
				draw_circle(detail_a.lerp(detail_b, float(i) / m), w * 0.75, Color(0.55, 0.32, 0.1))
		for e in [a, b]:
			draw_circle(e, w * 0.9, Color(0.1, 0.1, 0.1))
			draw_circle(e, w * 0.55, UiPalette.ACCENT)
		if label_font and zoom >= 2.0:
			var mid = (a + b) * 0.5 + Vector2(6, -6)
			var txt = "%s %.0f km · vyťaženie %.0f %%" % ["Železnica" if str(l.kind) == "rail" else "Ropovod", float(l.km), u * 100.0]
			draw_string_outline(label_font, mid, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, UiPalette.OUTLINE)
			draw_string(label_font, mid, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UiPalette.BAD if u > 1.0 else (UiPalette.WARN if u > 0.7 else UiPalette.OK))
	if line_mode != "":
		var mp = get_local_mouse_position()
		if _line_has_a:
			var a2 = _to_screen(_line_a)
			draw_line(a2, mp, Color(UiPalette.ACCENT, 0.8), 3.0, true)
			if label_font:
				var k = Transport.km(_line_a, _to_world(mp))
				var t = "%.0f km · %s" % [k, EconMath.eur(Transport.line_cost(line_mode, _line_a, _to_world(mp)))]
				draw_string_outline(label_font, mp + Vector2(12, -10), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, UiPalette.OUTLINE)
				draw_string(label_font, mp + Vector2(12, -10), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiPalette.ACCENT)
		elif label_font:
			draw_string_outline(label_font, mp + Vector2(12, -10), "Klikni na začiatok trate", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, UiPalette.OUTLINE)
			draw_string(label_font, mp + Vector2(12, -10), "Klikni na začiatok trate", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiPalette.ACCENT)
		queue_redraw()


# ===================== JUAN20: Atlas – blizky pohlad =====================
func _vis(p: Vector2, m: float) -> bool:
	return p.x > -m and p.y > -m and p.x < size.x + m and p.y < size.y + m

# JUAN23: priestorova mriezka (pamat za rychlost) - kresli sa len to, co je v zornom poli, bez prechodu celeho sveta
const GRID_CELL = 6.0
var _grids := {}
var _allc: Array = []

func _grid(name: String, arr: Array, seg: bool) -> Dictionary:
	if _grids.has(name) and int(_grids[name].n) == arr.size():
		return _grids[name]
	var cells := {}
	for i in arr.size():
		var it = arr[i]
		var a: Vector2
		var b: Vector2
		if seg:
			a = it[0]; b = it[1]
		else:
			a = it.pos if typeof(it) == TYPE_DICTIONARY else it
			b = a
		var x0 = int(floor(minf(a.x, b.x) / GRID_CELL)); var x1 = int(floor(maxf(a.x, b.x) / GRID_CELL))
		var y0 = int(floor(minf(a.y, b.y) / GRID_CELL)); var y1 = int(floor(maxf(a.y, b.y) / GRID_CELL))
		if (x1 - x0 + 1) * (y1 - y0 + 1) > 400:
			x1 = x0; y1 = y0
		for cx in range(x0, x1 + 1):
			for cy in range(y0, y1 + 1):
				var k = Vector2i(cx, cy)
				if not cells.has(k):
					cells[k] = PackedInt32Array()
				cells[k].append(i)
	var g = {"n": arr.size(), "cells": cells}
	_grids[name] = g
	return g

func _visible_items(name: String, arr: Array, seg: bool, margin_px: float = 60.0) -> Array:
	var g = _grid(name, arr, seg)
	var sc = maxf(_fit() * zoom, 0.0001)
	var w0 = _to_world(Vector2(-margin_px, -margin_px))
	var w1 = _to_world(size + Vector2(margin_px, margin_px))
	var x0 = int(floor(w0.x / GRID_CELL)) - 1; var x1 = int(floor(w1.x / GRID_CELL)) + 1
	var y0 = int(floor(w0.y / GRID_CELL)) - 1; var y1 = int(floor(w1.y / GRID_CELL)) + 1
	if (x1 - x0 + 1) * (y1 - y0 + 1) > g.cells.size():
		return arr
	var out: Array = []
	var seen := {}
	var cells: Dictionary = g.cells
	for cx in range(x0, x1 + 1):
		for cy in range(y0, y1 + 1):
			var k = Vector2i(cx, cy)
			if not cells.has(k):
				continue
			for i in cells[k]:
				if seg:
					if seen.has(i):
						continue
					seen[i] = true
				out.append(arr[i])
	return out

func _all_cities(minpop: float) -> Array:
	var out: Array = []
	for iso in DataLoader.country_ids:
		for c in TerrainSystem.cities(str(iso)):
			if float(c.pop) >= minpop:
				out.append(c)
	return out

func _nearest_links(pts: Array, k: int, maxd: float) -> Array:
	var out: Array = []
	var seen = {}
	for i in pts.size():
		var d: Array = []
		for j in pts.size():
			if i != j:
				var dd = (pts[i] as Vector2).distance_squared_to(pts[j])
				if dd < maxd * maxd:
					d.append([dd, j])
		d.sort_custom(func(a, b): return a[0] < b[0])
		for t in mini(k, d.size()):
			var j2 = int(d[t][1])
			var key = "%d_%d" % [mini(i, j2), maxi(i, j2)]
			if not seen.has(key):
				seen[key] = true
				out.append([pts[i], pts[j2]])
	return out

const POWER_IND = ["power_coal", "gas_plant", "nuclear_plant", "solar_plant"]
const WELL_IND = ["oil_well", "gas_well"]
const PIPE_DEST = ["oil_refinery", "gas_plant", "gas_works", "chem_plant"]

# infrastruktura z realnych dat: mesta (cesty, dialnice, zeleznice, pristavy, letiska) + firmy v ulozenej hre (elektrarne, vrty)
func atlas_infra() -> Dictionary:
	if _ainfra_static.is_empty():
		var t0 = Time.get_ticks_msec()
		var big: Array = []
		for c in _all_cities(500000.0):
			big.append(c.pos)
		var mid: Array = []
		for c in _all_cities(150000.0):
			mid.append(c.pos)
		var base = infra_data()
		_ainfra_static = {"highways": _nearest_links(big, 2, 26.0), "rails": _nearest_links(mid, 1, 16.0), "roads": base.roads, "ports": base.ports.duplicate(), "airports": base.airports.duplicate(), "towns": _all_cities(30000.0), "ms": Time.get_ticks_msec() - t0}
	var layout: Array = [GameState.state_revision]
	for f in GameState.firms:
		var ind = str(f.get("industry", ""))
		if not bool(f.get("closed", false)) and (ind in POWER_IND or ind in WELL_IND or ind in PIPE_DEST or ind in ["shipyard", "airport"]):
			layout.append([str(f.get("id", "")), ind, firm_world_pos(f)])
	if layout == _ainfra_layout and not _ainfra.is_empty():
		return _ainfra
	_ainfra_layout = layout
	_ainfra_key += 1
	# Old spatial grids reference the previous infrastructure geometry.
	for grid_name in _grids.keys():
		if str(grid_name).begins_with("plines"):
			_grids.erase(grid_name)
	var power: Array = []
	var wells: Array = []
	var dests: Array = []
	var ports: Array = _ainfra_static.ports.duplicate()
	var airports: Array = _ainfra_static.airports.duplicate()
	for f in GameState.firms:
		if bool(f.get("closed", false)):
			continue
		var ind = str(f.get("industry", ""))
		var wp = firm_world_pos(f)
		if ind in POWER_IND:
			power.append([wp, ind])
		if ind in WELL_IND:
			wells.append([wp, ind])
		if ind in PIPE_DEST:
			dests.append([wp, ind])
		if ind == "shipyard":
			ports.append(wp)
		if ind == "airport":
			airports.append(wp)
	var plines: Array = []  # vedenia VN: elektraren -> 2 najblizsie mesta
	for pw in power:
		var near: Array = []
		for c in _ainfra_static.towns:
			var d = (c.pos as Vector2).distance_squared_to(pw[0])
			if d < 22.0 * 22.0:
				near.append([d, c.pos])
		near.sort_custom(func(a, b): return a[0] < b[0])
		for i in mini(2, near.size()):
			plines.append([pw[0], near[i][1]])
	var pipes: Array = []  # potrubia: vrt -> najblizsi spracovatel (rafineria/plynaren/elektraren)
	for w in wells:
		var best = null
		var bd = 60.0 * 60.0
		for d2 in dests:
			if str(w[1]) == "gas_well" and str(d2[1]) == "oil_refinery":
				continue
			var dd = (d2[0] as Vector2).distance_squared_to(w[0])
			if dd < bd and dd > 0.01:
				bd = dd
				best = d2[0]
		if best != null:
			pipes.append([w[0], best, str(w[1])])
	_ainfra = {"power": power, "plines": plines, "pipes": pipes, "ports": ports, "airports": airports}
	return _ainfra

func _dashed(a: Vector2, b: Vector2, col: Color, w: float, on: float, off: float) -> void:
	var L = a.distance_to(b)
	if L < 1.0:
		return
	var n = int(L / (on + off)) + 1
	for i in n:
		var t0 = float(i) * (on + off) / L
		if t0 >= 1.0:
			break
		_mlseg(a.lerp(b, t0), a.lerp(b, minf(1.0, (float(i) * (on + off) + on) / L)), col, w)

# JUAN23: predpocitane polia segmentov (svetove suradnice) + cache precarkovania podla zoomu
var _wl_c := {}
func _wl(name: String, arr: Array, off: Vector2) -> PackedVector2Array:
	var k = name + str(arr.size())
	if not _wl_c.has(k):
		var pk = PackedVector2Array()
		for r in arr:
			pk.append(r[0] + off)
			pk.append(r[1] + off)
		_wl_c[k] = pk
	return _wl_c[k]

func _wdash(name: String, arr: Array, on: float, off: float) -> PackedVector2Array:
	var q = pow(1.08, roundf(log(maxf(on + off, 0.0001)) / log(1.08)))  # kvantovanie (~8 %) -> cache aj pocas plynuleho zoomu
	on = on * q / maxf(on + off, 0.0001)
	var step = q
	var k = "d" + name + str(arr.size()) + "|" + str(step)
	if not _wl_c.has(k):
		if _wl_c.size() > 400:
			_wl_c.clear()
		var pk = PackedVector2Array()
		for r in arr:
			var a: Vector2 = r[0]; var b: Vector2 = r[1]
			var L = a.distance_to(b)
			if L <= 0.0 or step <= 0.0:
				continue
			var t = 0.0
			while t < L:
				pk.append(a.lerp(b, t / L))
				pk.append(a.lerp(b, minf(1.0, (t + on) / L)))
				t += step
				if pk.size() > 400000:
					break
		_wl_c[k] = pk
	return _wl_c[k]

var _ml := {}
func _mlseg(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var k = [col, snappedf(w, 0.25)]
	if not _ml.has(k):
		_ml[k] = PackedVector2Array()
	var arr: PackedVector2Array = _ml[k]
	arr.append(a)
	arr.append(b)
	_ml[k] = arr

func _mlflush(aa: bool = false) -> void:
	for k in _ml.keys():
		var arr: PackedVector2Array = _ml[k]
		if arr.size() >= 2:
			draw_multiline(arr, k[0], float(k[1]), aa)
	_ml.clear()

func _seg_vis(a: Vector2, b: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).grow(20).intersects(Rect2(a, Vector2.ZERO).expand(b))

func _draw_atlas_near(sc: float) -> void:
	var st = _ainfra_static if not _ainfra_static.is_empty() else {}
	var d = atlas_infra()
	st = _ainfra_static
	var _tq = Time.get_ticks_usec()
	var u = _fit() * zoom  # px na svetovu jednotku (0.25 st.)
	var w = clampf(u * 0.16, 1.0, 7.0)
	var fade_city = clampf((CITY_ZOOM - zoom) / (CITY_ZOOM * 0.35), 0.0, 1.0)  # 3D mesta prechadzaju do satelitneho detailu
	# JUAN23: segmenty sa zbieraju a kreslia jednym draw_multiline na styl (namiesto tisicov draw_line)
	var aa = not GFX.low()
	# JUAN23: staticke siete (cesty, zeleznice, dialnice) ako predpocitane polia vo svetovych suradniciach, kreslene cez transformaciu
	var inv = 1.0 / maxf(u, 0.0001)
	var o = _origin()
	draw_set_transform(o, 0.0, Vector2(u, u))
	if u >= 6.0:
		draw_multiline(_wl("roads", st.roads, Vector2.ZERO), Color("D6CCB0", 0.85), maxf(1.0, w * 0.6) * inv, aa)
	if u >= 4.0:
		draw_set_transform(o + Vector2(w, w), 0.0, Vector2(u, u))
		draw_multiline(_wl("rails", st.rails, Vector2.ZERO), Color("1E1E22"), (w * 0.9 + 1.0) * inv, aa)
		if not (GFX.low() and u < 10.0):
			draw_multiline(_wdash("rails", st.rails, w * 3.0 * inv, w * 3.0 * inv), Color("ECECEC"), maxf(1.0, w * 0.45) * inv, false)
		draw_set_transform(o, 0.0, Vector2(u, u))
	var hwl = _wl("highways", st.highways, Vector2.ZERO)
	draw_multiline(hwl, Color("3C2814", 0.9), (w * 1.3 + 1.5) * inv, aa)
	draw_multiline(hwl, Color("F0A840", 0.9), w * 1.3 * inv, aa)
	if u >= 20.0:
		draw_multiline(_wdash("highways", st.highways, 6.0 * inv, 6.0 * inv), Color(1, 1, 1, 0.7), 1.0 * inv, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for pl in d.pipes:
		var a = _to_screen(pl[0]); var b = _to_screen(pl[1])
		if _seg_vis(a, b):
			_mlseg(a, b, Color("462812"), w + 3.0)
	_mlflush(aa)
	for pl in d.pipes:
		var a = _to_screen(pl[0]); var b = _to_screen(pl[1])
		if _seg_vis(a, b):
			_dashed(a, b, Color("E2A040") if str(pl[2]) == "gas_well" else Color("C87A2E"), w + 1.0, w * 5.0, w * 1.5)
	_mlflush(aa)
	for pl in (_visible_items("plines%d" % _ainfra_key, d.plines, true) if u >= 5.0 else []):  # vedenia VN so stozarmi
		var a = _to_screen(pl[0]); var b = _to_screen(pl[1])
		if not _seg_vis(a, b):
			continue
		draw_line(a, b, Color(0.98, 0.88, 0.35, 0.8), maxf(1.0, w * 0.4), true)
		var n = 1 if GFX.low() else maxi(2, int(a.distance_to(b) / maxf(18.0, w * 10.0)))
		for i in range(1, n):
			var q = a.lerp(b, float(i) / n)
			var hgt = clampf(w * 3.0, 4.0, 14.0)
			draw_polyline(PackedVector2Array([q + Vector2(-hgt * 0.35, 0), q + Vector2(0, -hgt), q + Vector2(hgt * 0.35, 0)]), Color(0.15, 0.15, 0.15, 0.9), 1.0)
			draw_line(q + Vector2(-hgt * 0.4, -hgt * 0.8), q + Vector2(hgt * 0.4, -hgt * 0.8), Color(0.15, 0.15, 0.15, 0.9), 1.0)
	prof["an0"] = Time.get_ticks_usec() - _tq; _tq = Time.get_ticks_usec()
	var s2 = clampf(u * 0.5, 4.0, 16.0)
	for pp in d.ports:
		var q = _to_screen(pp) + Vector2(s2 * 1.2, s2 * 0.6)
		if _vis(q, 30):
			draw_rect(Rect2(q - Vector2(s2, s2 * 0.35), Vector2(s2 * 2.0, s2 * 0.7)), Color("46464C"))
			for k in 3:
				draw_line(q + Vector2(-s2 * 0.8 + k * s2 * 0.7, -s2 * 0.35), q + Vector2(-s2 * 0.8 + k * s2 * 0.7, -s2 * 1.3), Color("E6A028"), 2.0)
	for ap in d.airports:
		var q = _to_screen(ap) + Vector2(-s2 * 1.6, s2 * 0.8)
		if _vis(q, 30):
			draw_line(q + Vector2(-s2 * 1.5, s2 * 0.4), q + Vector2(s2 * 1.5, -s2 * 0.4), Color("505458"), s2 * 0.45)
			draw_line(q + Vector2(-s2 * 1.3, s2 * 0.35), q + Vector2(s2 * 1.3, -s2 * 0.35), Color(1, 1, 1, 0.8), 1.0)
			box(q + Vector2(0, s2 * 0.6), s2 * 0.4, s2 * 0.5)
	prof["an1"] = Time.get_ticks_usec() - _tq; _tq = Time.get_ticks_usec()
	# mesta: 3D zhluky (miznu do satelitneho detailu pri CITY_ZOOM)
	var cities_vis: Array = []
	if not st.has("towns_big"):
		st["towns_big"] = st.towns.filter(func(t): return float(t.pop) >= 400000.0)
	var far_lod = u < 8.0 and zoom < CITY_ZOOM * 0.75  # JUAN23: LOD - z dialky len velke mesta
	for c in _visible_items("towns_big" if far_lod else "towns", st.towns_big if far_lod else st.towns, false, 300.0):
		var cp = _to_screen(c.pos)
		var rr = maxf(3.0, float(c.r) * sc)
		if not _vis(cp, rr + 40.0):
			continue
		cities_vis.append([c, cp])
	cities_vis.sort_custom(func(a, b): return a[1].y < b[1].y)
	AD.begin_batch()  # JUAN23: 3D mesta + elektrarne jednym volanim
	for cv in cities_vis:
		var c: Dictionary = cv[0]
		if zoom >= CITY_ZOOM * 0.75:
			AD.flush(self)
			_draw_city_detail(c, sc)
		if fade_city > 0.01 and (float(c.pop) >= (400000.0 if u < 8.0 else 30000.0)):
			AD.city(self, c, cv[1], sc, fade_city)
	prof["an2"] = Time.get_ticks_usec() - _tq; _tq = Time.get_ticks_usec()
	for p0 in d.power:  # elektrarne (aj AI) ako modely
		var q2 = _to_screen(p0[0])
		if _vis(q2, 40):
			AD.firm(self, q2, clampf(u * 0.45, 3.0, 14.0), str(p0[1]), false, null)
	AD.end_batch(self)
	prof["an3"] = Time.get_ticks_usec() - _tq; _tq = Time.get_ticks_usec()
	# firmy hraca: 3D model podla typu + zvyraznenie
	var isz = icon_px()
	for s in _my_sites():
		var p2 = _to_screen(s.wp)
		if _vis(p2, 60):
			AD.firm(self, p2, clampf(u * 0.55, 5.0, 22.0), str(s.ind), true, type_icon(str(s.ind)))
			_logo_badge(s, p2 + Vector2(0, -clampf(u * 0.55, 5.0, 22.0) * 2.0), clampf(u * 0.55, 5.0, 22.0) * 1.6)
	prof["an4"] = Time.get_ticks_usec() - _tq; _tq = Time.get_ticks_usec()
	# nazvy miest az navrchu, mensie, odsadene od stredu (neprekryvaju trasy v strede)
	if label_font:
		for cv in cities_vis:
			var c2: Dictionary = cv[0]
			if float(c2.pop) > (500000.0 if u < 8.0 else (100000.0 if u < 20.0 else 0.0)):
				var lp = cv[1] + Vector2(clampf(float(c2.r) * sc * 0.6, 8.0, 60.0), 14.0)
				var fs = 11 if u < 20.0 else 13
				draw_string_outline(label_font, lp, str(c2.name), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0.08, 0.06, 0.05, 0.9))
				draw_string(label_font, lp, str(c2.name), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("F6EEDA"))

func box(p: Vector2, hw: float, h: float) -> void:
	AD.box(self, p, hw, h, Color("C9C4B8"), Color("8C8F94"))


# ===================== JUAN21: logá a výrobky =====================
func _site_corp(site: Dictionary) -> String:
	var sid = str(site.get("id", ""))
	if sid.begins_with("hq:"):
		return sid.substr(3)
	return str(GameState.firm_by_id(sid).get("corp", ""))

func _logo_badge(site: Dictionary, p: Vector2, isz: float) -> void:
	var cid = _site_corp(site)
	if cid == "" or not StockMarket.ex().get("corps", {}).has(cid):
		return
	if str(site.get("id", "")).begins_with("hq:"):  # centrala: velke logo
		var r = isz * 1.15
		Brand.draw_logo(self, Rect2(p - Vector2(r, r) * 0.5 - Vector2(0, isz * 0.95), Vector2(r, r)), Brand.logo(cid), label_font)
	else:  # firma v korporacii: male logo v rohu
		var r2 = maxf(9.0, isz * 0.55)
		Brand.draw_logo(self, Rect2(p + Vector2(isz * 0.35, -isz * 0.9), Vector2(r2, r2)), Brand.logo(cid), null)

func _draw_products() -> void:
	if product_firm == "":
		return
	var f = GameState.firm_by_id(product_firm)
	if f.is_empty():
		return
	var src = _to_screen(firm_world_pos(f))
	var rows = Brand.destinations(product_firm)
	var agg = {}
	for r in rows:
		agg[r.iso] = float(agg.get(r.iso, 0.0)) + float(r.qty)
	var mx = 0.001
	for v in agg.values():
		mx = maxf(mx, float(v))
	for iso in agg.keys():
		var dst = _to_screen(capital_of(str(iso)))
		var q = float(agg[iso])
		var w = 1.5 + 4.0 * q / mx
		var mid = (src + dst) * 0.5 + (dst - src).orthogonal().normalized() * src.distance_to(dst) * 0.18
		var pts = PackedVector2Array()
		for i in 17:
			var t = i / 16.0
			pts.append(src.lerp(mid, t).lerp(mid.lerp(dst, t), t))
		draw_polyline(pts, Color(0, 0, 0, 0.5), w + 2.0, true)
		draw_polyline(pts, Color(0.35, 0.85, 1.0, 0.9), w, true)
		var dir = (pts[16] - pts[14]).normalized()
		draw_colored_polygon(PackedVector2Array([dst, dst - dir * 10 + dir.orthogonal() * 5, dst - dir * 10 - dir.orthogonal() * 5]), Color(0.35, 0.85, 1.0))
		draw_circle(dst, 9.0, Color(0.05, 0.1, 0.15, 0.9))
		if label_font:
			var t2 = "%.0f" % q if q >= 1.0 else "%.1f" % q
			draw_string(label_font, dst + Vector2(-label_font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x * 0.5, 4), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	if label_font:
		var tt = "Kam skončili výrobky: %s" % str(f.get("name", ""))
		draw_string_outline(label_font, Vector2(12, size.y - 14), tt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, UiPalette.OUTLINE)
		draw_string(label_font, Vector2(12, size.y - 14), tt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.35, 0.85, 1.0))
