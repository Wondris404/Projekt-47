extends RefCounted
# M09: Eureka. Viditeľná podmienka s progresom; splnenie zníži cenu a čas výskumu (ODHAD v data/p47x_balance.json).

static func defs(m) -> Dictionary:
	var section = m.balance.get("M09", {})
	var e = section.get("eureka", {}) if typeof(section) == TYPE_DICTIONARY else {}
	return e if typeof(e) == TYPE_DICTIONARY else {}

static func has_eureka(m, rid: String) -> bool:
	return m.active("M09") and bool(m.peek("m09").get("got", {}).get(rid, false))

static func mult(m, rid: String) -> float:
	return 1.0 - clampf(m.num("M09", "discount", 0.4), 0.0, 0.9) if has_eureka(m, rid) else 1.0

static func _player_firms(arg: String) -> int:
	var kinds = arg.split(",", false) if arg != "" else PackedStringArray()
	var n = 0
	for f in GameState.firms:
		if str(f.get("owner", "")) != "player":
			continue
		if kinds.is_empty() or str(f.get("industry", "")) in kinds:
			n += 1
	return n

# Vráti [aktuálne, cieľ] pre progres bar.
static func progress(m, rid: String) -> Array:
	var d: Dictionary = defs(m).get(rid, {})
	if d.is_empty():
		return [0.0, 0.0]
	var n = float(d.get("n", 1))
	match str(d.get("type", "")):
		"count_industry":
			return [float(_player_firms(str(d.get("arg", "")))), n]
		"firms_total":
			return [float(_player_firms("")), n]
		"cash_over":
			return [float(GameState.player.get("cash", 0.0)), n]
		"rating_over":
			return [float(GameState.player.get("rating", 0.0)), n]
		"own_state":
			var emp = GameState.ext.get("emp", {})
			return [float(emp.get("states", []).size() if typeof(emp) == TYPE_DICTIONARY else 0), n]
	return [0.0, n]

static func text(m, rid: String) -> String:
	if not m.active("M09"):
		return ""
	var d: Dictionary = defs(m).get(rid, {})
	if d.is_empty():
		return ""
	if has_eureka(m, rid):
		return "Eureka splnená: −%d %% ceny a času." % roundi(m.num("M09", "discount", 0.4) * 100.0)
	var pr = progress(m, rid)
	return "Eureka (−%d %% ceny a času): %s %s / %s" % [roundi(m.num("M09", "discount", 0.4) * 100.0), str(d.get("text", "")), _fmt(pr[0]), _fmt(pr[1])]

static func _fmt(v: float) -> String:
	return EconMath.eur(v) if v >= 100000.0 else str(int(v))

static func monthly(m) -> void:
	var done: Array = GameState.player.get("done", [])
	var running: Array = GameState.research_running()
	for rid in defs(m).keys():
		if rid in done or has_eureka(m, rid):
			continue
		var pr = progress(m, rid)
		if float(pr[1]) <= 0.0 or float(pr[0]) < float(pr[1]):
			continue
		var row = m.state("m09")
		if typeof(row.get("got")) != TYPE_DICTIONARY:
			row["got"] = {}
		row.got[rid] = true
		# Spustený výskum: zľava sa započíta zo zostávajúcich dní.
		for slot in running:
			if str(slot.get("id", "")) == rid:
				slot.left = maxi(1, int(ceil(float(slot.left) * mult(m, rid))))
		GameState.post_news("Eureka: %s je o %d %% lacnejší a rýchlejší." % [str(GameState.research_def(rid).get("name", rid)), roundi(m.num("M09", "discount", 0.4) * 100.0)])
