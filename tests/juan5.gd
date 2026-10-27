extends RefCounted
# JUAN5: 165 krajin + urovnova simulacia (#14), politika krajin (#15), strom vyskumu (#16)
var u

func run(host) -> void:
	u = host
	_countries()
	_tiers()
	_bench()
	_old_save()
	_politics()
	_research()
	_names()
	_airport()
	_credit()
	_stocks()
	_influence()

func _countries() -> void:
	u._new()
	var n = DataLoader.country_ids.size()
	u._chk("j5_165_countries", n == 165 and GameState.world.size() == 165, str(n))
	var shapes = {}
	for c in DataLoader.map.get("countries", []):
		shapes[str(c.get("iso2", ""))] = true
	u._chk("j5_map_all_countries", DataLoader.country_ids.all(func(i): return shapes.has(i)), "%d tvarov" % shapes.size())
	var m = load("res://scripts/ui/world_map.gd").new()
	m._ready()
	var hit = 0
	for sh in m.shapes:
		var tri = Geometry2D.triangulate_polygon(sh.main_poly)
		if tri.size() >= 3 and m.region_at_world((sh.main_poly[tri[0]] + sh.main_poly[tri[1]] + sh.main_poly[tri[2]]) / 3.0) == str(sh.iso):
			hit += 1
	u._chk("j5_map_clickable", m.shapes.size() == 165 and hit >= 160, "%d/%d" % [hit, m.shapes.size()])
	m.free()
	u._chk("j5_no_tw_xk", not DataLoader.countries.has("TW") and not DataLoader.countries.has("XK"))

func _tiers() -> void:
	u._new()
	MarketSystem.refresh_tiers()
	var t1 = MarketSystem.tier1_count()
	u._chk("j5_tier1_count", t1 >= 60 and t1 <= 80 + 6, str(t1))
	u._chk("j5_core_tier1", DataLoader.core_ids.all(func(i): return MarketSystem.tier_of(i) == 1))
	u._chk("j5_big_in_tier1", ["ID", "AR", "ZA", "KR", "CH", "BE"].all(func(i): return MarketSystem.tier_of(i) == 1))
	# najmensia ekonomika = tier 2; po zalozeni firmy sa povysi
	var small = ""
	var g = 1e30
	for iso in DataLoader.country_ids:
		var v = float(DataLoader.countries[iso].get("gdp_usd", 0.0))
		if v < g:
			g = v
			small = iso
	u._chk("j5_small_tier2", MarketSystem.tier_of(small) == 2, small)
	GameState.player.cash = 1.0e7
	var err = GameState.found_firm("cafe", "", small)
	MarketSystem.refresh_tiers()
	u._chk("j5_promote_on_firm", err == "" and MarketSystem.tier_of(small) == 1, err)
	# tier 2 trh sa hybe (agregovane raz za 7 dni) a ostava bez NaN
	var t2 = ""
	for iso in DataLoader.country_ids:
		if MarketSystem.tier_of(iso) == 2:
			t2 = iso
			break
	var p0 = MarketSystem.price(t2, "wheat")
	var s0 = float(GameState.markets[t2]["wheat"].stock)
	for i in 14:
		GameState.simulate_day()
	var ok = true
	for iso in DataLoader.country_ids:
		for cid in DataLoader.commodity_ids:
			if EconMath.is_bad(MarketSystem.price(iso, cid)):
				ok = false
	u._chk("j5_tier2_updates", ok and (MarketSystem.price(t2, "wheat") != p0 or float(GameState.markets[t2]["wheat"].stock) != s0), t2)
	# vojna povysi krajinu do tier 1
	GameState.wars.clear()
	var t2b = ""
	for iso in DataLoader.country_ids:
		if MarketSystem.tier_of(iso) == 2 and iso != small:
			t2b = iso
	GeopoliticsSystem._start_war(t2b, "SK")
	MarketSystem.refresh_tiers()
	u._chk("j5_promote_on_war", MarketSystem.tier_of(t2b) == 1, t2b)
	GameState.wars.clear()

