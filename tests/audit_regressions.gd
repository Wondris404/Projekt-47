extends RefCounted

func run(u) -> void:
	_detached_map_ready(u)
	_save_size_limit(u)
	_save_replace_backup(u)
	_trade_ledger(u)
	_power_input(u)
	_maintenance(u)
	_world_caches(u)
	_transport_index(u)
	_atlas_cache(u)
	_atlas_geometry(u)

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

func _atlas_geometry(u) -> void:
	var ad = load("res://scripts/ui/atlas_draw.gd")
	var city = {"name": "Audit mesto", "iso": "SK", "pop": 500000.0, "r": 3.0}
	var same = true
	for view in [[Vector2(100, 100), 4.0, 1.0], [Vector2(110, 120), 4.0, 1.0], [Vector2(110, 120), 8.0, 0.5]]:
		ad.use_city_geometry_cache = false
		ad.begin_batch()
		ad.city(null, city, view[0], view[1], view[2])
		var vertices: PackedVector2Array = ad.B_v.duplicate()
		var colors: PackedColorArray = ad.B_c.duplicate()
		ad.use_city_geometry_cache = true
		for repeat in 2:
			ad.begin_batch()
			ad.city(null, city, view[0], view[1], view[2])
			if ad.B_v != vertices or ad.B_c != colors: same = false
	u._chk("audit_atlas_geometry_exact_pan_zoom_fade", same)
	for i in ad.CITY_GEOMETRY_LIMIT + 2:
		city.name = "Audit mesto %d" % i
		ad.begin_batch()
		ad.city(null, city, Vector2.ZERO, 4.0, 1.0)
	u._chk("audit_atlas_geometry_bounded", ad._city_geometry.size() <= ad.CITY_GEOMETRY_LIMIT)
	ad.B_on = false
	ad.B_v.clear()
	ad.B_c.clear()

func _save_size_limit(u) -> void:
	u._chk("audit_save_limit_utf8_boundary", SaveSystem._within_save_limit("ž", 2) and not SaveSystem._within_save_limit("ž", 1))
	u._new()
	var previous_dir = SaveSystem.base_dir
	SaveSystem.base_dir = "user://audit_size_%d" % Time.get_ticks_usec()
	var path = SaveSystem.save_slot(1)
	var exists = FileAccess.file_exists(path)
	var previous = FileAccess.get_file_as_string(path) if exists else ""
	u._chk("audit_save_limit_small_saved", exists and not previous.is_empty())
	GameState.ext["audit_oversize"] = "x".repeat(SaveSystem.MAX_SAVE_BYTES + 1)
	var error = SaveSystem.save_slot(1)
	GameState.ext.erase("audit_oversize")
	u._chk("audit_save_limit_rejects_oversize", error == SaveSystem.last_error and error.contains("limit"))
	u._chk("audit_save_limit_preserves_slot", exists and FileAccess.get_file_as_string(path) == previous)
	SaveSystem.base_dir = previous_dir

func _detached_map_ready(u) -> void:
	var map = load("res://scripts/ui/world_map.gd").new()
	map._ready()
	u._chk("audit_detached_map_ready", not map.is_inside_tree() and map._atlas_layer != null)
	map.free()

func _save_replace_backup(u) -> void:
	u._new()
	var previous_dir = SaveSystem.base_dir
	SaveSystem.base_dir = "user://audit_backup_%d" % Time.get_ticks_usec()
	var path = SaveSystem.save_slot(1)
	var original_cash = float(GameState.player.cash)
	var original_hash = FileAccess.get_sha256(path)
	GameState.player.cash = original_cash + 12345.0
	var saved = SaveSystem.save_slot(1)
	u._chk("audit_backup_written", saved == path and not original_hash.is_empty() and FileAccess.get_sha256(path + ".backup") == original_hash)
	GameState.player.cash = 0.0
	var err = SaveSystem.load_slot(1)
	u._chk("audit_backup_current_preferred", err == "" and not SaveSystem.last_load_from_backup and is_equal_approx(float(GameState.player.cash), original_cash + 12345.0))
	# Presun stranou napodobní chýbajúci cieľ po neúspešnom nahradení, bez mazania.
	var moved = DirAccess.rename_absolute(path, path + ".held") == OK
	GameState.player.cash = 0.0
	err = SaveSystem.load_slot(1)
	u._chk("audit_backup_recovery_v3", moved and err == "" and SaveSystem.last_load_from_backup and is_equal_approx(float(GameState.player.cash), original_cash) and GameState.SAVE_VERSION == 3)
	var path2 = SaveSystem.save_slot(2)
	var hash2 = FileAccess.get_sha256(path2)
	var blocked = DirAccess.make_dir_absolute(path2 + ".backup") == OK
	GameState.player.cash = original_cash + 54321.0
	var refusal = SaveSystem.save_slot(2)
	u._chk("audit_backup_failure_preserves_slot", blocked and refusal == SaveSystem.last_error and refusal.contains("záložná") and FileAccess.get_sha256(path2) == hash2)
	SaveSystem.base_dir = previous_dir
