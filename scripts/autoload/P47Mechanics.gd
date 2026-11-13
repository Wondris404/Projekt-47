extends Node
# Voliteľné mechaniky; žiadny zápis stavu ani RNG pri čítaní alebo vypnutí.
# ODHAD: všetky nové bilančné koeficienty sú v data/p47x_balance.json.
const M12 = preload("res://scripts/p47x/m12_sovereign.gd")
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

func tension_premium(_iso: String) -> float:
	return 0.0

func monthly() -> void:
	if active("M12"):
		M12.monthly(self)