func _bench() -> void:
	u._new()
	GameState.config["wars"] = false
	for i in 3:
		GameState.simulate_day()
	var t0 = Time.get_ticks_usec()
	for i in 30:
		GameState.simulate_day()
	var ms = (Time.get_ticks_usec() - t0) / 30000.0
	print("P47_J5_BENCH countries=%d tier1=%d ms_per_day=%.1f" % [DataLoader.country_ids.size(), MarketSystem.tier1_count(), ms])
	# limit 40 ms/den je ciel na beznom PC; v teste tolerancia x2 kvoli zataznemu stroju
	u._chk("j5_bench_ms_per_day", ms <= 80.0, "%.1f ms" % ms)

func _old_save() -> void:
	u._new()
	var d: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	var core: Array = DataLoader.core_ids
	for key in ["world", "markets", "central"]:
		for iso in d[key].keys():
			if not iso in core:
				d[key].erase(iso)
	d.erase("ext")
	d.player.erase("research_extra")
	var err = GameState.from_dict(d)
	u._chk("j5_old_save_26_loads", err == "" and GameState.world.size() == 165 and GameState.markets.size() == 165, err)
	var p_new = MarketSystem.price("ID", "wheat")
	var base = float(DataLoader.commodity("wheat").get("base_price", 1.0))
	for i in 10:
		GameState.simulate_day()
	var ok = true
	for iso in DataLoader.country_ids:
		if EconMath.is_bad(MarketSystem.price(iso, "wheat")) or float(GameState.markets[iso]["wheat"].dref) <= 0.0:
			ok = false
	u._chk("j5_old_save_runs", ok and abs(p_new - base) < 0.001 and abs(MarketSystem.price("ID", "wheat") / base - 1.0) < 0.3)
	u._chk("j5_old_save_politics", PoliticsSystem.country("NG").has("parties") and PoliticsSystem.country("SK").has("leader_name"))

func _politics() -> void:
	u._new()
	var kinds = {}
	for iso in DataLoader.country_ids:
		var c = PoliticsSystem.country(iso)
		kinds[str(c.gov)] = true
		if c.get("parties", []).size() < 2 or c.get("parties", []).size() > 4 or str(c.get("leader_name", "")) == "":
			u._chk("j5_pol_country_" + iso, false)
	u._chk("j5_pol_all_gov_types", kinds.size() == 5, str(kinds.keys()))
	u._chk("j5_pol_gov_examples", PoliticsSystem.country("CN").gov == "communist" and PoliticsSystem.country("SA").gov == "monarchy" and PoliticsSystem.country("DE").gov == "democracy" and PoliticsSystem.country("RU").gov == "autocracy")
	u._chk("j5_pol_no_elections_autocracy", int(PoliticsSystem.country("CN").next_election) == -1 and int(PoliticsSystem.country("DE").next_election) > 0)
	u._chk("j5_pol_bribe_cost_by_gov", PoliticsSystem.action_cost("RU", "bribe") / PoliticsSystem.action_cost("RU", "lobby_tax") < PoliticsSystem.action_cost("DE", "bribe") / PoliticsSystem.action_cost("DE", "lobby_tax"))
	u._chk("j5_pol_scandal_by_gov", PoliticsSystem.scandal_chance("DE", "bribe") > PoliticsSystem.scandal_chance("RU", "bribe"))
	GameState.player.cash = 1.0e9
	var de = PoliticsSystem.country("DE")
	var pid = str(de.parties[de.parties.size() - 1].id)
	var pop0 = float(PoliticsSystem.party_in("DE", pid).popularity)
	var r = PoliticsSystem.act("DE", "fund_party", pid, 0.0, 0.99)
	u._chk("j5_fund_party", bool(r.success) and float(PoliticsSystem.party_in("DE", pid).popularity) > pop0, str(r.text))
	var ru = PoliticsSystem.country("RU")
	var pid2 = str(ru.parties[ru.parties.size() - 1].id)
	var a0 = float(PoliticsSystem.party_in("RU", pid2).popularity)
	PoliticsSystem.act("RU", "fund_party", pid2, 0.0, 0.99)
	u._chk("j5_fund_party_weaker_autocracy", float(PoliticsSystem.party_in("RU", pid2).popularity) - a0 < float(PoliticsSystem.party_in("DE", pid).popularity) - pop0)
	u._chk("j5_war_support_needs_war", not bool(PoliticsSystem.act("NO", "war_support").ok))
	GameState.wars.clear()
	GeopoliticsSystem._start_war("PL", "BY")
	GameState.found_firm("pmc_unit", "", "SK")
	var cash0 = float(GameState.player.cash)
	var rel0 = GeopoliticsSystem.relation("SK", "PL")
	var r2 = PoliticsSystem.act("PL", "war_support", "", 0.0, 0.99)
	u._chk("j5_war_support", bool(r2.success) and GeopoliticsSystem.relation("SK", "PL") > rel0 and str(r2.text).find("PMC") >= 0, str(r2.text))
	GameState.wars.clear()
	var r3 = PoliticsSystem.act("FR", "lobby_sanction", "IR", 0.0, 0.99)
	u._chk("j5_lobby_sanction", bool(r3.success) and GeopoliticsSystem.is_sanctioned("FR", "IR"))
	var r4 = PoliticsSystem.act("FR", "lobby_trade", "IR", 0.0, 0.99)
	u._chk("j5_lobby_trade", bool(r4.success) and not GeopoliticsSystem.is_sanctioned("FR", "IR") and GameState.treaties.has(GeopoliticsSystem.sanction_key("FR", "IR")))
	var reg0 = float(PoliticsSystem.country("IT").reg)
	var r5 = PoliticsSystem.act("IT", "strike", "", 0.0, 0.0)
	u._chk("j5_strike_scandal", bool(r5.success) and bool(r5.scandal) and float(PoliticsSystem.country("IT").reg) < reg0)
	u._chk("j5_pol_text", PoliticsSystem.text("US").find("Líder") >= 0 and PoliticsSystem.text("US").find("Strany") >= 0)
	# tier 2 politika: zjednodusena (raz za 3 mesiace)
	GameState.config.politics = true
	for i in 100:
		GameState.simulate_day()
	u._chk("j5_pol_monthly_165", PoliticsSystem.country(DataLoader.country_ids[DataLoader.country_ids.size() - 1]).has("approval"))

