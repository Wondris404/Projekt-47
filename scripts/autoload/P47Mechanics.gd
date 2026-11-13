extends Node
# Voliteľné mechaniky; žiadny zápis stavu ani RNG pri čítaní alebo vypnutí.
# ODHAD: všetky nové bilančné koeficienty sú v data/p47x_balance.json.
const M12 = preload("res://scripts/p47x/m12_sovereign.gd")
const M09 = preload("res://scripts/p47x/m09_eureka.gd")
const M02 = preload("res://scripts/p47x/m02_tension.gd")
const M03 = preload("res://scripts/p47x/m03_blocs.gd")
const M25 = preload("res://scripts/p47x/m25_proxy.gd")
var balance: Dictionary = {}

func _ready() -> void:
	var f = FileAccess.open("res://data/p47x_balance.json", FileAccess.READ)
	if f != null:
		var parsed = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			balance = parsed

func active(id: String) -> bool:
	var root = GameState.ext.get("p47x", {})
	if typeof(root) == TYPE_DICTIONARY:
		var flags = root.get("enabled", {})
		if typeof(flags) == TYPE_DICTIONARY and flags.has(id):
			return bool(flags[id])
	var section = balance.get(id, {})
	return typeof(section) == TYPE_DICTIONARY and bool(section.get("enabled", false))

func num(id: String, key: String, fallback: float) -> float:
	var section = balance.get(id, {})
	if typeof(section) != TYPE_DICTIONARY:
		return fallback
	var v = section.get(key, fallback)
	if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
		return fallback
	return float(v) if is_finite(float(v)) else fallback

func sum_parts(parts: Array) -> float:
	var total = 0.0
	for part in parts:
		total += float(part.get("value", 0.0))
	return total

func breakdown_text(parts: Array, percent: bool = true) -> String:
	if not active("M44") or parts.is_empty():
		return ""
	var lines: PackedStringArray = []
	for part in parts:
		var value = float(part.get("value", 0.0))
		lines.append("%s: %+.4f%s" % [str(part.get("label", "")), value * 100.0 if percent else value, " p. b." if percent else ""])
	return "\n".join(lines)

# Stav mechaník je len v GameState.ext.p47x; vytvorí sa až pri prvom zápise.
func state(key: String) -> Dictionary:
	if typeof(GameState.ext.get("p47x")) != TYPE_DICTIONARY:
		GameState.ext["p47x"] = {}
	var root: Dictionary = GameState.ext.p47x
	if typeof(root.get(key)) != TYPE_DICTIONARY:
		root[key] = {}
	return root[key]

func peek(key: String) -> Dictionary:
	var root = GameState.ext.get("p47x", {})
	if typeof(root) != TYPE_DICTIONARY or typeof(root.get(key)) != TYPE_DICTIONARY:
		return {}
	return root[key]

# Deterministické RNG podľa tagu: nemení GameState.rng ani sekvenciu iných systémov.
func roll(tag: String, salt: String = "") -> float:
	var r = RandomNumberGenerator.new()
	r.seed = hash("%s|%s|%s|%d" % [str(GameState.config.get("seed", 47)), tag, salt, GameState.day_index])
	return r.randf()

func set_enabled(id: String, on: bool) -> void:
	var root = GameState.ext.get("p47x", {})
	if typeof(root) != TYPE_DICTIONARY:
		root = {}
	var flags = root.get("enabled", {})
	if typeof(flags) != TYPE_DICTIONARY:
		flags = {}
	flags[id] = on
	root["enabled"] = flags
	GameState.ext["p47x"] = root

# Testy: zapne len vymenované mechaniky, ostatné vypne (uložené v ext.p47x.enabled).
func only(ids: Array) -> void:
	for id in balance.keys():
		if str(id).begins_with("M"):
			set_enabled(str(id), str(id) in ids)

func tension_premium(iso: String) -> float:
	if not active("M02"):
		return 0.0
	return minf(num("M12", "tension_cap", 0.05), M02.value(self) / 100.0 * num("M12", "tension_cap", 0.05)) + M02.by_iso(self, iso) / 100.0 * num("M12", "tension_iso_k", 0.02)

func add_tension(amount: float, iso: String, reason: String) -> void:
	if active("M02"):
		M02.add(self, amount, iso, reason)

func tension_demand_mult(cid: String) -> float:
	return M02.demand_mult(self, cid) if active("M02") else 1.0

# Akcia, ktorá zníži DEFCON, chce potvrdenie: druhé rovnaké stlačenie v ten istý deň ju vykoná.
func confirm_needed(action: String, target: String) -> String:
	if not active("M02") or not M02.would_lower_defcon(self, action):
		return ""
	var row = state("tension_confirm")
	var key = "%s|%s|%d" % [action, target, GameState.day_index]
	if str(row.get("pending", "")) == key:
		row.erase("pending")
		return ""
	row["pending"] = key
	return "Pozor: akcia zníži DEFCON na %d. Stlač ju znova na potvrdenie." % M02.defcon_of(self, M02.value(self) + M02.action_amount(self, action))

func status_text() -> String:
	if not active("M02"):
		return ""
	return "DEFCON %d · napätie %.0f" % [M02.defcon(self), M02.value(self)]

func research_mult(rid: String) -> float:
	return M09.mult(self, rid)

func bloc_tariff(a: String, b: String) -> float:
	return M03.tariff_extra(self, a, b) if active("M03") else 0.0

func bloc_restricted(a: String, b: String) -> bool:
	return active("M03") and M03.restricted(self, a, b)

func proxy_supply(war_id: String, side_iso: String, kind: String, amount_month: float) -> String:
	if not active("M25"):
		return "Proxy dodávky sú vypnuté."
	return M25.supply(self, war_id, side_iso, kind, amount_month)

func concession_mult(iso: String) -> float:
	return M25.concession_mult(self, iso) if active("M25") else 1.0

func monthly() -> void:
	if active("M25"):
		M25.monthly(self)
	if active("M03"):
		M03.monthly(self)
	if active("M02"):
		M02.monthly(self)
	if active("M12"):
		M12.monthly(self)
	if active("M09"):
		M09.monthly(self)
