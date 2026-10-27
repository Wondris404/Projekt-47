extends Node

func setup() -> void:
	GameState.relations.clear()
	GameState.wars.clear()
	for iso in DataLoader.country_ids:
		var c: Dictionary = DataLoader.countries[iso]
		for b in c.get("borders", []):
			_add(iso, str(b), 22)
		if c.get("eu", false):
			for other in DataLoader.country_ids:
				if other != iso and DataLoader.countries[other].get("eu", false):
					_add(iso, other, 18)
	for w in DataLoader.wars:
		if int(w.get("start", 0)) < 1945:
			continue
		var delta = -28
		if int(w.get("end", 0)) >= 1990 or int(w.get("end", 0)) == 0:
			delta = -48
		for a in w.get("side_a", []):
			for b in w.get("side_b", []):
				if DataLoader.countries.has(str(a)) and DataLoader.countries.has(str(b)):
					_add(str(a), str(b), delta)
	for pair in DataLoader.tension_seed:
		var a = str(pair.get("a", ""))
		var b = str(pair.get("b", ""))
		if DataLoader.countries.has(a) and DataLoader.countries.has(b):
			_add(a, b, int(pair.get("delta", -20)))
	if GameState.config.get("hot", false):
		for iso in DataLoader.country_ids:
			for b in DataLoader.countries[iso].get("borders", []):
				_add(iso, str(b), -12)

func _key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a

func _add(a: String, b: String, delta: int) -> void:
	if a == "" or b == "" or a == b:
		return
	var k = _key(a, b)
	GameState.relations[k] = int(GameState.relations.get(k, 8)) + delta

func relation(a: String, b: String) -> int:
	if a == b:
		return 100
	return int(GameState.relations.get(_key(a, b), 8))

func set_relation(a: String, b: String, value: int) -> void:
	GameState.relations[_key(a, b)] = clampi(value, -100, 100)

func sanction_key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a

func is_sanctioned(a: String, b: String) -> bool:
	return GameState.sanctions.has(sanction_key(a, b))

func _has_pair(bucket: Array, a: String, b: String) -> bool:
	return bucket.has(sanction_key(a, b))

func _toggle_pair(bucket_name: String, target: String, on: bool, news: String) -> String:
	var home = str(GameState.player.get("home", ""))
	if target == "" or target == home or not DataLoader.countries.has(target):
		return "Neplatná krajina."
	var key = sanction_key(home, target)
	var bucket: Array = GameState.get(bucket_name)
	if on:
		if bucket.has(key):
			return "Už platí."
		bucket.append(key)
	else:
		if not bucket.has(key):
			return "Nič také neplatí."
		bucket.erase(key)
	GameState.post_news(news % target)
	return ""

func impose_embargo(target: String) -> String:
	var err = _toggle_pair("embargoes", target, true, "Embargo voči %s.")
	if err == "":
		var home = str(GameState.player.get("home", ""))
		set_relation(home, target, relation(home, target) - 20)
	return err

func lift_embargo(target: String) -> String:
	return _toggle_pair("embargoes", target, false, "Embargo voči %s je zrušené.")

func form_alliance(target: String) -> String:
	var err = _toggle_pair("alliances", target, true, "Spojenectvo s %s.")
	if err == "":
		set_relation(str(GameState.player.get("home", "")), target, mini(100, relation(str(GameState.player.get("home", "")), target) + 30))
	return err

func break_alliance(target: String) -> String:
	return _toggle_pair("alliances", target, false, "Spojenectvo s %s končí.")

func sign_treaty(target: String) -> String:
	return _toggle_pair("treaties", target, true, "Obchodná zmluva s %s.")

func break_treaty(target: String) -> String:
	return _toggle_pair("treaties", target, false, "Obchodná zmluva s %s končí.")

func grant_relief(target: String) -> String:
	return _toggle_pair("reliefs", target, true, "Colná úľava pre %s.")

func revoke_relief(target: String) -> String:
	return _toggle_pair("reliefs", target, false, "Colná úľava pre %s končí.")

