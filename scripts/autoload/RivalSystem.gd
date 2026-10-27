extends Node
# JUAN4: AI podnikatelskí konkurenti. Zakladaju firmy (owner "ai", pole "rival"), bojuju o trh,
# reaguju na ceny (expanduju pri vysokej cene / marzi, pri cenovej vojne s hracom pridaju vyrobu).
# Stav: GameState.ext.rivals (volitelny kluc savu). Bezi len ked GameState.config.rivals == true.

const NAMES = ["Danubia Holding", "Nordwerk Industries", "Atlas Trade Group", "Ferrox Capital", "Kestrel Ventures", "Orinoco Partners", "Baltica Group", "Sunvale Corp"]
const MAX_FIRMS = 6

func _ext() -> Dictionary:
	if typeof(GameState.get("ext")) != TYPE_DICTIONARY:
		GameState.ext = {}
	return GameState.ext

func _rng(tag: String) -> RandomNumberGenerator:
	var r = RandomNumberGenerator.new()
	r.seed = absi(("%s|riv|%s|%d" % [str(GameState.config.get("seed", 47)), tag, GameState.day_index]).hash())
	return r

func rivals() -> Array:
	var e = _ext()
	if not e.has("rivals") or typeof(e.rivals) != TYPE_ARRAY:
		e["rivals"] = []
	return e.rivals

func setup(count: int = -1) -> void:
	var e = _ext()
	e["rivals"] = []
	var n = count if count >= 0 else clampi(int(round(4.0 * Difficulty.ai_mult())), 2, 8)
	var ids: Array = DataLoader.country_ids.duplicate()
	ids.sort_custom(func(a, b): return float(DataLoader.countries[a].get("gdp_usd", 0)) > float(DataLoader.countries[b].get("gdp_usd", 0)))
	var home = str(GameState.player.get("home", "SK"))
	for i in n:
		var iso = home if i == 0 else str(ids[(i - 1) % mini(ids.size(), 12)])
		e.rivals.append({"id": "r%d" % i, "name": NAMES[i % NAMES.size()], "home": iso, "cash": 3.0e6 * Difficulty.ai_mult(), "aggr": clamp(0.4 + 0.1 * i, 0.3, 0.9) * Difficulty.ai_mult(), "firms": []})

func rival_firms(rid: String) -> Array:
	var out: Array = []
	for f in GameState.firms:
		if str(f.get("rival", "")) == rid and not bool(f.get("closed", false)):
			out.append(f)
	return out

func _player_industries() -> Dictionary:
	var out: Dictionary = {}
	for f in GameState.player_firms():
		out["%s|%s" % [str(f.country), str(f.industry)]] = true
	return out

func monthly() -> void:
	if not bool(GameState.config.get("rivals", false)):
		return
	var pl = _player_industries()
	var resist = PoliticsSystem.bonus_sum("rival")
	for rv in rivals():
		var r = _rng(str(rv.id))
		var mine = rival_firms(str(rv.id))
		profit_share(rv, mine)  # JUAN-P47: podiel zisku firiem ide do rozpoctu konkurenta
		# 1) reakcia na ceny/marzu: expanzia alebo utlm
		for f in mine:
			var hist: Array = f.get("history", [])
			var rev = 0.0
			var prof = 0.0
			for i in range(mini(30, hist.size())):
				rev += float(hist[hist.size() - 1 - i].get("rev", 0.0))
				prof += float(hist[hist.size() - 1 - i].get("profit", 0.0))
			var margin = prof / max(rev, 1.0)
			var fac: Dictionary = f.facilities[0]
			var price_war = pl.has("%s|%s" % [str(f.country), str(f.industry)])
			if margin > 0.10 or (price_war and r.randf() < float(rv.aggr) * (1.0 - resist)):
				fac.scale = min(4.0, float(fac.scale) + (0.25 if price_war else 0.15))
				f.price_war = price_war
			elif margin < -0.05:
				fac.scale = max(0.4, float(fac.scale) - 0.15)
		# 2) zalozenie novej firmy
		if mine.size() < MAX_FIRMS and r.randf() < 0.25 * float(rv.aggr) * (1.0 - resist):
			found_for(rv, r)

# JUAN-P47: mesacne presunie PROFIT_SHARE cisteho zisku firiem (poslednych 30 dni) z ich pokladnice do rozpoctu
# konkurenta; pri strate rozpocet doplni firmu tym istym podielom straty (rozpocet nikdy pod 0). Navyse holding stiahne
# polovicu hotovosti firmy nad prevadzkovou rezervou (25 % ceny podniku, min. 90 tis. €). Peniaze sa nevytvaraju.
const PROFIT_SHARE = 0.5
const SWEEP_SHARE = 0.5

