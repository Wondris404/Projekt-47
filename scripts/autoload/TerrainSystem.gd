extends Node
# JUAN4: teren, nalezistia surovin a mestske zony.
# Vsetko je deterministicke z dat (countries.json endow, map.json polygony, cities.json) -> netreba ukladat do savu.
# Svetove suradnice = ako WorldMap.project (1440x720, 4 px na stupen).

const RES_NAMES = {"coal": "Uhlie", "iron": "Železná ruda", "copper": "Meď", "oil": "Ropa", "gas": "Zemný plyn", "farmland": "Úrodná pôda"}
const RES_COLORS = {"coal": Color(0.25, 0.25, 0.25), "iron": Color(0.70, 0.35, 0.20), "copper": Color(0.85, 0.55, 0.25), "oil": Color(0.10, 0.10, 0.12), "gas": Color(0.45, 0.70, 0.95), "farmland": Color(0.75, 0.80, 0.30)}
const TERRAIN_NAMES = {"plains": "Nížina", "forest": "Les", "hills": "Pahorkatina", "mountains": "Hory", "desert": "Púšť", "tundra": "Tundra", "urban": "Mesto"}
const TERRAIN_COLORS = {"plains": Color(0.42, 0.52, 0.28), "forest": Color(0.20, 0.36, 0.18), "hills": Color(0.50, 0.45, 0.30), "mountains": Color(0.55, 0.52, 0.50), "desert": Color(0.78, 0.68, 0.42), "tundra": Color(0.72, 0.76, 0.78), "urban": Color(0.95, 0.55, 0.15)}
# odvetvie -> potrebne nalezisko ("" = nevyzaduje)
const NEEDS_DEPOSIT = {"coal_mine": "coal", "iron_mine": "iron", "copper_mine": "copper", "oil_well": "oil", "gas_well": "gas", "wheat_farm": "farmland"}
const URBAN_ONLY = ["cafe", "finance_office", "bank", "trade_desk", "stock_broker"]
const DEPOSIT_R = 3.0
# endow kluc v countries.json pre kazdu surovinu
const ENDOW_KEY = {"coal": "coal", "iron": "iron_ore", "copper": "copper", "oil": "crude_oil", "farmland": "wheat"}

var _cache_dep: Dictionary = {}
var _cache_city: Dictionary = {}
var _cache_poly: Dictionary = {}
var _noise: FastNoiseLite
var cities_data: Dictionary = {}

func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = 4747
	_noise.frequency = 0.045
	var f = FileAccess.open("res://data/cities.json", FileAccess.READ)
	if f:
		var d = JSON.parse_string(f.get_as_text())
		if typeof(d) == TYPE_DICTIONARY:
			cities_data = d

static func project(lat: float, lon: float) -> Vector2:
	var w = float(DataLoader.map.get("w", 1440))
	var h = float(DataLoader.map.get("h", 720))
	return Vector2((lon + 180.0) / 360.0 * (w - 1.0), (90.0 - lat) / 180.0 * (h - 1.0))

static func lat_of(wp: Vector2) -> float:
	var h = float(DataLoader.map.get("h", 720))
	return 90.0 - wp.y / (h - 1.0) * 180.0

func polys(iso: String) -> Array:
	if _cache_poly.has(iso):
		return _cache_poly[iso]
	var out: Array = []
	for c in DataLoader.map.get("countries", []):
		if str(c.get("iso2", "")) != iso:
			continue
		for ring in c.get("polys", []):
			var pk = PackedVector2Array()
			for p in ring:
				if typeof(p) == TYPE_ARRAY and p.size() >= 2:
					pk.append(Vector2(float(p[0]), float(p[1])))
			if pk.size() >= 3:
				out.append(pk)
	_cache_poly[iso] = out
	return out

func inside(iso: String, wp: Vector2) -> bool:
	for pk in polys(iso):
		if Geometry2D.is_point_in_polygon(wp, pk):
			return true
	return false

func cities(iso: String) -> Array:
	if _cache_city.has(iso):
		return _cache_city[iso]
	var out: Array = []
	var rows = cities_data.get(iso, [])
	if typeof(rows) != TYPE_ARRAY or rows.is_empty():
		var c: Dictionary = DataLoader.countries.get(iso, {})
		rows = [{"name": str(c.get("capital", iso)), "lat": float(c.get("capital_lat", c.get("lat", 0.0))), "lon": float(c.get("capital_lon", c.get("lon", 0.0))), "pop": int(float(c.get("population", 1e6)) * 0.1), "capital": true}]
	for r in rows:
		var pop = float(r.get("pop", 100000))
		out.append({"name": str(r.get("name", "?")), "pos": project(float(r.lat), float(r.lon)), "pop": pop,
			"capital": bool(r.get("capital", false)), "r": clamp(0.9 + sqrt(pop / 1.0e6) * 0.9, 1.5, 4.5), "iso": iso})
	_cache_city[iso] = out
	return out

