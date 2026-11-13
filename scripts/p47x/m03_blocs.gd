extends RefCounted
# M03: bloky Západ/Východ/Nezúčastnení na jednej osi príslušnosti 0 (Východ) – 100 (Západ).
# Platí len do roku cold_war_end; potom sú všetci nezúčastnení. Koeficienty: data/p47x_balance.json (ODHAD).

static func cold_war(m) -> bool:
	return int(GameState.date.get("y", 2024)) <= int(m.num("M03", "cold_war_end", 1991))

static func default_align(m, iso: String) -> float:
	var section: Dictionary = m.balance.get("M03", {})
	if iso in section.get("west", []):
		return m.num("M03", "west_align", 85.0)
	if iso in section.get("east", []):
		return m.num("M03", "east_align", 15.0)
	return 50.0

static func align(m, iso: String) -> float:
	var row = m.peek("blocs").get("align", {})
	return float(row.get(iso, default_align(m, iso)))

static func bloc_of_align(m, a: float) -> String:
	if a >= m.num("M03", "west_at", 65.0):
		return "west"
	if a <= m.num("M03", "east_at", 35.0):
		return "east"
	return "nam"

static func bloc(m, iso: String) -> String:
	if not cold_war(m):
		return "nam"
	return bloc_of_align(m, align(m, iso))

static func opposite(m, a: String, b: String) -> bool:
	var ba = bloc(m, a)
	var bb = bloc(m, b)
	return ba != "nam" and bb != "nam" and ba != bb

static func tariff_extra(m, a: String, b: String) -> float:
	return m.num("M03", "opposite_tariff", 0.06) if opposite(m, a, b) else 0.0

static func restricted(m, a: String, b: String) -> bool:
	return cold_war(m) and opposite(m, a, b) and absf(align(m, a) - align(m, b)) > m.num("M03", "restrict_gap", 60.0)

static func monthly(m) -> void:
	if not cold_war(m):
		return
	var row = m.state("blocs")
	if typeof(row.get("align")) != TYPE_DICTIONARY:
		row["align"] = {}
	var home = str(GameState.player.get("home", ""))
	var home_bloc = bloc(m, home)
	var dir = 1.0 if home_bloc == "west" else (-1.0 if home_bloc == "east" else 0.0)
	for iso in GameState.world.keys():
		var before = bloc(m, iso)
		var a = align(m, iso)
		if iso != home:
			a += dir * PoliticsSystem.influence(iso) * m.num("M03", "influence_k", 0.02)
		var pol: Dictionary = GameState.ext.get("politics", {}).get(iso, {}) if typeof(GameState.ext.get("politics", {})) == TYPE_DICTIONARY else {}
		if str(pol.get("gov", "")) == "communist" and a > m.num("M03", "east_at", 35.0):
			a -= m.num("M03", "communist_drift", 2.0)
		a = clampf(a, 0.0, 100.0)
		if absf(a - default_align(m, iso)) > 0.0001 or row.align.has(iso):
			row.align[iso] = a
		var after = bloc(m, iso)
		if after != before:
			GameState.post_news("%s mení blok: %s → %s." % [str(GameState.world[iso].get("name_sk", iso)), _name(before), _name(after)], "politika")

static func _name(b: String) -> String:
	return {"west": "Západ", "east": "Východ", "nam": "Nezúčastnení"}.get(b, b)

static func label(m, iso: String) -> String:
	return "Blok: %s (príslušnosť %.0f)" % [_name(bloc(m, iso)), align(m, iso)] if cold_war(m) else ""
