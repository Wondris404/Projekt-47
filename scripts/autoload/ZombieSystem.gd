extends Node
# Halloween DLC. Keď je zombie_mode vypnuté, daily() nič nespraví a hru nemení.

const PASS_HASH := "e3d9de4005aed8f1dc9e87df9aeefbc1dfa64ec76ad57b9b83a26c67aad57714"
const SETTINGS := "user://settings.cfg"
var balance: Dictionary = {}

func _ready() -> void:
	var f = FileAccess.open("res://data/zombie_balance.json", FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		balance = parsed

func num(key: String, fallback: float) -> float:
	return float(balance.get(key, fallback))

func active() -> bool:
	var gs = GameState.get("game_settings")
	return typeof(gs) == TYPE_DICTIONARY and bool(gs.get("zombie_mode", false))

func password_ok(text: String) -> bool:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(text.to_utf8_buffer())
	return ctx.finish().hex_encode() == PASS_HASH

func unlocked() -> bool:
	var cf = ConfigFile.new()
	if cf.load(SETTINGS) != OK:
		return false
	return bool(cf.get_value("dlc", "unlocked", false))

func set_unlocked() -> void:
	var cf = ConfigFile.new()
	cf.load(SETTINGS)
	cf.set_value("dlc", "unlocked", true)
	cf.save(SETTINGS)

func _news(text: String) -> void:
	# DLC správy idú do panelu Noviny (fáza B) vo vlastnej kategórii.
	GameState.post_news(text, "nákaza")

func z() -> Dictionary:
	if typeof(GameState.zombie) != TYPE_DICTIONARY:
		GameState.zombie = {}
	return GameState.zombie

func daily() -> void:
	if not active():
		return
	var row = z()
	if bool(row.get("ended", false)):
		return
	_ensure(row)
	_story(row)
	_grow_and_spread(row)
	_flights(row)
	_zones(row)
	_economy(row)
	_vaccine(row)
	_ending(row)

func _ensure(row: Dictionary) -> void:
	if not row.has("regions"):
		row["regions"] = {}
	if not row.has("flights"):
		row["flights"] = []
	if not row.has("zones"):
		row["zones"] = []
	if not row.has("evac"):
		row["evac"] = []
	if not row.has("buildings"):
		row["buildings"] = []
	if not row.has("policy"):
		row["policy"] = {}
	if not row.has("helicopters"):
		row["helicopters"] = []
	if not row.has("fighters"):
		row["fighters"] = []
	if not row.has("vaccine"):
		row["vaccine"] = {"progress": 0.0, "owner": "", "firm": "", "done": false, "deployed": false, "name": ""}
	if not row.has("saved"):
		row["saved"] = 0
	if not row.has("draw"):
		row["draw"] = []
	if not row.has("corp"):
		_spawn_corp(row)

func _spawn_corp(row: Dictionary) -> void:
	row["corp"] = {"name": "United Wealth Corp.", "country": "US", "note": "Fiktívna firma len v tomto DLC."}
	if not GameState.world.has("US"):
		return
	for f in GameState.firms:
		if str(f.get("name", "")) == "United Wealth Corp.":
			return
	var ind: Dictionary = DataLoader.industries.get("pharma_lab", {})
	GameState.firms.append({
		"id": "uwc",
		"name": "United Wealth Corp.",
		"owner": "dlc",
		"country": "US",
		"industry": "pharma_lab",
		"cash": 5000000.0,
		"closed": false,
		"shares": 1000,
		"public": 0.0,
		"share_price": 1000.0,
		"history": [],
		"distress": 0,
		"workers": 40.0,
		"facilities": [{
			"recipe": str(ind.get("recipe", "pharma_lab")),
			"country": "US",
			"scale": 1.0,
			"auto": false,
			"util": 0.0,
			"zone": "industrial",
			"inventory": {},
			"cargo": "",
			"src": "US",
			"dst": "",
		}],
	})

func _story(row: Dictionary) -> void:
	if GameState.day_index == int(num("news_day", 7)) and not bool(row.get("news_shock", false)):
		row["news_shock"] = true
		_news("ŠOKUJÚCE: United Wealth Corp. tajne vyvíjala pre USA vírus, ktorý mení ľudí na zombie.")
	if GameState.day_index == int(num("outbreak_day", 8)) and not bool(row.get("outbreak", false)):
		row["outbreak"] = true
		var reg = _region("PL", "Kraków")
		reg["infection"] = num("outbreak_pct", 5.0)
		_refresh(reg)
		_news("Nákaza vypukla v Krakove!")

func _region(iso: String, city_name: String) -> Dictionary:
	var row = z()
	var key = iso + "|" + city_name
	if not row.regions.has(key):
		var city = TerrainSystem.city_named(iso, city_name)
		var pos = city.get("pos", Vector2.ZERO)
		row.regions[key] = {
			"iso": iso,
			"name": city_name,
			"pop": float(city.get("pop", 100000.0)),
			"pos": [pos.x, pos.y],
			"infection": 0.0,
			"zombies": 0,
			"status": "čistý",
			"fell_news": false,
			"air_news": false,
		}
	return row.regions[key]

func _refresh(reg: Dictionary) -> void:
	var inf = clampf(float(reg.get("infection", 0.0)), 0.0, 100.0)
	reg["infection"] = inf
	reg["zombies"] = int(float(reg.get("pop", 0.0)) * inf / 100.0 * num("zombie_pop_frac", 0.35))
	if inf <= 0.0:
		reg["status"] = "čistý"
	elif inf >= num("fallen_at", 70.0):
		reg["status"] = "padol"
		if not bool(reg.get("fell_news", false)):
			reg["fell_news"] = true
			_news("%s padlo." % str(reg.get("name", "Mesto")))
	else:
		reg["status"] = "ohrozený"

func _slow(reg: Dictionary) -> float:
	var s = 1.0
	var row = z()
	var key = str(reg.get("iso", "")) + "|" + str(reg.get("name", ""))
	for bld in row.get("buildings", []):
		if str(bld.get("region", "")) != key:
			continue
		var kind = str(bld.get("kind", ""))
		var lv = clampi(int(bld.get("level", 1)), 1, 3)
		if kind == "nemocnica":
			s *= num("hospital_slow", 0.72) - (lv - 1) * 0.05
		elif kind == "karantena":
			s *= num("quarantine_block", 0.82) - (lv - 1) * 0.06
	if int(row.get("army", {}).get(str(reg.get("iso", "")), 0)) > 0:
		s *= num("army_slow", 0.7)
	var pol = str(row.get("policy", {}).get(str(reg.get("iso", "")), "ignore"))
	if pol == "exile":
		s *= num("exile_slow", 0.8)
	elif pol == "kill":
		s *= num("kill_slow", 0.45)
	if bool(row.get("vaccine", {}).get("deployed", false)):
		s *= 0.55
	return clampf(s, 0.15, 1.0)

func _grow_and_spread(row: Dictionary) -> void:
	if not bool(row.get("outbreak", false)):
		return
	var keys = row.regions.keys()
	for key in keys:
		var reg: Dictionary = row.regions[key]
		if float(reg.get("infection", 0.0)) <= 0.0:
			continue
		var dens = float(reg.get("pop", 0.0)) / 1000000.0 * num("density", 0.35)
		reg["infection"] = float(reg.infection) + (num("daily_growth", 3.0) + dens) * _slow(reg)
		_refresh(reg)
		if float(reg.infection) < num("spread_at", 10.0):
			continue
		_spread_from(reg)

func _spread_from(reg: Dictionary) -> void:
	var iso = str(reg.get("iso", ""))
	var origin = str(reg.get("name", ""))
	var here = TerrainSystem.city_named(iso, origin)
	if here.is_empty():
		return
	var nearest_name := ""
	var nearest_km := 1.0e12
	var cities = TerrainSystem.cities(iso)
	for city in cities:
		if str(city.name) == origin:
			continue
		var km = here.pos.distance_to(city.pos) * 27.8
		if km < nearest_km:
			nearest_km = km
			nearest_name = str(city.name)
		if km > num("neighbor_km", 260.0):
			continue
		var kind = "road"
		if float(city.pop) >= 400000.0 and float(here.get("pop", 0.0)) >= 400000.0:
			kind = "air"
		elif Society.is_port_city(iso, str(city.name)) or Society.is_port_city(iso, origin):
			kind = "port"
		elif km < 120.0:
			kind = "rail"
		var chance = num(kind + "_chance", 0.2)
		var roll = float(absi(hash(str(GameState.day_index) + origin + str(city.name))) % 10000) / 10000.0
		if roll < chance:
			_seed(iso, str(city.name), num("transfer", 4.0))
			if kind == "air" and not bool(reg.get("air_news", false)):
				reg["air_news"] = true
				_news("Letisko %s zatvorené." % origin)
	if nearest_name != "" and nearest_km <= num("neighbor_km", 260.0) * 1.4:
		_seed(iso, nearest_name, num("min_spread", 1.5))
	for border in DataLoader.countries.get(iso, {}).get("borders", []):
		var other = str(border)
		if not DataLoader.countries.has(other):
			continue
		var foreign = TerrainSystem.cities(other)
		if foreign.is_empty():
			continue
		var hop = foreign[0]
		var hkm = here.pos.distance_to(hop.pos) * 27.8
		if hkm > 700.0:
			continue
		var roll2 = float(absi(hash("x" + str(GameState.day_index) + iso + other)) % 10000) / 10000.0
		if roll2 < num("air_chance", 0.72) * 0.25:
			_seed(other, str(hop.name), num("transfer", 4.0) * 0.5)

func _seed(iso: String, city_name: String, amount: float) -> void:
	if city_name == "":
		return
	var reg = _region(iso, city_name)
	if str(reg.get("status", "")) == "padol":
		return
	reg["infection"] = float(reg.get("infection", 0.0)) + amount
	_refresh(reg)

func country_infection(iso: String) -> float:
	if not active():
		return 0.0
	var worst = 0.0
	for reg in z().get("regions", {}).values():
		if str(reg.get("iso", "")) == iso:
			worst = maxf(worst, float(reg.get("infection", 0.0)))
	return worst

func region_at(iso: String, city_name: String) -> Dictionary:
	if not active() or city_name == "":
		return {}
	var key = iso + "|" + city_name
	return z().get("regions", {}).get(key, {})

func tip(iso: String, city_name: String) -> String:
	if not active():
		return ""
	var reg = region_at(iso, city_name)
	if reg.is_empty():
		return "Nákaza: čistý región"
	return "Nákaza %s: %.0f %%, zombie %d, stav %s" % [str(reg.get("name", city_name)), float(reg.infection), int(reg.zombies), str(reg.status)]

func color_for(iso: String) -> Color:
	var p = country_infection(iso) / 100.0
	var c = Color(0.25, 0.72, 0.32)
	c = c.lerp(Color(0.92, 0.82, 0.2), clampf(p / 0.35, 0.0, 1.0))
	c = c.lerp(Color(0.95, 0.45, 0.12), clampf((p - 0.25) / 0.45, 0.0, 1.0))
	return c.lerp(Color(0.45, 0.05, 0.08), clampf((p - 0.7) / 0.3, 0.0, 1.0))

func model_count(reg: Dictionary) -> int:
	var n = int(ceil(float(reg.get("zombies", 0)) / maxf(num("models_per", 10000.0), 1.0)))
	return clampi(n, 0, int(num("max_models", 5)))

func buy_helicopter() -> String:
	if not active():
		return "DLC nie je zapnuté."
	var price = num("heli_price", 900000.0)
	if float(GameState.player.cash) < price:
		return "Helikoptéra stojí %s." % EconMath.eur(price)
	GameState.player.cash = float(GameState.player.cash) - price
	var id = "h%d" % (z().helicopters.size() + 1)
	z().helicopters.append({"id": id, "lost": false})
	_news("Kúpená helikoptéra %s." % id)
	return ""

func buy_fighter() -> String:
	if not active():
		return "DLC nie je zapnuté."
	var price = num("fighter_price", 2500000.0)
	if float(GameState.player.cash) < price:
		return "Stíhačka stojí %s." % EconMath.eur(price)
	GameState.player.cash = float(GameState.player.cash) - price
	z().fighters.append({"id": "f%d" % (z().fighters.size() + 1)})
	_news("Kúpená stíhačka.")
	return ""

func toggle_evac(firm_id: String) -> String:
	if not active():
		return "DLC nie je zapnuté."
	var firm = GameState.firm_by_id(firm_id)
	if firm.is_empty():
		return "Firma neexistuje."
	var ind = str(firm.get("industry", ""))
	if not ind in ["cargo_port", "airport", "airline", "shipyard", "logistics_hub"]:
		return "Evakuačná zóna môže byť prístav, letisko alebo tvoja budova dopravy."
	var ids: Array = z().evac
	if firm_id in ids:
		ids.erase(firm_id)
		return "Označenie evakuácie zrušené."
	ids.append(firm_id)
	_news("Evakuačná zóna: %s." % str(firm.get("name", firm_id)))
	return ""

func can_zone(iso: String) -> String:
	if Empire.owns_state(iso):
		return ""
	if not Society.st().get("contracts", {}).get(iso, {}).is_empty():
		return ""
	if float(PoliticsSystem.influence(iso)) >= 50.0:
		return ""
	return "Safe zónu môžeš kresliť len so zmluvou s vládou, s vplyvom aspoň 50 % alebo ak vlastníš štát."

func add_draw_point(world: Vector2, close_it: bool) -> String:
	if not active():
		return ""
	var row = z()
	var pts: Array = row.draw
	if close_it or (pts.size() >= 3 and world.distance_to(Vector2(float(pts[0][0]), float(pts[0][1]))) < 1.2):
		var msg = _close_zone(row)
		if msg != "":
			_news(msg)
		return msg
	pts.append([world.x, world.y])
	row["draw"] = pts
	return ""

func _close_zone(row: Dictionary) -> String:
	var pts: Array = row.get("draw", [])
	if pts.size() < 3:
		return "Safe zóna potrebuje aspoň tri body."
	var iso = GameState.selected_iso
	var why = can_zone(iso)
	if why != "":
		row["draw"] = []
		return why
	row.zones.append({
		"id": "sz%d" % (row.zones.size() + 1),
		"iso": iso,
		"pts": pts.duplicate(),
		"people": 0,
		"food": 20.0,
		"meds": 10.0,
		"fuel": 10.0,
		"defense": 10.0,
		"alive": true,
	})
	row["draw"] = []
	_news("Safe zóna v krajine %s." % str(GameState.world.get(iso, {}).get("name_sk", iso)))
	return ""

func city_safe(iso: String, city_name: String) -> String:
	if not active():
		return "DLC nie je zapnuté."
	var why = can_zone(iso)
	if why != "":
		return why
	var city = TerrainSystem.city_named(iso, city_name)
	if city.is_empty():
		return "Mesto nenájdené."
	var owned = false
	for f in GameState.player_firms():
		if str(f.get("country", "")) == iso and str(f.get("city", "")) == city_name:
			owned = true
	if Empire.owns_state(iso):
		owned = true
	if not owned:
		return "Toto mesto nevlastníš. Kresli polygón, alebo ho vlastni firmou či celým štátom."
	var p: Vector2 = city.pos
	var r = float(city.get("r", 2.0))
	z().zones.append({
		"id": "sz%d" % (z().zones.size() + 1),
		"iso": iso,
		"city": city_name,
		"pts": [[p.x - r, p.y - r], [p.x + r, p.y - r], [p.x + r, p.y + r], [p.x - r, p.y + r]],
		"people": 0,
		"food": 30.0,
		"meds": 15.0,
		"fuel": 15.0,
		"defense": 20.0,
		"alive": true,
	})
	_news("Mesto %s je safe zóna." % city_name)
	return ""

func build_in_zone(kind: String) -> String:
	if not active():
		return "DLC nie je zapnuté."
	if z().zones.is_empty():
		return "Najprv nakresli safe zónu."
	var zone: Dictionary = z().zones[z().zones.size() - 1]
	if not bool(zone.get("alive", true)):
		return "Táto safe zóna padla."
	var cost = 400000.0 * Difficulty.cost_mult()
	if float(GameState.player.cash) < cost:
		return "Stavba stojí %s." % EconMath.eur(cost)
	GameState.player.cash = float(GameState.player.cash) - cost
	var names = {
		"nemocnica": "Nemocnica", "letisko": "Letisko pre evakuovaných", "karantena": "Karanténna zóna",
		"baraky": "Baráky", "pristav": "Prístav", "zeleznica": "Železnica", "mur": "Múr",
	}
	if not names.has(kind):
		return "Neznáma stavba."
	z().buildings.append({
		"id": "zb%d" % (z().buildings.size() + 1),
		"kind": kind,
		"name": names[kind],
		"level": 1,
		"zone": str(zone.get("id", "")),
		"region": str(zone.get("iso", "")) + "|" + str(zone.get("city", "")),
	})
	if kind == "baraky":
		zone["cap_bonus"] = int(zone.get("cap_bonus", 0)) + int(num("zone_people", 8000))
	_news("V safe zóne stojí %s (úroveň 1)." % names[kind])
	return ""

func upgrade_building(bid: String) -> String:
	for bld in z().get("buildings", []):
		if str(bld.get("id", "")) != bid:
			continue
		if int(bld.get("level", 1)) >= 3:
			return "Stavba je na maxime."
		var cost = 500000.0 * int(bld.level)
		if float(GameState.player.cash) < cost:
			return "Vylepšenie stojí %s." % EconMath.eur(cost)
		GameState.player.cash = float(GameState.player.cash) - cost
		bld["level"] = int(bld.level) + 1
		return "%s je na úrovni %d." % [str(bld.name), int(bld.level)]
	return "Stavba nenájdená."

func set_policy(iso: String, pol: String) -> String:
	if not active():
		return "DLC nie je zapnuté."
	if not Empire.owns_state(iso):
		return "Politiku nákazy nastavíš len v štáte, ktorý vlastníš."
	if not pol in ["exile", "kill", "ignore"]:
		return "Neznáma voľba."
	z().policy[iso] = pol
	var text = {
		"exile": "Poslať helikoptérami do vyhnanstva: stojí peniaze a stroje, nákaza sa spomalí stredne.",
		"kill": "Zabiť nakazených a podozrivých: nákaza sa spomalí silno, reputácia prudko klesne a hrozia sankcie.",
		"ignore": "Nechať tak: nič nestojí a nákaza sa šíri voľne.",
	}
	if pol == "kill":
		GameState.player.rating = maxf(0.0, float(GameState.player.get("rating", 55.0)) - num("kill_rating", 12.0))
		_news("Svet odsudzuje postup v krajine %s. Reputácia padá." % str(GameState.world.get(iso, {}).get("name_sk", iso)))
		if GameState.world.has("US"):
			GeopoliticsSystem.security_council(iso)
	elif pol == "exile":
		if z().helicopters.is_empty():
			return "Na vyhnanstvo treba aspoň jednu helikoptéru."
		GameState.player.cash = maxf(0.0, float(GameState.player.cash) - 150000.0)
	_news(text[pol])
	return ""

func _flights(row: Dictionary) -> void:
	if not bool(row.get("outbreak", false)):
		return
	var zones: Array = row.get("zones", [])
	if not zones.is_empty() and not row.helicopters.is_empty() and not row.evac.is_empty():
		var zone: Dictionary = zones[0]
		if bool(zone.get("alive", true)):
			var room = int(num("zone_people", 8000)) + int(zone.get("cap_bonus", 0)) - int(zone.get("people", 0))
			var haul = mini(room, int(num("heli_people", 120)) * row.helicopters.size())
			if haul > 0 and float(zone.get("food", 0.0)) > 0.0:
				zone["people"] = int(zone.get("people", 0)) + haul
				row["saved"] = int(row.get("saved", 0)) + haul
				var a = _evac_pos(row)
				var b = _zone_center(zone)
				row.flights.append({"kind": "heli", "t": 0.0, "a": [a.x, a.y], "b": [b.x, b.y], "back": false, "flash": 0})
	if not row.fighters.is_empty() and not zones.is_empty():
		var center = _zone_center(zones[0])
		row.flights.append({"kind": "fighter", "t": 0.0, "a": [center.x, center.y], "b": [center.x + 4.0, center.y], "patrol": true, "flash": 1})
	var keep: Array = []
	for fl in row.flights:
		fl["t"] = float(fl.get("t", 0.0)) + 0.34
		if str(fl.get("kind", "")) == "heli" and float(fl.t) >= 0.5 and not bool(fl.get("back", false)):
			var mid = Vector2(float(fl.a[0]), float(fl.a[1])).lerp(Vector2(float(fl.b[0]), float(fl.b[1])), 0.5)
			if _fallen_near(mid) and float(absi(hash(str(GameState.day_index) + str(fl.a))) % 100) / 100.0 < num("heli_loss", 0.08):
				fl["crash"] = true
				fl["t"] = 1.1
				if row.helicopters.size() > 0:
					row.helicopters.pop_back()
				_news("Helikoptéra sa stratila nad padnutým regiónom.")
		if float(fl.t) < 1.15:
			keep.append(fl)
	row["flights"] = keep.slice(-24)

func _evac_pos(row: Dictionary) -> Vector2:
	if row.evac.is_empty():
		return Vector2.ZERO
	var firm = GameState.firm_by_id(str(row.evac[0]))
	if firm.is_empty():
		return Vector2.ZERO
	var p = firm.get("pos", [0, 0])
	if typeof(p) == TYPE_ARRAY and p.size() >= 2:
		return Vector2(float(p[0]), float(p[1]))
	var city = TerrainSystem.city_named(str(firm.get("country", "")), str(firm.get("city", "")))
	return city.get("pos", Vector2.ZERO)

func _zone_center(zone: Dictionary) -> Vector2:
	var pts: Array = zone.get("pts", [])
	if pts.is_empty():
		return Vector2.ZERO
	var s = Vector2.ZERO
	for p in pts:
		s += Vector2(float(p[0]), float(p[1]))
	return s / float(pts.size())

func _fallen_near(p: Vector2) -> bool:
	for reg in z().get("regions", {}).values():
		if str(reg.get("status", "")) != "padol":
			continue
		var rp = reg.get("pos", [0, 0])
		if Vector2(float(rp[0]), float(rp[1])).distance_to(p) < 8.0:
			return true
	return false

func _zones(row: Dictionary) -> void:
	for zone in row.get("zones", []):
		if not bool(zone.get("alive", true)):
			continue
		zone["food"] = float(zone.get("food", 0.0)) - int(zone.get("people", 0)) / 4000.0
		zone["meds"] = float(zone.get("meds", 0.0)) - 0.15
		zone["fuel"] = float(zone.get("fuel", 0.0)) - 0.1
		if float(zone.food) <= 0.0 or float(zone.meds) <= 0.0:
			var leave = mini(int(zone.get("people", 0)), 80)
			zone["people"] = int(zone.people) - leave
			row["saved"] = maxi(0, int(row.get("saved", 0)) - leave)
			if float(absi(hash("q" + str(zone.get("id", "")) + str(GameState.day_index))) % 100) < 30:
				var city = str(zone.get("city", ""))
				if city != "":
					_seed(str(zone.get("iso", "")), city, 2.0)
		var pressure = 0.0
		for reg in row.regions.values():
			if str(reg.get("iso", "")) == str(zone.get("iso", "")) and str(reg.get("status", "")) == "padol":
				pressure += float(reg.get("zombies", 0))
		var hold = 0.2
		for bld in row.buildings:
			if str(bld.get("zone", "")) == str(zone.get("id", "")) and str(bld.get("kind", "")) == "mur":
				var lv = clampi(int(bld.get("level", 1)), 1, 3)
				var table: Array = balance.get("wall_hold", [0.5, 0.7, 0.9])
				hold = float(table[lv - 1])
		if pressure > num("wall_breach", 80000.0) * (0.4 + hold):
			zone["alive"] = false
			var where = str(zone.get("city", str(GameState.world.get(str(zone.get("iso", "")), {}).get("name_sk", "zóna"))))
			_news("Múr v %s prelomený!" % where)

func _economy(row: Dictionary) -> void:
	if not bool(row.get("outbreak", false)):
		return
	var g = 0.0
	var n = 0
	for reg in row.regions.values():
		g += float(reg.get("infection", 0.0))
		n += 1
	if n == 0:
		return
	g = g / float(n)
	var mix = num("price_mix", 0.55)
	for iso in GameState.markets.keys():
		for cid in ["arms", "pharma", "wheat", "fuel", "pmc_services"]:
			if not GameState.markets[iso].has(cid):
				continue
			var book: Dictionary = GameState.markets[iso][cid]
			var base = float(DataLoader.commodity(cid).get("base_price", book.get("price", 1.0)))
			var target = base * (1.0 + mix * g / 100.0)
			book["price"] = lerpf(float(book.get("price", base)), target, 0.05)
	if GameState.day_index % 7 == 0:
		_news("Nákaza: akcie a turizmus klesajú, zbrane, lieky, jedlo a palivo dražejú.")

func _vaccine(row: Dictionary) -> void:
	var vac: Dictionary = row.vaccine
	if bool(vac.get("deployed", false)) or str(vac.get("firm", "")) == "":
		return
	var firm = GameState.firm_by_id(str(vac.firm))
	if firm.is_empty() or bool(firm.get("closed", false)):
		_news("Laboratórium %s zničené." % str(vac.get("name", "firmy")))
		vac["firm"] = ""
		vac["progress"] = 0.0
		return
	var iso = str(firm.get("country", ""))
	var city = str(firm.get("city", ""))
	if city != "" and str(region_at(iso, city).get("status", "")) == "padol":
		firm["closed"] = true
		_news("Laboratórium %s zničené." % str(firm.get("name", "")))
		vac["firm"] = ""
		vac["progress"] = 0.0
		return
	vac["progress"] = float(vac.get("progress", 0.0)) + 1.0
	if float(vac.progress) >= num("vaccine_days", 360.0):
		vac["done"] = true
		vac["owner"] = str(firm.get("owner", "player"))
		_news("Vakcína je hotová: %s." % str(firm.get("name", "laboratórium")))

func start_vaccine(firm_id: String) -> String:
	if not active():
		return "DLC nie je zapnuté."
	var firm = GameState.firm_by_id(firm_id)
	if firm.is_empty():
		return "Firma neexistuje."
	if not str(firm.get("industry", "")) in ["pharma_lab", "hospital"]:
		return "Vakcínu skúma len laboratórium alebo nemocnica."
	var cost = num("vaccine_cost", 250000.0)
	if float(GameState.player.cash) < cost and str(firm.get("owner", "")) == "player":
		return "Výskum stojí %s." % EconMath.eur(cost)
	if str(firm.get("owner", "")) == "player":
		GameState.player.cash = float(GameState.player.cash) - cost
	var vac: Dictionary = z().vaccine
	vac["firm"] = firm_id
	vac["name"] = str(firm.get("name", "laboratórium"))
	vac["progress"] = float(vac.get("progress", 0.0))
	_news("Výskum vakcíny začal v %s. Trvá to mesiace, ďalšie peniaze ho zrýchlia." % str(firm.get("name", "")))
	return ""

func boost_vaccine() -> String:
	var vac: Dictionary = z().vaccine
	if str(vac.get("firm", "")) == "":
		return "Najprv začni výskum."
	var cost = num("vaccine_cost", 250000.0)
	if float(GameState.player.cash) < cost:
		return "Investícia stojí %s." % EconMath.eur(cost)
	GameState.player.cash = float(GameState.player.cash) - cost
	vac["progress"] = float(vac.get("progress", 0.0)) + num("vaccine_boost_days", 15.0)
	return "Výskum sa zrýchlil."

func deploy_vaccine() -> String:
	var vac: Dictionary = z().vaccine
	if not bool(vac.get("done", false)):
		return "Vakcína ešte nie je hotová."
	vac["deployed"] = true
	GameState.player.cash = float(GameState.player.cash) + 2000000.0
	_news("Vakcína ide do štátov. Nákaza začína klesať.")
	for reg in z().regions.values():
		reg["infection"] = float(reg.get("infection", 0.0)) * 0.85
		_refresh(reg)
	return ""

func _ending(row: Dictionary) -> void:
	var vac: Dictionary = row.get("vaccine", {})
	var win = bool(vac.get("deployed", false)) or GameState.day_index >= int(num("survive_days", 720))
	var zones: Array = row.get("zones", [])
	var alive = 0
	for zone in zones:
		if bool(zone.get("alive", true)):
			alive += 1
	if not zones.is_empty() and alive == 0:
		row["ended"] = true
		row["result"] = "prehra"
		GameState.paused = true
		_news(_stats(row, "Prehra. Všetky tvoje safe zóny padli."))
		return
	if win and bool(row.get("outbreak", false)):
		row["ended"] = true
		row["result"] = "výhra"
		GameState.paused = true
		_news(_stats(row, "Výhra."))

func _stats(row: Dictionary, title: String) -> String:
	var alive = 0
	for zone in row.get("zones", []):
		if bool(zone.get("alive", true)):
			alive += 1
	var who = str(row.get("vaccine", {}).get("name", "nikto"))
	if not bool(row.get("vaccine", {}).get("done", false)):
		who = "nikto"
	return "%s Zachránených ľudí: %d. Safe zóny, ktoré držia: %d. Vakcínu vyvinul: %s." % [title, int(row.get("saved", 0)), alive, who]

func summary() -> String:
	if not active():
		return "Halloween DLC je vypnuté."
	var row = z()
	var lines = ["HALLOWEEN DLC – ZOMBIE APOKALYPSA", _stats(row, str(row.get("result", "Prebieha.")))]
	lines.append("Helikoptéry %d, stíhačky %d." % [row.get("helicopters", []).size(), row.get("fighters", []).size()])
	for zone in row.get("zones", []):
		lines.append("Zóna %s: ľudia %d, jedlo %.0f, lieky %.0f, palivo %.0f, %s" % [str(zone.get("id", "")), int(zone.get("people", 0)), float(zone.get("food", 0)), float(zone.get("meds", 0)), float(zone.get("fuel", 0)), "drží" if bool(zone.get("alive", true)) else "padla"])
	var vac: Dictionary = row.get("vaccine", {})
	lines.append("Vakcína: %.0f / %.0f dní." % [float(vac.get("progress", 0.0)), num("vaccine_days", 360.0)])
	return "\n".join(lines)

func assign_army(iso: String) -> String:
	if not active():
		return "DLC nie je zapnuté."
	if typeof(z().get("army")) != TYPE_DICTIONARY:
		z()["army"] = {}
	z().army[iso] = int(z().army.get(iso, 0)) + 1
	_news("Armáda a letectvo kryjú %s a evakuačné trasy. Okruh stíhačiek je 600 km." % str(GameState.world.get(iso, {}).get("name_sk", iso)))
	return ""
