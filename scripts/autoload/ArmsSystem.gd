extends Node
# Fáza D. Bez návrhov sú arms_mult a air_mult presne 1.0.

var catalog: Dictionary = {}

func _ready() -> void:
	var f = FileAccess.open("res://data/blueprints.json", FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for row in parsed.get("blueprints", []):
		if typeof(row) == TYPE_DICTIONARY:
			catalog[str(row.get("id", ""))] = row

func _bag(key: String) -> Array:
	if typeof(GameState.ext) != TYPE_DICTIONARY:
		GameState.ext = {}
	if typeof(GameState.ext.get(key)) != TYPE_ARRAY:
		GameState.ext[key] = []
	return GameState.ext[key]

func owned() -> Array:
	return _bag("owned_bp")

func designs() -> Array:
	return _bag("designs")

func has_plant(kind: String) -> bool:
	for f in GameState.player_firms():
		if str(f.get("industry", "")) == kind and not bool(f.get("closed", false)):
			return true
	return false

func arms_mult() -> float:
	return _mult(["weapon", "tank"])

func air_mult() -> float:
	return _mult(["aircraft", "civil_air"])

func _mult(kinds: Array) -> float:
	if typeof(GameState.ext) != TYPE_DICTIONARY:
		return 1.0
	var rows = GameState.ext.get("designs", [])
	if typeof(rows) != TYPE_ARRAY or rows.is_empty():
		return 1.0
	var best = 0.0
	for d in rows:
		if str(d.get("kind", "")) in kinds:
			best = maxf(best, float(d.get("quality", 0.0)))
	if best <= 0.0:
		return 1.0
	return 1.0 + clampf(best, 0.0, 100.0) / 400.0

func buy_bp(bp_id: String) -> String:
	var row = catalog.get(bp_id, {})
	if row.is_empty():
		return "Neznámy blueprint."
	if not has_plant(str(row.get("plant", ""))):
		return "Treba %s." % str(row.get("plant", ""))
	if bp_id in owned():
		return "Blueprint už máš."
	var price = float(row.get("price", 0.0))
	if float(GameState.player.cash) < price:
		return "Blueprint stojí %s." % EconMath.eur(price)
	GameState.player.cash = float(GameState.player.cash) - price
	owned().append(bp_id)
	GameState.post_news("Kúpený blueprint %s." % str(row.get("name", bp_id)), "firmy")
	return ""

func design(bp_id: String, name: String, price: float, power: float, quality: float) -> String:
	var row = catalog.get(bp_id, {})
	if row.is_empty():
		return "Neznámy blueprint."
	if not bp_id in owned():
		return "Najprv kúp blueprint."
	if not has_plant(str(row.get("plant", ""))):
		return "Chýba výrobný závod."
	if name.strip_edges() == "":
		return "Návrh potrebuje názov."
	designs().append({
		"id": "d%d" % (designs().size() + 1),
		"bp": bp_id,
		"name": name.strip_edges(),
		"kind": str(row.get("kind", "")),
		"price": clampf(price, 1.0, 1.0e12),
		"power": clampf(power, 1.0, 100.0),
		"quality": clampf(quality, 1.0, 100.0),
	})
	GameState.post_news("Nový návrh: %s." % name.strip_edges(), "firmy")
	return ""

func sell(design_id: String) -> String:
	var rows = designs()
	for i in rows.size():
		var d: Dictionary = rows[i]
		if str(d.get("id", "")) != design_id:
			continue
		var pay = float(d.get("price", 0.0)) * float(d.get("quality", 1.0)) / 10.0
		GameState.player.cash = float(GameState.player.cash) + pay
		rows.remove_at(i)
		GameState.post_news("Štát kúpil %s za %s." % [str(d.get("name", "")), EconMath.eur(pay)], "firmy")
		return ""
	return "Návrh nenájdený."