func _research() -> void:
	u._new()
	var branches = {}
	for r in DataLoader.research:
		branches[str(r.get("branch", ""))] = true
	u._chk("j5_research_branches", branches.size() >= 6 and DataLoader.research.size() >= 18, str(branches.keys()))
	GameState.player.cash = 1.0e8
	u._chk("j5_research_slots_1", GameState.research_slots() == 1)
	u._chk("j5_research_prereq", GameState.start_research("auto2") != "")
	u._chk("j5_research_start", GameState.start_research("auto1") == "" and GameState.start_research("mine1") == "")
	u._chk("j5_research_queue_when_full", GameState.research_running().size() == 1 and GameState.player.research_queue.has("mine1"))
	u._chk("j5_rnd_center", GameState.build_rnd_center() == "" and GameState.research_slots() == 2)
	GameState._tick_research()
	u._chk("j5_research_parallel", GameState.research_running().size() == 2)
	for i in 60:
		GameState._tick_research()
	u._chk("j5_research_done", "auto1" in GameState.player.done and "mine1" in GameState.player.done and float(GameState.player.modifiers.labor_mult) <= 0.84 and float(GameState.player.modifiers.get("yield_mining", 1.0)) > 1.1)
	PoliticsSystem.focus_state().done.append("rnd1")
	u._chk("j5_research_focus_slot", GameState.research_slots() == 3)
	GameState.start_research("logistics1")
	for i in 40:
		GameState._tick_research()
	GameState.start_research("logistics2")
	for i in 60:
		GameState._tick_research()
	u._chk("j5_research_best_value", is_equal_approx(float(GameState.player.modifiers.freight_mult), 0.78))
	var d: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	u._chk("j5_research_save", GameState.from_dict(d) == "" and bool(GameState.player.get("rnd_center", false)) and "auto1" in GameState.player.done)
	var view = load("res://scripts/ui/research_tree_view.gd").new()
	view.rebuild()
	u._chk("j5_research_view", view.get_child_count() >= DataLoader.research.size() + 6)
	view.free()

