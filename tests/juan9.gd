extends RefCounted
# JUAN9 Faza A: viac bank, vnutorne dodavky v korporacii, rucne umiestnenie vsetkych typov, ikonky
var u

func run(host) -> void:
	u = host
	_banks()
	_internal()
	_placement()
	_icons()
	_stocks10()
	_quote10()
	_empire10()
	_juan13()
	_juan15()
	_juan17()
	_juan19()
	_juan20()
	_juan21()
	_juan22()
	_juan23()

func _banks() -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 5.0e6
	var e1 = BankingSystem.found_player_bank("Banka A", "SK")
	var e2 = BankingSystem.found_player_bank("Banka B", "CZ")
	u._chk("j9_two_banks", e1 == "" and e2 == "" and BankingSystem.player_banks().size() == 2, "%s|%s" % [e1, e2])
	var b: Dictionary = BankingSystem.player_banks()[0]
	BankProducts.set_rates(b, 0.03, 0.05, 0.07, 0.1)
	u._chk("j9_one_deposit_rate", absf(float(b.deposit_rate) - float(b.sav_rate)) < 1e-9)
	u._chk("j9_help_text", BankingSystem.HELP.find("Záloha") >= 0 and BankingSystem.HELP.find("Limit") >= 0)

func _internal() -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 2.0e7
	GameState.found_firm("coal_mine", "", "SK")
	var mine: Dictionary = GameState.player_firms()[GameState.player_firms().size() - 1]
	GameState.found_firm("power_coal", "", "SK")
	var plant: Dictionary = GameState.player_firms()[GameState.player_firms().size() - 1]
	GameState.found_firm("power_coal", "", "CZ")
	var plant_cz: Dictionary = GameState.player_firms()[GameState.player_firms().size() - 1]
	# bez korporacie: nic vnutorne
	IndustrySystem.plan_and_post()
	var own0 = float(plant.facilities[0].get("internal", {}).get("coal", 0.0))
	u._chk("j9_no_corp_market", own0 == 0.0, str(own0))
	StockMarket.setup()
	var cerr = StockMarket.create_corp("Uhlie Holding", [str(mine.id), str(plant.id), str(plant_cz.id)])
	var cid = str(plant.get("corp", "")) if cerr == "" else ""
	IndustrySystem.plan_and_post()
	var own1 = float(plant.facilities[0].get("internal", {}).get("coal", 0.0))
	var own_cz = float(plant_cz.facilities[0].get("internal", {}).get("coal", 0.0))
	var own_el = float(mine.facilities[0].get("internal", {}).get("electricity", 0.0))
	u._chk("j9_corp_same_country_internal", cid != "" and own1 > 0.0, "%s coal=%.2f" % [cid, own1])
	u._chk("j9_other_country_market", own_cz == 0.0, str(own_cz))
	u._chk("j9_electricity_internal", own_el > 0.0, str(own_el))
	u._chk("j9_transport_cost_only", IndustrySystem.TRANSPORT_SHARE < 0.2)

func _placement() -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 5.0e7
	var m = load("res://scripts/ui/world_map.gd").new()
	m._ready()
	var cap: Vector2 = m.capital_of("SK")
	var c = TerrainSystem.urban_at("SK", cap)
	u._chk("j9_cap_is_city", not c.is_empty())
	var hotel = IndustrySystem.place_at("SK", "hotel", cap)
	u._chk("j9_place_any_type", bool(hotel.ok), str(hotel))
	var nuke = IndustrySystem.place_at("SK", "nuclear_plant", cap)
	u._chk("j9_nuke_not_in_city", not bool(nuke.ok) and str(nuke.reason).find("mest") >= 0, str(nuke.reason))
	var far = cap + Vector2(400, 400)
	var cafe = TerrainSystem.can_place("cafe", "SK", far)
	u._chk("j9_cafe_needs_city", not bool(cafe.ok))
	var ap = TerrainSystem.can_place("airport", "SK", cap)
	u._chk("j9_airport_msg", not bool(ap.ok) and str(ap.reason) != "", str(ap.reason))
	var bank = IndustrySystem.place_at("SK", "bank", cap)
	u._chk("j9_bank_is_map_firm", bool(bank.ok) and BankingSystem.player_banks().size() >= 1, str(bank))
	var agg: Dictionary = m.country_markers()
	u._chk("j9_country_aggregate", agg.has("SK") and int(agg.SK.n) >= 2, str(agg.get("SK", {})))
	m.free()

