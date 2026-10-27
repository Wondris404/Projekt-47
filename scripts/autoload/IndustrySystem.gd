extends Node

func io_map(raw) -> Dictionary:
	if typeof(raw) == TYPE_DICTIONARY:
		return raw
	var out = {}
	if typeof(raw) == TYPE_ARRAY:
		for row in raw:
			if typeof(row) != TYPE_DICTIONARY:
				continue
			out[str(row.get("commodity", ""))] = float(row.get("amount", 0.0))
	return out

func apply_spec(inventory: Dictionary, spec: Dictionary, runs: float = 1.0, yield_mult: float = 1.0) -> Dictionary:
	var inputs = io_map(spec.get("inputs", {}))
	var outputs = io_map(spec.get("outputs", {}))
	var actual = max(0.0, runs)
	for in_id in inputs.keys():
		var per = float(inputs[in_id])
		if per <= 0.0:
			continue
		actual = min(actual, float(inventory.get(in_id, 0.0)) / per)
	actual = max(0.0, actual)
	var consumed = {}
	var produced = {}
	for in_id in inputs.keys():
		var per_in = float(inputs[in_id])
		var take = min(float(inventory.get(in_id, 0.0)), per_in * actual)
		if take > 0.0:
			inventory[in_id] = float(inventory.get(in_id, 0.0)) - take
			consumed[str(in_id)] = take
	for out_id in outputs.keys():
		var made = float(outputs[out_id]) * actual * yield_mult
		if made > 0.0:
			inventory[out_id] = float(inventory.get(out_id, 0.0)) + made
			produced[str(out_id)] = made
	return {"actual": actual, "consumed": consumed, "produced": produced}

func apply_recipe(inventory: Dictionary, recipe_id: String, runs: float, yield_mult: float = 1.0) -> Dictionary:
	return apply_spec(inventory, DataLoader.recipes.get(recipe_id, {}), runs, yield_mult)

func place_available(iso: String, industry_id: String) -> bool:
	var ind: Dictionary = DataLoader.industries.get(industry_id, {})
	if ind.is_empty():
		return false
	var recipe: Dictionary = DataLoader.recipes.get(str(ind.get("recipe", "")), {})
	var key = str(recipe.get("endow", ""))
	if key == "":
		return true
	var endow = float(GameState.world.get(iso, {}).get("endow", {}).get(key, 0.0))
	return endow >= 0.3

# ===== JUAN5 #18: triedy podnikov, odomykanie (progresia), upgrady 1-3, media =====
const TIER_NAMES = {"small": "Malý podnik", "medium": "Stredný podnik", "large": "Veľký podnik", "finance": "Finančná firma", "media": "Médiá", "grey": "Šedá zóna"}
# any = staci jedno z (vyskum r / focus f), all = treba vsetko; nw = min. ciste imanie (EUR)
const UNLOCK = {
	"small": {"any": [], "nw": 0.0},
	"medium": {"any": ["r:biz_med", "f:ind1"], "nw": 250000.0},
	"large": {"all": ["r:biz_large", "f:ind2"], "nw": 2000000.0},
	"finance": {"any": ["r:score1", "f:fin2"], "nw": 1000000.0},
	"media": {"any": ["f:med2", "r:cons2"], "nw": 500000.0},
	"grey": {"all": ["f:dirty"], "nw": 0.0},
}
const UPGRADE_SCALE = 1.35

func tier_of_industry(ind_id: String) -> String:
	return str(DataLoader.industries.get(ind_id, {}).get("tier", "small"))

func progression_on() -> bool:
	return bool(GameState.config.get("progression", false)) and not bool(GameState.config.get("dev", false))

func _req_ok(code: String) -> bool:
	var p = code.split(":")
	if p[0] == "r":
		return p[1] in GameState.player.get("done", [])
	return PoliticsSystem.focus_done(p[1])

func _req_name(code: String) -> String:
	var p = code.split(":")
	if p[0] == "r":
		return "výskum „%s“" % str(GameState.research_def(p[1]).get("name", p[1]))
	return "cieľ „%s“" % str(PoliticsSystem.focus_def(p[1]).get("name", p[1]))

# "" = odomknute, inak dovod
func unlock_reason(ind_id: String, iso: String = "") -> String:
	if ind_id == "airport" and iso != "" and not airport_city_ok(iso):
		return "Letisko vyžaduje mesto s aspoň 200 tis. obyvateľmi."
	if not progression_on():
		if tier_of_industry(ind_id) == "grey" and not PoliticsSystem.focus_done("dirty") and not bool(GameState.config.get("dev", false)):
			return "Šedá zóna: treba cieľ „Korupcia a podsvetie“."
		return ""
	var u: Dictionary = UNLOCK.get(tier_of_industry(ind_id), UNLOCK.small)
	var any: Array = u.get("any", [])
	if not any.is_empty() and not any.any(func(c): return _req_ok(str(c))):
		return "%s: treba %s." % [TIER_NAMES.get(tier_of_industry(ind_id), ""), " alebo ".join(any.map(func(c): return _req_name(str(c))))]
	for c in u.get("all", []):
		if not _req_ok(str(c)):
			return "%s: treba %s." % [TIER_NAMES.get(tier_of_industry(ind_id), ""), _req_name(str(c))]
	var nw = float(u.get("nw", 0.0))
	if nw > 0.0 and GameState.net_worth() < nw:
		return "%s: treba čisté imanie aspoň %s (máš %s)." % [TIER_NAMES.get(tier_of_industry(ind_id), ""), EconMath.eur(nw), EconMath.eur(GameState.net_worth())]
	return ""

func firm_level(firm: Dictionary) -> int:
	return int(firm.get("level", 1))

func upgrade_cost(firm: Dictionary) -> float:
	return float(DataLoader.industries.get(str(firm.get("industry", "")), {}).get("cost", 0.0)) * 0.5 * float(firm_level(firm)) * Difficulty.cost_mult()

func upgrade_firm(firm_id: String) -> String:
	var firm = _player_firm(firm_id)
	if firm.is_empty():
		return "Firma nie je tvoja."
	var lv = firm_level(firm)
	if lv >= 3:
		return "Firma má najvyššiu úroveň (3)."
	var rid = "upg%d" % (lv + 1)
	if not bool(GameState.config.get("dev", false)) and not rid in GameState.player.get("done", []):
		return "Úroveň %d odomkne výskum „%s“." % [lv + 1, str(GameState.research_def(rid).get("name", rid))]
	var cost = upgrade_cost(firm)
	if float(GameState.player.cash) < cost:
		return "Upgrade stojí %s." % EconMath.eur(cost)
	GameState.player.cash = float(GameState.player.cash) - cost
	firm["level"] = lv + 1
	for fac in firm.get("facilities", []):
		fac.scale = float(fac.get("scale", 1.0)) * UPGRADE_SCALE
	GameState.post_news("%s: úroveň %d (výkon ×%.2f)." % [str(firm.name), lv + 1, UPGRADE_SCALE])
	return ""

# media hraca: reputacia mesacne a bonus k lobingu/volbam
func media_count() -> int:
	var n = 0
	for f in GameState.player_firms():
		if tier_of_industry(str(f.get("industry", ""))) == "media":
			n += 1
	return n

# JUAN5 #18: letisko – poplatky za lety (tvoje letecke spolocnosti v krajine) a pasazierov (turizmus = tvoje hotely + velkost krajiny)
# realne mesto z cities.json (aspon 200 tis. obyvatelov)
const AIRPORT_CITY_POP = 200000.0
func airport_city(iso: String) -> String:
	var best = ""
	var bp = 0.0
	for c in TerrainSystem.cities(iso):
		if float(c.get("pop", 0.0)) >= AIRPORT_CITY_POP and float(c.pop) > bp:
			bp = float(c.pop)
			best = str(c.name)
	return best

func airport_city_ok(iso: String) -> bool:
	return airport_city(iso) != ""

func airport_fees(iso: String) -> float:
	var airlines = 0
	var hotels = 0
	for f in GameState.player_firms():
		if str(f.get("country", "")) != iso:
			continue
		var ind = str(f.get("industry", ""))
		if ind == "airline":
			airlines += 1
		elif ind == "hotel":
			hotels += 1
	var pop_m = float(DataLoader.countries.get(iso, {}).get("population", 0.0)) / 1000000.0
	var flights = 120.0 + 180.0 * airlines          # lety mesacne
	var pax = flights * 140.0 * (1.0 + 0.15 * hotels) * clampf(sqrt(pop_m) / 3.0, 0.3, 3.0)
	return flights * 900.0 + pax * 6.0              # pristavacie poplatky + poplatok za pasaziera