func declare_war(target: String) -> String:
	var home = str(GameState.player.get("home", ""))
	if target == "" or target == home or not DataLoader.countries.has(target):
		return "Neplatná krajina."
	if _opponents(home, target):
		return "Vojna už trvá."
	_start_war(home, target)
	return ""

func is_un_sanctioned(iso: String) -> bool:
	return GameState.un_sanctions.has("UN|" + iso)

func security_council(target: String) -> String:
	if target == "" or not DataLoader.countries.has(target):
		return "Neplatná krajina."
	var key = "UN|" + target
	if not GameState.un_sanctions.has(key):
		GameState.un_sanctions.append(key)
	GameState.world_events.append({"type": "un_sanction", "target": target, "day": GameState.day_index})
	GameState.post_news("Bezpečnostná rada uvalila sankcie na %s." % target)
	return ""

func lift_security_council(target: String) -> String:
	var key = "UN|" + target
	if not GameState.un_sanctions.has(key):
		return "Žiadna sankcia BR."
	GameState.un_sanctions.erase(key)
	GameState.post_news("Bezpečnostná rada zrušila sankcie na %s." % target)
	return ""

func war_between(a: String, b: String) -> Dictionary:
	for w in GameState.wars:
		var sa: Array = w.get("a", [])
		var sb: Array = w.get("b", [])
		if (a in sa and b in sb) or (a in sb and b in sa):
			return w
	return {}

func make_peace(target: String) -> String:
	var home = str(GameState.player.get("home", ""))
	var ended = false
	var left: Array = []
	var ended_wars: Array = []
	for w in GameState.wars:
		if _opponents(home, target) and ((home in w.get("a", []) and target in w.get("b", [])) or (home in w.get("b", []) and target in w.get("a", []))):
			ended = true
			ended_wars.append(w)
			GameState.post_news("Mier: %s." % w.get("name", target))
		else:
			left.append(w)
	if not ended:
		return "Žiadna vojna."
	GameState.wars = left
	for ew in ended_wars:
		_war_recovery(ew)
	set_relation(home, target, -20)
	return ""

func relation_rows() -> Array:
	var home = str(GameState.player.get("home", "SK"))
	var rows: Array = []
	for iso in DataLoader.country_ids:
		if str(iso) == home:
			continue
		var flags = []
		if is_sanctioned(home, str(iso)):
			flags.append("sankcia")
		if _has_pair(GameState.embargoes, home, str(iso)):
			flags.append("embargo")
		if _has_pair(GameState.alliances, home, str(iso)):
			flags.append("spojenec")
		if _has_pair(GameState.treaties, home, str(iso)):
			flags.append("zmluva")
		if _has_pair(GameState.reliefs, home, str(iso)):
			flags.append("clo")
		if _opponents(home, str(iso)):
			flags.append("vojna")
		rows.append({"iso": str(iso), "relation": relation(home, str(iso)), "flags": flags, "tariff": tariff(home, str(iso))})
	return rows

func impose_sanction(target: String) -> String:
	var home = str(GameState.player.get("home", ""))
	if target == "" or target == home or not DataLoader.countries.has(target):
		return "Neplatná krajina."
	var key = sanction_key(home, target)
	if GameState.sanctions.has(key):
		return "Sankcia už platí."
	GameState.sanctions.append(key)
	set_relation(home, target, relation(home, target) - 25)
	GameState.post_story("sanction", "Sankcia voči %s. Obchod je obmedzený." % target)
	return ""

func lift_sanction(target: String) -> String:
	var home = str(GameState.player.get("home", ""))
	var key = sanction_key(home, target)
	if not GameState.sanctions.has(key):
		return "Žiadna sankcia."
	GameState.sanctions.erase(key)
	GameState.post_news("Sankcia voči %s je zrušená." % target)
	return ""

func blocked(a: String, b: String) -> bool:
	if a == b:
		return false
	if is_sanctioned(a, b) or _has_pair(GameState.embargoes, a, b) or is_un_sanctioned(a) or is_un_sanctioned(b):
		return true
	if relation(a, b) <= -60:
		return true
	return _opponents(a, b)

