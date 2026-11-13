extends RefCounted
# M25: proxy vojny – hráč dodáva zbrane alebo úvery jednej strane vojny. Koeficienty: data/p47x_balance.json (ODHAD).
# Zjednodušenie: PMC dodávky idú cez existujúce Society.deploy, tu len zbrane a úvery.

static func _war(war_id: String) -> Dictionary:
	for w in GameState.wars:
		if str(w.get("id", "")) == war_id:
			return w
	return {}

static func contracts(m) -> Array:
	var c = m.peek("proxy").get("contracts", [])
	return c if typeof(c) == TYPE_ARRAY else []

static func supply(m, war_id: String, side_iso: String, kind: String, amount_month: float) -> String:
	var w = _war(war_id)
	if w.is_empty():
		return "Vojna neexistuje."
	if not (side_iso in w.get("a", []) or side_iso in w.get("b", [])):
		return "Krajina vo vojne nebojuje."
	if not (kind in ["arms", "credit"]):
		return "Neznámy druh dodávky."
	if EconMath.is_bad(amount_month) or amount_month < m.num("M25", "min_amount", 10000.0):
		return "Príliš malá dodávka."
	if kind == "arms" and not (ArmsSystem.has_plant("arms_plant") or ArmsSystem.has_plant("aircraft_plant")):
		return "Na dodávky zbraní potrebuješ zbrojovku alebo letecký závod."
	if kind == "credit" and BankingSystem._player_bank().is_empty():
		return "Na úvery potrebuješ vlastnú banku."
	var row = m.state("proxy")
	if typeof(row.get("contracts")) != TYPE_ARRAY:
		row["contracts"] = []
	row.contracts.append({"war_id": war_id, "side_iso": side_iso, "kind": kind, "amount_month": amount_month, "months": 0})
	GameState.post_news("Proxy dodávka (%s) pre %s: %s mesačne." % ["zbrane" if kind == "arms" else "úver", str(GameState.world.get(side_iso, {}).get("name_sk", side_iso)), EconMath.eur(amount_month)], "politika")
	return ""

static func concession_mult(m, iso: String) -> float:
	var until = int(m.peek("proxy").get("concessions", {}).get(iso, -1))
	return m.num("M25", "concession_mult", 0.7) if until > GameState.day_index else 1.0

static func monthly(m) -> void:
	var list = contracts(m)
	if list.is_empty():
		return
	var row = m.state("proxy")
	var keep: Array = []
	var home = str(GameState.player.get("home", ""))
	for c in list:
		var w = _war(str(c.war_id))
		var side = str(c.side_iso)
		if w.is_empty():
			# Vojna skončila: strana odmení dodávateľa koncesiou (lacnejšie zakladanie firiem).
			if typeof(row.get("concessions")) != TYPE_DICTIONARY:
				row["concessions"] = {}
			row.concessions[side] = GameState.day_index + int(m.num("M25", "concession_months", 60)) * 30
			GameState.post_news("Koncesia v %s: zakladanie firiem −%d %% na %d mesiacov." % [str(GameState.world.get(side, {}).get("name_sk", side)), roundi((1.0 - m.num("M25", "concession_mult", 0.7)) * 100.0), int(m.num("M25", "concession_months", 60))], "politika")
			continue
		var amount = float(c.amount_month)
		if str(c.kind) == "arms":
			var income = amount * (1.0 + m.num("M25", "intensity_bonus", 0.1) * float(w.get("intensity", 0.5)))
			GameState.player.cash = float(GameState.player.cash) + income - amount * m.num("M25", "cost_share", 0.8)
			if not LawSystem.arms_export_allowed(home, side) and m.roll("proxy", "%s|%s" % [c.war_id, side]) < m.num("M25", "detect_chance", 0.25):
				GameState.player.rating = int(GameState.player.get("rating", 55)) - int(m.num("M25", "detect_rating", 8))
				var enemies: Array = w.get("b", []) if side in w.get("a", []) else w.get("a", [])
				for e in enemies:
					GeopoliticsSystem.set_relation(home, str(e), GeopoliticsSystem.relation(home, str(e)) - int(m.num("M25", "detect_relation", 10)))
				GameState.post_news("Odhalené nelegálne dodávky zbraní pre %s: rating −%d, zmluva končí." % [side, int(m.num("M25", "detect_rating", 8))], "politika")
				continue
		else:
			var bank = BankingSystem._player_bank()
			if bank.is_empty() or SovereignLoans.lend(bank, side, amount, SovereignLoans.suggested_rate(side), int(m.num("M25", "credit_months", 24))) != "":
				GameState.post_news("Proxy úver pre %s sa tento mesiac nepodaril." % side, "politika")
		GeopoliticsSystem.set_relation(home, side, GeopoliticsSystem.relation(home, side) + int(m.num("M25", "gratitude_month", 2)))
		m.add_tension(m.num("M25", "tension_month", 1.0), home, "Proxy dodávka pre %s" % side)
		c.months = int(c.months) + 1
		keep.append(c)
	row.contracts = keep
