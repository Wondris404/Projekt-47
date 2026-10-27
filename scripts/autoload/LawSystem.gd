extends Node

var international: Array = []
var by_country = {}

func _ready() -> void:
	var raw = DataLoader.laws
	international = raw.get("international", [])
	by_country = raw.get("countries", {})

func bind_world() -> void:
	for iso in GameState.world.keys():
		var c: Dictionary = GameState.world[iso]
		c.tax_rate = corporate_tax(iso)
		c.min_reserve = min_reserve(iso)
		c.wage_mult = wage_mult(iso)

func statutes(iso: String) -> Array:
	var rows = by_country.get(iso, [])
	if typeof(rows) != TYPE_ARRAY:
		return []
	return rows

func international_law() -> Array:
	return international

func set_tax(iso: String, rate: float) -> float:
	if not GameState.world.has(iso):
		return -1.0
	var applied = clampf(rate, 0.0, 0.6)
	GameState.world[iso].tax_override = applied
	return applied

func corporate_tax(iso: String) -> float:
	var country: Dictionary = GameState.world.get(iso, {})
	if country.has("tax_override"):
		return float(country.tax_override)
	for row in statutes(iso):
		if str(row.get("area", "")) == "tax":
			return float(row.get("corporate_tax", 0.21))
	return float(GameState.world.get(iso, {}).get("tax_rate", 0.21))

func minister_sheet(iso: String) -> Dictionary:
	var c: Dictionary = GameState.world.get(iso, {})
	var stability = float(c.get("stability", (1.0 - float(c.get("political_risk", 0.2))) * 100.0))
	var central: Dictionary = GameState.central.get(iso, {})
	var rate = float(central.get("base_rate", central.get("policy", 0.0)))
	var cpi = 1.0
	if GameState.markets.has(iso):
		cpi = MarketSystem.cpi_index(iso)
	var n_wars = 0
	for w in GameState.wars:
		var side_a = w.get("a", [])
		var side_b = w.get("b", [])
		if iso in side_a or iso in side_b:
			n_wars += 1
	var n_sanctions = 0
	for s in GameState.sanctions:
		if iso in str(s):
			n_sanctions += 1
	var n_ai = 0
	for firm in GameState.firms:
		if str(firm.get("owner", "")) == "ai" and not firm.get("closed", false):
			n_ai += 1
	return {
		"tax": corporate_tax(iso),
		"debt": float(c.get("debt_gdp", 0.0)),
		"stability": stability,
		"rating": stability,
		"rate": rate,
		"cpi": cpi,
		"pi": float(c.get("inflation", 0.0)),
		"unemployment": float(c.get("unemployment", 0.0)),
		"n_laws": statutes(iso).size(),
		"n_wars": n_wars,
		"n_sanctions": n_sanctions,
		"n_ai_firms": n_ai,
	}

func wage_mult(iso: String) -> float:
	for row in statutes(iso):
		if str(row.get("area", "")) == "labor":
			return float(row.get("wage_mult", 1.0))
	return 1.0

func min_reserve(iso: String) -> float:
	var floor = 0.08
	for row in international:
		if str(row.get("id", "")) == "basel":
			floor = float(row.get("min_reserve", 0.08))
	for row in statutes(iso):
		if str(row.get("area", "")) == "bank":
			floor = max(floor, float(row.get("min_reserve", floor)))
	return floor

func arms_licensed(iso: String) -> bool:
	for row in statutes(iso):
		if str(row.get("area", "")) == "arms" and bool(row.get("license", false)):
			return true
	return false

func arms_export_allowed(src: String, dst: String) -> bool:
	if not arms_licensed(src):
		return false
	if src != dst and GeopoliticsSystem.at_war(dst):
		return false
	return true

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func in_customs_union(a: String, b: String) -> bool:
	if a == b:
		return true
	var ca: Dictionary = DataLoader.countries.get(a, {})
	var cb: Dictionary = DataLoader.countries.get(b, {})
	return bool(ca.get("eu", false)) and bool(cb.get("eu", false))

func summary(iso: String) -> String:
	var text = "Medzinárodné právo\n"
	for row in international:
		text += "• %s\n" % str(row.get("name", ""))
	var cname = str(GameState.world.get(iso, {}).get("name_sk", iso))
	text += "\n%s — daň %s, rezerva banky %s\n" % [cname, EconMath.pct(corporate_tax(iso)), EconMath.pct(min_reserve(iso))]
	if bool(DataLoader.countries.get(iso, {}).get("eu", false)):
		text += "• Zmluva o fungovaní EÚ, colná únia\n"
	for row in statutes(iso):
		text += "• %s\n" % str(row.get("name", ""))
	if not arms_export_allowed(iso, iso):
		text += "Vývoz zbraní bez licencie je neplatný.\n"
	return text
