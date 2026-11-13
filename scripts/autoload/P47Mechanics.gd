extends Node
# Voliteľné mechaniky; žiadny zápis stavu ani RNG pri čítaní alebo vypnutí.
# ODHAD: všetky nové bilančné koeficienty sú v data/p47x_balance.json.
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
