extends RefCounted
# JUAN20: Atlas – 3D izometricke mesta, modely firiem a infrastruktura z realnych dat hry.
# Vsetko kreslene vektorovo (vlastne tvary), bez cudzich assetov.

const ROOF = [Color("A65A42"), Color("8E4A3A"), Color("C9C4B8"), Color("6E6E72"), Color("B7B0A3"), Color("9B7B5B")]


# JUAN23: davkovanie - vsetky tvary (aj ciary ako tenke stvoruholniky) do jedneho triangle array volania, poradie zachovane
static var B_on := false
static var B_v := PackedVector2Array()
static var B_c := PackedColorArray()

static func begin_batch() -> void:
	B_on = true
	B_v.clear()
	B_c.clear()

static func flush(m: CanvasItem) -> void:
	if B_v.size() >= 3:
		var idx = PackedInt32Array()
		idx.resize(B_v.size())
		for i in B_v.size():
			idx[i] = i
		RenderingServer.canvas_item_add_triangle_array(m.get_canvas_item(), idx, B_v, B_c)
	B_v.clear()
	B_c.clear()

static func end_batch(m: CanvasItem) -> void:
	flush(m)
	B_on = false

static func _tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	B_v.append(a); B_v.append(b); B_v.append(c)
	B_c.append(col); B_c.append(col); B_c.append(col)