func _names() -> void:
	# JUAN5 #17: mena personalu podla krajiny, spravne pohlavie, seedovane
	u._chk("j5_names_all_countries", DataLoader.country_ids.all(func(i): return DataLoader.names.get("country", {}).has(i)))
	u._chk("j5_name_sk_female", DataLoader.person_name("SK", 3, "f").ends_with("ová"), DataLoader.person_name("SK", 3, "f"))
	u._chk("j5_name_ru_female", DataLoader.person_name("RU", 5, "f").ends_with("a"), DataLoader.person_name("RU", 5, "f"))
	u._chk("j5_name_pl_female", not DataLoader.person_name("PL", 26, "f").ends_with("ski"), DataLoader.person_name("PL", 26, "f"))
	u._chk("j5_name_jp_family_first", DataLoader.names.groups.jp.s.has(DataLoader.person_name("JP", 1, "m").split(" ")[0]))
	u._chk("j5_name_deterministic", DataLoader.person_name("BR", 12345, "m") == DataLoader.person_name("BR", 12345, "m"))
	u._new()
	GameState.player.cash = 1.0e7
	GameState.found_firm("cafe", "", "JP")
	var f: Dictionary = GameState.player_firms()[GameState.player_firms().size() - 1]
	var c1 = IndustrySystem.manager_candidates(f)
	var c2 = IndustrySystem.manager_candidates(f)
	var jp: Dictionary = DataLoader.names.groups.jp
	var ok = true
	for c in c1:
		var parts = str(c.name).split(" ")
		var firsts: Array = jp.f if str(c.gender) == "f" else jp.m
		if not jp.s.has(parts[0]) or not firsts.has(parts[1]):
			ok = false
	u._chk("j5_manager_names_by_country", ok and str(c1) == str(c2), str(c1.map(func(x): return x.name)))
	IndustrySystem.hire_manager(str(f.id), c1[0])
	u._chk("j5_manager_gender_saved", str(f.manager.get("gender", "")) == str(c1[0].gender))
	var leaders = {"US": "Donald Trumpet", "RU": "Vladimir Putout", "CN": "Xi Jinpong", "FR": "Emmanuel Macaroon", "DE": "Olaf Scholzzz", "IT": "Giorgia Meloney"}
	u._chk("j5_leader_puns", leaders.keys().all(func(i): return str(DataLoader.politics[i].leader_name) == leaders[i]))

func _airport() -> void:
	# JUAN5 #18: letisko (velky podnik), vyzaduje mesto, poplatky rastu s leteckou spolocnostou a hotelmi
	u._new()
	u._chk("j5_hotel_exists", DataLoader.industries.has("hotel") if typeof(DataLoader.industries) == TYPE_DICTIONARY else true)
	u._chk("j5_airport_tier", IndustrySystem.tier_of_industry("airport") == "large")
	u._chk("j5_airport_city", IndustrySystem.airport_city_ok("SK") and IndustrySystem.unlock_reason("airport", "SK").find("mesto") < 0)
	var small = ""
	for iso in DataLoader.country_ids:
		if not IndustrySystem.airport_city_ok(str(iso)):
			small = str(iso)
			break
	u._chk("j5_airport_needs_city", small == "" or IndustrySystem.unlock_reason("airport", small).find("mesto") >= 0, small)
	var base = IndustrySystem.airport_fees("SK")
	GameState.player.cash = 1.0e8
	GameState.found_firm("airline", "", "SK")
	var with_air = IndustrySystem.airport_fees("SK")
	GameState.found_firm("hotel", "", "SK")
	var with_hotel = IndustrySystem.airport_fees("SK")
	u._chk("j5_airport_fees", base > 0.0 and with_air > base and with_hotel > with_air, "%.0f %.0f %.0f" % [base, with_air, with_hotel])
	var err = GameState.found_firm("airport", "", "SK")
	var c0 = float(GameState.player.cash)
	var got = IndustrySystem.airport_monthly()
	u._chk("j5_airport_monthly", err == "" and got > 0.0 and float(GameState.player.cash) > c0, err)

