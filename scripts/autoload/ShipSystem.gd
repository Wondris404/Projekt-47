extends Node
# Fáza C. Prázdna flotila nič nemení: žiadny RNG, žiadny freight_pool.

var catalog: Dictionary = {}

func _ready() -> void:
	var f = FileAccess.open("res://data/ships.json", FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for row in parsed.get("ships", []):
		if typeof(row) == TYPE_DICTIONARY:
			catalog[str(row.get("id", ""))] = row

func spec(kind_id: String) -> Dictionary:
	return catalog.get(kind_id, {})

func fleet() -> Array:
	if typeof(GameState.ext) != TYPE_DICTIONARY:
		GameState.ext = {}
	if typeof(GameState.ext.get("fleet")) != TYPE_ARRAY:
		GameState.ext["fleet"] = []
	return GameState.ext["fleet"]

func civil_count() -> int:
	var n = 0
	for s in fleet():
		if str(s.get("kind", "")) != "military":
			n += 1
	return n

func has_yard() -> bool:
	for f in GameState.player_firms():
		if str(f.get("industry", "")) == "shipyard":
			return true
	return false

func price_of(kind_id: String, yard: bool) -> float:
	var p = float(spec(kind_id).get("price", 0.0))
	return p * (0.72 if yard else 1.0)

func buy(kind_id: String, yard: bool) -> String:
	var row = spec(kind_id)
	if row.is_empty():
		return "Neznámy typ lode."
	var price = price_of(kind_id, yard)
	if yard and not has_yard():
		return "Vlastná lodenica chýba."
	if float(GameState.player.cash) < price:
		return "Loď stojí %s." % EconMath.eur(price)
	GameState.player.cash = float(GameState.player.cash) - price
	var pair = _route(kind_id)
	fleet().append({
		"id": "s%d" % (fleet().size() + 1),
		"kind_id": kind_id,
		"name": str(row.get("name", kind_id)),
		"kind": str(row.get("kind", "general")),
		"cargo": str(row.get("cargo", "")),
		"cargo_qty": 0.0,
		"src": pair[0],
		"dst": pair[1],
		"t": 0.0,
		"owner": "player",
	})
	GameState.post_news("Kúpená loď: %s." % str(row.get("name", kind_id)), "firmy")
	return ""

func sell_military(ship_id: String) -> String:
	var ships = fleet()
	for i in ships.size():
		var s: Dictionary = ships[i]
		if str(s.get("id", "")) != ship_id:
			continue
		if str(s.get("kind", "")) != "military":
			return "Štáty kupujú len vojenské lode. Boj v hre nie je."
		var pay = price_of(str(s.get("kind_id", "")), false) * 0.9
		GameState.player.cash = float(GameState.player.cash) + pay
		ships.remove_at(i)
		GameState.post_news("Štát kúpil vojenskú loď za %s." % EconMath.eur(pay), "firmy")
		return ""
	return "Loď nenájdená."

func daily() -> void:
	if typeof(GameState.ext) != TYPE_DICTIONARY:
		return
	var ships = GameState.ext.get("fleet", [])
	if typeof(ships) != TYPE_ARRAY or ships.is_empty():
		return
	var maint = 0.0
	var fuel = 0.0
	for s in ships:
		var row = spec(str(s.get("kind_id", "")))
		maint += float(row.get("maintain", 0.0)) / 30.0
		if str(s.get("kind", "")) == "military":
			continue
		fuel += float(row.get("fuel", 0.0)) / 30.0
		var speed = maxf(float(row.get("speed", 12.0)), 1.0)
		var days = maxf(2.0, 400.0 / speed)
		s["eta"] = int(ceil((1.0 - float(s.get("t", 0.0))) * days))
		s["t"] = float(s.get("t", 0.0)) + 1.0 / days
		if float(s.t) >= 1.0:
			var tmp = str(s.src)
			s["src"] = str(s.dst)
			s["dst"] = tmp
			s["t"] = 0.0
			s["cargo_qty"] = float(row.get("capacity", 0.0))
			s["eta"] = int(days)
	GameState.player.cash = float(GameState.player.cash) - maint - fuel
	_charter()

func _charter() -> void:
	if civil_count() <= 0:
		return
	var take = 0.0
	for iso in MarketSystem.freight_pool.keys():
		var pool = float(MarketSystem.freight_pool[iso])
		var cut = minf(pool * 0.12, float(civil_count()) * 400.0)
		if cut <= 0.0:
			continue
		MarketSystem.freight_pool[iso] = pool - cut
		take += cut
	if take > 0.0:
		GameState.player.cash = float(GameState.player.cash) + take

func own_freight(a: String, b: String, cid: String) -> float:
	if civil_count() <= 0:
		return MarketSystem.freight_unit(a, b, cid)
	var row = spec("feeder")
	return float(row.get("fuel", 6000.0)) / 100000.0

func _route(kind_id: String) -> Array:
	var isos = ["SK", "NL", "DE", "PL", "US", "CN"]
	var h = absi(hash(kind_id)) % isos.size()
	var a = isos[h]
	var b = isos[(h + 2) % isos.size()]
	if not DataLoader.countries.has(a):
		a = "SK"
	if not DataLoader.countries.has(b) or b == a:
		b = "DE" if a != "DE" else "PL"
	return [a, b]

func pos_of(ship: Dictionary) -> Vector2:
	var a = _port_pos(str(ship.get("src", "SK")))
	var b = _port_pos(str(ship.get("dst", "DE")))
	return a.lerp(b, clampf(float(ship.get("t", 0.0)), 0.0, 1.0))

func _port_pos(iso: String) -> Vector2:
	var names: Array = Society.port_cities(iso)
	if not names.is_empty():
		var city = TerrainSystem.city_named(iso, str(names[0]))
		if not city.is_empty():
			return city.pos
	var cs = TerrainSystem.cities(iso)
	if not cs.is_empty():
		return cs[0].pos
	var c: Dictionary = DataLoader.countries.get(iso, {})
	return TerrainSystem.project(float(c.get("lat", 48.0)), float(c.get("lon", 17.0)))

func ship_at(world: Vector2) -> String:
	var best = ""
	var bd = 2.2
	var n = 0
	for s in fleet():
		if n >= 32:
			break
		n += 1
		if str(s.get("kind", "")) == "military":
			continue
		var d = pos_of(s).distance_to(world)
		if d < bd:
			bd = d
			best = str(s.get("id", ""))
	return best

func info(ship_id: String) -> String:
	for s in fleet():
		if str(s.get("id", "")) != ship_id:
			continue
		return "%s\nNáklad: %s (%.0f)\nCieľ: %s\nETA: %d dní" % [
			str(s.get("name", ship_id)),
			str(s.get("cargo", "—")) if str(s.get("cargo", "")) != "" else "—",
			float(s.get("cargo_qty", 0.0)),
			str(GameState.world.get(str(s.get("dst", "")), {}).get("name_sk", s.get("dst", ""))),
			int(s.get("eta", 1)),
		]
	return "Loď nenájdená."

# Vzdušná doprava v rovnakom systéme ako lode (fáza C). Halloween DLC sem posiela
# helikoptéry a stíhačky; len výpočet polohy pre mapu, nič sa neukladá.
func air_traffic(anim_time: float) -> Array:
	var out: Array = []
	if not has_node("/root/ZombieSystem") or not ZombieSystem.active():
		return out
	var wobble = fposmod(anim_time * 0.15, 1.0)
	for fl in ZombieSystem.z().get("flights", []):
		if typeof(fl) != TYPE_DICTIONARY or out.size() >= 24:
			continue
		var aa = fl.get("a", [0, 0])
		var bb = fl.get("b", [0, 0])
		var a = Vector2(float(aa[0]), float(aa[1]))
		var b = Vector2(float(bb[0]), float(bb[1]))
		var t = clampf(float(fl.get("t", 0.0)), 0.0, 1.0)
		var kind = str(fl.get("kind", "heli"))
		var e = {"kind": kind, "state": "fly", "flash": int(fl.get("flash", 0)), "pos": a, "heading": Vector2.RIGHT}
		if bool(fl.get("crash", false)):
			e.state = "crash"
			e.pos = a.lerp(b, 0.5)
		elif bool(fl.get("patrol", false)):
			var ang = (t + wobble) * TAU
			e.state = "patrol"
			e.pos = a + Vector2(cos(ang), sin(ang)) * 3.2
			e.heading = Vector2(-sin(ang), cos(ang))
		elif kind == "heli" and t < 0.12:
			e.state = "hover"
			e.pos = a
		else:
			var tt = clampf(t + wobble * 0.08, 0.0, 1.0)
			e.pos = a.lerp(b, tt)
			e.heading = (b - a).normalized() if a.distance_to(b) > 0.05 else Vector2.RIGHT
		out.append(e)
	return out