func _opponents(a: String, b: String) -> bool:
	for w in GameState.wars:
		var sa: Array = w.get("a", [])
		var sb: Array = w.get("b", [])
		if (a in sa and b in sb) or (a in sb and b in sa):
			return true
	return false

func at_war(iso: String) -> bool:
	for w in GameState.wars:
		if iso in w.get("a", []) or iso in w.get("b", []):
			return true
	return false

func war_intensity_world() -> float:
	var n = 0.0
	for w in GameState.wars:
		n += float(w.get("intensity", 0.5))
	return min(n, 2.5)

func conflict_demand(hot: bool, cid: String) -> float:
	if not hot:
		return 1.0
	if cid == "arms" or cid == "weapons":
		return 3.1
	if cid == "chemicals":
		return 1.55
	if cid == "pmc_services" or cid == "pmc":
		return 2.6
	return 1.0

func supply_mult(iso: String, _cid: String) -> float:
	var m = 1.0
	if at_war(iso):
		m *= 0.82
	if bool(GameState.world.get(iso, {}).get("infra_damage", false)):
		m *= 0.75
	return m

func apply_war_shock(c: Dictionary) -> Dictionary:
	var before_infl = float(c.get("inflation", 0.02))
	c.inflation_at_shock = before_infl
	c.inflation = before_infl + 0.03
	var tb = float(c.get("trade_balance", 0.0))
	c.trade_balance = tb - abs(tb) * 0.25 - 1.0
	c.infra_damage = true
	var iso = str(c.get("iso2", c.get("id", "")))
	for site in GameState.sites:
		if str(site.get("iso", "")) == iso and str(site.get("kind", "")) == "infra" and not bool(site.get("damaged", false)):
			site.damaged = true
			break
	return c

# DEAD: duplikat EventSystem.demand_mult, bez volajuceho (etapa 0: nezmazane, len oznacene)
func demand_mult(iso: String, cid: String) -> float:
	var m = 1.0
	var hot = at_war(iso)
	var near = false
	if not hot:
		var c: Dictionary = DataLoader.countries.get(iso, {})
		for b in c.get("borders", []):
			if at_war(str(b)):
				near = true
				break
	if hot or near or war_intensity_world() > 0.4:
		if hot:
			m *= conflict_demand(true, cid)
		elif cid == "arms" or cid == "weapons":
			m *= 1.45
		elif cid == "chemicals":
			m *= 1.12
		elif cid == "pmc_services" or cid == "pmc":
			m *= 1.3
		if cid == "crude_oil":
			m *= 1.18 if hot else 1.06
		elif cid in ["automobiles", "electronics", "construction"]:
			m *= 0.78 if hot else 0.92
	if hot and cid == "food_service":
		m *= 0.88
	return m

func tariff(a: String, b: String) -> float:
	if a == b:
		return 0.0
	if blocked(a, b):
		return 0.85
	var ca: Dictionary = DataLoader.countries.get(a, {})
	var cb: Dictionary = DataLoader.countries.get(b, {})
	var ba = str(ca.get("trade_bloc", ""))
	if _has_pair(GameState.alliances, a, b) or _has_pair(GameState.treaties, a, b):
		return 0.0
	if ba != "" and ba == str(cb.get("trade_bloc", "")):
		return 0.0
	if _has_pair(GameState.reliefs, a, b):
		return 0.01
	return 0.045