func airport_monthly() -> float:
	var total = 0.0
	for f in GameState.player_firms():
		if str(f.get("industry", "")) == "airport":
			var fee = airport_fees(str(f.get("country", "")))
			total += fee
	if total > 0.0:
		GameState.player.cash = float(GameState.player.cash) + total
	return total

# JUAN5 #18: predaj firmy (60 % hodnoty); zalozenu firmu predat nejde
func sell_firm(firm_id: String) -> String:
	var f = _player_firm(firm_id)
	if f.is_empty():
		return "Firma nie je tvoja."
	if str(f.get("pledged", "")) != "":
		return "Firma je založená v banke – kým beží úver, predať ju nemôžeš."
	if str(f.get("listed", "")) != "" or str(f.get("corp", "")) != "":
		return "Firma je na burze alebo v holdingu – predaj akcie."
	var v = BankingSystem.asset_market_value({"kind": "firm", "id": firm_id}) * 0.6 / 0.7
	f.closed = true
	f.owner = "sold"
	GameState.player.cash = float(GameState.player.cash) + v
	GameState.post_news("Predaná firma %s za %s." % [str(f.get("name", "")), EconMath.eur(v)])
	return ""

func media_monthly() -> void:
	var n = media_count()
	if n > 0:
		GameState.player.rating = mini(100, int(GameState.player.get("rating", 55)) + mini(n, 3))

func industry_button_ids() -> Array:
	return DataLoader.industry_ids.duplicate()

func _player_firm(firm_id: String) -> Dictionary:
	for firm in GameState.firms:
		if str(firm.get("id", "")) == firm_id and str(firm.get("owner", "")) == "player" and not firm.get("closed", false):
			return firm
	return {}

func set_firm_production(firm_id: String, commodity: String, util: float) -> float:
	var firm = _player_firm(firm_id)
	if firm.is_empty():
		return -1.0
	var applied = clampf(util, 0.25, 1.0)
	for fac in firm.get("facilities", []):
		fac.util = applied
		fac.auto = false
		fac.focus = commodity
	return applied

func set_sale_price(firm_id: String, commodity: String, price: float) -> float:
	var firm = _player_firm(firm_id)
	if firm.is_empty():
		return -1.0
	var px = max(0.01, price)
	for fac in firm.get("facilities", []):
		if not fac.has("sale_prices") or typeof(fac.sale_prices) != TYPE_DICTIONARY:
			fac.sale_prices = {}
		fac.sale_prices[commodity] = px
	return px

func set_shifts(firm_id: String, shifts: int) -> int:
	var firm = _player_firm(firm_id)
	if firm.is_empty():
		return -1
	var count = clampi(shifts, 1, 3)
	for fac in firm.get("facilities", []):
		fac.shifts = count
	return count

func sign_pmc(firm_id: String, government: String) -> String:
	var firm = _player_firm(firm_id)
	if firm.is_empty():
		return "Žiadna firma."
	if not DataLoader.countries.has(government):
		return "Neplatná vláda."
	firm.pmc_contract = {"government": government, "active": true}
	GameState.post_news("PMC kontrakt s %s." % government)
	return ""

func cancel_pmc(firm_id: String) -> String:
	var firm = _player_firm(firm_id)
	if firm.is_empty() or not firm.has("pmc_contract"):
		return "Žiadny kontrakt."
	firm.pmc_contract = {"government": "", "active": false}
	GameState.post_news("PMC kontrakt je zrušený.")
	return ""

func set_trade_route(firm_id: String, commodity: String, direction: String, qty: float) -> String:
	var firm = _player_firm(firm_id)
	if firm.is_empty():
		return "Žiadna firma."
	if direction != "import" and direction != "export":
		return "Zlý smer."
	if not DataLoader.commodities.has(commodity):
		return "Neznámy tovar."
	firm.trade_order = {"commodity": commodity, "direction": direction, "qty": max(0.0, qty)}
	var iso = str(firm.get("country", ""))
	if direction == "import":
		MarketSystem.post_bid(iso, commodity, firm_id + ":trade", qty)
	else:
		MarketSystem.post_offer(iso, commodity, firm_id + ":trade", qty)
	return ""

func firm_ledger(firm_id: String) -> Dictionary:
	var firm = _player_firm(firm_id)
	if firm.is_empty():
		return {}
	var tax = 0.0
	var wages = 0.0
	var hist: Array = firm.get("history", [])
	if hist.size() > 0:
		var last: Dictionary = hist[hist.size() - 1]
		tax = float(last.get("tax", 0.0))
		wages = float(last.get("wages", 0.0))
	var stock = ""
	for fac in firm.get("facilities", []):
		var inv: Dictionary = fac.get("inventory", {})
		for key in inv.keys():
			stock += "%s %.1f " % [str(key), float(inv[key])]
	return {
		"tax": tax,
		"wages": wages,
		"shifts": int(firm.get("facilities", [{}])[0].get("shifts", 1)) if firm.get("facilities", []).size() > 0 else 1,
		"inventory": stock,
		"pmc": bool(firm.get("pmc_contract", {}).get("active", false)),
		"trade": str(firm.get("trade_order", {}).get("direction", "")),
	}

func set_production(util: float) -> float:
	var applied = clampf(util, 0.25, 1.0)
	for firm in GameState.firms:
		if str(firm.get("owner", "")) != "player" or firm.get("closed", false):
			continue
		for fac in firm.get("facilities", []):
			fac.util = applied
			fac.auto = false
	return applied

func tax_due(iso: String, profit: float) -> float:
	return max(0.0, profit) * LawSystem.corporate_tax(iso)

func place_firm(iso: String, industry_id: String) -> Dictionary:
	var before = GameState.player_firms().size()
	if not place_available(iso, industry_id):
		return {"ok": false, "reason": "unavailable", "count": before}
	var err = GameState.found_firm(industry_id, "", iso)
	var after = GameState.player_firms().size()
	if err != "":
		return {"ok": false, "reason": err, "count": after}
	return {"ok": true, "reason": "", "count": after}

# ===== JUAN9: vnutorne dodavky v ramci korporacie/holdingu v tej istej krajine =====
# Dodavatel a odberatel v tej istej krajine a v tej istej korporacii: odberatel plati len dopravu (TRANSPORT_SHARE z trhovej ceny).
const TRANSPORT_SHARE = 0.06
var _internal: Dictionary = {}   # "corp|iso|commodity" -> zostava ponuky na dnes
var _internal_requests: Dictionary = {}
var _internal_delivered: Array = []
var record_goods_flow := true
var _market_executions: Dictionary = {}
var _direct_trades: Array = []
var use_local_competition_cache := true
var _local_competition: Dictionary = {}
var _local_competition_members: Dictionary = {}
var _local_competition_valid := false
var _player_ai_counts: Dictionary = {}

func _build_internal_pool() -> void:
	_internal = {}
	_internal_requests = {}
	_internal_delivered = []
	for firm in GameState.firms:
		if firm.get("closed", false) or str(firm.get("corp", "")) == "" or str(firm.get("owner", "")) != "player":
			continue
		for fi in firm.facilities.size():
			var fac: Dictionary = firm.facilities[fi]
			var recipe: Dictionary = DataLoader.recipes.get(fac.get("recipe", ""), {})
			var desired = _throughput(firm, fac, recipe) if not recipe.is_empty() else 0.0
			for out_id in recipe.get("outputs", {}).keys():
				var k = "%s|%s|%s" % [str(firm.corp), str(fac.get("country", firm.country)), out_id]
				_internal[k] = float(_internal.get(k, 0.0)) + float(recipe.outputs[out_id]) * desired + float(fac.inventory.get(out_id, 0.0))
				fac["reserved"] = {}

