extends RefCounted
# M12: jednotný výnos štátu z dlhu, sadzby, rizika a napätia. Koeficienty: data/p47x_balance.json (ODHAD).

static func parts(m, iso: String) -> Array:
	var c: Dictionary = GameState.world.get(iso, {})
	var policy = float(GameState.central.get(iso, {}).get("policy", 0.03))
	var out: Array = [
		{"label": "Dlh/HDP", "value": maxf(0.0, float(c.get("debt_gdp", 0.5))) * m.num("M12", "k_debt", 0.03)},
		{"label": "Centrálna sadzba", "value": policy * m.num("M12", "k_policy", 0.33)},
		{"label": "Politické riziko", "value": float(c.get("political_risk", 0.1)) * m.num("M12", "k_political_risk", 0.35)},
		{"label": "Svetové napätie", "value": m.tension_premium(iso)},
	]
	var raw = m.sum_parts(out)
	out.append({"label": "Ohraničenie výnosu", "value": clampf(raw, m.num("M12", "min", 0.004), m.num("M12", "max", 0.5)) - raw})
	return out

static func yield_of(m, iso: String) -> float:
	return m.sum_parts(parts(m, iso))

static func loan_parts(m, iso: String) -> Array:
	var c: Dictionary = GameState.world.get(iso, {})
	var out: Array = parts(m, iso)
	out.append({"label": "Úverová marža", "value": m.num("M12", "loan_margin", 0.025)})
	out.append({"label": "Nestabilita", "value": (100.0 - clampf(float(c.get("stability", 50.0)), 0.0, 100.0)) / 100.0 * m.num("M12", "loan_stability_k", 0.05)})
	var raw = m.sum_parts(out)
	out.append({"label": "Ohraničenie sadzby", "value": clampf(raw, 0.01, 0.4) - raw})
	return out

static func monthly(m) -> void:
	var threshold = m.num("M12", "penalty_threshold", 0.15)
	var row: Dictionary = m.state("m12")
	var pen: Dictionary = row.get("gdp_pen", {})
	# Krajiny, ktoré už na štarte majú vysoký výnos (fallback dáta), sa trestajú len za zhoršenie oproti štartu.
	var base: Dictionary = row.get("base", {})
	for iso in GameState.world.keys():
		if not GameState.central.has(iso):
			continue
		var c: Dictionary = GameState.world[iso]
		var y = yield_of(m, iso)
		if not base.has(iso):
			base[iso] = y
		var over = maxf(0.0, y - maxf(threshold, float(base[iso])))
		if over > 0.0:
			c.stability = clampf(float(c.get("stability", 50.0)) - minf(over * m.num("M12", "stability_k", 50.0), m.num("M12", "stability_max_month", 5.0)), 0.0, 100.0)
		# Postih rastu nie je kumulatívny: drží sa len rozdiel oproti minulému mesiacu.
		var want = over * m.num("M12", "gdp_growth_k", 0.2)
		var had = float(pen.get(iso, 0.0))
		if absf(want - had) > 0.0:
			c.gdp_growth = float(c.get("gdp_growth", 0.02)) - (want - had)
		if want > 0.0:
			pen[iso] = want
		else:
			pen.erase(iso)
	row["gdp_pen"] = pen
	row["base"] = base