func _icons() -> void:
	var miss: Array = []
	for id in DataLoader.industries.keys():
		if not FileAccess.file_exists("res://assets/icons/%s.png" % str(id)):
			miss.append(id)
	u._chk("j9_icon_every_type", miss.is_empty() and FileAccess.file_exists("res://assets/icons/bank.png"), str(miss))

func _stocks10() -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 1.0e12
	StockMarket.setup()
	var rows = StockMarket.listings()
	var secs = {}
	for r in rows:
		secs[str(r.sector)] = true
	u._chk("j10_100_listed", rows.size() >= 100, str(rows.size()))
	u._chk("j10_sectors", secs.size() >= 10, str(secs.keys()))
	StockMarket.weekly()
	u._chk("j10_sector_index", StockMarket.sector_index("arms") > 0.0 and (StockMarket.ex().sidx.arms as Array).size() >= 1)
	var t = ""
	for r in rows:
		if str(r.kind) == "nat":
			t = str(r.ticker)
			break
	u._chk("j10_no_absorb_small", not StockMarket.can_absorb(t))
	var berr = StockMarket.buy(t, StockMarket.SHARES * 0.6)
	u._chk("j10_absorb_ready", StockMarket.can_absorb(t), "%s stake %.2f" % [berr, StockMarket.stake(t)])
	GameState.found_firm("cafe", "", "SK")
	GameState.found_firm("bakery", "", "SK")
	var pf = GameState.player_firms()
	StockMarket.create_corp("A Holding", [str(pf[0].id), str(pf[1].id)])
	var cid = str(pf[0].get("corp", ""))
	var v0 = StockMarket.corp_value(StockMarket.ex().corps[cid])
	var e = StockMarket.absorb_into_corp(cid, t)
	u._chk("j10_absorbed", e == "" and str(StockMarket.listing(t).in_corp) == cid and StockMarket.corp_value(StockMarket.ex().corps[cid]) > v0, e)
	u._chk("j10_absorb_once", StockMarket.absorb_into_corp(cid, t) != "")

func _quote10() -> void:
	u._new()
	GameState.config.progression = false
	StockMarket.setup()
	var t = str(StockMarket.listings()[0].ticker)
	GameState.player.cash = 100.0
	var q = StockMarket.quote(t, 1000.0, "buy")
	u._chk("j10_quote_poor", not bool(q.ok) and str(q.reason).find("peňazí") >= 0 and float(q.fee) > 0.0, str(q.reason))
	GameState.player.cash = 1.0e9
	var q2 = StockMarket.quote(t, 1000.0, "buy")
	var c0 = float(GameState.player.cash)
	StockMarket.buy(t, 1000.0)
	u._chk("j10_quote_matches_buy", absf((c0 - float(GameState.player.cash)) - float(q2.total)) < 0.01 and absf(StockMarket.stake(t) - float(q2.stake_after)) < 1e-9)
	var q3 = StockMarket.quote(t, 500.0, "sell")
	var c1 = float(GameState.player.cash)
	StockMarket.sell(t, 500.0)
	u._chk("j10_quote_matches_sell", absf((float(GameState.player.cash) - c1) - float(q3.total)) < 0.01)

