extends RefCounted

func run(u) -> void:
	_trade_ledger(u)
	_power_input(u)
	_maintenance(u)
	_world_caches(u)
	_transport_index(u)
	_atlas_cache(u)

func _trade_ledger(u) -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 2.0e8
	var err = GameState.found_firm("trade_desk", "Audit obchodu", "SK")
	u._chk("audit_trade_setup", err == "", err)
	if err != "":
		return
	var firm: Dictionary = GameState.player_firms()[-1]
	var fac: Dictionary = firm.facilities[0]
	fac.src = "SK"
	fac.dst = "CZ"
	fac.cargo = "coffee"
	GameState.markets.SK.coffee.price = 100.0
	GameState.markets.CZ.coffee.price = 10000.0
	GameState.markets.SK.coffee.stock = 10000.0
	GameState.markets.CZ.coffee.last_dem = 1000.0
	GameState.markets.CZ.coffee.last_sup = 0.0
	var before = float(firm.cash)
	IndustrySystem.settle()
	var h: Dictionary = firm.history[-1]
	var trade: Dictionary = firm.goods_flow[-1].trades[0]
	u._chk("audit_trade_revenue", is_equal_approx(float(h.rev), float(trade.revenue)))
	u._chk("audit_trade_cost", is_equal_approx(float(h.cogs), float(trade.cost)))
	u._chk("audit_trade_profit_matches_cash", is_equal_approx(float(h.profit), float(firm.cash) - before))
	u._chk("audit_trade_tax", is_equal_approx(float(h.tax), IndustrySystem.tax_due("SK", float(trade.revenue) - float(trade.cost))))

func _power_input(u) -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 2.0e8
	GameState.found_firm("wheat_farm", "Audit energie", "SK")
	var firm: Dictionary = GameState.player_firms()[-1]
	GameState.firms = [firm]
	GameState.player.modifiers.power_mult = 0.5
	var fac: Dictionary = firm.facilities[0]
	fac.inventory = {"electricity": 0.125}
	firm.plans = [{"fi": 0, "desired": 1.0}]
	GameState.markets.SK.wheat.sell_fill = 0.0
	IndustrySystem.settle()
	u._chk("audit_power_research_full_run", is_equal_approx(float(fac.inventory.get("wheat", 0.0)), 1.5))
	u._chk("audit_power_exact_consumption", is_zero_approx(float(fac.inventory.electricity)))
	u._chk("audit_power_recipe_immutable", is_equal_approx(float(DataLoader.recipes.wheat_farm.inputs.electricity), 0.25))

func _maintenance(u) -> void:
	# A v3 history row from the previous version has no maintenance field.
	var old = {"rev": 1000.0, "cogs": 100.0, "wages": 100.0, "rent": 50.0, "tax": 50.0, "profit": 620.0, "day": 0}
	var firm = {"history": [old], "cash": 50000.0}
	var summary = IndustrySystem.firm_summary(firm)
	u._chk("audit_legacy_costs_include_maintenance", is_equal_approx(float(summary.costs), 380.0))
	u._chk("audit_legacy_reserve_includes_maintenance", is_equal_approx(float(summary.reserve), 11400.0))
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 2.0e8
	GameState.found_firm("cafe", "Audit údržby", "SK")
	GameState.simulate_day()
	var f: Dictionary = GameState.player_firms()[-1]
	var h: Dictionary = f.history[-1]
	u._chk("audit_maintenance_recorded", is_equal_approx(float(h.get("maintain", 0.0)), 8.0))
	var s = IndustrySystem.firm_summary(f)
	u._chk("audit_summary_accounting_identity", is_equal_approx(float(s.rev) - float(s.costs), float(s.profit)))