func internal_take(firm: Dictionary, iso: String, in_id: String, want: float) -> float:
	if str(firm.get("corp", "")) == "" or str(firm.get("owner", "")) != "player" or want <= 0.0:
		return 0.0
	var k = "%s|%s|%s" % [str(firm.corp), iso, in_id]
	var avail = float(_internal.get(k, 0.0))
	var take = minf(avail, want)
	if take <= 0.0:
		return 0.0
	_internal[k] = avail - take
	# rezervuj u dodavatelov (aby to nepredali na trhu)
	var left = take
	for f2 in GameState.firms:
		if left <= 0.0:
			break
		if f2 == firm or f2.get("closed", false) or str(f2.get("corp", "")) != str(firm.corp):
			continue
		for fac2 in f2.facilities:
			if str(fac2.get("country", f2.country)) != iso:
				continue
			var r2: Dictionary = DataLoader.recipes.get(fac2.get("recipe", ""), {})
			if not r2.get("outputs", {}).has(in_id):
				continue
			var res: Dictionary = fac2.get("reserved", {})
			res[in_id] = float(res.get(in_id, 0.0)) + left
			fac2["reserved"] = res
			if record_goods_flow:
				var trace_key = "%s|%d|%s" % [str(f2.get("id", "")), f2.facilities.find(fac2), in_id]
				if not _internal_requests.has(trace_key):
					_internal_requests[trace_key] = []
				_internal_requests[trace_key].append({"seller": str(f2.get("id", "")), "buyer": str(firm.get("id", "")), "cid": in_id, "iso": iso, "qty": left})
			left = 0.0
			break
	return take

func plan_and_post() -> void:
	plan_start()
	plan_chunk(0, GameState.firms.size())

func plan_start() -> void:
	_build_internal_pool()

func plan_chunk(start: int, count: int) -> int:
	var end = mini(start + count, GameState.firms.size())
	for firm_index in range(start, end):
		var firm: Dictionary = GameState.firms[firm_index]
		if firm.get("closed", false):
			continue
		firm["plans"] = []
		for fi in firm.facilities.size():
			var fac: Dictionary = firm.facilities[fi]
			var recipe: Dictionary = DataLoader.recipes.get(fac.get("recipe", ""), {})
			if recipe.is_empty() or recipe.get("trade", false) or recipe.has("service"):  # JUAN-P47: sluzby bez trhu
				continue
			var desired = _throughput(firm, fac, recipe)
			var iso = str(fac.get("country", firm.country))
			var budget = float(firm.cash) * 0.9
			for out_id in recipe.get("outputs", {}).keys():
				var have = float(fac.inventory.get(out_id, 0.0))
				var planned = float(recipe.outputs[out_id]) * desired
				budget += (have + planned) * MarketSystem.price(iso, out_id) * 0.8
			var input_cost = 0.0
			for in_id in recipe.get("inputs", {}).keys():
				var need = _input_qty(firm, recipe, in_id) * desired
				var have_in = float(fac.inventory.get(in_id, 0.0))
				var buy = max(0.0, need - have_in)
				input_cost += buy * MarketSystem.price(iso, in_id)
			var scale_cash = 1.0
			if input_cost > budget and input_cost > 0.0:
				scale_cash = budget / input_cost
			desired *= scale_cash
			for in_id in recipe.get("inputs", {}).keys():
				var need2 = _input_qty(firm, recipe, in_id) * desired
				var buy2 = max(0.0, need2 - float(fac.inventory.get(in_id, 0.0)))
				var own = internal_take(firm, iso, in_id, buy2)  # JUAN9: z vlastnej korporacie
				var intr: Dictionary = fac.get("internal", {})
				intr[in_id] = own
				fac["internal"] = intr
				MarketSystem.post_bid(iso, in_id, firm.id + ":" + str(fi), buy2 - own)
			for out_id in recipe.get("outputs", {}).keys():
				var offer = maxf(0.0, float(fac.inventory.get(out_id, 0.0)) + float(recipe.outputs[out_id]) * desired - float(fac.get("reserved", {}).get(out_id, 0.0)))
				MarketSystem.post_offer(iso, out_id, firm.id + ":" + str(fi), offer)
			firm.plans.append({"fi": fi, "desired": desired})
	return end

func settle() -> void:
	settle_start()
	settle_chunk(0, GameState.firms.size())

func settle_start() -> void:
	Transport.begin_day()  # JUAN19
	_market_executions.clear()
	_direct_trades.clear()
	_prepare_local_competition()

func _prepare_local_competition() -> void:
	_local_competition.clear()
	_local_competition_members.clear()
	_player_ai_counts.clear()
	for firm in GameState.firms:
		if firm.get("closed", false):
			continue
		var key = str(firm.get("country", "")) + "|" + str(firm.get("industry", ""))
		_local_competition[key] = int(_local_competition.get(key, 0)) + 1
		_local_competition_members[str(firm.get("id", ""))] = key
		if str(firm.get("owner", "")) == "player" and str(firm.get("industry", "")) == "ai_firm":
			var iso = str(firm.get("country", ""))
			_player_ai_counts[iso] = int(_player_ai_counts.get(iso, 0)) + 1
	_local_competition_valid = true