func _credit() -> void:
	# JUAN5 #18: limit, zabezpeceny uver, zabratie, nezabezpeceny 30k, progresia
	u._new()
	GameState.config.progression = true
	var lim0 = BankingSystem.loan_limit()
	u._chk("j5_limit_start", lim0 >= 50000.0 and lim0 <= 400000.0, str(lim0))
	u._chk("j5_prog_small_ok", IndustrySystem.unlock_reason("cafe") == "")
	u._chk("j5_prog_medium_locked", IndustrySystem.unlock_reason("hotel") != "")
	u._chk("j5_prog_large_locked", IndustrySystem.unlock_reason("airport", "SK") != "")
	var un = BankingSystem.request_unsecured_loan(30000.0)
	var un2 = BankingSystem.request_unsecured_loan(30000.0)
	var over = BankingSystem.request_unsecured_loan(40000.0)
	u._chk("j5_unsecured", bool(un.ok) and not bool(un2.ok) and not bool(over.ok), str(un))
	GameState.config.progression = false
	GameState.player.cash = 2.0e6
	GameState.found_firm("hotel", "", "SK")
	var f: Dictionary = GameState.player_firms()[GameState.player_firms().size() - 1]
	var items = [{"kind": "firm", "id": str(f.id)}]
	var cv = BankingSystem.collateral_value(items)
	u._chk("j5_haircut", cv > 0.0 and cv < BankingSystem.asset_market_value(items[0]) * 0.51, "%.0f" % cv)
	var too = BankingSystem.request_secured_loan(cv * 1.5, 5, items)
	u._chk("j5_secured_cap", not bool(too.ok))
	var amt = minf(cv, BankingSystem.loan_limit()) * 0.9
	var ok = BankingSystem.request_secured_loan(amt, 5, items)
	u._chk("j5_secured_ok", bool(ok.ok) and str(f.get("pledged", "")) != "", str(ok))
	u._chk("j5_pledged_no_sell", IndustrySystem.sell_firm(str(f.id)) != "" and StockMarket.ipo_firm(str(f.id)) != "")
	var again = BankingSystem.request_secured_loan(1000.0, 5, items)
	u._chk("j5_pledged_twice", not bool(again.ok))
	var loan: Dictionary = GameState.player.loans[GameState.player.loans.size() - 1]
	loan.missed = 3
	BankingSystem.collateral_monthly()
	u._chk("j5_seized", str(f.get("owner", "")) != "player" and not GameState.player_firms().has(f), str(f.get("owner", "")))
	# cash zaloha + splatenie uvolni
	GameState.player.cash = 500000.0
	var r3 = BankingSystem.request_secured_loan(50000.0, 5, [{"kind": "cash", "amount": 100000.0}])
	var l3: Dictionary = GameState.player.loans[GameState.player.loans.size() - 1]
	var c_before = float(GameState.player.cash)
	l3.remaining = 0.0
	BankingSystem.collateral_monthly()
	u._chk("j5_cash_release", bool(r3.ok) and float(GameState.player.cash) > c_before + 99000.0 and int(GameState.player.get("loans_repaid", 0)) >= 1, str(r3))