func _empire10() -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 5.0e11
	StockMarket.setup()
	var cap: Vector2 = TerrainSystem.cities("SK")[0].pos
	var city = str(TerrainSystem.cities("SK")[0].name)
	# 5: budova len cez realitku
	u._chk("j10_building_needs_realty", Empire.buy_building("SK", city) != "")
	GameState.found_firm("real_estate", "", "SK")
	u._chk("j10_building_buy", Empire.buy_building("SK", city) == "" and Empire.buildings_in("SK", city).size() == 1)
	var c0 = float(GameState.player.cash)
	Empire.monthly()
	u._chk("j10_building_rent", float(GameState.player.cash) > c0)
	u._chk("j10_refinery_gasworks", DataLoader.industries.has("oil_refinery") and DataLoader.industries.has("gas_works") and DataLoader.commodity_ids.has("fuel"))
	var m = load("res://scripts/ui/world_map.gd").new()
	m._ready()
	var inf = m.infra_data()
	u._chk("j10_infra", inf.roads.size() > 50 and inf.ports.size() > 10 and inf.airports.size() > 10 and inf.lanes.size() > 5, "r%d p%d a%d l%d" % [inf.roads.size(), inf.ports.size(), inf.airports.size(), inf.lanes.size()])
	m.free()
	# 7: charita
	var r0 = Empire.popularity()
	var de = Empire.donate("SK", 200000.0)
	u._chk("j10_charity", de == "" and Empire.popularity() > r0, "%s %.0f->%.0f" % [de, r0, Empire.popularity()])
	for i in 10:
		Empire.donate("SK", 200000.0)
	u._chk("j10_charity_cap", Empire.popularity() <= r0 + 5.5)
	# 8: staty
	var s = Empire.stats()
	u._chk("j10_stats", s.has("employees") and s.has("influence") and s.has("security") and float(s.worth) > 0.0)
	# 9: kupa statu
	var p = Empire.state_price("SK")
	u._chk("j10_state_price", p > 1e9, EconMath.eur(p))
	GameState.player.cash = 10.0
	u._chk("j10_state_too_poor", Empire.buy_state("SK") != "")
	GameState.player.cash = p * 3.0
	u._chk("j10_state_buy", Empire.buy_state("SK") == "" and Empire.owns_state("SK"))
	u._chk("j10_state_gov", Empire.set_state_gov("SK", "monarchy") == "" and str(PoliticsSystem.country("SK").gov) == "monarchy")
	# HQ + dane
	GameState.found_firm("cafe", "", "CZ")
	GameState.found_firm("bakery", "", "CZ")
	var pf = GameState.player_firms()
	var a = pf[pf.size() - 1]
	var b = pf[pf.size() - 2]
	StockMarket.create_corp("Test Holding", [str(a.id), str(b.id)])
	var cid = str(a.corp)
	u._chk("j10_hq_needs_city", Empire.set_hq(cid, "SK", cap + Vector2(300, 300)) != "")
	u._chk("j10_hq_set", Empire.set_hq(cid, "SK", cap) == "" and Empire.tax_iso(a) == "SK")
	u._chk("j10_hq_own_state_tax", Empire.tax_mult(a) == Empire.STATE_TAX_MULT)
	var cz = TerrainSystem.cities("CZ")[0].pos
	var cash1 = float(GameState.player.cash)
	u._chk("j10_hq_move_fee", Empire.set_hq(cid, "CZ", cz) == "" and float(GameState.player.cash) <= cash1 - Empire.HQ_FEE_MIN + 0.01 and Empire.tax_iso(a) == "CZ")
	# financna divizia
	var d = Empire.fin(cid)
	d.on = true
	d.trade = true
	d.acquire = true
	d.max_deal = 1.0e12
	a.month_hist = [{"rev": 1000.0, "costs": 0.0, "profit": 100000.0}]
	a.cash = 200000.0
	b.month_hist = [{"rev": 0.0, "costs": 500.0, "profit": -5000.0}]
	Empire.fin_monthly(cid)
	u._chk("j10_fin_budget", float(d.budget) > 0.0 and (d.flags as Array).size() >= 1, "b=%.0f flags=%d" % [float(d.budget), (d.flags as Array).size()])
	d.budget = 1.0e11
	for w in 6:
		StockMarket.weekly()
	Empire.fin_weekly(cid)
	var absorbed = 0
	for r in StockMarket.listings():
		if str(r.get("in_corp", "")) == cid:
			absorbed += 1
	u._chk("j10_fin_acquire_merge", absorbed >= 1 and (d.log as Array).size() >= 1, "abs=%d log=%s" % [absorbed, str((d.log as Array).slice(0, 2))])
	# 6: fond
	GameState.found_firm("invest_fund", "", "SK")
	var fnd = GameState.player_firms()[GameState.player_firms().size() - 1]
	fnd.cash = 1.0e7
	Empire.fund_monthly(fnd)
	u._chk("j10_fund_holdings", Empire.fund_rows(fnd).size() >= 1 and (fnd.fund.log as Array).size() >= 1)
	# save roundtrip
	var dd = GameState.to_dict()
	u._chk("j10_save_ext", JSON.stringify(dd).find("\"emp\"") >= 0)