static func _colored_polygon(m: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	if not B_on:
		m.draw_colored_polygon(pts, col)
		return
	for i in range(1, pts.size() - 1):  # vsetky tvary modelov su konvexne
		_tri(pts[0], pts[i], pts[i + 1], col)

static func _line(m: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float = 1.0, aa: bool = false) -> void:
	if not B_on:
		m.draw_line(a, b, col, w, aa)
		return
	var d = b - a
	var L = d.length()
	if L < 0.0001:
		return
	var n = Vector2(-d.y, d.x) / L * maxf(w, 1.0) * 0.5
	_tri(a - n, a + n, b + n, col)
	_tri(a - n, b + n, b - n, col)

static func _polyline(m: CanvasItem, pts: PackedVector2Array, col: Color, w: float = 1.0, aa: bool = false) -> void:
	if not B_on:
		m.draw_polyline(pts, col, w, aa)
		return
	for i in pts.size() - 1:
		_line(m, pts[i], pts[i + 1], col, w)

static func _circle(m: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	if not B_on:
		m.draw_circle(c, r, col)
		return
	var n = clampi(int(r * 0.8) + 6, 8, 24)
	var prev = c + Vector2(r, 0)
	for i in range(1, n + 1):
		var q = c + Vector2(cos(TAU * i / n), sin(TAU * i / n)) * r
		_tri(c, prev, q, col)
		prev = q

static func _arc(m: CanvasItem, c: Vector2, r: float, a0: float, a1: float, pts: int, col: Color, w: float = 1.0, aa: bool = false) -> void:
	if not B_on:
		m.draw_arc(c, r, a0, a1, pts, col, w, aa)
		return
	var prev = c + Vector2(cos(a0), sin(a0)) * r
	for i in range(1, pts + 1):
		var t = a0 + (a1 - a0) * i / pts
		var q = c + Vector2(cos(t), sin(t)) * r
		_line(m, prev, q, col, w)
		prev = q

static func _rect(m: CanvasItem, r: Rect2, col: Color, filled: bool = true, w: float = 1.0) -> void:
	if not B_on:
		m.draw_rect(r, col, filled, w if not filled else -1.0)
		return
	if filled:
		_tri(r.position, r.position + Vector2(r.size.x, 0), r.end, col)
		_tri(r.position, r.end, r.position + Vector2(0, r.size.y), col)
	else:
		var a = r.position; var b = r.position + Vector2(r.size.x, 0); var c = r.end; var d = r.position + Vector2(0, r.size.y)
		_line(m, a, b, col, w); _line(m, b, c, col, w); _line(m, c, d, col, w); _line(m, d, a, col, w)

# cache rozlozenia budov mesta (nahodne cisla + triedenie sa nepocitaju kazdy snimok)
static var _city_lay := {}
static var use_city_geometry_cache := true
const CITY_GEOMETRY_LIMIT = 128
static var _city_geometry := {}

static func _shade(c: Color, k: float) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, c.a)

# kvader: zakladna stred p, polsirka hw (px), vyska h (px); lava stena svetla, prava tmava, strecha
static func box(m: CanvasItem, p: Vector2, hw: float, h: float, wall: Color, roof: Color, a: float = 1.0) -> void:
	var dy = hw * 0.5
	var o = Color(0.1, 0.09, 0.08, 0.85 * a)
	var L = PackedVector2Array([p + Vector2(-hw, -h), p + Vector2(0, -h + dy), p + Vector2(0, dy), p + Vector2(-hw, 0)])
	var R = PackedVector2Array([p + Vector2(hw, -h), p + Vector2(0, -h + dy), p + Vector2(0, dy), p + Vector2(hw, 0)])
	var T = PackedVector2Array([p + Vector2(0, -h - dy), p + Vector2(hw, -h), p + Vector2(0, -h + dy), p + Vector2(-hw, -h)])
	_colored_polygon(m, L, Color(wall, a))
	_colored_polygon(m, R, Color(_shade(wall, 0.62), a))
	_colored_polygon(m, T, Color(roof, a))
	if hw >= 3.0:
		T.append(T[0])
		_polyline(m, T, o, 1.0)
		_line(m, p + Vector2(0, -h + dy), p + Vector2(0, dy), o, 1.0)
		if h > hw * 1.6 and hw >= 4.0:  # okna na vysokych budovach
			var n = int(h / 4.0)
			for i in range(1, n):
				var y = -h + dy + float(i) * (h - dy) / n
				_line(m, p + Vector2(-hw * 0.85, y - hw * 0.42), p + Vector2(-hw * 0.15, y - hw * 0.08), Color(1, 0.95, 0.7, 0.25 * a), 1.0)

# tien budovy na zem (smer JV)
static func shadow(m: CanvasItem, p: Vector2, hw: float, h: float, a: float = 1.0) -> void:
	var s = Vector2(h * 0.55, h * 0.3)
	_colored_polygon(m, PackedVector2Array([p + Vector2(-hw, 0), p + Vector2(0, hw * 0.5), p + Vector2(hw, 0), p + Vector2(hw, 0) + s, p + Vector2(0, hw * 0.5) + s, p + Vector2(-hw, 0) + s]), Color(0, 0, 0, 0.28 * a))

# mesto ako zhluk vysokych budov (velkost podla obyvatelov)
static func city(m: CanvasItem, c: Dictionary, cp: Vector2, sc: float, a: float) -> void:
	var ck = str(c.name) + str(c.get("iso", ""))
	var signature = [cp, sc, a, float(c.pop), float(c.r)]
	if B_on and use_city_geometry_cache and _city_geometry.has(ck):
		var cached: Dictionary = _city_geometry[ck]
		if cached.signature == signature:
			B_v.append_array(cached.vertices)
			B_c.append_array(cached.colors)
			return
	var first_vertex = B_v.size()
	var pop = float(c.pop)
	var n = clampi(int(log(maxf(pop, 10.0)) / log(10.0) * 2.6 - 9.0), 2, 14)
	var r_px = clampf(float(c.r) * sc * 0.55, 6.0, 140.0)
	var hw = clampf(r_px / 5.0, 2.0, 16.0)
	_circle(m, cp + Vector2(0, hw * 0.4), r_px * 0.9, Color(0.78, 0.74, 0.66, 0.22 * a))
	if not _city_lay.has(ck):
		var rng = RandomNumberGenerator.new()
		rng.seed = hash(ck)
		var lay: Array = []
		for i in n:
			var ang = rng.randf() * TAU
			var dn = sqrt(rng.randf()) * 0.7
			var tall = 1.0 - dn
			lay.append([Vector2(cos(ang) * dn, sin(ang) * dn * 0.55), rng.randf_range(0.7, 1.15), (1.2 + tall * rng.randf_range(1.0, 4.5) * clampf(pop / 1.5e6, 0.5, 1.6)), rng.randi() % ROOF.size()])
		lay.sort_custom(func(x, y): return x[0].y < y[0].y)
		_city_lay[ck] = lay
	var bs: Array = []
	for l in _city_lay[ck]:
		bs.append([cp + l[0] * r_px, hw * l[1], hw * l[2], l[3]])
	for b in bs:
		shadow(m, b[0], b[1], b[2], a)
	for b in bs:
		var roof: Color = ROOF[b[3]] if b[2] < b[1] * 2.4 else Color("D8D4CA")
		box(m, b[0], b[1], b[2], Color("D2C9B6"), roof, a)
	if B_on and use_city_geometry_cache:
		if not _city_geometry.has(ck) and _city_geometry.size() >= CITY_GEOMETRY_LIMIT:
			_city_geometry.erase(_city_geometry.keys()[0])
		_city_geometry[ck] = {"signature": signature, "vertices": B_v.slice(first_vertex), "colors": B_c.slice(first_vertex)}

# modely firiem podla typu
static func kind_of(ind: String) -> String:
	if ind in ["coal_mine", "iron_mine", "copper_mine"]: return "mine"
	if ind in ["oil_well", "gas_well"]: return "well"
	if ind in ["power_coal", "gas_plant"]: return "power"
	if ind == "nuclear_plant": return "nuclear"
	if ind == "solar_plant": return "solar"
	if ind in ["oil_refinery", "chem_plant", "gas_works", "pharma_lab"]: return "tanks"
	if ind in ["wheat_farm", "coffee_farm", "livestock"]: return "farm"
	if ind in ["logistics_hub", "warehouse", "trade_desk"]: return "logi"
	if ind in ["bank", "finance_office", "software", "insurance", "invest_fund", "stock_broker", "offshore", "telecom", "tv_station", "social_network", "ad_agency", "newspaper", "hq", "real_estate", "hotel", "casino"]: return "tower"
	if ind == "airport" or ind == "airline": return "airport"
	if ind == "shipyard": return "shipyard"
	if ind == "data_center": return "datacenter"
	if ind == "ai_firm": return "ai"
	if ind == "aircraft_plant": return "hangar"
	if ind in ["steel_mill", "textile_mill", "electronics_plant", "auto_plant", "arms_plant", "chip_fab", "construction_co"]: return "factory"
	return "shop"

static func firm(m: CanvasItem, p: Vector2, s: float, ind: String, mine: bool, icon: Texture2D) -> void:
	var k = kind_of(ind)
	if mine:
		_arc(m, p + Vector2(0, s * 0.2), s * 1.9, 0, TAU, 32, Color(1.0, 0.6, 0.15, 0.95), maxf(2.0, s * 0.18), true)
		_circle(m, p + Vector2(0, s * 0.2), s * 1.85, Color(1.0, 0.6, 0.15, 0.14))
	var h = s * 1.3
	var wall = Color("B9B4AA")
	var roof = Color("8C8F94")
	match k:
		"mine":
			wall = Color("7A6E62"); h = s * 0.8
		"tower":
			wall = Color("9FB4C8"); roof = Color("D9E2EA"); h = s * 3.2
		"farm":
			_colored_polygon(m, PackedVector2Array([p + Vector2(-s * 1.8, 0), p + Vector2(0, -s * 0.9), p + Vector2(s * 1.8, 0), p + Vector2(0, s * 0.9)]), Color("C8B45A"))
			wall = Color("A0462E"); roof = Color("6B2E22"); h = s * 0.9
		"solar":
			for i in 3:
				var q = p + Vector2(-s + i * s * 0.9, -s * 0.2 + i * s * 0.25)
				_colored_polygon(m, PackedVector2Array([q + Vector2(-s * 0.6, 0), q + Vector2(0, -s * 0.35), q + Vector2(s * 0.6, 0), q + Vector2(0, s * 0.35)]), Color("2A4C7A"))
			_icon(m, p, s, icon, mine, s * 0.6)
			return
		"airport":
			_line(m, p + Vector2(-s * 2.2, s * 0.6), p + Vector2(s * 2.2, -s * 0.6), Color("4A4E52"), s * 0.7)
			_line(m, p + Vector2(-s * 2.0, s * 0.55), p + Vector2(s * 2.0, -s * 0.55), Color(1, 1, 1, 0.8), 1.0)
			h = s * 0.8
		"logi":
			wall = Color("C6BBA2"); h = s * 0.9
		"datacenter":
			wall = Color("5A606A"); roof = Color("3A3E46"); h = s * 0.9
		"ai":
			wall = Color("2E3A52"); roof = Color("8FD0FF"); h = s * 2.6
		"hangar":
			wall = Color("A9ADB3"); roof = Color("7D8288"); h = s * 1.0
	shadow(m, p, s, h)
	box(m, p, s, h, wall, roof)
	var top = p + Vector2(0, -h)
	match k:
		"mine":
			_polyline(m, PackedVector2Array([top + Vector2(-s * 0.6, 0), top + Vector2(0, -s * 2.0), top + Vector2(s * 0.6, 0)]), Color("2A2A2A"), 2.0)
			_arc(m, top + Vector2(0, -s * 2.0), s * 0.35, 0, TAU, 12, Color("2A2A2A"), 2.0)
		"well":
			_polyline(m, PackedVector2Array([top + Vector2(-s * 0.5, 0), top + Vector2(0, -s * 2.4), top + Vector2(s * 0.5, 0)]), Color("2A2A2A"), 2.0)
			_circle(m, top + Vector2(0, -s * 2.6), s * 0.28, Color("FF9A2A") if ind == "gas_well" else Color("202020"))
		"power", "factory", "tanks":
			if k == "tanks":
				for o in [-0.9, 0.9]:
					var q = top + Vector2(s * o, s * 0.2)
					_rect(m, Rect2(q - Vector2(s * 0.4, s * 0.5), Vector2(s * 0.8, s * 0.5)), Color("E2E0D8"))
					_circle(m, q - Vector2(0, s * 0.5), s * 0.4, Color("F2F0EA"))
			var cx = top + Vector2(s * 0.45, 0)
			_rect(m, Rect2(cx - Vector2(s * 0.16, s * 1.7), Vector2(s * 0.32, s * 1.7)), Color("8A4A3C"))
			_circle(m, cx - Vector2(-s * 0.2, s * 2.1), s * 0.45, Color(0.88, 0.88, 0.88, 0.55))
			_circle(m, cx - Vector2(-s * 0.6, s * 2.6), s * 0.6, Color(0.88, 0.88, 0.88, 0.35))
		"nuclear":
			for o in [-0.7, 0.7]:
				var q = top + Vector2(s * o, s * 0.1)
				_colored_polygon(m, PackedVector2Array([q + Vector2(-s * 0.55, 0), q + Vector2(-s * 0.35, -s * 1.4), q + Vector2(s * 0.35, -s * 1.4), q + Vector2(s * 0.55, 0)]), Color("D8D8D0"))
				_line(m, q + Vector2(0, 0), q + Vector2(0, -s * 1.4), Color(0.6, 0.6, 0.58), 1.0)
				_circle(m, q + Vector2(0, -s * 1.9), s * 0.55, Color(1, 1, 1, 0.5))
		"logi":
			var cols = [Color("C84A3A"), Color("3A6EBE"), Color("E6AA28")]
			for i in 3:
				_rect(m, Rect2(top + Vector2(-s * 0.9 + i * s * 0.62, -s * 0.45), Vector2(s * 0.55, s * 0.4)), cols[i])
		"datacenter":  # chladiace jednotky + zelene LED
			for i in 3:
				_rect(m, Rect2(top + Vector2(-s * 0.9 + i * s * 0.62, -s * 0.35), Vector2(s * 0.5, s * 0.3)), Color("9AA0A8"))
				_circle(m, top + Vector2(-s * 0.65 + i * s * 0.62, -s * 0.2), s * 0.1, Color("50E080"))
		"ai":  # svietiaca antena a pas
			_line(m, top, top + Vector2(0, -s * 1.4), Color("D0D8E0"), 2.0)
			_circle(m, top + Vector2(0, -s * 1.5), s * 0.28, Color("FF8C3C"))
			_line(m, p + Vector2(-s, -h * 0.5), p + Vector2(0, -h * 0.5 + s * 0.5), Color(0.55, 0.85, 1.0, 0.9), 2.0)
		"hangar":  # oblucikova strecha + lietadlo
			_arc(m, top + Vector2(0, s * 0.3), s * 0.9, PI, TAU, 12, Color("6A6E74"), 3.0)
			_line(m, top + Vector2(-s * 1.2, -s * 0.9), top + Vector2(s * 1.2, -s * 0.9), Color("F0F0F4"), 2.0)
			_line(m, top + Vector2(0, -s * 1.3), top + Vector2(0, -s * 0.5), Color("F0F0F4"), 2.0)
		"shipyard":
			_line(m, top + Vector2(s * 0.5, 0), top + Vector2(s * 0.5, -s * 2.2), Color("E6AA28"), 2.0)
			_line(m, top + Vector2(s * 0.5, -s * 2.2), top + Vector2(-s * 1.2, -s * 1.9), Color("E6AA28"), 2.0)
	_icon(m, p, s, icon, mine, h)

static func _icon(m: CanvasItem, p: Vector2, s: float, icon: Texture2D, mine: bool, h: float) -> void:
	if icon == null or s < 5.0:
		return
	var isz = clampf(s * 1.3, 10.0, 26.0)
	var q = p + Vector2(-isz * 0.5, -h - s * 2.8 - isz)
	_rect(m, Rect2(q - Vector2(2, 2), Vector2(isz + 4, isz + 4)), Color(0.06, 0.07, 0.09, 0.85))
	flush(m); m.draw_texture_rect(icon, Rect2(q, Vector2(isz, isz)), false)
	_rect(m, Rect2(q - Vector2(2, 2), Vector2(isz + 4, isz + 4)), Color(1.0, 0.6, 0.15) if mine else Color(0.6, 0.6, 0.6), false, 1.5)
