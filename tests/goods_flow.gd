extends RefCounted

func run(u) -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 2.0e8
	var err = GameState.found_firm("cafe", "Test výroby", "SK")
	u._chk("flow_firm_create", err == "", err)
	if err != "":
		return
	var firm: Dictionary = GameState.player_firms()[-1]
	u._chk("flow_old_save_empty", IndustrySystem.goods_flow_text(firm).contains("Zatiaľ"))
	GameState.simulate_day()
	var flows: Array = firm.get("goods_flow", [])
	u._chk("flow_records_day", flows.size() == 1, str(flows))
	if flows.is_empty():
		return
	var day: Dictionary = flows[0]
	u._chk("flow_has_input_and_output", not day.inputs.is_empty() and not day.outputs.is_empty(), str(day))
	var output: Dictionary = day.outputs.values()[0]
	u._chk("flow_amounts_valid", float(output.produced) >= 0.0 and float(output.sold) >= 0.0 and float(output.revenue) >= 0.0)
	var display = IndustrySystem.goods_flow_text(firm)
	u._chk("flow_market_display", display.contains("Trh:") and display.contains("predané") and display.contains("vyrobené"), display)
	u._chk("flow_no_false_final_customer", display.contains("Ďalší vývoz"))
	var id = str(firm.id)
	var saved = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	var load_err = GameState.from_dict(saved)
	var restored = GameState.firm_by_id(id)
	u._chk("flow_save_v3", load_err == "" and int(saved.v) == 3 and restored.get("goods_flow", []).size() == 1, load_err)
	var old = restored.duplicate(true)
	old.erase("goods_flow")
	u._chk("flow_legacy_default", IndustrySystem.goods_flow_text(old).contains("Zatiaľ"))
	var stale = restored.duplicate(true)
	stale.goods_flow[0].day = GameState.day_index - 31
	u._chk("flow_old_days_not_displayed", IndustrySystem.goods_flow_text(stale).contains("Zatiaľ"))
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 2.0e8
	var trade_err = GameState.found_firm("trade_desk", "Test obchodu", "SK")
	u._chk("flow_trade_create", trade_err == "", trade_err)
	if trade_err != "":
		return
	var trader: Dictionary = GameState.player_firms()[-1]
	var fac: Dictionary = trader.facilities[0]
	fac.src = "SK"
	fac.dst = "CZ"
	fac.cargo = "coffee"
	GameState.markets.SK.coffee.price = 100.0
	GameState.markets.CZ.coffee.price = 10000.0
	GameState.markets.SK.coffee.stock = 10000.0
	GameState.markets.CZ.coffee.last_dem = 1000.0
	GameState.markets.CZ.coffee.last_sup = 0.0
	var saved_cash = float(trader.cash)
	var saved_stock = float(GameState.markets.SK.coffee.stock)
	IndustrySystem._run_desks(trader, 0.0)
	var plain_cash = float(trader.cash)
	var plain_stock = float(GameState.markets.SK.coffee.stock)
	trader.cash = saved_cash
	GameState.markets.SK.coffee.stock = saved_stock
	var flow = {"day": GameState.day_index, "inputs": {}, "outputs": {}, "trades": []}
	IndustrySystem._run_desks(trader, 0.0, flow)
	u._chk("flow_trade_no_economy_change", is_equal_approx(float(trader.cash), plain_cash) and is_equal_approx(float(GameState.markets.SK.coffee.stock), plain_stock))
	u._chk("flow_trade_actual_route", flow.trades.size() == 1 and str(flow.trades[0].src) == "SK" and str(flow.trades[0].dst) == "CZ", str(flow.trades))
	if not flow.trades.is_empty():
		var t: Dictionary = flow.trades[0]
		u._chk("flow_trade_exact_amount_profit", is_equal_approx(float(t.qty), saved_stock - plain_stock) and is_equal_approx(float(t.revenue) - float(t.cost), plain_cash - saved_cash))
		trader.goods_flow = [flow]
		var trade_text = IndustrySystem.trade_flow_text(trader)
		u._chk("flow_trade_display", trade_text.contains(str(GameState.world.SK.name_sk)) and trade_text.contains(str(GameState.world.CZ.name_sk)) and trade_text.contains("marža"), trade_text)
		var trade_host = load("res://scripts/main.gd").new()
		var trade_panel = trade_host.firm_detail_text(trader)
		u._chk("flow_trade_detail_integration", trade_panel.contains("OBCHODNÉ PRESUNY") and trade_panel.contains("marža"))
		trade_host.free()
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 2.0e8
	GameState.found_firm("coal_mine", "Baňa", "SK")
	var mine: Dictionary = GameState.player_firms()[-1]
	GameState.found_firm("power_coal", "Elektráreň", "SK")
	var plant: Dictionary = GameState.player_firms()[-1]
	var corp_err = StockMarket.create_corp("Uhlie", [str(mine.id), str(plant.id)])
	u._chk("flow_internal_corp", corp_err == "", corp_err)
	u._chk("flow_market_corporation_name", IndustrySystem._market_party_name(str(mine.id)).contains("Uhlie"))
	GameState.simulate_day()
	var mine_flow: Array = mine.get("goods_flow", [])
	var plant_flow: Array = plant.get("goods_flow", [])
	var transfers: Array = mine_flow[-1].get("internal_transfers", []) if not mine_flow.is_empty() else []
	var received: Array = plant_flow[-1].get("internal_transfers", []) if not plant_flow.is_empty() else []
	u._chk("flow_internal_real_delivery", not transfers.is_empty() and transfers == received, str(transfers))
	if not transfers.is_empty():
		u._chk("flow_internal_partners", str(transfers[0].seller) == str(mine.id) and str(transfers[0].buyer) == str(plant.id) and float(transfers[0].qty) > 0.0, str(transfers))
		var txt = IndustrySystem.goods_flow_text(plant)
		u._chk("flow_internal_display", txt.contains("Baňa") and txt.contains("Elektráreň") and txt.contains("Vnútorná dodávka"), txt)
		var host = load("res://scripts/main.gd").new()
		var panel_text = host.firm_detail_text(plant)
		u._chk("flow_firm_detail_integration", panel_text.contains("VÝROBA A PREDAJ") and panel_text.contains("Vnútorná dodávka") and panel_text.contains("Obchod"))
		host.free()
	var start = GameState.to_dict().duplicate(true)
	GameState.from_dict(start.duplicate(true))
	IndustrySystem.record_goods_flow = false
	for i in 3:
		GameState.simulate_day()
	var without = GameState.to_dict().duplicate(true)
	GameState.from_dict(start.duplicate(true))
	IndustrySystem.record_goods_flow = true
	for i in 3:
		GameState.simulate_day()
	var with_flow = GameState.to_dict().duplicate(true)
	for f in without.firms:
		f.erase("goods_flow")
	for f in with_flow.firms:
		f.erase("goods_flow")
	without.ext.erase("market_journal")
	with_flow.ext.erase("market_journal")
	u._chk("flow_simulation_identical", JSON.stringify(without) == JSON.stringify(with_flow))
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 2.0e8
	GameState.found_firm("coal_mine", "Predajca", "SK")
	var seller: Dictionary = GameState.player_firms()[-1]
	GameState.found_firm("power_coal", "Odberateľ A", "SK")
	var buyer_a: Dictionary = GameState.player_firms()[-1]
	GameState.found_firm("power_coal", "Odberateľ B", "SK")
	var buyer_b: Dictionary = GameState.player_firms()[-1]
	IndustrySystem._market_executions.clear()
	MarketSystem.matching_market["SK|coal"] = {"supply": 0.0, "demand": 20.0}
	IndustrySystem._market_execution("SK", "coal", "sellers", seller, 10.0, 100.0)
	IndustrySystem._market_execution("SK", "coal", "buyers", buyer_a, 2.0, 110.0)
	IndustrySystem._market_execution("SK", "coal", "buyers", buyer_b, 3.0, 110.0)
	IndustrySystem._match_market_executions()
	var pairs: Array = seller.goods_flow[-1].market_matches
	u._chk("market_match_multiple_buyers", pairs.size() == 3 and str(pairs[0].buyer) == str(buyer_a.id) and str(pairs[1].buyer) == str(buyer_b.id))
	u._chk("market_match_households", str(pairs[-1].buyer) == "@households" and is_equal_approx(float(pairs[-1].qty), 5.0))
	u._chk("market_match_record_prices", is_equal_approx(float(pairs[0].seller_price), 100.0) and is_equal_approx(float(pairs[0].buyer_price), 110.0))
	u._chk("market_match_country_and_goods", str(pairs[0].src) == "SK" and str(pairs[0].dst) == "SK" and str(pairs[0].cid) == "coal")
	u._chk("market_match_both_firms", buyer_a.goods_flow[-1].market_matches.size() == 1 and str(buyer_a.goods_flow[-1].market_matches[0].seller) == str(seller.id))
	u._chk("market_match_global_journal", not GameState.ext.get("market_journal", []).is_empty() and int(GameState.ext.market_journal[-1].day) == GameState.day_index)
	var total = 0.0
	for pair in pairs:
		total += float(pair.qty)
	u._chk("market_match_conserves_seller", is_equal_approx(total, 10.0))
	for i in 31:
		GameState.day_index = i + 1
		IndustrySystem._market_execution("SK", "coal", "sellers", seller, 1.0, 100.0)
		IndustrySystem._match_market_executions()
	u._chk("market_match_bounded_days", GameState.ext.market_journal.size() <= 30 and seller.goods_flow.size() <= 30)
	u._new()
	for iso in DataLoader.country_ids:
		var book: Dictionary = GameState.markets[iso].coffee
		book.last_dem = 100.0
		book.stock = 4200.0
		book.price = 100.0
	var source: Dictionary = GameState.markets.SK.coffee
	var destination: Dictionary = GameState.markets.CZ.coffee
	source.stock = 10000.0
	source.price = 10.0
	destination.stock = 100.0
	destination.price = 10000.0
	var source_before = float(source.stock)
	var destination_before = float(destination.stock)
	MarketSystem.begin_day_start()
	MarketSystem.trade_routes()
	var routes: Array = MarketSystem.route_transfers.filter(func(r): return str(r.cid) == "coffee" and str(r.src) == "SK" and str(r.dst) == "CZ")
	u._chk("market_route_recorded", routes.size() == 1, str(routes))
	if not routes.is_empty():
		var qty = float(routes[0].qty)
		u._chk("market_route_actual_quantities", is_equal_approx(source_before - float(source.stock), qty) and is_equal_approx(float(destination.stock) - destination_before, qty))
		IndustrySystem._market_executions.clear()
		IndustrySystem._match_market_executions()
		var journal_routes: Array = GameState.ext.market_journal[-1].rows.filter(func(r): return str(r.get("kind", "")) == "market_transfer" and str(r.cid) == "coffee" and str(r.src) == "SK" and str(r.dst) == "CZ")
		u._chk("market_route_persisted", journal_routes.size() == 1 and int(journal_routes[0].day) == GameState.day_index)
	MarketSystem._distance_cache.wait_for_completion()
	var distances_ok = true
	for iso in DataLoader.country_ids:
		for dest in ["SK", "US", "CN"]:
			var a: Dictionary = DataLoader.countries[iso]
			var b: Dictionary = DataLoader.countries[dest]
			var expected = EconMath.haversine(float(a.get("lat", 0.0)), float(a.get("lon", 0.0)), float(b.get("lat", 0.0)), float(b.get("lon", 0.0)))
			if MarketSystem._distance_cache.distance(str(iso), dest, -1.0) != expected:
				distances_ok = false
				break
	u._chk("distance_cache_exact", distances_ok)
	u._chk("distance_cache_unknown_fallback", MarketSystem._distance_cache.distance("?", "SK", -123.0) == -123.0)
	GameState.ext.market_journal = [{"day": 0, "rows": [{"qty": 1.0}]}]
	GameState.day_index = 31
	MarketSystem.route_transfers.clear()
	IndustrySystem._market_executions.clear()
	IndustrySystem._direct_trades.clear()
	IndustrySystem._match_market_executions()
	u._chk("market_journal_expired_empty_day", GameState.ext.market_journal.is_empty())