func _juan13() -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 1.0e9
	StockMarket.setup()
	# zavislost
	var d0 = Empire.dependency("SK")
	u._chk("j13_dep_none", float(d0.index) < 10.0 and str(d0.label) == "Žiadna", str(d0.index))
	for i in 6:
		GameState.found_firm("power_coal", "", "SK")
	for f in GameState.player_firms():
		f.month_hist = [{"rev": 2.0e8, "costs": 0.0, "profit": 1.0e7}]
		f.workers = 5000.0
	var d1 = Empire.dependency("SK")
	u._chk("j13_dep_grows", float(d1.index) > float(d0.index) + 10.0 and (d1.resources as Array).size() >= 1, "%.1f %s" % [float(d1.index), str(d1.parts)])
	u._chk("j13_dep_text", Empire.dependency_text("SK").find("ZÁVISLOSŤ") >= 0)
	var c0 = PoliticsSystem.action_chance("CZ", "lobby_relief")
	var c1 = PoliticsSystem.action_chance("SK", "lobby_relief")
	u._chk("j13_dep_lobby", c1 >= c0, "%.2f %.2f" % [c0, c1])
	# pravne oddelenie
	BankingSystem.found_player_bank("Právna banka", "CZ")
	var b: Dictionary = BankingSystem.player_banks()[0]
	b.defaults_total = 1.0e6
	b.recovered_total = 0.0
	b.written_off = 0.0
	var p0 = BankProducts.legal_chance(b)
	u._chk("j13_legal_base", p0 >= 0.4 and p0 <= 0.6, str(p0))
	u._chk("j13_legal_none", BankProducts.legal_monthly(b).is_empty())
	BankProducts.hire_lawyer(b, 2)
	BankProducts.train_lawyers(b)
	var p1 = BankProducts.legal_chance(b)
	u._chk("j13_legal_level", p1 > p0)
	var r = BankProducts.legal_monthly(b, 0.0)
	u._chk("j13_legal_win", float(r.got) > 0.0 and float(r.cost) == 2.0 * BankProducts.LAWYER_MONTHLY, str(r))
	var rl = BankProducts.legal_monthly(b, 0.999)
	u._chk("j13_legal_lose", float(rl.get("got", 0.0)) == 0.0)
	var f2 = GameState.player_firms()
	StockMarket.create_corp("Lex Holding", [str(f2[0].id), str(f2[1].id)])
	BankProducts.set_bank_corp(b, str(f2[0].corp))
	u._chk("j13_legal_corp", BankProducts.legal_chance(b) > p1)
	GameState.player.cash = 1.0e13
	Empire.buy_state("CZ")
	u._chk("j13_legal_full_dep", BankProducts.legal_chance(b) >= 0.99 and Empire.dependency("CZ").label == "Úplná")
	# dlhopisy
	GameState.player.cash = 1000.0
	var q = BankingSystem.bond_quote(100000.0, 0.01, 5.0)
	var q2 = BankingSystem.bond_quote(100000.0, 0.12, 5.0)
	u._chk("j13_bond_discount", float(q.proceeds) < float(q2.proceeds) and float(q.proceeds) < 100000.0)
	var nw0 = GameState.net_worth()
	var e = BankingSystem.issue_bond_ex(100000.0, 0.06, 5.0)
	u._chk("j13_bond_issue", e == "" and absf(GameState.net_worth() - nw0 - (float(BankingSystem.bond_quote(100000.0, 0.06, 5.0).proceeds) - 100000.0)) < 2.0e4, "%s nw %.0f->%.0f" % [e, nw0, GameState.net_worth()])
	u._chk("j13_bond_limit", BankingSystem.issue_bond_ex(1.0e15, 0.06, 5.0) != "")