func monthly() -> void:
	if not GameState.config.get("wars", true):
		_drift()
		return
	var hot_bonus = 0.05 if GameState.config.get("hot", false) else 0.0
	var keys: Array = GameState.relations.keys()
	for k in keys:
		if float(GameState.relations[k]) > -50:
			continue
		var parts: PackedStringArray = str(k).split("|")
		if parts.size() != 2:
			continue
		if _opponents(parts[0], parts[1]):
			continue
		var chance = 0.02 + hot_bonus
		if float(GameState.relations[k]) < -75:
			chance += 0.04
		chance *= Difficulty.ai_mult()  # JUAN4: agresivita AI
		if GameState.rng.randf() < chance:
			_start_war(parts[0], parts[1])
	# days sa pocitaju len v daily() (+1/den); mesacne sa uz nepripocitava 30 (dvojita inkrementacia)
	var to_end: Array = []
	for w in GameState.wars:
		if GameState.rng.randf() < 0.06 + float(w.get("days", 0)) / 8000.0:
			to_end.append(w)
	for w2 in to_end:
		_end_war(w2)
	_drift()

func _drift() -> void:
	for k in GameState.relations.keys():
		var v = float(GameState.relations[k])
		if abs(v) < 3.0:
			continue
		GameState.relations[k] = int(round(v * 0.985))

const WAR_GDP_PEN = 0.015

func _start_war(a: String, b: String) -> void:
	if not DataLoader.countries.has(a) or not DataLoader.countries.has(b):
		return
	var name = "%s – %s" % [DataLoader.countries[a].get("name_sk", a), DataLoader.countries[b].get("name_sk", b)]
	GameState.wars.append({
		"id": _next_war_id(),
		"name": name,
		"a": [a],
		"b": [b],
		"intensity": 0.55 + GameState.rng.randf() * 0.3,
		"days": 0,
	})
	set_relation(a, b, -85)
	for iso in [a, b]:
		var c: Dictionary = GameState.world[iso]
		apply_war_shock(c)
		c.gdp_growth = float(c.gdp_growth) - WAR_GDP_PEN
		c.war_gdp_pen = float(c.get("war_gdp_pen", 0.0)) + WAR_GDP_PEN  # etapa 1: evidencia odpocitaneho, aby sa vratilo presne
		c.political_risk = EconMath.cl(float(c.political_risk) + 0.08, 0.02, 0.9)
	GameState.post_story("war", "Vojna: %s. Obchod stojí, zbrane a chémia zdražujú." % name)

func _next_war_id() -> String:
	var top = -1
	for w in GameState.wars:
		var id = str(w.get("id", ""))
		if id.begins_with("w") and id.substr(1).is_valid_int():
			top = maxi(top, int(id.substr(1)))
	return "w%d" % (top + 1)

func _end_war(w: Dictionary) -> void:
	for i in GameState.wars.size():
		if is_same(GameState.wars[i], w):
			GameState.wars.remove_at(i)
			break
	GameState.post_news("Prímerie: %s." % w.get("name", "konflikt"))
	_war_recovery(w)

# etapa 1, krok 5: po mieri sa vratia trvale dopady vojny (inak by sa ceny nevratili k zakladu).
# gdp_growth: vrati sa presne to, co _start_war odpocital za TUTO vojnu (evidencia war_gdp_pen; pri starom save bez nej
# sa predpoklada WAR_GDP_PEN za kazdu vojnu). infra_damage sa ruší az ked krajina nema ziadnu dalsiu vojnu.
# Nevracia sa: inflacia +0.03 a trade_balance z apply_war_shock, political_risk +0.08, site.damaged (opravy = povodna mechanika).
func _war_recovery(w: Dictionary) -> void:
	for iso in w.get("a", []) + w.get("b", []):
		var key = str(iso)
		if not GameState.world.has(key):
			continue
		var c: Dictionary = GameState.world[key]
		var remaining = 0
		for w2 in GameState.wars:
			if key in w2.get("a", []) or key in w2.get("b", []):
				remaining += 1
		var pen = float(c.get("war_gdp_pen", WAR_GDP_PEN * float(remaining + 1)))
		var back = minf(WAR_GDP_PEN, pen)
		if back > 0.0:
			c.gdp_growth = float(c.get("gdp_growth", 0.02)) + back
			c.war_gdp_pen = pen - back
		if remaining == 0:
			c.infra_damage = false

func daily() -> void:
	for w in GameState.wars:
		w.days = int(w.get("days", 0)) + 1