func settle_chunk(start: int, count: int) -> int:
	var end = mini(start + count, GameState.firms.size())
	for firm_index in range(start, end):
		var firm: Dictionary = GameState.firms[firm_index]
		if firm.get("closed", false):
			continue
		var is_pl = str(firm.get("owner", "")) == "player"
		var rev = 0.0
		var cogs = 0.0
		var wages = 0.0
		var rent = 0.0
		var maintain = 0.0
		var flow = {"day": GameState.day_index, "inputs": {}, "outputs": {}, "trades": []} if is_pl and record_goods_flow else {}
		for fi in firm.facilities.size():
			var fac: Dictionary = firm.facilities[fi]
			var recipe: Dictionary = DataLoader.recipes.get(fac.get("recipe", ""), {})
			if recipe.is_empty() or recipe.get("trade", false):
				continue
			if recipe.has("service"):  # JUAN-P47: nemocnica, pristav, skoly – prijem zo Society, naklady denne
				var sv = _settle_service(firm, fac, recipe)
				rev += float(sv.rev)
				wages += float(sv.wages)
				rent += float(sv.rent)
				maintain += float(sv.maint)
				cogs += float(sv.cogs)
				continue
			var iso = str(fac.get("country", firm.country))
			var actor = firm.id + ":" + str(fi)
			var plan = _plan_for(firm, fi)
			var desired = float(plan.get("desired", 0.0))
			var buy_fill = 1.0
			for in_id in recipe.get("inputs", {}).keys():
				buy_fill = MarketSystem.actor_buy_fill(iso, in_id)
				var need = _input_qty(firm, recipe, in_id) * desired
				var have = float(fac.inventory.get(in_id, 0.0))
				var own_in = float(fac.get("internal", {}).get(in_id, 0.0))  # JUAN9: od vlastnej korporacie len doprava
				var own_cost = own_in * MarketSystem.price(iso, in_id) * TRANSPORT_SHARE
				var td = Transport.discount(firm, in_id) if is_pl else {"d": 0.0, "logi": 0.0, "hub": ""}  # JUAN19
				var own_save = own_cost * float(td.d)
				own_cost -= own_save
				firm.cash = float(firm.cash) - own_cost
				cogs += own_cost
				have += own_in
				var bought = max(0.0, need - have) * buy_fill * buy_share(firm)  # JUAN3: bez pravej ruky sa nakupuje len cast
				var cost = bought * MarketSystem.price(iso, in_id)
				if is_pl:  # JUAN19: kupene od konkurencie = cena + doprava (zlava zeleznica/ropovod/logistika)
					var mt = cost * (Transport.MARKET_TRANSPORT if in_id in Transport.GOODS else 0.0)
					var m_save = mt * float(td.d)
					cost += mt - m_save
					var lg_part = (own_save + m_save) * (float(td.logi) / maxf(float(td.d), 0.0001)) if float(td.d) > 0.0 else 0.0
					Transport.log_input(firm, in_id, own_in, bought, own_cost + mt - m_save, own_save + m_save, str(td.hub), lg_part)
					Transport.use(firm, in_id, own_in + bought)
				firm.cash = float(firm.cash) - cost
				cogs += cost
				fac.inventory[in_id] = have + bought
				if bought > 0.0:
					_market_execution(iso, str(in_id), "buyers", firm, bought, cost / bought)
				if is_pl and record_goods_flow:
					_flow_add(flow.inputs, str(in_id), {"bought": bought, "internal": own_in, "cost": cost})
			var applied: Dictionary = apply_spec(fac.inventory, _production_spec(firm, recipe), desired, _yield_mult(firm, str(fac.recipe)))
			var made = float(applied.get("actual", 0.0))
			for out_id in recipe.get("outputs", {}).keys():
				var sell_fill = MarketSystem.actor_sell_fill(iso, out_id)
				var rsv = minf(float(fac.get("reserved", {}).get(out_id, 0.0)), float(fac.inventory.get(out_id, 0.0)))
				_trace_internal_delivery(firm, fi, str(out_id), rsv)
				fac.inventory[out_id] = float(fac.inventory.get(out_id, 0.0)) - rsv  # JUAN9: odovzdane vlastnej korporacii
				var available = float(fac.inventory.get(out_id, 0.0))
				var sold = available * sell_fill
				var px = MarketSystem.price(iso, out_id) * _local_mult(firm, fac, out_id)
				var gain = sold * px
				if is_pl and out_id in Transport.GOODS and sold > 0.0:  # JUAN19: doprava vyrobkov k odberatelom/pristavom
					var sd = Transport.discount(firm, out_id)
					var st_cost = gain * Transport.SALES_TRANSPORT * (1.0 - float(sd.d))
					firm.cash = float(firm.cash) - st_cost
					cogs += st_cost
					Transport.use(firm, out_id, sold)
				firm.cash = float(firm.cash) + gain
				rev += gain
				fac.inventory[out_id] = float(fac.inventory.get(out_id, 0.0)) - sold
				if sold > 0.0:
					_market_execution(iso, str(out_id), "sellers", firm, sold, px)
				if is_pl and record_goods_flow:
					_flow_add(flow.outputs, str(out_id) + "|" + iso, {"produced": float(applied.get("produced", {}).get(out_id, 0.0)), "sold": sold, "internal": rsv, "revenue": gain})
			var wage_rate = _wage(iso, firm)
			var labor = float(recipe.get("labor", 0.0)) * float(fac.get("scale", 1.0)) * (made / max(desired, 0.001))
			var wage = wage_rate * labor
			firm.cash = float(firm.cash) - wage
			wages += wage
			var zone_rent = float(recipe.get("rent", 10.0)) * float(fac.get("scale", 1.0)) * _zone_rent(str(fac.get("zone", "")))
			var maint = float(recipe.get("maintain", 0.0)) * float(fac.get("scale", 1.0))
			firm.cash = float(firm.cash) - zone_rent - maint
			rent += zone_rent
			maintain += maint
		var freight_cut = 0.0
		for fac2 in firm.facilities:
			if str(fac2.get("recipe", "")) == "logistics_hub":
				var pool = float(MarketSystem.freight_pool.get(fac2.country, 0.0))
				var cut = pool * 0.08 * float(fac2.get("scale", 1.0))
				firm.cash = float(firm.cash) + cut
				rev += cut
				freight_cut += cut
		var desk_totals = _run_desks(firm, rev, flow)
		rev += float(desk_totals.revenue)
		cogs += float(desk_totals.cost)
		if str(firm.get("owner", "")) == "player" and not firm.get("manager", {}).is_empty():  # JUAN3: plat pravej ruky
			var sal = float(firm.manager.get("salary", 0.0)) / 30.0
			firm.cash = float(firm.cash) - sal
			wages += sal
		var ops = rev - cogs - wages - rent - maintain
		var tiso = Empire.tax_iso(firm)  # JUAN10: korporacia plati dane v krajine centraly (HQ)
		var tax_rate = LawSystem.corporate_tax(tiso)
		var tax = tax_due(tiso, ops) * Empire.tax_mult(firm) * Society.tax_mult(firm)  # JUAN-P47: vyhodne zakony
		firm.cash = float(firm.cash) - tax
		var profit = ops - tax
		if not firm.has("history") or firm.history == null:
			firm.history = []
		firm.history.append({
			"rev": rev, "cogs": cogs, "wages": wages, "rent": rent, "maintain": maintain,
			"tax": tax, "profit": profit, "day": GameState.day_index,
		})
		if is_pl and record_goods_flow and (not flow.inputs.is_empty() or not flow.outputs.is_empty() or not flow.trades.is_empty()):
			var flows: Array = firm.get("goods_flow", [])
			flows.append(flow)
			if flows.size() > 30:
				flows.pop_front()
			firm["goods_flow"] = flows
		if str(firm.get("owner", "")) == "player":  # JUAN3: mesacny akumulator pre graf
			var acc: Dictionary = firm.get("month_acc", {})
			acc["rev"] = float(acc.get("rev", 0.0)) + rev
			acc["costs"] = float(acc.get("costs", 0.0)) + (rev - profit)
			acc["profit"] = float(acc.get("profit", 0.0)) + profit
			firm["month_acc"] = acc
		if firm.history.size() > 40:
			firm.history.pop_front()
		if float(firm.cash) < 0.0:
			firm.distress = int(firm.get("distress", 0)) + 1
		else:
			firm.distress = max(0, int(firm.get("distress", 0)) - 1)
	if record_goods_flow and end >= GameState.firms.size() and not _internal_delivered.is_empty():
		_store_internal_deliveries()
	if record_goods_flow and end >= GameState.firms.size():
		_match_market_executions()
	if end >= GameState.firms.size():
		_local_competition_valid = false
	return end

# JUAN-P47: denne vyuctovanie sluzbovej prevadzky (bez trhu): prijem z cache Society, mzdy podla obsadenosti
func _settle_service(firm: Dictionary, fac: Dictionary, recipe: Dictionary) -> Dictionary:
	var iso = str(fac.get("country", firm.country))
	var sc = float(fac.get("scale", 1.0))
	var tgt = target_workers(firm)
	var fill = 1.0 if tgt <= 0.0 else clampf(workers(firm) / tgt, 0.0, 1.0)
	var eff = firm_efficiency(firm) if str(firm.get("owner", "")) == "player" else 1.0
	var income = Society.service_income_day(firm) * clampf(eff / 0.95, 0.5, 1.2)
	var wage = _wage(iso, firm) * float(recipe.get("labor", 0.0)) * sc * fill
	var zr = float(recipe.get("rent", 10.0)) * sc * _zone_rent(str(fac.get("zone", "")))
	var mt = float(recipe.get("maintain", 0.0)) * sc
	var en = 0.0
	for in_id in recipe.get("inputs", {}).keys():
		en += float(recipe.inputs[in_id]) * sc * MarketSystem.price(iso, str(in_id))
	firm.cash = float(firm.cash) + income - wage - zr - mt - en
	return {"rev": income, "wages": wage, "rent": zr, "maint": mt, "cogs": en}

func _market_execution(iso: String, cid: String, side: String, firm: Dictionary, qty: float, unit_price: float) -> void:
	if not record_goods_flow:
		return
	var key = iso + "|" + cid
	if not _market_executions.has(key):
		_market_executions[key] = {"sellers": [], "buyers": []}
	_market_executions[key][side].append({"id": str(firm.get("id", "")), "player": str(firm.get("owner", "")) == "player", "qty": qty, "price": unit_price})

func _match_market_executions() -> void:
	var players := {}
	var journal_rows: Array = MarketSystem.route_transfers.duplicate()
	journal_rows.append_array(_direct_trades)
	for firm in GameState.firms:
		if str(firm.get("owner", "")) == "player":
			players[str(firm.get("id", ""))] = firm
	for key in _market_executions:
		var data: Dictionary = _market_executions[key]
		var parts = str(key).split("|")
		var npc: Dictionary = MarketSystem.matching_market.get(key, {})
		var sellers: Array = data.sellers.duplicate(true)
		var buyers: Array = data.buyers.duplicate(true)
		var market_price = MarketSystem.price(parts[0], parts[1])
		sellers.append({"id": "@market", "player": false, "qty": float(npc.get("supply", 0.0)), "price": market_price})
		buyers.append({"id": "@households", "player": false, "qty": float(npc.get("demand", 0.0)), "price": market_price})
		sellers.append({"id": "@market", "player": false, "qty": 1.0e100, "price": market_price})
		buyers.append({"id": "@market", "player": false, "qty": 1.0e100, "price": market_price})
		var si = 0
		var bi = 0
		while si < sellers.size() and bi < buyers.size():
			if float(sellers[si].qty) <= 0.000000001:
				si += 1
				continue
			if float(buyers[bi].qty) <= 0.000000001:
				bi += 1
				continue
			if str(sellers[si].id).begins_with("@") and str(buyers[bi].id).begins_with("@"):
				break
			var amount = minf(float(sellers[si].qty), float(buyers[bi].qty))
			var entry = {"day": GameState.day_index, "seller": str(sellers[si].id), "buyer": str(buyers[bi].id), "cid": parts[1], "src": parts[0], "dst": parts[0], "qty": amount, "seller_price": float(sellers[si].price), "buyer_price": float(buyers[bi].price)}
			journal_rows.append(entry)
			var seen := {}
			for id in [entry.seller, entry.buyer]:
				if players.has(id) and not seen.has(id):
					seen[id] = true
					_store_market_match(players[id], entry)
			sellers[si].qty = float(sellers[si].qty) - amount
			buyers[bi].qty = float(buyers[bi].qty) - amount
	var journal: Array = GameState.ext.get("market_journal", [])
	while not journal.is_empty() and int(journal[0].get("day", -1)) <= GameState.day_index - 30:
		journal.pop_front()
	if not journal_rows.is_empty():
		journal.append({"day": GameState.day_index, "rows": journal_rows})
		while journal.size() > 30:
			journal.pop_front()
	if not journal.is_empty() or GameState.ext.has("market_journal"):
		GameState.ext["market_journal"] = journal
	_market_executions.clear()
	_direct_trades.clear()