# JUAN15: burzova firma, odberatelia, DEV save
func _juan15() -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 1.0e9
	StockMarket.setup()
	for _w in 10:
		StockMarket.weekly()
	var e = GameState.found_firm("stock_broker", "", "SK")
	var bf: Dictionary = {}
	for f in GameState.player_firms():
		if str(f.industry) == "stock_broker":
			bf = f
	u._chk("j15_broker_found", not bf.is_empty(), str(e))
	if bf.is_empty():
		return
	bf.cash = 2.0e7
	var b = Empire.broker(bf)
	b.risk = 2
	b.cap_pct = 0.8
	# vynut podhodnotene akcie
	var n = 0
	for row in StockMarket.listings():
		if str(row.kind) in ["nat", "rival"] and n < 5:
			row.price = float(row.price) * 0.7
			n += 1
	Empire.broker_weekly(bf)
	u._chk("j15_broker_buys", (b.own as Dictionary).size() >= 1 and int(b.trades) >= 1, "own=%d cash=%.0f" % [(b.own as Dictionary).size(), float(bf.cash)])
	u._chk("j15_broker_fee", float(b.fees) >= Empire.BROKER_FEE_WEEK)
	var t = str(b.own.keys()[0]) if not (b.own as Dictionary).is_empty() else ""
	u._chk("j15_no_double", t != "" and Empire.broker_held(t) > 0.0)
	# fin divizia ticker nekupi
	if t != "":
		var row2 = StockMarket.listing(t)
		row2.price = float(row2.price) * 3.0
		Empire.broker_weekly(bf)
		u._chk("j15_broker_sells", not b.own.has(t), "pl=%.0f" % float(b.pl))
	u._chk("j15_broker_text", Empire.broker_text(bf).find("BURZA") >= 0)
	b.on = false
	var tr = int(b.trades)
	Empire.broker_weekly(bf)
	u._chk("j15_broker_off", int(b.trades) == tr)
	# odberatelia
	Empire.st().cust = {}
	Empire.st().cust_prev = {}
	var pf: Dictionary = GameState.player_firms()[0]
	Empire.record_sales("SK", "electricity", [{"actor": str(pf.id) + ":0", "qty": 10.0}], [{"actor": "aiX:0", "qty": 30.0}], 70.0, 100.0, 1.0, 50.0)
	var c = Empire.customers("*", "eur")
	u._chk("j15_customers", (c.rows as Array).size() == 2 and absf(float(c.total) - 500.0) < 0.01 and str(c.rows[0].buyer) == "Domácnosti a štát", str(c.rows))
	Empire.monthly()
	u._chk("j15_customers_month", Empire.customers("*").full_month and (Empire.st().cust as Dictionary).is_empty())
	# save roundtrip ext
	var d = GameState.to_dict()
	u._chk("j15_save_ext", d.ext.emp.has("cust_prev"))


func _juan17() -> void:
	u._new()
	Empire.st().cust = {}
	Empire.st().cust_prev = {}
	GameState.config.progression = false
	GameState.player.cash = 1.0e9
	GameState.found_firm("power_coal", "", "SK")
	if GameState.player_firms().is_empty():
		u._chk("j17_firm", false)
		return
	var pf: Dictionary = GameState.player_firms()[0]
	Empire.record_sales("SK", "electricity", [{"actor": str(pf.id) + ":0", "qty": 10.0}], [], 100.0, 100.0, 1.0, 50.0)
	Empire.record_sales("CZ", "electricity", [{"actor": str(pf.id) + ":0", "qty": 1.0}], [], 100.0, 100.0, 1.0, 50.0)
	var d = Empire.customers_by_iso()
	u._chk("j17_by_iso", absf(float(d.SK.eur) - 500.0) < 0.01 and absf(float(d.CZ.eur) - 50.0) < 0.01 and not d.has("DE"), str(d))
	var WM = load("res://scripts/ui/world_map.gd")
	u._chk("j17_ramp", WM.cust_ramp(0.0) != WM.cust_ramp(1.0) and WM.cust_ramp(1.0).g > WM.cust_ramp(1.0).r)