func _stocks() -> void:
	# JUAN5 #19: burza, dividendy, takeover, IPO, holding + spin-off, kontrola 50 %
	u._new()
	RivalSystem.setup(3)
	StockMarket.setup()
	var ls = StockMarket.listings()
	u._chk("j5_stock_listings", ls.size() >= 20, str(ls.size()))
	u._chk("j5_stock_no_tier2", ls.all(func(r): return MarketSystem.tier_of(str(r.iso)) != 2 or str(r.kind) == "rival"))
	var t = ""
	for r in ls:
		if str(r.kind) == "nat":
			t = str(r.ticker)
			break
	for i in 10:
		StockMarket.weekly()
	u._chk("j5_stock_hist", StockMarket.listing(t).hist.size() >= 10 and StockMarket.ex().index.size() >= 10)
	GameState.player.cash = 1.0e13
	var e1 = StockMarket.buy(t, 400000.0)
	var d = StockMarket.monthly()
	u._chk("j5_stock_buy_div", e1 == "" and d > 0.0, e1)
	u._chk("j5_takeover_needs_50", StockMarket.takeover(t) != "")
	StockMarket.buy(t, 200000.0)
	u._chk("j5_takeover", StockMarket.takeover(t) == "" and bool(StockMarket.listing(t).controlled))
	var rt = ""
	for r in ls:
		if str(r.kind) == "rival":
			rt = str(r.ticker)
			break
	var rid = str(StockMarket.listing(rt).rival)
	GameState.found_firm("cafe", "", "SK")
	var rf: Dictionary = GameState.firms[GameState.firms.size() - 1]
	rf.owner = "ai"
	rf.rival = rid
	StockMarket.buy(rt, 600000.0)
	u._chk("j5_hostile_rival", StockMarket.takeover(rt) == "" and str(rf.owner) == "player")
	# IPO jednej firmy
	GameState.player.cash = 5.0e7
	GameState.found_firm("telecom", "", "SK")
	var big: Dictionary = GameState.player_firms()[GameState.player_firms().size() - 1]
	GameState.found_firm("cafe", "", "SK")
	var small: Dictionary = GameState.player_firms()[GameState.player_firms().size() - 1]
	u._chk("j5_ipo_min_size", StockMarket.ipo_firm(str(small.id)) != "")
	var c0 = float(GameState.player.cash)
	var ei = StockMarket.ipo_firm(str(big.id), 0.3)
	var bt = str(big.get("listed", ""))
	u._chk("j5_ipo", ei == "" and float(GameState.player.cash) > c0 and absf(StockMarket.stake(bt) - 0.7) < 0.01, ei)
	u._chk("j5_ipo_once", StockMarket.ipo_firm(str(big.id)) != "")
	StockMarket.sell(bt, 250000.0)
	u._chk("j5_lose_control", str(big.owner) != "player")
	# holding
	GameState.found_firm("hotel", "", "SK")
	var h1: Dictionary = GameState.player_firms()[GameState.player_firms().size() - 1]
	GameState.found_firm("hotel", "", "SK")
	var h2: Dictionary = GameState.player_firms()[GameState.player_firms().size() - 1]
	GameState.found_firm("hotel", "", "CZ")
	var h3: Dictionary = GameState.player_firms()[GameState.player_firms().size() - 1]
	u._chk("j5_corp_needs2", StockMarket.create_corp("X", [str(h1.id)]) != "")
	var ec = StockMarket.create_corp("Wondris Holding", [str(h1.id), str(h2.id)])
	var cid = "C%d" % int(StockMarket.ex().seq)
	var corp: Dictionary = StockMarket.ex().corps.get(cid, {})
	var sumv = StockMarket.firm_value(h1) + StockMarket.firm_value(h2)
	u._chk("j5_corp_value", ec == "" and StockMarket.corp_value(corp) > sumv and StockMarket.corp_value(corp) <= sumv * 1.26, ec)
	u._chk("j5_corp_add", StockMarket.corp_add(cid, str(h3.id)) == "" and corp.firms.size() == 3)
	var ec2 = StockMarket.ipo_corp(cid, 0.3)
	u._chk("j5_corp_ipo", ec2 == "" and bool(StockMarket.listing(str(corp.ticker)).public), ec2)
	var es = StockMarket.spin_off(cid, str(h3.id))
	u._chk("j5_spinoff", es == "" and corp.firms.size() == 2 and str(h3.get("corp", "")) == "" and str(h3.get("listed", "")) != "" and absf(StockMarket.stake(str(h3.listed)) - 0.7) < 0.01, es)
	# save v3 kompatibilita
	var dct = GameState.to_dict()
	u._chk("j5_stock_saved", dct.has("ext") and dct.ext.has("exch"))

func _influence() -> void:
	# JUAN8: vplyv/lobing namiesto priamej diplomacie
	u._new()
	GameState.config.politics = true
	PoliticsSystem.ensure()
	GameState.player.cash = 1.0e8
	var c0 = PoliticsSystem.action_chance("DE", "lobby_trade")
	var r1 = PoliticsSystem.act("DE", "media_campaign", "", 0.0, 0.99)
	u._chk("j8_media_influence", bool(r1.ok) and PoliticsSystem.influence("DE") >= 10.0, str(r1))
	u._chk("j8_influence_chance", PoliticsSystem.action_chance("DE", "lobby_trade") > c0)
	var r2 = PoliticsSystem.act("DE", "lobby_relief", "FR", 0.0, 0.99)
	u._chk("j8_relief", bool(r2.success) and GameState.reliefs.has(GeopoliticsSystem.sanction_key("DE", "FR")), str(r2))
	var r3 = PoliticsSystem.act("DE", "lobby_embargo", "RU", 0.0, 0.99)
	u._chk("j8_embargo", bool(r3.success) and GameState.embargoes.has(GeopoliticsSystem.sanction_key("DE", "RU")))
	var r4 = PoliticsSystem.act("DE", "lobby_embargo", "", 0.0, 0.99)
	u._chk("j8_needs_target", not bool(r4.ok))
	var before = PoliticsSystem.influence("DE")
	PoliticsSystem.act("DE", "lobby_trade", "PL", 0.99, 0.0)
	u._chk("j8_scandal_hurts", PoliticsSystem.influence("DE") < before)
	u._chk("j8_bribe_locked", not bool(PoliticsSystem.act("DE", "bribe").ok))
	u._chk("j8_saved", GameState.to_dict().ext.has("influence"))