func _store_market_match(firm: Dictionary, entry: Dictionary) -> void:
	var days: Array = firm.get("goods_flow", [])
	if days.is_empty() or int(days[-1].get("day", -1)) != GameState.day_index:
		days.append({"day": GameState.day_index, "inputs": {}, "outputs": {}, "trades": []})
		if days.size() > 30:
			days.pop_front()
	var day: Dictionary = days[-1]
	if not day.has("market_matches"):
		day["market_matches"] = []
	day.market_matches.append(entry)
	firm["goods_flow"] = days

func _trace_internal_delivery(firm: Dictionary, facility_index: int, cid: String, quantity: float) -> void:
	if quantity <= 0.0:
		return
	var key = "%s|%d|%s" % [str(firm.get("id", "")), facility_index, cid]
	var left = quantity
	for request in _internal_requests.get(key, []):
		var delivered = minf(left, float(request.get("qty", 0.0)))
		if delivered > 0.0:
			var record: Dictionary = request.duplicate()
			record["qty"] = delivered
			_internal_delivered.append(record)
			left -= delivered
		if left <= 0.0:
			break

func _store_internal_deliveries() -> void:
	var participants := {}
	for firm in GameState.firms:
		if str(firm.get("owner", "")) == "player":
			participants[str(firm.get("id", ""))] = firm
	for delivery in _internal_delivered:
		for id in [str(delivery.seller), str(delivery.buyer)]:
			if not participants.has(id):
				continue
			var firm: Dictionary = participants[id]
			var days: Array = firm.get("goods_flow", [])
			if days.is_empty() or int(days[-1].get("day", -1)) != GameState.day_index:
				days.append({"day": GameState.day_index, "inputs": {}, "outputs": {}, "trades": []})
				if days.size() > 30:
					days.pop_front()
			var row: Dictionary = days[-1]
			if not row.has("internal_transfers"):
				row["internal_transfers"] = []
			row.internal_transfers.append(delivery)
			firm["goods_flow"] = days
	_internal_delivered.clear()

func _flow_add(rows: Dictionary, key: String, values: Dictionary) -> void:
	var row: Dictionary = rows.get(key, {})
	for field in values:
		row[field] = float(row.get(field, 0.0)) + float(values[field])
	rows[key] = row

func goods_flow_text(firm: Dictionary) -> String:
	var inputs := {}
	var outputs := {}
	var internal := {}
	var matches := {}
	for day in firm.get("goods_flow", []):
		if int(day.get("day", -100)) <= GameState.day_index - 30:
			continue
		for key in day.get("inputs", {}):
			_flow_add(inputs, str(key), day.inputs[key])
		for key in day.get("outputs", {}):
			_flow_add(outputs, str(key), day.outputs[key])
		for transfer in day.get("internal_transfers", []):
			var key = "%s|%s|%s" % [str(transfer.seller), str(transfer.buyer), str(transfer.cid)]
			_flow_add(internal, key, {"qty": transfer.qty})
		for trade in day.get("market_matches", []):
			var key = "%s|%s|%s|%s" % [str(trade.seller), str(trade.buyer), str(trade.cid), str(trade.dst)]
			var actual_price = float(trade.buyer_price) if str(trade.buyer) == str(firm.get("id", "")) else float(trade.seller_price)
			_flow_add(matches, key, {"qty": trade.qty, "value": float(trade.qty) * actual_price})
	var text = "\nVÝROBA A PREDAJ (posledných 30 dní):\n"
	if inputs.is_empty() and outputs.is_empty():
		return text + "Zatiaľ nie sú dostupné údaje.\n"
	for key in inputs:
		var item: Dictionary = DataLoader.commodity(str(key))
		var row: Dictionary = inputs[key]
		text += "• Vstup %s: nakúpené %.4f %s, z vlastnej korporácie %.4f %s; nákup %s\n" % [str(item.get("name", key)), float(row.get("bought", 0.0)), str(item.get("unit", "")), float(row.get("internal", 0.0)), str(item.get("unit", "")), EconMath.eur(float(row.get("cost", 0.0)))]
	for key in outputs:
		var parts = str(key).split("|")
		var item: Dictionary = DataLoader.commodity(parts[0])
		var row: Dictionary = outputs[key]
		var market = str(GameState.world.get(parts[1], {}).get("name_sk", parts[1]))
		text += "• %s: vyrobené %.2f %s, predané %.2f %s za %s; vlastnej korporácii %.2f %s. Trh: %s.\n" % [str(item.get("name", parts[0])), float(row.get("produced", 0.0)), str(item.get("unit", "")), float(row.get("sold", 0.0)), str(item.get("unit", "")), EconMath.eur(float(row.get("revenue", 0.0))), float(row.get("internal", 0.0)), str(item.get("unit", "")), market]
		var stock = 0.0
		for fac in firm.get("facilities", []):
			if str(fac.get("country", firm.get("country", ""))) == parts[1]:
				stock += float(fac.get("inventory", {}).get(parts[0], 0.0))
		text += "  Na sklade: %.4f %s.\n" % [stock, str(item.get("unit", ""))]
	for key in matches:
		var parts = str(key).split("|")
		var seller_name = _market_party_name(parts[0])
		var buyer_name = _market_party_name(parts[1])
		var item = DataLoader.commodity(parts[2])
		var country = str(GameState.world.get(parts[3], {}).get("name_sk", parts[3]))
		text += "• Obchod %s → %s: %s %.4f %s; %s, krajina trhu %s.\n" % [seller_name, buyer_name, str(item.get("name", parts[2])), float(matches[key].qty), str(item.get("unit", "")), EconMath.eur(float(matches[key].value)), country]
	if not outputs.is_empty():
		text += "Protistrany priraďuje trh podľa poradia pri zúčtovaní. Ďalší vývoz zo spoločných zásob trhu sa nesleduje po jednotlivých firmách.\n"
	for key in internal:
		var parts = str(key).split("|")
		var seller = GameState.firm_by_id(parts[0])
		var buyer = GameState.firm_by_id(parts[1])
		var commodity = DataLoader.commodity(parts[2])
		text += "• Vnútorná dodávka %s → %s: %s %.4f %s.\n" % [str(seller.get("name", parts[0])), str(buyer.get("name", parts[1])), str(commodity.get("name", parts[2])), float(internal[key].qty), str(commodity.get("unit", ""))]
	return text

func _market_party_name(id: String) -> String:
	if id == "@households":
		return "Domácnosti a štát"
	if id == "@market":
		return "Spoločný trh a jeho zásoby"
	var firm: Dictionary = GameState.firm_by_id(id)
	var name = str(firm.get("name", id))
	var corp_id = str(firm.get("corp", ""))
	var corps: Dictionary = GameState.ext.get("exch", {}).get("corps", {})
	var corp_name = str(corps.get(corp_id, {}).get("name", ""))
	return name + " (" + corp_name + ")" if corp_name != "" else name

func trade_flow_text(firm: Dictionary) -> String:
	var rows := {}
	for day in firm.get("goods_flow", []):
		if int(day.get("day", -100)) <= GameState.day_index - 30:
			continue
		for trade in day.get("trades", []):
			var key = "%s|%s|%s" % [str(trade.cid), str(trade.src), str(trade.dst)]
			_flow_add(rows, key, {"qty": trade.qty, "cost": trade.cost, "revenue": trade.revenue})
	var text = "\nOBCHODNÉ PRESUNY (posledných 30 dní):\n"
	if rows.is_empty():
		return text + "Zatiaľ nebol zaznamenaný obchod.\n"
	for key in rows:
		var parts = str(key).split("|")
		var item: Dictionary = DataLoader.commodity(parts[0])
		var row: Dictionary = rows[key]
		var src = str(GameState.world.get(parts[1], {}).get("name_sk", parts[1]))
		var dst = str(GameState.world.get(parts[2], {}).get("name_sk", parts[2]))
		var margin = float(row.revenue) - float(row.cost)
		text += "• %s: %.4f %s; trh %s → trh %s. Náklady %s, tržby %s, obchodný zisk %s (marža %.1f %%).\n" % [str(item.get("name", parts[0])), float(row.qty), str(item.get("unit", "")), src, dst, EconMath.eur(float(row.cost)), EconMath.eur(float(row.revenue)), EconMath.eur(margin), 100.0 * margin / maxf(float(row.revenue), 0.00001)]
	return text + "Konkrétnych dodávateľov a odberateľov súhrnný trh neurčuje.\n"