func urban_at(iso: String, wp: Vector2) -> Dictionary:
	for c in cities(iso):
		if wp.distance_to(c.pos) <= float(c.r):
			return c
	return {}

func city_named(iso: String, nm: String) -> Dictionary:
	for c in cities(iso):
		if str(c.name) == nm:
			return c
	return {}

func _bbox(iso: String) -> Rect2:
	var r = Rect2()
	var first = true
	for pk in polys(iso):
		for p in pk:
			if first:
				r = Rect2(p, Vector2.ZERO)
				first = false
			else:
				r = r.expand(p)
	return r

func deposits(iso: String) -> Array:
	if _cache_dep.has(iso):
		return _cache_dep[iso]
	var out: Array = []
	var c: Dictionary = DataLoader.countries.get(iso, {})
	var endow: Dictionary = c.get("endow", {})
	var box = _bbox(iso)
	var rng = RandomNumberGenerator.new()
	rng.seed = absi(iso.hash()) + 47
	var area_f = clamp(sqrt(max(box.size.x * box.size.y, 1.0)) / 25.0, 0.6, 4.0)
	var plan: Dictionary = {}
	for res in ENDOW_KEY.keys():
		var e = float(endow.get(ENDOW_KEY[res], 0.0))
		plan[res] = int(round(e * 2.5 * area_f)) if e >= 0.12 else 0
	var oil_e = float(endow.get("crude_oil", 0.0))
	plan["gas"] = int(round((oil_e * 0.8 + float(c.get("fuel_export_share", 0.0))) * 2.0 * area_f)) if oil_e + float(c.get("fuel_export_share", 0.0)) > 0.2 else 0
	if float(endow.get("coal", 0.0)) >= 0.08 and plan.coal == 0:
		plan.coal = 1
	for res in ["coal", "iron", "copper", "oil", "gas", "farmland"]:
		var n = mini(int(plan.get(res, 0)), 12)
		var tries = 0
		while n > 0 and tries < 400 and box.size.x > 0.0:
			tries += 1
			var p = Vector2(rng.randf_range(box.position.x, box.end.x), rng.randf_range(box.position.y, box.end.y))
			if not inside(iso, p):
				continue
			var bad = false
			for city in cities(iso):
				if p.distance_to(city.pos) < float(city.r) + DEPOSIT_R:
					bad = true
					break
			if bad:
				continue
			var t = terrain_at(p, iso)
			if res == "farmland" and t in ["mountains", "desert", "tundra"]:
				continue
			out.append({"res": res, "pos": p, "r": DEPOSIT_R, "iso": iso})
			n -= 1
	_cache_dep[iso] = out
	return out

func deposit_at(iso: String, wp: Vector2, res: String = "") -> Dictionary:
	for d in deposits(iso):
		if (res == "" or str(d.res) == res) and wp.distance_to(d.pos) <= float(d.r) * (1.0 + 0.5 * float(GameState.player.get("modifiers", {}).get("survey", 0.0))):  # JUAN5: prieskum loziska
			return d
	return {}

func terrain_at(wp: Vector2, iso: String = "") -> String:
	if iso != "" and not urban_at(iso, wp).is_empty():
		return "urban"
	var lat = abs(lat_of(wp))
	var n = _noise.get_noise_2d(wp.x, wp.y)
	if lat > 64.0:
		return "tundra"
	var dry = 0.0
	if iso != "":
		var c: Dictionary = DataLoader.countries.get(iso, {})
		dry = float(c.get("fuel_export_share", 0.0)) * 0.6 - float(c.get("agri_share", 0.05)) * 2.0
	if lat > 14.0 and lat < 34.0 and n + dry > 0.05:
		return "desert"
	if n > 0.35:
		return "mountains"
	if n > 0.15:
		return "hills"
	if n < -0.2:
		return "forest"
	return "plains"