func _world_caches(u) -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 2.0e8
	GameState.found_firm("cafe", "Pôvodná firma", "SK")
	var old: Dictionary = GameState.player_firms()[-1]
	Empire._player_firm_map()
	var saved = GameState.to_dict().duplicate(true)
	saved.firms[-1].name = "Načítaná firma"
	Transport._day = GameState.day_index
	var err = GameState.from_dict(saved)
	u._chk("audit_v3_load", err == "" and GameState.SAVE_VERSION == 3, err)
	var pm = Empire._player_firm_map()
	u._chk("audit_sales_cache_after_load", str(pm[str(old.id)].name) == "Načítaná firma")
	Transport.lines().append({"id": "test", "kind": "rail", "a": [0, 0], "b": [1, 1], "cap": 600.0, "used": 123.0, "used_prev": 0.0})
	Transport.begin_day()
	u._chk("audit_transport_after_load", float(Transport.lines()[-1].used_prev) == 123.0 and float(Transport.lines()[-1].used) == 0.0)
	MarketSystem._cw["SK"] = {"wheat": 999.0}
	MarketSystem._cw_day = GameState.day_index
	MarketSystem.reset_runtime()
	u._chk("audit_cpi_cache_reset", MarketSystem._cw.is_empty() and MarketSystem._cw_day == -1)
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 2.0e8
	GameState.found_firm("cafe", "Nová firma", "SK")
	u._chk("audit_sales_cache_new_game", str(Empire._player_firm_map()[str(GameState.player_firms()[-1].id)].name) == "Nová firma")

func _transport_index(u) -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 1.0e10
	for kind in ["coal_mine", "logistics_hub", "logistics_hub", "cargo_port", "ai_firm", "data_center"]:
		GameState.found_firm(kind, "Audit " + kind, "SK")
	var firms = GameState.player_firms()
	for f in firms: f.pos = [100.0, 100.0]
	firms[2].facilities[0].scale = 4.0
	var expected := {}
	Transport.use_support_index = false
	Transport.invalidate()
	for f in firms:
		for cid in ["coal", "crude_oil", "electricity"]:
			expected[str(f.id) + cid] = Transport.discount(f, cid).duplicate()
	Transport.use_support_index = true
	Transport.invalidate()
	var identical = true
	for f in firms:
		for cid in ["coal", "crude_oil", "electricity"]:
			if Transport.discount(f, cid) != expected[str(f.id) + cid]: identical = false
	u._chk("audit_transport_index_exact", identical)
	IndustrySystem._prepare_local_competition()
	var yields_equal = true
	for f in firms:
		IndustrySystem.use_local_competition_cache = false
		var scan = IndustrySystem._yield_mult(f, str(f.facilities[0].recipe))
		IndustrySystem.use_local_competition_cache = true
		if scan != IndustrySystem._yield_mult(f, str(f.facilities[0].recipe)): yields_equal = false
	u._chk("audit_ai_index_exact", yields_equal)
	var saved = GameState.to_dict().duplicate(true)
	GameState.from_dict(saved.duplicate(true))
	IndustrySystem.use_local_competition_cache = false
	Transport.use_support_index = false
	for i in 3: GameState.simulate_day()
	var reference = JSON.stringify(GameState.to_dict())
	GameState.from_dict(saved.duplicate(true))
	Transport.use_support_index = true
	IndustrySystem.use_local_competition_cache = true
	for i in 3: GameState.simulate_day()
	u._chk("audit_transport_simulation_exact", reference == JSON.stringify(GameState.to_dict()))

func _atlas_cache(u) -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 2.0e8
	GameState.found_firm("power_coal", "Atlas test", "SK")
	var firm: Dictionary = GameState.player_firms()[-1]
	firm.pos = [100.0, 100.0]
	var map = load("res://scripts/ui/world_map.gd").new()
	map.atlas_infra()
	firm.pos = [200.0, 200.0]
	var moved = map.atlas_infra()
	var found = false
	for p in moved.power:
		if p[0] == Vector2(200.0, 200.0): found = true
	u._chk("audit_atlas_moved_power", found)
	firm.closed = true
	var closed = map.atlas_infra()
	var ghost = false
	for p in closed.power:
		if p[0] == Vector2(200.0, 200.0): ghost = true
	u._chk("audit_atlas_closed_power", not ghost)
	map.free()