func _run_desks(firm: Dictionary, _rev_in: float, flow: Dictionary = {}) -> Dictionary:
	var totals = {"revenue": 0.0, "cost": 0.0}
	for fac in firm.facilities:
		var recipe: Dictionary = DataLoader.recipes.get(fac.get("recipe", ""), {})
		if not recipe.get("trade", false):
			continue
		var cid = str(fac.get("cargo", ""))
		var src = str(fac.get("src", firm.country))
		var dst = str(fac.get("dst", ""))
		if cid == "" or dst == "" or dst == src:
			var pick = _best_route(src)
			cid = pick.cid
			dst = pick.dst
			fac.cargo = cid
			fac.dst = dst
			fac.src = src
		if cid == "" or dst == "" or not DataLoader.commodities.has(cid):
			continue
		var cap = float(recipe.get("capacity", 30.0)) * float(fac.get("scale", 1.0))
		var src_px = MarketSystem.price(src, cid)
		var dst_px = MarketSystem.price(dst, cid)
		var fmult = 1.0
		if str(firm.get("owner", "")) == "player":
			fmult = float(GameState.player.modifiers.get("freight_mult", 1.0))
		var freight = MarketSystem.freight_unit(src, dst, cid) * fmult
		var tariff = GeopoliticsSystem.tariff(src, dst)
		var unit_cost = src_px * (1.0 + tariff) + freight
		if dst_px <= unit_cost * 1.02:
			continue
		var affordable = float(firm.cash) * 0.45 / max(unit_cost, 0.01)
		var qty = min(cap, affordable)
		qty = MarketSystem.try_arbitrage(src, dst, cid, qty)
		if qty <= 0.0:
			continue
		var cost = qty * unit_cost
		var gain = qty * dst_px
		firm.cash = float(firm.cash) - cost + gain
		totals.revenue += gain
		totals.cost += cost
		if record_goods_flow:
			_direct_trades.append({"day": GameState.day_index, "seller": "@market", "buyer": str(firm.get("id", "")), "cid": cid, "src": src, "dst": src, "qty": qty, "seller_price": src_px, "buyer_price": unit_cost, "kind": "desk_purchase"})
			_direct_trades.append({"day": GameState.day_index, "seller": str(firm.get("id", "")), "buyer": "@market", "cid": cid, "src": src, "dst": dst, "qty": qty, "seller_price": dst_px, "buyer_price": dst_px, "kind": "desk_sale"})
		if not flow.is_empty():
			flow.trades.append({"cid": cid, "src": src, "dst": dst, "qty": qty, "cost": cost, "revenue": gain})
	return totals

func _best_route(home: String) -> Dictionary:
	var best = {"cid": "", "dst": "", "score": 0.0}
	var home_c: Dictionary = DataLoader.countries.get(home, {})
	var candidates: Array = home_c.get("borders", []).duplicate()
	for extra in ["DE", "US", "CN", "NL", "PL", "FR", "SK", "CZ"]:
		if DataLoader.countries.has(extra):
			candidates.append(extra)
	for cid in ["coffee", "crude_oil", "wheat", "steel", "electronics", "copper"]:
		if not DataLoader.commodities.has(cid):
			continue
		for dst in candidates:
			if str(dst) == home:
				continue
			var spread = MarketSystem.price(str(dst), cid) - MarketSystem.price(home, cid) - MarketSystem.freight_unit(home, str(dst), cid)
			if spread > float(best.score):
				best = {"cid": cid, "dst": str(dst), "score": spread}
	return best

func _plan_for(firm: Dictionary, fi: int) -> Dictionary:
	for p in firm.get("plans", []):
		if int(p.fi) == fi:
			return p
	return {}

func _throughput(firm: Dictionary, fac: Dictionary, recipe: Dictionary) -> float:
	var iso = str(fac.get("country", firm.country))
	var c: Dictionary = GameState.world.get(iso, {})
	var util = float(fac.get("util", 1.0))
	if fac.get("auto", true):
		var unit_rev = 0.0
		var unit_cost = 0.0
		for out_id in recipe.get("outputs", {}).keys():
			unit_rev += float(recipe.outputs[out_id]) * MarketSystem.price(iso, out_id)
		for in_id in recipe.get("inputs", {}).keys():
			unit_cost += _input_qty(firm, recipe, in_id) * MarketSystem.price(iso, in_id)
		unit_cost += float(recipe.get("labor", 0.0)) * _wage(iso, firm)
		unit_cost += float(recipe.get("rent", 0.0)) + float(recipe.get("maintain", 0.0))
		var margin = (unit_rev - unit_cost) / max(unit_rev, 1.0)
		if margin < 0.0:
			util = 0.25
		elif margin < 0.08:
			util = 0.65
		else:
			util = 1.0
	var site = 1.0
	var endow_key = str(recipe.get("endow", ""))
	if endow_key != "":
		site = float(c.get("endow", {}).get(endow_key, 0.4))
	var infra = float(c.get("infra", c.get("infrastructure", 1.0))) * Society.infra_mult(iso)  # JUAN-P47: pristavy
	var rate = float(GameState.central.get(iso, {}).get("base_rate", GameState.central.get(iso, {}).get("policy", 0.02)))
	var invest = BankingSystem.investment_factor(rate)
	firm.last_invest = invest
	return max(0.0, util * float(fac.get("scale", 1.0)) * site * infra * invest * firm_efficiency(firm))

func _input_qty(firm: Dictionary, recipe: Dictionary, in_id: String) -> float:
	var q = float(recipe.inputs[in_id])
	if in_id == "electricity" and firm.get("owner", "") == "player":
		q *= float(GameState.player.modifiers.get("power_mult", 1.0))
	return q

# Planning and production must use the same researched input quantities.
# Copy only modified inputs; the shared recipe remains immutable.
func _production_spec(firm: Dictionary, recipe: Dictionary) -> Dictionary:
	var inputs: Dictionary = recipe.get("inputs", {})
	if not inputs.has("electricity") or firm.get("owner", "") != "player" or float(GameState.player.modifiers.get("power_mult", 1.0)) == 1.0:
		return recipe
	var spec = recipe.duplicate()
	spec.inputs = inputs.duplicate()
	spec.inputs.electricity = _input_qty(firm, recipe, "electricity")
	return spec

func _yield_mult(firm: Dictionary, recipe_id: String) -> float:
	if firm.get("owner", "") != "player":
		return 1.0
	if use_local_competition_cache and _local_competition_valid:
		var boost = 1.0
		if not str(firm.get("industry", "")) in ["ai_firm", "data_center"]:
			boost += minf(Brand.AI_BOOST_MAX, Brand.AI_BOOST_EACH * int(_player_ai_counts.get(str(firm.get("country", "")), 0)))
		return _yield_mult0(firm, recipe_id) * boost
	return _yield_mult0(firm, recipe_id) * Brand.ai_boost(firm)  # JUAN21: AI firma v krajine zvysuje vykon

func _yield_mult0(firm: Dictionary, recipe_id: String) -> float:
	var m: Dictionary = GameState.player.modifiers
	if recipe_id in ["wheat_farm", "coffee_farm", "livestock"]:
		return float(m.get("yield_agro", 1.0))
	if recipe_id in ["chem_plant", "pharma_lab"]:
		return float(m.get("yield_chem", 1.0))
	if recipe_id == "arms_plant":
		return float(m.get("yield_weapons", 1.0)) * float(m.get("yield_factory", 1.0))
	# JUAN5: research tree - tazba, tovarne, spotrebne produkty
	if recipe_id in ["oil_well", "coal_mine", "iron_mine", "copper_mine"]:
		return float(m.get("yield_mining", 1.0))
	var y = 1.0
	if recipe_id in ["steel_mill", "auto_plant", "electronics_plant", "textile_mill", "power_coal"]:
		y *= float(m.get("yield_factory", 1.0))
	if recipe_id in ["cafe", "textile_mill", "auto_plant", "electronics_plant"]:
		y *= float(m.get("yield_consumer", 1.0))
	return y