# kind = industry id (cafe, finance_office, bank, coal_mine...). Vrati {ok, reason}.
func can_place(ind_id: String, iso: String, wp: Vector2) -> Dictionary:
	var city = urban_at(iso, wp)
	if ind_id in URBAN_ONLY:
		if city.is_empty():
			return {"ok": false, "reason": "%s sa dá postaviť len v meste (oranžové kruhy)." % _ind_name(ind_id)}
		return {"ok": true, "reason": "", "city": str(city.name)}
	# JUAN9: pravidla pre vsetky typy firiem podla zony
	var zone = str(DataLoader.industries.get(ind_id, {}).get("zone", ""))
	if ind_id == "airport":
		var near = _near_city(iso, wp, 3.0, 200000.0)
		if near.is_empty():
			return {"ok": false, "reason": "Letisko musí byť pri meste s aspoň 200 tis. obyvateľmi (klikni blízko veľkého mesta)."}
		if not city.is_empty():
			return {"ok": false, "reason": "Letisko nemôže byť priamo v centre mesta %s – klikni kúsok vedľa." % str(city.name)}
		return {"ok": true, "reason": "", "city": str(near.name)}
	if zone == "commercial" and NEEDS_DEPOSIT.get(ind_id, "") == "":
		if city.is_empty():
			return {"ok": false, "reason": "%s patrí do mesta (oranžové kruhy). Klikni do mesta." % _ind_name(ind_id)}
		return {"ok": true, "reason": "", "city": str(city.name)}
	if ind_id == "cargo_port":  # JUAN-P47: len pri primorskom/riecnom meste
		for pc in cities(iso):
			if Society.is_port_city(iso, str(pc.name)) and wp.distance_to(pc.pos) <= float(pc.r) * 2.5:
				return {"ok": true, "reason": "", "city": str(pc.name)}
		var names: Array = Society.port_cities(iso)
		if names.is_empty():
			return {"ok": false, "reason": "V tejto krajine nie je prímorské ani riečne mesto pre nákladný prístav."}
		return {"ok": false, "reason": "Nákladný prístav musí byť pri prímorskom/riečnom meste: %s." % ", ".join(names)}
	if zone == "port":
		if _near_city(iso, wp, 2.5, 0.0).is_empty():
			return {"ok": false, "reason": "%s musí byť pri meste (prístav, sklady, doprava). Klikni blízko mesta." % _ind_name(ind_id)}
		return {"ok": true, "reason": ""}
	if ind_id in ["nuclear_plant", "power_coal", "gas_plant", "chem_plant", "steel_mill", "oil_refinery", "gas_works"] and not city.is_empty():
		return {"ok": false, "reason": "%s nemôže stáť v meste %s (bezpečnosť, hluk). Klikni mimo mesta." % [_ind_name(ind_id), str(city.name)]}
	var need = str(NEEDS_DEPOSIT.get(ind_id, ""))
	if need != "":
		if not city.is_empty():
			return {"ok": false, "reason": "%s nemôže stáť v meste %s. Hľadaj náleziško mimo mesta." % [_ind_name(ind_id), str(city.name)]}
		if deposit_at(iso, wp, need).is_empty():
			return {"ok": false, "reason": "Tu nie je náleziško: %s. Zapni prekrytie Teren a klikni na značku." % RES_NAMES[need]}
		return {"ok": true, "reason": ""}
	return {"ok": true, "reason": ""}

func _near_city(iso: String, wp: Vector2, mult: float, min_pop: float) -> Dictionary:
	for c in cities(iso):
		if float(c.get("pop", 0.0)) >= min_pop and wp.distance_to(c.pos) <= float(c.r) * mult:
			return c
	return {}

func valid_spots(ind_id: String, iso: String) -> Array:
	var out: Array = []
	var zn = str(DataLoader.industries.get(ind_id, {}).get("zone", ""))
	if ind_id == "cargo_port":
		for c in cities(iso):
			if Society.is_port_city(iso, str(c.name)):
				out.append({"pos": c.pos, "r": c.r})
		return out
	if ind_id in URBAN_ONLY or zn in ["commercial", "port"] or ind_id in ["airport", "hq"]:
		for c in cities(iso):
			out.append({"pos": c.pos, "r": c.r})
		return out
	var need = str(NEEDS_DEPOSIT.get(ind_id, ""))
	for d in deposits(iso):
		if need == "" or str(d.res) == need:
			out.append({"pos": d.pos, "r": d.r})
	return out

func _ind_name(ind_id: String) -> String:
	return str(DataLoader.industries.get(ind_id, {}).get("name", ind_id)) if ind_id != "bank" else "Banka"

func summary(iso: String) -> String:
	var cnt: Dictionary = {}
	for d in deposits(iso):
		cnt[d.res] = int(cnt.get(d.res, 0)) + 1
	var parts: Array = []
	for k in cnt.keys():
		parts.append("%s %d" % [RES_NAMES[k], cnt[k]])
	return "Náleziská: " + (", ".join(parts) if parts.size() > 0 else "žiadne")
