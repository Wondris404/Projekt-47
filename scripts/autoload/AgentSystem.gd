extends Node

const ADJ = ["Dunajská", "Karpatská", "Severná", "Prístavná", "Korunná", "Nová", "Horská", "Obchodná", "Úverná", "Mestská", "Nížinná", "Kráľovská"]

func spawn_ai() -> void:
	var n_banks = 0
	for i in DataLoader.country_ids.size():
		if i >= 28:
			break
		var iso: String = DataLoader.country_ids[i]
		var banks_here = 2 if i < 10 else 1
		for b in banks_here:
			_make_ai_bank(iso, n_banks)
			n_banks += 1
		if i < 18:
			_make_ai_firms(iso)

func _make_ai_bank(iso: String, idx: int) -> void:
	var c: Dictionary = GameState.world[iso]
	var equity = max(2.0e6, float(c.gdp_usd) / GameState.usd_per_eur * 0.000015)
	var policy = float(GameState.central[iso].policy)
	var risk = float(c.political_risk)
	GameState.banks.append({
		"id": "ai_b%d" % idx,
		"name": "%s banka %s" % [ADJ[idx % ADJ.size()], c.get("name_sk", iso)],
		"owner": "ai",
		"country": iso,
		"equity": equity,
		"reserves": equity * 3.0,
		"deposits": equity * 8.0,
		"npc_loans": equity * 6.0,
		"explicit": 0.0,
		"deposit_rate": policy * 0.55,
		"lending_rate": policy + 0.028 + risk * 0.04,
		"strictness": 0.45,
		"confidence": 0.72,
		"owe_cb": 0.0,
		"defaults_total": 0.0,
		"profit_recent": 0.0,
		"failed": false,
	})

func _make_ai_firms(iso: String) -> void:
	var ranked: Array = []
	var endow: Dictionary = GameState.world[iso].get("endow", {})
	for ind_id in DataLoader.industry_ids:
		var ind: Dictionary = DataLoader.industries[ind_id]
		var recipe: Dictionary = DataLoader.recipes.get(ind.get("recipe", ""), {})
		if recipe.get("trade", false) or bool(ind.get("juan5", false)):  # JUAN5: nove typy podnikov AI statne firmy nezakladaju (zachova spravanie)
			continue
		var key = str(recipe.get("endow", ""))
		var score = float(endow.get(key, 0.8)) if key != "" else 0.7
		if float(ind.get("cost", 1e9)) > float(GameState.world[iso].gdp_usd) / GameState.usd_per_eur * 0.002:
			continue
		ranked.append({"id": ind_id, "score": score, "cost": float(ind.cost)})
	ranked.sort_custom(func(a, b): return float(a.score) > float(b.score))
	var made = 0
	for row in ranked:
		if made >= 2:
			break
		if float(row.score) < 0.9 and made > 0:
			break
		var ind: Dictionary = DataLoader.industries[row.id]
		var firm = {
			"id": "ai_%s_%d" % [iso, made],
			"name": "%s %s" % [GameState.world[iso].get("name_sk", iso), ind.get("name", "firma")],
			"owner": "ai",
			"country": iso,
			"industry": row.id,
			"cash": float(ind.cost) * 0.35,
			"closed": false,
			"shares": 1000,
			"public": 0.4,
			"share_price": float(ind.cost) / 1000.0,
			"history": [],
			"distress": 0,
			"facilities": [_facility(ind, iso)],
		}
		GameState.firms.append(firm)
		made += 1

func _facility(ind: Dictionary, iso: String) -> Dictionary:
	return {
		"recipe": ind.get("recipe", ""),
		"country": iso,
		"scale": 1.0,
		"auto": true,
		"util": 1.0,
		"zone": ind.get("zone", "industrial"),
		"inventory": {},
		"cargo": "",
		"src": iso,
		"dst": "",
	}

func found_site(iso: String) -> String:
	if not GameState.world.has(iso):
		return ""
	var ind: Dictionary = DataLoader.industries.get("cafe", {})
	var id = "ai_site_%d" % GameState.firms.size()
	GameState.firms.append({
		"id": id,
		"name": "Pobočka %s" % GameState.world[iso].get("name_sk", iso),
		"owner": "ai",
		"country": iso,
		"industry": "cafe",
		"cash": 8000.0,
		"closed": false,
		"shares": 1000,
		"public": 0.0,
		"share_price": float(ind.get("cost", 80000.0)) / 1000.0,
		"history": [],
		"distress": 0,
		"facilities": [_facility(ind, iso)],
	})
	GameState.post_news("AI založila pobočku v %s." % iso)
	return id