func _wage(iso: String, firm: Dictionary) -> float:
	var c: Dictionary = GameState.world.get(iso, {})
	var eur_pc = float(c.get("gdp_pc_usd", 20000.0)) / max(GameState.usd_per_eur, 0.2)
	var mult = 1.0
	if firm.get("owner", "") == "player":
		mult = float(GameState.player.modifiers.get("labor_mult", 1.0))
	return eur_pc * 0.40 / 365.0 * mult * LawSystem.wage_mult(iso)

func _local_mult(firm: Dictionary, fac: Dictionary, cid: String) -> float:
	var com: Dictionary = DataLoader.commodity(cid)
	if com.get("tradable", true) and not DataLoader.recipes.get(fac.recipe, {}).get("local", false):
		return 1.0
	var comp = 0
	if use_local_competition_cache and _local_competition_valid:
		var key = str(fac.country) + "|" + str(firm.industry)
		comp = int(_local_competition.get(key, 0))
		if str(_local_competition_members.get(str(firm.id), "")) == key:
			comp -= 1
	else:
		for other in GameState.firms:
			if other.id == firm.id or other.get("closed", false):
				continue
			if str(other.country) == str(fac.country) and str(other.industry) == str(firm.industry):
				comp += 1
	var m = 1.0 / (1.0 + 0.12 * comp)
	var zone = str(fac.get("zone", ""))
	if zone == "commercial" and cid == "food_service":
		m *= 1.16
	elif zone == "industrial" and cid == "food_service":
		m *= 0.78
	elif zone == "port" and cid == "logistics":
		m *= 1.2
	return m

func _zone_rent(zone: String) -> float:
	if zone == "commercial":
		return 1.25
	if zone == "port":
		return 1.1
	return 1.0

# JUAN-FIX (A2-K0c4 DIVIDENDY): firma si necha prevadzkovu rezervu (RESERVE_DAYS dni nakladov,
# EMA z history), cely zvysok ide hracovi. Stratova firma (zisk za obdobie <= 0) nevyplaca nic.
const RESERVE_DAYS = 30
var last_dividends = 0.0  # runtime pre UI: suma poslednej mesacnej vyplaty
signal dividends_paid(total: float)

func _history_cost(row: Dictionary) -> float:
	# Older v3 rows omitted maintenance, but net profit already included it.
	if row.has("rev") and row.has("profit"):
		return maxf(0.0, float(row.rev) - float(row.profit))
	return float(row.get("cogs", 0.0)) + float(row.get("wages", 0.0)) + float(row.get("rent", 0.0)) + float(row.get("tax", 0.0)) + float(row.get("maintain", 0.0))

func firm_reserve(firm: Dictionary) -> float:
	var hist: Array = firm.get("history", [])
	if hist.is_empty():
		return 0.0
	var alpha = 2.0 / (30.0 + 1.0)
	var ema = -1.0
	for h in hist:
		var c = _history_cost(h)
		ema = c if ema < 0.0 else alpha * c + (1.0 - alpha) * ema
	return max(0.0, ema) * float(RESERVE_DAYS)

func firm_period_profit(firm: Dictionary) -> float:
	var hist: Array = firm.get("history", [])
	var since = int(firm.get("last_div_day", -1))
	var total = 0.0
	if since >= 0:
		for h in hist:
			if int(h.get("day", -1)) > since:
				total += float(h.get("profit", 0.0))
	else:
		var start = max(0, hist.size() - 30)
		for i in range(start, hist.size()):
			total += float(hist[i].get("profit", 0.0))
	return total

# Vrati sumu vyplatenu vsetkymi firmami hraca.
func pay_dividends() -> float:
	var total = 0.0
	for firm in GameState.player_firms():
		var profit = firm_period_profit(firm)
		var pay = 0.0
		if profit > 0.0:
			pay = max(0.0, float(firm.cash) - firm_reserve(firm))
			if str(firm.get("industry", "")) in ["stock_broker", "invest_fund"]:
				pay = minf(pay, profit)  # investicne firmy si drzia vlozeny kapital
		if pay > 0.0:
			BankingSystem._pull_dividend(pay, firm)
		firm.last_dividend = pay
		firm.last_div_day = GameState.day_index
		total += pay
	last_dividends = total
	if total > 0.0:
		dividends_paid.emit(total)
	return total

# Prehlad pre panel "Moje firmy": sucty za poslednych 30 dni.
func firm_summary(firm: Dictionary) -> Dictionary:
	var hist: Array = firm.get("history", [])
	var rev = 0.0
	var costs = 0.0
	var profit = 0.0
	var start = max(0, hist.size() - 30)
	for i in range(start, hist.size()):
		var h: Dictionary = hist[i]
		rev += float(h.get("rev", 0.0))
		costs += _history_cost(h)
		profit += float(h.get("profit", 0.0))
	return {"rev": rev, "costs": costs, "profit": profit, "cash": float(firm.get("cash", 0.0)),
		"reserve": firm_reserve(firm), "last_dividend": float(firm.get("last_dividend", 0.0))}


# ===== JUAN3: umiestnenie budov, mesacna historia, potreby firmy, prava ruka =====
# Typy budov pre "Postaviť tu": kind -> industry id (ceny z data/industries.json:
# Kaviareň cafe 80 000 € + prevádzkový kapitál 17 600 €; Kancelária finance_office 220 000 € + 48 400 €;
# Banka = licencia BankingSystem.found_player_bank 500 000 €).
const BUILD_KINDS = {"cafe": "cafe", "office": "finance_office", "bank": "bank", "coal_mine": "coal_mine", "iron_mine": "iron_mine", "copper_mine": "copper_mine", "oil_well": "oil_well", "farm": "wheat_farm", "pmc": "pmc_unit"}
const BUILD_NAMES = {"cafe": "Kaviareň", "office": "Kancelária", "bank": "Banka", "coal_mine": "Uhoľná baňa", "iron_mine": "Baňa na rudu", "copper_mine": "Medená baňa", "oil_well": "Ropný vrt", "farm": "Farma", "pmc": "PMC (súkromná bezpečnostná firma)"}
const MONTH_HIST_MAX = 24
const NO_MANAGER_EFF = 0.8      # bez pravej ruky ide firma na 80 %
const NO_MANAGER_BUY = 0.5      # bez pravej ruky sa dokupi len polovica materialu
const NO_MANAGER_QUIT = 0.05    # bez pravej ruky odide kazdy mesiac 5 % ludi a nikto ich nenahradi
const MANAGER_NAMES = ["Ján Kováč", "Petra Horváthová", "Marek Szabó", "Eva Nagyová", "Tomáš Baláž", "Lucia Molnárová", "Martin Varga", "Zuzana Tóthová", "Peter Lukáč", "Katarína Bieliková"]

func build_cost(kind: String) -> float:
	if kind == "bank":
		return 500000.0
	var ind: Dictionary = DataLoader.industries.get(str(BUILD_KINDS.get(kind, kind)), {})
	var cost = float(ind.get("cost", 0.0)) * Difficulty.cost_mult()  # JUAN4
	return cost + max(4000.0, cost * 0.22)

# pos = svetove suradnice mapy (WorldMap._to_world). Vrati {ok, reason, id}.
func place_at(iso: String, kind: String, pos: Vector2) -> Dictionary:
	if not BUILD_KINDS.has(kind) and DataLoader.industries.has(kind):
		kind = _kind_for(kind)  # JUAN9: kazdy typ firmy sa da postavit na mape
	if not BUILD_KINDS.has(kind) and not DataLoader.industries.has(kind) and kind != "hq":
		return {"ok": false, "reason": "Neznámy typ budovy.", "id": ""}
	if not GameState.world.has(iso):
		return {"ok": false, "reason": "Neznáma krajina.", "id": ""}
	var terr: Dictionary = TerrainSystem.can_place(str(BUILD_KINDS.get(kind, kind)), iso, pos)  # JUAN4: teren a naleziska
	if not bool(terr.get("ok", true)):
		return {"ok": false, "reason": str(terr.get("reason", "")), "id": ""}
	if kind == "hq":  # JUAN10: centrala korporacie
		var cid = str(GameState.player.get("hq_corp", ""))
		var eh = Empire.set_hq(cid, iso, pos)
		return {"ok": eh == "", "reason": eh, "id": cid}
	if kind == "bank":
		var nm = "Banka %s" % str(GameState.world[iso].get("name_sk", iso))
		var err_b = BankingSystem.found_player_bank(nm, iso)
		if err_b != "":
			return {"ok": false, "reason": err_b, "id": ""}
		var bank: Dictionary = BankingSystem._player_bank()
		bank["pos"] = [pos.x, pos.y]
		return {"ok": true, "reason": "", "id": str(bank.get("id", ""))}
	var err = GameState.found_firm(str(BUILD_KINDS.get(kind, kind)), "", iso)
	if err != "":
		return {"ok": false, "reason": err, "id": ""}
	var firm: Dictionary = GameState.firms[GameState.firms.size() - 1]
	firm["pos"] = [pos.x, pos.y]
	var cty = TerrainSystem.urban_at(iso, pos)
	if not cty.is_empty():
		firm["city"] = str(cty.name)
	elif str(terr.get("city", "")) != "":
		firm["city"] = str(terr.city)  # JUAN-P47: pristav/letisko pri meste
	return {"ok": true, "reason": "", "id": str(firm.get("id", ""))}