func _juan19() -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 1.0e9
	# plyn
	u._chk("j19_gas_plant_uses_gas", DataLoader.recipes.gas_plant.inputs.has("natural_gas") and not DataLoader.recipes.gas_plant.inputs.has("crude_oil"))
	u._chk("j19_gas_well_deposit", TerrainSystem.NEEDS_DEPOSIT.get("gas_well", "") == "gas" and DataLoader.recipes.gas_well.outputs.has("natural_gas"))
	# vsetky recepty: vstupy existuju ako komodity
	var bad = []
	for rid in DataLoader.recipes.keys():
		for i in DataLoader.recipes[rid].get("inputs", {}).keys():
			if not DataLoader.commodities.has(i):
				bad.append(rid + ":" + i)
	u._chk("j19_inputs_known", bad.is_empty(), str(bad))
	GameState.found_firm("steel_mill", "", "SK")
	var mill: Dictionary = {}
	for f in GameState.player_firms():
		if str(f.industry) == "steel_mill":
			mill = f
	u._chk("j19_mill", not mill.is_empty())
	if mill.is_empty():
		return
	for _d in 3:
		GameState.simulate_day()
	var sup: Dictionary = mill.get("supply", {})
	var bought = 0.0
	var tr = 0.0
	for k in sup.keys():
		bought += float(sup[k].bought)
		tr += float(sup[k].transport)
	u._chk("j19_buys_from_market_plus_transport", bought > 0.0 and tr > 0.0, str(sup))
	var d0 = Transport.discount(mill, "iron_ore")
	var p = Transport.firm_wp(mill)
	var e = Transport.build_line("rail", p - Vector2(3, 0), p + Vector2(3, 0))
	var d1 = Transport.discount(mill, "iron_ore")
	u._chk("j19_rail", e == "" and float(d1.rail) > 0.5 and float(d0.d) < float(d1.d), "%s %s" % [e, str(d1)])
	u._chk("j19_rail_not_electricity", float(Transport.discount(mill, "electricity").rail) == 0.0)
	var e2 = Transport.build_line("pipe", p - Vector2(0, 3), p + Vector2(0, 3))
	u._chk("j19_pipe", e2 == "" and float(Transport.discount(mill, "natural_gas").pipe) > 0.8 and float(Transport.discount(mill, "steel").pipe) == 0.0)
	GameState.simulate_day()
	GameState.simulate_day()
	var used = 0.0
	for l in Transport.lines():
		used += float(l.used_prev) + float(l.used)
	u._chk("j19_utilization", used > 0.0, str(used))
	GameState.found_firm("logistics_hub", "", "SK")
	var hub: Dictionary = {}
	for f in GameState.player_firms():
		if str(f.industry) == "logistics_hub":
			hub = f
	if not hub.is_empty():
		hub.pos = [p.x + 1.0, p.y]
		var lp = Transport.logi_params(hub)
		u._chk("j19_logi", float(Transport.discount(mill, "electricity").logi) > 0.2 and float(lp.km) >= 150.0, str(lp))
		hub.level = 3
		u._chk("j19_logi_scales", float(Transport.logi_params(hub).share) > float(lp.share))
	u._chk("j19_text", Transport.supply_text(mill).find("ZDROJE VSTUPOV") >= 0)
	u._chk("j19_save", GameState.to_dict().ext.has("transport"))
	u._chk("j19_short_line", Transport.build_line("rail", p, p + Vector2(0.1, 0)) != "")


# JUAN20: Atlas mapa
func _juan20() -> void:
	var AD = load("res://scripts/ui/atlas_draw.gd")
	u._chk("j20_world_tex", FileAccess.file_exists("res://assets/atlas/world.jpg"))
	u._chk("j20_tile_europe", FileAccess.file_exists("res://assets/atlas/t_6_1.jpg"))
	u._chk("j20_kinds", AD.kind_of("nuclear_plant") == "nuclear" and AD.kind_of("gas_well") == "well" and AD.kind_of("coal_mine") == "mine" and AD.kind_of("bank") == "tower" and AD.kind_of("cafe") == "shop")
	var all_known = true
	for ind in DataLoader.industries.keys() if typeof(DataLoader.industries) == TYPE_DICTIONARY else []:
		if AD.kind_of(str(ind)) == "":
			all_known = false
	u._chk("j20_kinds_all", all_known)