func profit_share(rv: Dictionary, mine: Array) -> float:
	var moved = 0.0
	for f in mine:
		var hist: Array = f.get("history", [])
		var prof = 0.0
		for i in range(mini(30, hist.size())):
			prof += float(hist[hist.size() - 1 - i].get("profit", 0.0))
		if prof > 0.0:
			var take = minf(prof * PROFIT_SHARE, maxf(float(f.get("cash", 0.0)), 0.0))
			f.cash = float(f.get("cash", 0.0)) - take
			moved += take
			var reserve = maxf(float(DataLoader.industries.get(str(f.get("industry", "")), {}).get("cost", 0.0)) * 0.25, 90000.0)
			if float(f.cash) > reserve:
				var sw = (float(f.cash) - reserve) * SWEEP_SHARE
				f.cash = float(f.cash) - sw
				moved += sw
		elif prof < 0.0:
			var give = minf(-prof * PROFIT_SHARE, maxf(float(rv.get("cash", 0.0)) + moved, 0.0))
			f.cash = float(f.get("cash", 0.0)) + give
			moved -= give
	rv["cash"] = maxf(float(rv.get("cash", 0.0)) + moved, 0.0)
	rv["income_month"] = moved
	rv["income_total"] = float(rv.get("income_total", 0.0)) + moved
	return moved

func found_for(rv: Dictionary, r: RandomNumberGenerator = null) -> String:
	if r == null:
		r = _rng(str(rv.id) + "f")
	var iso = str(rv.home)
	var pl = _player_industries()
	var choice = ""
	# polovicu casu utoci na odvetvie, kde podnika hrac
	if pl.size() > 0 and r.randf() < 0.5:
		var key = str(pl.keys()[r.randi() % pl.size()])
		iso = key.split("|")[0]
		choice = key.split("|")[1]
	if DataLoader.recipes.get(str(DataLoader.industries.get(choice, {}).get("recipe", "")), {}).has("service"):
		choice = ""  # JUAN-P47: sluzbove podniky (pristav, skoly, nemocnica) stavia Society.ai_monthly podla dopytu, nie kopirovanim hraca
	if choice == "" or not DataLoader.industries.has(choice):
		var opts: Array = []
		for ind_id in DataLoader.industry_ids:
			var rec: Dictionary = DataLoader.recipes.get(str(DataLoader.industries[ind_id].get("recipe", "")), {})
			if rec.get("trade", false) or rec.has("service") or float(DataLoader.industries[ind_id].get("cost", 1e9)) > float(rv.cash) or str(DataLoader.industries[ind_id].get("tier", "")) == "grey":
				continue
			opts.append(ind_id)
		if opts.is_empty():
			return ""
		choice = str(opts[r.randi() % opts.size()])
	var ind: Dictionary = DataLoader.industries[choice]
	var cost = float(ind.get("cost", 0.0))
	if float(rv.cash) < cost:
		return ""
	rv.cash = float(rv.cash) - cost
	var id = "rv_%s_%d" % [str(rv.id), GameState.firms.size()]
	var city: Dictionary = TerrainSystem.cities(iso)[0] if TerrainSystem.cities(iso).size() > 0 else {}
	var firm = {
		"id": id, "name": "%s %s" % [str(rv.name), str(ind.get("name", "firma"))], "owner": "ai", "rival": str(rv.id),
		"country": iso, "industry": choice, "cash": cost * 0.3, "closed": false, "shares": 1000, "public": 0.0,
		"share_price": cost / 1000.0, "history": [], "distress": 0, "facilities": [AgentSystem._facility(ind, iso)],
	}
	if not city.is_empty():
		firm["pos"] = [float(city.pos.x) + r.randf_range(-2.0, 2.0), float(city.pos.y) + r.randf_range(-2.0, 2.0)]
	GameState.firms.append(firm)
	GameState.post_news("Konkurencia: %s otvára %s v krajine %s." % [str(rv.name), str(ind.get("name", "")), str(GameState.world.get(iso, {}).get("name_sk", iso))])
	return id

# podiel hraca vs. konkurencie na trzbach odvetvia v krajine (posledných 30 dni)
func market_share(iso: String, industry: String) -> Dictionary:
	var tot = 0.0
	var mine = 0.0
	var riv = 0.0
	for f in GameState.firms:
		if str(f.get("country", "")) != iso or str(f.get("industry", "")) != industry or bool(f.get("closed", false)):
			continue
		var rev = 0.0
		var hist: Array = f.get("history", [])
		for i in range(mini(30, hist.size())):
			rev += float(hist[hist.size() - 1 - i].get("rev", 0.0))
		if rev <= 0.0:
			rev = float(f.facilities[0].get("scale", 1.0)) if f.get("facilities", []).size() > 0 else 0.0
		tot += rev
		if str(f.get("owner", "")) == "player":
			mine += rev
		elif str(f.get("rival", "")) != "":
			riv += rev
	return {"player": mine / max(tot, 0.0001), "rivals": riv / max(tot, 0.0001), "total": tot}

func text() -> String:
	var out = "AI KONKURENTI\n"
	if rivals().is_empty():
		return out + "Žiadni (zapnú sa v novej hre)."
	for rv in rivals():
		var fs = rival_firms(str(rv.id))
		out += "• %s (%s): %d firiem, hotovosť %s\n" % [str(rv.name), str(GameState.world.get(str(rv.home), {}).get("name_sk", rv.home)), fs.size(), EconMath.eur(float(rv.cash))]
	for f in GameState.player_firms():
		var sh = market_share(str(f.country), str(f.industry))
		out += "Tvoj podiel %s v %s: %d %% (konkurenti %d %%)\n" % [str(DataLoader.industries.get(str(f.industry), {}).get("name", f.industry)), str(f.country), int(float(sh.player) * 100), int(float(sh.rivals) * 100)]
	return out