func _kind_for(ind_id: String) -> String:
	for k in BUILD_KINDS.keys():
		if str(BUILD_KINDS[k]) == ind_id:
			return str(k)
	return ind_id

func firm_pos(firm: Dictionary) -> Variant:
	var p = firm.get("pos", null)
	if typeof(p) == TYPE_ARRAY and p.size() >= 2:
		return Vector2(float(p[0]), float(p[1]))
	return null

func _main_recipe(firm: Dictionary) -> Dictionary:
	var facs: Array = firm.get("facilities", [])
	if facs.is_empty():
		return {}
	return DataLoader.recipes.get(str(facs[0].get("recipe", "")), {})

func target_workers(firm: Dictionary) -> float:
	var total = 0.0
	for fac in firm.get("facilities", []):
		var r: Dictionary = DataLoader.recipes.get(str(fac.get("recipe", "")), {})
		total += float(r.get("labor", 0.0)) * float(fac.get("scale", 1.0))
	return total

func workers(firm: Dictionary) -> float:
	return float(firm.get("workers", target_workers(firm)))

# JUAN-P47: realisticky pocet ludi. "labor" ostava ekonomicka pracovna jednotka (mzdy, recepty, save sa nemenia);
# "staff" v recepte je pocet ludi pri skale 1. Obsadenost (workers / target_workers) sa zachovava.
func staff_ratio(recipe: Dictionary) -> float:
	var lab = float(recipe.get("labor", 0.0))
	if lab <= 0.0:
		return 1.0
	return float(recipe.get("staff", lab)) / lab

func target_headcount(firm: Dictionary) -> float:
	var total = 0.0
	for fac in firm.get("facilities", []):
		var r: Dictionary = DataLoader.recipes.get(str(fac.get("recipe", "")), {})
		total += float(r.get("labor", 0.0)) * staff_ratio(r) * float(fac.get("scale", 1.0))
	return total

func headcount(firm: Dictionary) -> float:
	var tw = target_workers(firm)
	if tw <= 0.0:
		return 0.0
	return round(target_headcount(firm) * workers(firm) / tw)

func has_manager(firm: Dictionary) -> bool:
	var m = firm.get("manager", {})
	return typeof(m) == TYPE_DICTIONARY and not m.is_empty()

# Efektivita vyroby: NPC firmy 1.0; hrac bez pravej ruky 0.8 * obsadenost; s pravou rukou 0.9 + 0.3 * skill.
func firm_efficiency(firm: Dictionary) -> float:
	if str(firm.get("owner", "")) != "player":
		return 1.0
	var tgt = target_workers(firm)
	var staff = 1.0 if tgt <= 0.0 else clampf(workers(firm) / tgt, 0.0, 1.0)
	var soc = float(firm.get("soc_mult", 1.0))  # JUAN-P47: spokojnost, vzdelanie, akademia, univerzita (mesacne)
	if has_manager(firm):
		return (0.9 + 0.3 * clampf(float(firm.manager.get("skill", 0.5)), 0.0, 1.0)) * staff * soc
	return NO_MANAGER_EFF * staff * soc

func buy_share(firm: Dictionary) -> float:
	if str(firm.get("owner", "")) != "player" or has_manager(firm):
		return 1.0
	return NO_MANAGER_BUY

func manager_candidates(firm: Dictionary) -> Array:
	var out: Array = []
	var iso = str(firm.get("country", "SK"))
	var base = _wage(iso, firm) * 30.0
	var seed_v = absi(str(firm.get("id", "")).hash()) + int(GameState.date.get("m", 1)) * 7 + int(GameState.date.get("y", 2024)) * 13
	for i in 3:
		var h = absi(hash(seed_v + i * 101))
		var skill = 0.3 + float(h % 61) / 100.0  # 0.30 .. 0.90
		var gender = "f" if ((h / 977) + int(GameState.config.get("seed", 47))) % 2 == 1 else "m"  # JUAN5 #17
		var nm = DataLoader.person_name(iso, h + int(GameState.config.get("seed", 47)) * 7919, gender)
		out.append({"name": nm, "gender": gender, "skill": skill,
			"salary": snappedf(base * (2.0 + 4.0 * skill), 10.0)})
	return out

func hire_manager(firm_id: String, cand: Dictionary) -> String:
	var firm = _player_firm(firm_id)
	if firm.is_empty():
		return "Firma nie je tvoja."
	firm["manager"] = {"name": str(cand.get("name", "?")), "gender": str(cand.get("gender", "m")), "skill": float(cand.get("skill", 0.5)), "salary": float(cand.get("salary", 0.0)) * PoliticsSystem.bonus_mult("mgr_cost")}  # JUAN4: focus Siet zien
	GameState.post_news("%s je nová pravá ruka vo firme %s." % [firm.manager.name, firm.name])
	return ""

func fire_manager(firm_id: String) -> String:
	var firm = _player_firm(firm_id)
	if firm.is_empty() or not has_manager(firm):
		return "Firma nemá pravú ruku."
	GameState.post_news("%s odchádza z firmy %s." % [firm.manager.name, firm.name])
	firm["manager"] = {}
	return ""

# Mesacna uzavierka hracovych firiem (volane z GameState pri zmene mesiaca, pred dividendami).
func close_month(y: int, m: int) -> void:
	for firm in GameState.player_firms():
		var acc: Dictionary = firm.get("month_acc", {})
		var mh: Array = firm.get("month_hist", [])
		mh.append({"y": y, "m": m, "rev": float(acc.get("rev", 0.0)), "costs": float(acc.get("costs", 0.0)), "profit": float(acc.get("profit", 0.0))})
		while mh.size() > MONTH_HIST_MAX:
			mh.pop_front()
		firm["month_hist"] = mh
		firm["month_acc"] = {}
		var tgt = target_workers(firm)
		if has_manager(firm):
			firm["workers"] = tgt  # prava ruka doplni/prepusti ludi na ciel
		else:
			firm["workers"] = max(0.0, workers(firm) * (1.0 - NO_MANAGER_QUIT))

# Co firma musi kupovat (mesacne pri aktualnom tempe).
func firm_needs(firm: Dictionary) -> Array:
	var out: Array = []
	for fac in firm.get("facilities", []):
		var recipe: Dictionary = DataLoader.recipes.get(str(fac.get("recipe", "")), {})
		if recipe.is_empty() or recipe.get("trade", false) or recipe.has("service"):
			continue
		var iso = str(fac.get("country", firm.get("country", "")))
		var daily = _throughput(firm, fac, recipe)
		for in_id in recipe.get("inputs", {}).keys():
			var qty = _input_qty(firm, recipe, in_id) * daily * 30.0
			out.append({"id": str(in_id), "name": str(DataLoader.commodity(str(in_id)).get("name", in_id)), "qty": qty, "cost": qty * MarketSystem.price(iso, str(in_id))})
	return out

func firm_detail(firm: Dictionary) -> Dictionary:
	var iso = str(firm.get("country", ""))
	var sm = firm_summary(firm)
	var w = workers(firm)
	return {
		"summary": sm, "needs": firm_needs(firm), "workers": w, "target_workers": target_workers(firm),
		"people": headcount(firm), "target_people": round(target_headcount(firm)),
		"wage_month": _wage(iso, firm) * w * 30.0, "efficiency": firm_efficiency(firm),
		"manager": firm.get("manager", {}), "month_hist": firm.get("month_hist", []),
	}
