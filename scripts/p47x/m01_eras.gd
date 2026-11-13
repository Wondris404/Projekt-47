extends RefCounted
# M01: éry a štartovacie roky. Rok 2024 = bez zmeny. Koeficienty a roky: data/p47x_balance.json (ODHAD, NEOVERENÉ).

static func eras(m) -> Dictionary:
	var e = m.balance.get("M01", {}).get("eras", {})
	return e if typeof(e) == TYPE_DICTIONARY else {}

static func years(m) -> Array:
	var out: Array = []
	for k in eras(m).keys():
		out.append(int(k))
	out.sort()
	return out

static func apply(m, cfg: Dictionary, world: Dictionary) -> void:
	var y = str(int(cfg.get("year", 2024)))
	var era: Dictionary = eras(m).get(y, {})
	if era.is_empty() or y == "2024":
		return
	var scale = clampf(float(era.get("gdp_scale", 1.0)), 0.01, 10.0)
	for iso in world.keys():
		var c: Dictionary = world[iso]
		for k in ["gdp_usd", "gdp_pc_usd", "exports_usd", "imports_usd"]:
			if c.has(k):
				c[k] = float(c[k]) * scale

static func era_year(m) -> int:
	return int(GameState.config.get("year", GameState.date.get("y", 2024)))

static func industry_lock(m, ind_id: String) -> String:
	var need = int(m.balance.get("M01", {}).get("min_year", {}).get(ind_id, 0))
	if need > 0 and int(GameState.date.get("y", 2024)) < need:
		return "Toto odvetvie v roku %d ešte neexistuje (od %d)." % [int(GameState.date.y), need]
	return ""