# JUAN21: logá, premenovanie, parodie, vozidla, AI, nehnutelnosti
func _juan21() -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 1.0e10
	# parodie na burze
	StockMarket.setup()
	var all_par = {}
	for sec in Brand.PARODY.keys():
		for n in Brand.PARODY[sec]:
			all_par[str(n)] = true
	var nat = StockMarket.listings().filter(func(r): return str(r.kind) == "nat")
	var parodied = nat.filter(func(r): return all_par.has(str(r.name)) or all_par.has(str(r.name).rsplit(" ", true, 1)[0]))
	u._chk("j21_parody", nat.size() > 50 and parodied.size() == nat.size(), "%d/%d" % [parodied.size(), nat.size()])
	u._chk("j21_parody_sector_kept", nat.all(func(r): return StockMarket.SECTORS.has(str(r.sector))))
	u._chk("j21_parody_once", int(StockMarket.ex().parody_v) == 1)
	# firmy + korporacia
	for k in ["auto_plant", "shipyard", "real_estate", "steel_mill", "ai_firm", "data_center", "aircraft_plant"]:
		GameState.found_firm(k, "", "SK")
	var by = {}
	for f in GameState.player_firms():
		by[str(f.industry)] = f
	u._chk("j21_new_firms", by.has("ai_firm") and by.has("data_center") and by.has("aircraft_plant"), str(by.keys()))
	u._chk("j21_icons", FileAccess.file_exists("res://assets/icons/ai_firm.png") and FileAccess.file_exists("res://assets/icons/data_center.png") and FileAccess.file_exists("res://assets/icons/aircraft_plant.png"))
	u._chk("j21_ai_chain", DataLoader.recipes.ai_firm.inputs.has("compute") and DataLoader.recipes.data_center.outputs.has("compute") and DataLoader.recipes.data_center.inputs.has("electronics"))
	var ce = StockMarket.create_corp("Wondris Motors", [str(by.auto_plant.id), str(by.shipyard.id)])
	var cid = str(by.auto_plant.get("corp", ""))
	u._chk("j21_corp", ce == "" and cid != "", ce)
	# logo
	u._chk("j21_logo_default", not Brand.logo(cid).is_empty() and not Brand.has_custom_logo(cid))
	var le = Brand.set_logo(cid, {"shape": "shield", "symbol": "bolt", "bg": "112233", "fg": "FFCC00", "text": "WMXYZ"})
	u._chk("j21_logo_set", le == "" and str(Brand.logo(cid).shape) == "shield" and str(Brand.logo(cid).text) == "WMXY")
	u._chk("j21_logo_bad", Brand.set_logo(cid, {"shape": "blob", "symbol": "bolt"}) != "")
	u._chk("j21_logo_saved", GameState.to_dict().ext.brand.logos.has(cid))
	u._chk("j21_logo_tex", Brand.logo_texture(cid) != null)
	# premenovanie
	u._chk("j21_rename_firm", Brand.rename_firm(str(by.steel_mill.id), "  Oceľ Wondris ") == "" and str(by.steel_mill.name) == "Oceľ Wondris")
	u._chk("j21_rename_short", Brand.rename_firm(str(by.steel_mill.id), "x") != "")
	u._chk("j21_rename_corp", Brand.rename_corp(cid, "Wondris Group") == "" and str(StockMarket.ex().corps[cid].name) == "Wondris Group")
	u._chk("j21_rename_not_mine", Brand.rename_firm("nonexistent", "Abc") != "")
	# vozidla
	u._chk("j21_makes_vehicles", Brand.makes_vehicles(by.auto_plant) and Brand.makes_vehicles(by.shipyard) and Brand.makes_vehicles(by.aircraft_plant) and not Brand.makes_vehicles(by.steel_mill))
	Brand.track(str(by.auto_plant.id), "automobiles", 10.0, "SK")
	var dst = Brand.destinations(str(by.auto_plant.id))
	var tot = 0.0
	for d in dst:
		tot += float(d.qty)
	u._chk("j21_track", dst.size() >= 2 and absf(tot - 10.0) < 0.01 and str(dst[0].iso) == "SK", str(dst))
	u._chk("j21_track_text", Brand.products_text(by.auto_plant).find("Slovensko") >= 0 or Brand.products_text(by.auto_plant).find("SK") >= 0)
	u._chk("j21_track_nonvehicle", (func(): Brand.track(str(by.steel_mill.id), "steel", 5.0, "SK"); return Brand.destinations(str(by.steel_mill.id)).is_empty()).call())
	# AI bonus
	u._chk("j21_ai_boost", absf(Brand.ai_boost(by.steel_mill) - 1.04) < 0.001 and Brand.ai_boost(by.ai_firm) == 1.0, str(Brand.ai_boost(by.steel_mill)))
	# nehnutelnosti
	Empire.st().buildings.append({"iso": "SK", "city": "Košice", "price": 500000.0, "rent": 3000.0, "day": 0})  # stara budova bez typu
	u._chk("j21_old_type", Empire.btype(Empire.st().buildings[-1]) == "office")
	u._chk("j21_buy_shop", Empire.buy_building("SK", "Bratislava", "shop") == "")
	u._chk("j21_buy_apt", Empire.buy_building("SK", "Bratislava", "apartments") == "")
	u._chk("j21_buy_plot", Empire.buy_building("SK", "Nitra", "plot") == "")
	u._chk("j21_buy_bad", Empire.buy_building("SK", "Nitra", "castle") != "")
	var shop = Empire.st().buildings.filter(func(b): return str(b.get("type", "")) == "shop")[0]
	u._chk("j21_shop_rent", float(shop.rent) > float(shop.price) * Empire.RENT_MONTHLY)
	var pi = Empire.st().buildings.size() - 1
	u._chk("j21_plot_no_rent", float(Empire.st().buildings[pi].rent) == 0.0)
	var cash0 = float(GameState.player.cash)
	u._chk("j21_develop", Empire.develop_plot(pi, "warehouse") == "" and Empire.btype(Empire.st().buildings[pi]) == "warehouse" and float(Empire.st().buildings[pi].rent) > 0.0 and float(GameState.player.cash) < cash0)
	u._chk("j21_develop_twice", Empire.develop_plot(pi, "office") != "")
	var rt = Empire.realty_rows("type")
	u._chk("j21_realty_type", int(rt.total.count) == 4 and rt.by_type.has("shop") and rt.by_type.has("office") and rt.by_type.has("warehouse"), str(rt.by_type.keys()))
	var rc = Empire.realty_rows("city", "", "count")
	u._chk("j21_realty_city", str(rc.rows[0].city) == "Bratislava" and int(rc.rows[0].count) == 2)
	u._chk("j21_realty_filter", int(Empire.realty_rows("country", "shop").total.count) == 1)
	u._chk("j21_save", GameState.to_dict().ext.has("brand"))