func move_production(firm_id: String, dest: String) -> String:
	if not GameState.world.has(dest):
		return "Neznáma krajina."
	var firm = GameState.firm_by_id(firm_id)
	if firm.is_empty() or str(firm.get("owner", "")) != "ai" or firm.get("closed", false):
		return "Firma sa nedá presunúť."
	firm.country = dest
	for fac in firm.get("facilities", []):
		fac.country = dest
		fac.src = dest
	GameState.post_news("Výroba %s ide do %s." % [firm_id, dest])
	return ""

func close_failed(firm_id: String) -> String:
	var firm = GameState.firm_by_id(firm_id)
	if firm.is_empty() or str(firm.get("owner", "")) != "ai":
		return "Nie je to AI firma."
	if float(firm.get("cash", 0.0)) >= 0.0 and int(firm.get("distress", 0)) < 4:
		return "Ešte stojí."
	firm.closed = true
	GameState.post_news("AI firma %s zatvorená." % firm_id)
	return ""

func month_decision(firm: Dictionary) -> String:
	var country = str(firm.get("country", ""))
	if GeopoliticsSystem.at_war(country):
		firm.decision = "militarize"
	elif float(firm.get("cash", 0.0)) > 5000.0:
		firm.decision = "invest"
	else:
		firm.decision = "trade"
	return str(firm.decision)

func country_policy(iso: String) -> String:
	if not GameState.world.has(iso):
		return "trade"
	var c: Dictionary = GameState.world[iso]
	var risk = float(c.get("political_risk", 0.2))
	if GeopoliticsSystem.at_war(iso):
		var days = 0
		for w in GameState.wars:
			if iso in w.get("a", []) or iso in w.get("b", []):
				days = maxi(days, int(w.get("days", 0)))
				if risk < 0.75 and days < 30:
					w.intensity = min(1.0, float(w.get("intensity", 0.5)) + 0.05)
		if risk >= 0.75 or days >= 30:
			for other in DataLoader.country_ids:
				if str(other) != iso and GeopoliticsSystem._opponents(iso, str(other)):
					var home_was = str(GameState.player.get("home", ""))
					GameState.player.home = iso
					GeopoliticsSystem.make_peace(str(other))
					GameState.player.home = home_was
					break
			return "peace"
		return "militarize"
	if risk >= 0.55:
		var target = ""
		for other in DataLoader.country_ids:
			if str(other) != iso:
				target = str(other)
				break
		if target != "":
			var key = GeopoliticsSystem.sanction_key(iso, target)
			if not GameState.sanctions.has(key):
				GameState.sanctions.append(key)
			GameState.post_news("%s uvaľuje sankcie voči %s." % [iso, target])
		return "sanction"
	return "trade"

func monthly() -> void:
	for firm in GameState.firms:
		if str(firm.get("owner", "")) == "ai" and not firm.get("closed", false):
			month_decision(firm)
	if GameState.config.get("ai_diplomacy", false):
		for iso in DataLoader.country_ids:
			country_policy(str(iso))
	for firm in GameState.firms:
		if str(firm.get("owner", "")) != "ai" or firm.get("closed", false):
			continue
		var hist: Array = firm.get("history", [])
		if hist.size() < 10:
			continue
		var profit = 0.0
		var rev = 0.0
		for i in range(mini(20, hist.size())):
			var row: Dictionary = hist[hist.size() - 1 - i]
			profit += float(row.get("profit", 0.0))
			rev += float(row.get("rev", 0.0))
		var margin = profit / max(rev, 1.0)
		var ind: Dictionary = DataLoader.industries.get(firm.industry, {})
		var cost = float(ind.get("cost", 100000.0))
		if margin > 0.14 and float(firm.cash) > cost * 0.5:
			var fac: Dictionary = firm.facilities[0]
			fac.scale = float(fac.scale) + 0.25
			firm.cash = float(firm.cash) - cost * 0.15
		elif margin < -0.02:
			firm.distress = int(firm.get("distress", 0)) + 1
			if int(firm.distress) > 3 and firm.facilities.size() > 0:
				var fac2: Dictionary = firm.facilities[0]
				fac2.scale = max(0.4, float(fac2.scale) - 0.2)
		else:
			firm.distress = 0
	for bank in GameState.banks:
		if bank.get("failed", false) or str(bank.owner) != "ai":
			continue
		var pol = float(GameState.central[bank.country].policy)
		var risk = float(GameState.world[bank.country].political_risk)
		bank.deposit_rate = pol * 0.55
		bank.lending_rate = pol + 0.03 + risk * 0.045