# JUAN22: % obyvatelov pouzivajucich media/telekom
func _juan22() -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 1.0e10
	for k in ["telecom", "newspaper", "tv_station", "social_network", "steel_mill"]:
		GameState.found_firm(k, "", "SK")
	var by = {}
	for f in GameState.player_firms():
		by[str(f.industry)] = f
	var tel = Brand.media_reach(by.telecom)
	u._chk("j22_telecom", float(tel.pct) > 0.0 and float(tel.pct) <= float(tel.cap_pct) + 1e-6, str(tel))
	u._chk("j22_news_lower", float(Brand.media_reach(by.newspaper).cap_pct) < float(tel.cap_pct))
	u._chk("j22_not_media", Brand.media_reach(by.steel_mill).is_empty() and not Brand.is_media(by.steel_mill))
	u._chk("j22_text", Brand.media_text(by.telecom).find("% obyvateľov") >= 0)
	var p0 = float(tel.pct)
	GameState.found_firm("telecom", "", "SK")
	var tel2 = Brand.media_reach(by.telecom)
	u._chk("j22_competition", float(tel2.pct) < p0, "%f %f" % [p0, float(tel2.pct)])
	by.telecom.level = 3
	u._chk("j22_level_up", float(Brand.media_reach(by.telecom).pct) > float(tel2.pct))
	var cm = Brand.country_media("SK")
	u._chk("j22_country", cm.size() == 4 and cm.all(func(r): return float(r.pct) > 0.0 and float(r.pct) <= 1.0))
	var big = Brand.media_reach(by.newspaper)
	u._chk("j22_cap_small_country", float(big.pct) <= Brand.media_cap("SK", "newspaper") + 1e-6)


# JUAN23: optimalizacia - den po fazach (cez snimky) = rovnaky vysledok ako simulate_day; cache dopravy
func _j23_run(phased: bool) -> Array:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 1.0e9
	for k in ["coal_mine", "steel_mill", "logistics_hub", "telecom"]:
		GameState.found_firm(k, "", "SK")
	var cap = Transport.firm_wp(GameState.player_firms()[0])
	Transport.build_line("rail", cap, cap + Vector2(3, 1))
	for _d in 12:
		if phased:
			while GameState.sim_budget(1, 1) == 0:
				pass
		else:
			GameState.simulate_day()
	return [GameState.day_index, snappedf(float(GameState.player.cash), 0.01), snappedf(MarketSystem.price("SK", "steel"), 0.0001), snappedf(MarketSystem.price("DE", "coal"), 0.0001)]

func _juan23() -> void:
	var a = _j23_run(false)
	var b = _j23_run(true)
	u._chk("j23_phased_same", a == b, "%s vs %s" % [a, b])
	u._chk("j23_finish_pending", not GameState.day_in_progress())
	var f = GameState.player_firms()[1]
	var d1 = Transport.discount(f, "coal")
	Transport.invalidate()
	var d2 = Transport._discount0(f, "coal")
	u._chk("j23_discount_cache", d1 == d2, "%s %s" % [d1, d2])
	u._chk("j23_gfx_setting", preload("res://scripts/gfx.gd").setting() in ["auto", "high", "low"])
	var m = preload("res://scripts/ui/world_map.gd").new()
	m._build()
	u._chk("j23_mesh_count", m.shapes.size() > 100 and m.shapes[0].has("mesh"), str(m.shapes.size()))
	m.free()
