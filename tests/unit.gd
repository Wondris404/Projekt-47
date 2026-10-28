extends RefCounted
# Jednotkove kontroly etapy 0. Spustenie: godot --headless --path . -- unit
# Vypisuje P47_UNIT_* riadky; exit 1 ak nejaka zlyha.

var fails = 0

func _chk(name: String, cond: bool, info: String = "") -> void:
	if cond:
		print("P47_UNIT_OK %s %s" % [name, info])
	else:
		print("P47_UNIT_FAIL %s %s" % [name, info])
		fails += 1

func _new() -> void:
	GameState.new_game({
		"loan": 0.0, "years": 5, "country": "SK", "scenario": "sandbox", "found": "",
		"wars": false, "disasters": false, "hot": false, "seed": 47, "name": "Unit", "year": 2024,
	})

func run() -> int:
	SaveSystem.use_test_dir()
	_new()
	_bonds()
	_bond_exploit()
	_save()
	_save_bonds()
	_save_deep()
	_wars()
	_share()
	_e1_supply()
	_e1_price()
	_e1_cpi()
	_e1_rate()
	_e1_shocks()
	_e1_review()
	_e1_final()
	_m1_ai_minister()
	_history_catalog()
	_juan2_dividends()
	_juan2_save_load()
	_juan3_loans()
	_juan3_manager()
	_juan3_history_save()
	_juan3_placement()
	load("res://tests/juan4.gd").new().run(self)  # JUAN4
	load("res://tests/juan5.gd").new().run(self)  # JUAN5
	load("res://tests/juan9.gd").new().run(self)  # JUAN9
	load("res://tests/descriptions.gd").new().run(self)
	SaveSystem.cleanup_test_dir()
	return 1 if fails > 0 else 0

func _bonds() -> void:
	GameState.player.cash = 10000.0
	GameState.player.bonds.clear()
	GameState.bond_orders.clear()
	BankingSystem.post_bond_order("ask", 100.0, 1.0)
	var r = BankingSystem.post_bond_order("bid", 100.0, 1.0)
	_chk("bond_fill", int(r.get("filled", 0)) == 1 and GameState.player.bonds.size() == 1)
	var b: Dictionary = GameState.player.bonds[0]
	var cpn = float(b.coupon)
	_chk("bond_coupon_sane", cpn > 0.0 and cpn < 0.35, str(cpn))
	_chk("bond_face_cash", abs(float(b.face) - 100.0) < 0.001 and abs(float(GameState.player.cash) - 9900.0) < 0.001, str(b))
	var v = BankingSystem._bond_value(b)
	_chk("bond_value_near_par", v > 55.0 and v < 145.0, str(v))
	var cash0 = float(GameState.player.cash)
	BankingSystem.service_bonds()
	var gain = float(GameState.player.cash) - cash0
	_chk("bond_daily_coupon_small", gain > 0.0 and gain < 0.2, str(gain))
	# kratsia splatnost = nizsia hodnota pri kupone pod vynosom, hodnota klesa k par
	var near = {"country": "SK", "face": 100.0, "coupon": 0.0, "years_left": 0.1}
	var far = {"country": "SK", "face": 100.0, "coupon": 0.0, "years_left": 5.0}
	_chk("bond_value_years_left", BankingSystem._bond_value(near) > BankingSystem._bond_value(far))

func _sig() -> String:
	return "%d|%.6f|%.6f|%.6f|%d" % [GameState.day_index, float(GameState.player.cash), MarketSystem.price("SK", "wheat"), float(GameState.world["SK"].inflation), GameState.rng.randi()]

func _save() -> void:
	_new()
	for i in 20:
		GameState.simulate_day()
	var msg = SaveSystem.save_slot(7)
	_chk("save_ok_path", msg.ends_with("slot_7.json") and msg.find("test_tmp_saves") >= 0, msg)
	_chk("save_no_tmp_left", not FileAccess.file_exists(msg + ".tmp"))
	var state_a = GameState.rng.state
	for i in 10:
		GameState.simulate_day()
	var sig1 = _sig()
	var err = SaveSystem.load_slot(7)
	_chk("load_ok", err == "", err)
	_chk("rng_state_restored", GameState.rng.state == state_a, "%d vs %d" % [GameState.rng.state, state_a])
	_chk("date_ints", typeof(GameState.date.m) == TYPE_INT and typeof(GameState.date.y) == TYPE_INT)
	for i in 10:
		GameState.simulate_day()
	var sig2 = _sig()
	_chk("save_load_deterministic", sig1 == sig2, sig1 + " vs " + sig2)
	# chybne savy: stav sa nesmie zmenit
	var good: Dictionary = GameState.to_dict()
	var before = JSON.stringify(GameState.to_dict())
	var cases = {
		"player_not_dict": {"player": 5},
		"month_13": {"date": {"y": 2024, "m": 13, "d": 1}},
		"date_str": {"date": {"y": "x", "m": 1, "d": 1}},
		"firms_not_array": {"firms": {}},
		"version_new": {"v": 99},
		"version_zero": {"v": 0},
		"firm_row_bad": {"firms": [1, 2]},
		"neg_day": {"day_index": -5},
		"bad_rng": {"rng_state": "abc"},
		"market_bad": {"markets": {"SK": 3}},
	}
	for name in cases.keys():
		var bad: Dictionary = good.duplicate(true)
		for k in cases[name].keys():
			bad[k] = cases[name][k]
		var e = GameState.from_dict(bad)
		_chk("reject_" + name, e != "", "prijate")
	var nan_d: Dictionary = good.duplicate(true)
	nan_d.player.cash = NAN
	_chk("reject_nan", GameState.from_dict(nan_d) != "")
	_chk("live_state_untouched", JSON.stringify(GameState.to_dict()) == before)
	# poskodeny subor
	var broken = SaveSystem.saves_dir().path_join("slot_6.json")
	var bf = FileAccess.open(broken, FileAccess.WRITE)
	bf.store_string("{not json")
	bf.close()
	_chk("reject_broken_file", SaveSystem.load_slot(6) != "")
	_chk("live_state_untouched2", JSON.stringify(GameState.to_dict()) == before)
	DirAccess.remove_absolute(broken)
	# chybajuca krajina a komodita sa dopln
	var partial: Dictionary = good.duplicate(true)
	partial.world.erase("CZ")
	partial.markets.erase("DE")
	partial.markets["SK"].erase("wheat")
	partial.central.erase("AT")
	var pe = GameState.from_dict(partial)
	_chk("accept_missing_countries", pe == "", pe)
	_chk("repaired_world", GameState.world.has("CZ") and GameState.markets.has("DE") and GameState.markets["SK"].has("wheat") and GameState.central.has("AT"))
	GameState.simulate_day()
	_chk("sim_after_repair", not EconMath.is_bad(MarketSystem.price("DE", "wheat")))
	# legacy v neuvedene -> prijmi ako v1
	var legacy: Dictionary = good.duplicate(true)
	legacy.erase("v")
	_chk("accept_no_version", GameState.from_dict(legacy) == "")
	# JSON round trip cele
	var rt = JSON.parse_string(JSON.stringify(good))
	_chk("accept_json_roundtrip", GameState.from_dict(rt) == "")
	DirAccess.remove_absolute(SaveSystem.saves_dir().path_join("slot_7.json"))

func _wars() -> void:
	_new()
	GameState.wars.clear()
	GeopoliticsSystem._start_war("SK", "CZ")
	GeopoliticsSystem._start_war("DE", "FR")
	GeopoliticsSystem._start_war("US", "CN")
	GeopoliticsSystem._end_war(GameState.wars[1])
	GeopoliticsSystem._start_war("PL", "UA")
	var ids = {}
	for w in GameState.wars:
		ids[str(w.id)] = true
	_chk("war_ids_unique", ids.size() == GameState.wars.size() and GameState.wars.size() == 3, str(ids.keys()))
	GameState.date = {"y": 2024, "m": 1, "d": 1}
	GameState.config.wars = false
	for w in GameState.wars:
		w.days = 0
	for i in 40:
		GameState.simulate_day()
	var d0 = int(GameState.wars[0].days) if GameState.wars.size() > 0 else -1
	_chk("war_days_single_count", d0 >= 38 and d0 <= 42, str(d0))
	# monthly nesmie menit days (pocitaju sa len v daily) a nesmie preskocit/duplikovat vojny
	GameState.config.wars = true
	var before = {}
	for w in GameState.wars:
		w.days = 100
		before[str(w.id)] = true
	GeopoliticsSystem.monthly()
	var ids2 = {}
	var days_ok = true
	for w in GameState.wars:
		ids2[str(w.id)] = true
		if before.has(str(w.id)) and int(w.days) != 100:
			days_ok = false
	_chk("war_monthly_days_unchanged", days_ok)
	_chk("war_monthly_ids_unique", ids2.size() == GameState.wars.size())

func _share() -> void:
	# etapa 1 krok 1: sucet podielov kazdej komodity cez krajiny = 1, vsetky >= 0, krajina mimo riadku > 0
	var worst = 0.0
	var neg = false
	for cid in DataLoader.commodity_ids:
		var total = 0.0
		for iso in DataLoader.country_ids:
			var v = DataLoader.share(cid, iso)
			total += v
			if v < 0.0:
				neg = true
		worst = max(worst, abs(total - 1.0))
	_chk("share_sums_to_one", worst < 1e-9 and not neg, str(worst))
	var sh = DataLoader.supply_shares.get("shares", {})
	var row: Dictionary = sh.get("crude_oil", {})
	var missing = ""
	for iso2 in DataLoader.country_ids:
		if not row.has(iso2):
			missing = str(iso2)
			break
	_chk("share_missing_country_positive", missing != "" and DataLoader.share("crude_oil", missing) > 0.0, missing)
	# populacia sa v dopyte nepocita 2x: dopyt krajiny je ~proporcionalny HDP, nie HDP x populacia
	var d_sk = MarketSystem._one_demand("SK", "wheat")
	var d_cn = MarketSystem._one_demand("CN", "wheat")
	var ratio = d_cn / max(d_sk, 1e-9)
	var gdp_ratio = float(GameState.world["CN"].gdp_usd) / float(GameState.world["SK"].gdp_usd)
	_chk("demand_not_pop_squared", ratio < gdp_ratio * 6.0 and ratio > gdp_ratio / 6.0, "dopyt CN/SK %.1f, HDP CN/SK %.1f" % [ratio, gdp_ratio])

func _bond_exploit() -> void:
	# nominal = zaplatena suma; zisk za rok <= cost*yield, aj pri extremnych cenach a q
	var yld = BankingSystem._bond_yield("SK")
	for px in [1.0, 10000.0, 50.0, 150.0, 100.0]:
		GameState.player.cash = 1.0e9
		GameState.player.bonds.clear()
		GameState.bond_orders.clear()
		var r1 = BankingSystem.post_bond_order("ask", px, 1000.0)
		var r2 = BankingSystem.post_bond_order("bid", px, 1000.0)
		if px < BankingSystem.BOND_PX_MIN or px > BankingSystem.BOND_PX_MAX:
			_chk("bond_band_reject_%d" % int(px), not bool(r1.get("ok", true)) and not bool(r2.get("ok", true)) and GameState.player.bonds.size() == 0 and abs(float(GameState.player.cash) - 1.0e9) < 0.01)
			continue
		var paid = 1.0e9 - float(GameState.player.cash)
		var face = 0.0
		var year_gain = 0.0
		for b in GameState.player.bonds:
			face += float(b.face)
			year_gain += float(b.face) * float(b.coupon)
		_chk("bond_face_eq_cost_%d" % int(px), GameState.player.bonds.size() == 1 and abs(face - paid) < 0.01 and abs(paid - px * 1000.0) < 0.01, "face %f paid %f" % [face, paid])
		_chk("bond_gain_le_cost_yield_%d" % int(px), year_gain <= paid * yld + 0.01, "%f vs %f" % [year_gain, paid * yld])
	# neplatne vstupy
	var open_before = BankingSystem.open_bond_orders().size()
	_chk("bond_reject_nan", not bool(BankingSystem.post_bond_order("bid", NAN, 1.0).get("ok", true)) and BankingSystem.open_bond_orders().size() == open_before)

func _save_bonds() -> void:
	_new()
	var good: Dictionary = GameState.to_dict()
	_chk("save_version_current", int(good.v) == GameState.SAVE_VERSION and GameState.SAVE_VERSION == 3)
	var cases = {
		"bond_no_country": {"country": "", "face": 100.0, "coupon": 0.05, "years_left": 3.0},
		"bond_face_zero": {"country": "SK", "face": 0.0, "coupon": 0.05, "years_left": 3.0},
		"bond_coupon_neg": {"country": "SK", "face": 100.0, "coupon": -0.1, "years_left": 3.0},
		"bond_coupon_gt1_v2": {"country": "SK", "face": 100.0, "coupon": 5.0, "years_left": 3.0},
		"bond_years_neg": {"country": "SK", "face": 100.0, "coupon": 0.05, "years_left": -1.0},
		"bond_not_dict": 5,
	}
	for name in cases.keys():
		var bad: Dictionary = good.duplicate(true)
		bad.player.bonds = [cases[name]]
		_chk("reject_" + name, GameState.from_dict(bad) != "")
	var empty_pl: Dictionary = good.duplicate(true)
	empty_pl.player = {}
	_chk("reject_empty_player", GameState.from_dict(empty_pl) != "")
	var no_pl: Dictionary = good.duplicate(true)
	no_pl.erase("player")
	_chk("reject_missing_player", GameState.from_dict(no_pl) != "")
	# migracia v1: kupon > 0.25 -> statny vynos; sluszny kupon a emisie hraca ostavaju
	var v1: Dictionary = good.duplicate(true)
	v1.v = 1
	v1.player.bonds = [
		{"country": "SK", "face": 100.0, "coupon": 1.0, "years_left": 4.0},
		{"country": "SK", "face": 100.0, "coupon": 100.0, "years_left": 4.0},
		{"country": "SK", "face": 100.0, "coupon": 0.04, "years_left": 4.0},
		{"country": "SK", "face": 500.0, "coupon": 0.9, "years_left": 2.0, "issuer": "player"},
	]
	var me = GameState.from_dict(v1)
	_chk("v1_load_ok", me == "", me)
	var y = BankingSystem._bond_yield("SK")
	var bb: Array = GameState.player.bonds
	_chk("v1_migrated_coupon", abs(float(bb[0].coupon) - y) < 1e-9 and abs(float(bb[1].coupon) - y) < 1e-9, str(bb))
	_chk("v1_small_coupon_kept", abs(float(bb[2].coupon) - 0.04) < 1e-9)
	_chk("v1_player_issue_kept", abs(float(bb[3].coupon) - 0.9) < 1e-9)
	var v2bad: Dictionary = good.duplicate(true)
	v2bad.v = GameState.SAVE_VERSION + 1
	_chk("reject_future_version", GameState.from_dict(v2bad) != "")

func _save_deep() -> void:
	# 8 poskodenych savov z QA (Miguel); kazdy cez docasne sloty (SaveSystem test dir) aj priamo
	_new()
	for i in 5:
		GameState.simulate_day()
	var good: Dictionary = GameState.to_dict()
	var before = JSON.stringify(GameState.to_dict())
	var mk = func(mut: Callable) -> Dictionary:
		var c: Dictionary = JSON.parse_string(JSON.stringify(good))
		mut.call(c)
		return c
	var bad_cases = {
		"world_population_str": func(c): c.world["SK"].population = "x",
		"firm_cash_str": func(c): c.firms[0].cash = "abc",
		"market_price_str": func(c): c.markets["SK"]["wheat"].price = "x",
		"player_cash_huge": func(c): c.player.cash = -1.0e300,
		"central_empty": func(c): c.central["SK"] = {},
		"bond_country_unknown": func(c): c.player.bonds = [{"country": "ZZ", "face": 100.0, "coupon": 0.05, "years_left": 3.0}],
		"date_31_feb": func(c): c.date = {"y": 2024, "m": 2, "d": 31},
		"date_29_feb_nonleap": func(c): c.date = {"y": 2023, "m": 2, "d": 29},
		"market_price_negative": func(c): c.markets["SK"]["wheat"].price = -5.0,
		"world_inflation_str": func(c): c.world["SK"].inflation = "abc",
		"central_policy_str": func(c): c.central["SK"].policy = "x",
	}
	for name in bad_cases.keys():
		var c2: Dictionary = mk.call(bad_cases[name])
		SaveSystem.saves_dir()
		var path = SaveSystem.saves_dir().path_join("slot_3.json")
		var f = FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(c2))
		f.close()
		var e = SaveSystem.load_slot(3)
		_chk("deep_reject_" + name, e != "", "prijate")
		DirAccess.remove_absolute(path)
	_chk("deep_live_untouched", JSON.stringify(GameState.to_dict()) == before)
	# 8. pripad: savy bez v a bez rng su legacy -> sa maju prijat (a RNG ostane nedotknuty)
	var legacy: Dictionary = mk.call(func(c): c.erase("v"); c.erase("rng_seed"); c.erase("rng_state"))
	var rng_before = GameState.rng.state
	_chk("deep_accept_legacy_no_v_no_rng", GameState.from_dict(legacy) == "")
	_chk("deep_legacy_rng_untouched", GameState.rng.state == rng_before)
	# a platny save s podobnymi polami prejde
	_chk("deep_accept_good", GameState.from_dict(mk.call(func(c): pass)) == "")
	# prazdne trhy/vojny/firmy (ok) a ciselne int namiesto float (ok)
	var ints: Dictionary = mk.call(func(c): c.world["SK"].population = 5428000)
	_chk("deep_accept_int_number", GameState.from_dict(ints) == "")

# ---------------- ETAPA 1 ----------------
func _e1_supply() -> void:
	# krok 1: pri tradovatelnych komoditach je sucet ponuky = svetovy referencny dopyt (kapacita), pri bez soku
	_new()
	GameState.simulate_day()
	var worst = 0.0
	for cid in DataLoader.commodity_ids:
		var sup = 0.0
		var dw = 0.0
		for iso in DataLoader.country_ids:
			sup += float(MarketSystem.sup_day.get(iso + "|" + cid, 0.0))
			dw += float(GameState.markets[iso][cid].get("dref", 0.0))
		worst = max(worst, abs(sup / max(dw, 1e-9) - 1.0))
	_chk("e1_supply_equals_world_demand", worst < 1e-6, "max odchylka %f" % worst)

func _e1_price() -> void:
	# krok 2: tlmeny krok konverguje aj pri e(1+e) > 1 a drzi ohranicenie 0.22-6.5 x base
	for el in [0.25, 0.9, 1.1, 2.0]:
		var base = 100.0
		var d0 = 1000.0
		var s0 = 700.0
		var p = base
		var prev = p
		var max_step = 0.0
		for i in 600:
			prev = p
			var dem = d0 * pow(p / base, -(1.0 + el))
			p = MarketSystem.adjust_price(p, dem, s0, 42.0 * d0, base)
			max_step = max(max_step, abs(log(p / prev)))
		var eq = base * pow(d0 / s0, 1.0 / (1.0 + el))
		_chk("e1_price_converges_el_%d" % int(el * 100), abs(p / prev - 1.0) < 0.002 and p >= base * 0.22 and p <= base * 6.5 and max_step < 0.12, "p %.2f eq %.2f krok %.3f" % [p, eq, max_step])
	# 200 dni v hre: vysokoelasticke komodity v SK neoscuuju (rozsah poslednych 100 dni) a drzia pasmo
	_new()
	var series = {}
	for cid in ["textiles", "food_service", "electronics", "automobiles"]:
		series[cid] = []
	for i in 200:
		GameState.simulate_day()
		if i >= 100:
			for cid in series.keys():
				series[cid].append(MarketSystem.price("SK", cid) / float(DataLoader.commodity(cid).base_price))
	for cid in series.keys():
		var a: Array = series[cid]
		_chk("e1_no_oscillation_" + cid, a.max() - a.min() < 0.2 and a.min() > 0.7 and a.max() < 1.3, "min %.3f max %.3f" % [a.min(), a.max()])

func _e1_cpi() -> void:
	_new()
	var w = MarketSystem.cpi_weights("SK")
	var tot = 0.0
	for cid in w.keys():
		tot += float(w[cid])
	_chk("e1_cpi_weights_sum_1", abs(tot - 1.0) < 1e-9 and w.size() >= 8, str(tot))
	_chk("e1_cpi_weights_not_equal", abs(float(w["wheat"]) - float(w["automobiles"])) > 1e-4)
	for cid in w.keys():
		GameState.markets["SK"][cid].price = float(DataLoader.commodity(cid).base_price)
	_chk("e1_cpi_base_is_one", abs(MarketSystem.cpi_index("SK") - 1.0) < 1e-9)
	GameState.markets["SK"]["wheat"].price = float(DataLoader.commodity("wheat").base_price) * 2.0
	_chk("e1_cpi_weighted", abs(MarketSystem.cpi_index("SK") - (1.0 + float(w["wheat"]))) < 1e-9)
	# mesacny priemer, nie jeden bod
	var c: Dictionary = GameState.world["SK"]
	c.cpi_acc = 3.0
	c.cpi_n = 3
	_chk("e1_cpi_month_average", abs(MarketSystem.cpi_month_average("SK") - 1.0) < 1e-9 and int(c.cpi_n) == 0)
	# medzirocna inflacia z priemerov troch mesiacov: rast 0.5 %/mes -> yoy ~ 6.17 %, inflacia sa posunie o 30 %
	_new()
	c = GameState.world["SK"]
	var hist = []
	for k in 14:
		hist.append(pow(1.005, k))
	c.cpi_hist = hist
	c.inflation = 0.0
	for cid in MarketSystem.cpi_weights("SK").keys():
		GameState.markets["SK"][cid].price = float(DataLoader.commodity(cid).base_price) * pow(1.005, 14)
	GameState._macro()
	var yoy = pow(1.005, 12) - 1.0
	_chk("e1_cpi_yoy_from_averages", abs(float(c.inflation) - 0.3 * yoy) < 0.002, "%f vs %f" % [float(c.inflation), 0.3 * yoy])
	# clamp vstupu: obrovsky rast cien sa orizne na INFL_MAX
	_new()
	c = GameState.world["SK"]
	c.cpi_hist = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
	c.inflation = 0.0
	for cid in MarketSystem.cpi_weights("SK").keys():
		GameState.markets["SK"][cid].price = float(DataLoader.commodity(cid).base_price) * 10.0
	GameState._macro()
	_chk("e1_cpi_clamp_max", float(c.inflation) <= 0.3 * GameState.INFL_MAX + 1e-9 and float(c.inflation) > 0.0, str(c.inflation))
	# kratka historia: vstupna inflacia hladko dozniva k 0 (bez skoku v 15. mesiaci)
	_new()
	c = GameState.world["SK"]
	var i0 = float(c.inflation)
	GameState._macro()
	_chk("e1_cpi_short_history_decays_input", abs(float(c.inflation) - i0 * (1.0 - GameState.INFL_DECAY)) < 1e-12, "%f -> %f" % [i0, float(c.inflation)])

func _e1_rate() -> void:
	_new()
	var iso = "SK"
	var c: Dictionary = GameState.world[iso]
	var row: Dictionary = GameState.central[iso]
	c.gdp_growth = 0.02
	c.stability = 80.0
	row.prev_rate = 0.05
	row.upd_day = GameState.day_index
	c.inflation = 0.05
	BankingSystem.update_rates()
	var r1 = float(GameState.central[iso].base_rate)
	c.inflation = 0.10
	BankingSystem.update_rates()
	var r2 = float(GameState.central[iso].base_rate)
	var slope = (r2 - r1) / (1.0 - BankingSystem.RATE_SMOOTH) / 0.05
	_chk("e1_taylor_slope_gt_1", slope > 1.0 and BankingSystem.TAYLOR_A_PI > 1.0, "sklon cielovej sadzby %.2f" % slope)
	_chk("e1_rate_idempotent_same_day", abs(float(GameState.central[iso].policy) - r2) < 1e-12)
	# vyhladzovanie: jeden krok sa nehne o viac nez (1-smooth)*|target-prev|
	_chk("e1_rate_smoothing", abs(r1 - 0.05) <= (1.0 - BankingSystem.RATE_SMOOTH) * 0.6, str(r1))
	# dno a strop; sadzba sa nelepi na strope: extremna inflacia -> strop, potom navrat pod 0.1 do 36 mesiacov
	c.inflation = 0.60
	var top = 0.0
	for m in 40:
		GameState.day_index += 30
		BankingSystem.update_rates()
		top = float(GameState.central[iso].base_rate)
	_chk("e1_rate_ceiling", top <= BankingSystem.RATE_MAX + 1e-12 and top > 0.3, str(top))
	c.inflation = 0.02
	var low = 1.0
	for m2 in 36:
		GameState.day_index += 30
		BankingSystem.update_rates()
		low = float(GameState.central[iso].base_rate)
	_chk("e1_rate_not_stuck_at_ceiling", low < 0.1, str(low))
	c.inflation = -0.25
	c.gdp_growth = -0.06
	for m3 in 60:
		GameState.day_index += 30
		BankingSystem.update_rates()
	var floor_r = float(GameState.central[iso].base_rate)
	_chk("e1_rate_floor", floor_r >= 0.0 and floor_r <= 0.005 + 1e-12, str(floor_r))

func _band_share(isos: Array = []) -> float:
	var inb = 0
	var n = 0
	for iso in DataLoader.country_ids:
		if not isos.is_empty() and not (iso in isos):
			continue
		for cid in DataLoader.commodity_ids:
			var r = MarketSystem.price(iso, cid) / float(DataLoader.commodity(cid).base_price)
			n += 1
			if r >= 0.7 and r <= 1.3:
				inb += 1
	return float(inb) / max(float(n), 1.0)

func _run_days(n: int) -> void:
	for i in n:
		GameState.simulate_day()

func _e1_shocks() -> void:
	# a) vojna SK-CZ 120 dni: ceny v SK sa pocas nej pohnu, po mieri sa do 2 rokov vratia do +-30 %
	_new()
	_run_days(30)
	GeopoliticsSystem._start_war("SK", "CZ")
	_run_days(120)
	var war_px = MarketSystem.price("SK", "wheat") / float(DataLoader.commodity("wheat").base_price)
	var war_share = _band_share(["SK"])
	GeopoliticsSystem._end_war(GameState.wars[0])
	_chk("e1_war_recovery_flags", not bool(GameState.world["SK"].get("infra_damage", false)) and GameState.wars.is_empty())
	_run_days(730)
	var after = _band_share()
	var after_sk = _band_share(["SK", "CZ"])
	_chk("e1_war_shock_visible", war_share < 1.0 or abs(war_px - 1.0) > 0.03, "pocas vojny pasmo SK %.2f pszenica %.2f" % [war_share, war_px])
	_chk("e1_war_recovers_2y", after >= 0.95 and after_sk >= 0.95, "po 2 rokoch vsetky %.3f SK/CZ %.3f" % [after, after_sk])
	# b) susko pre pseniicu v SK (22 dni): vrati sa
	_new()
	_run_days(20)
	GameState.world["SK"].weather = "drought"
	GameState.world["SK"].weather_left = 22
	var peak = 0.0
	for i in 40:
		GameState.simulate_day()
		peak = max(peak, MarketSystem.price("SK", "wheat") / float(DataLoader.commodity("wheat").base_price))
	_run_days(200)
	var back = MarketSystem.price("SK", "wheat") / float(DataLoader.commodity("wheat").base_price)
	_chk("e1_drought_spike_and_recovery", peak > 1.05 and back > 0.7 and back < 1.3, "vrchol %.2f po 240 dnoch %.2f" % [peak, back])
	# c) sankcia/embargo na CZ 100 dni, potom zrusenie: po roku spat v pasme
	_new()
	_run_days(30)
	GeopoliticsSystem.impose_sanction("CZ")
	_run_days(100)
	GeopoliticsSystem.lift_sanction("CZ")
	_run_days(365)
	_chk("e1_sanction_recovers", _band_share() >= 0.95, "%.3f" % _band_share())

# ---------------- ETAPA 1 - opravy po review ----------------
func _e1_review() -> void:
	# 1) sprava o primeri
	_new()
	GameState.wars.clear()
	GeopoliticsSystem._start_war("SK", "CZ")
	var n0 = GameState.news.size()
	GeopoliticsSystem._end_war(GameState.wars[0])
	_chk("e1_end_war_news", GameState.news.size() > n0 and str(GameState.news[0].text).begins_with("Prímerie"), str(GameState.news[0].text))
	# 2) dve suberzne vojny jednej krajiny: gdp_growth sa vrati presne, infra_damage az po poslednej
	_new()
	GameState.wars.clear()
	var g_sk = float(GameState.world["SK"].gdp_growth)
	var g_cz = float(GameState.world["CZ"].gdp_growth)
	var g_pl = float(GameState.world["PL"].gdp_growth)
	GeopoliticsSystem._start_war("SK", "CZ")
	GeopoliticsSystem._start_war("SK", "PL")
	_chk("e1_two_wars_penalty", abs(float(GameState.world["SK"].gdp_growth) - (g_sk - 0.03)) < 1e-12)
	GeopoliticsSystem._end_war(GameState.wars[0])
	_chk("e1_two_wars_after_first", abs(float(GameState.world["SK"].gdp_growth) - (g_sk - 0.015)) < 1e-12 and bool(GameState.world["SK"].infra_damage) and abs(float(GameState.world["CZ"].gdp_growth) - g_cz) < 1e-12)
	GeopoliticsSystem._end_war(GameState.wars[0])
	_chk("e1_two_wars_after_second", abs(float(GameState.world["SK"].gdp_growth) - g_sk) < 1e-12 and not bool(GameState.world["SK"].infra_damage) and abs(float(GameState.world["PL"].gdp_growth) - g_pl) < 1e-12 and abs(float(GameState.world["SK"].war_gdp_pen)) < 1e-12, str(GameState.world["SK"].gdp_growth))
	# stary save uprostred vojny (bez war_gdp_pen) sa po mieri tiez vrati
	_new()
	GameState.wars.clear()
	var g2 = float(GameState.world["SK"].gdp_growth)
	GeopoliticsSystem._start_war("SK", "CZ")
	GameState.world["SK"].erase("war_gdp_pen")
	GeopoliticsSystem._end_war(GameState.wars[0])
	_chk("e1_war_recovery_old_save", abs(float(GameState.world["SK"].gdp_growth) - g2) < 1e-12)
	# 3) save v2 z etapy 0 bez novych poli sa nacita a doplni defaulty; pokazene nove polia sa odmietnu
	_new()
	for i in 40:
		GameState.simulate_day()
	var good: Dictionary = GameState.to_dict()
	var mk = func(mut: Callable) -> Dictionary:
		var c: Dictionary = JSON.parse_string(JSON.stringify(good))
		mut.call(c)
		return c
	var old_v2: Dictionary = mk.call(func(c):
		c["v"] = 2
		for iso in c.world.keys():
			for k in ["cpi_hist", "cpi_acc", "cpi_n", "war_gdp_pen"]:
				c.world[iso].erase(k)
		for iso2 in c.central.keys():
			c.central[iso2].erase("prev_rate")
			c.central[iso2].erase("upd_day")
		for iso3 in c.markets.keys():
			for cid in c.markets[iso3].keys():
				c.markets[iso3][cid].erase("dref"))
	var e_old = GameState.from_dict(old_v2)
	_chk("e1_load_v2_without_new_fields", e_old == "", e_old)
	var def_ok = GameState.world["SK"].has("cpi_hist") and int(GameState.world["SK"].cpi_n) == 0 and GameState.central["SK"].has("prev_rate") and int(GameState.central["SK"].upd_day) == -1
	_chk("e1_load_defaults_filled", def_ok)
	for i in 5:
		GameState.simulate_day()
	var nan_ok = true
	for iso in DataLoader.country_ids:
		for cid in DataLoader.commodity_ids:
			if EconMath.is_bad(MarketSystem.price(iso, cid)):
				nan_ok = false
	_chk("e1_load_v2_then_runs", nan_ok and not EconMath.is_bad(float(GameState.central["SK"].base_rate)))
	var bad_cases = {
		"cpi_hist_str": func(c): c.world["SK"].cpi_hist = "x",
		"cpi_hist_elem_str": func(c): c.world["SK"].cpi_hist = [1.0, "x"],
		"cpi_hist_negative": func(c): c.world["SK"].cpi_hist = [1.0, -2.0],
		"cpi_hist_nan": func(c): c.world["SK"].cpi_hist = [1.0, NAN],
		"cpi_hist_inf": func(c): c.world["SK"].cpi_hist = [INF],
		"cpi_hist_huge_len": func(c): c.world["SK"].cpi_hist = range(200).map(func(i): return 1.0),
		"cpi_acc_str": func(c): c.world["SK"].cpi_acc = "x",
		"cpi_n_str": func(c): c.world["SK"].cpi_n = "x",
		"cpi_n_negative": func(c): c.world["SK"].cpi_n = -3,
		"cpi_n_fraction": func(c): c.world["SK"].cpi_n = 1.5,
		"war_gdp_pen_str": func(c): c.world["SK"].war_gdp_pen = "x",
		"prev_rate_str": func(c): c.central["SK"].prev_rate = "x",
		"prev_rate_range": func(c): c.central["SK"].prev_rate = 99.0,
		"prev_rate_nan": func(c): c.central["SK"].prev_rate = NAN,
		"upd_day_str": func(c): c.central["SK"].upd_day = "x",
		"upd_day_fraction": func(c): c.central["SK"].upd_day = 2.5,
	}
	var before_j = JSON.stringify(GameState.to_dict())
	for name in bad_cases.keys():
		var gd: Dictionary = GameState.to_dict()
		var bd: Dictionary = JSON.parse_string(JSON.stringify(gd))
		bad_cases[name].call(bd)
		_chk("e1_reject_" + name, GameState.from_dict(bd) != "")
	_chk("e1_reject_keeps_live_state", JSON.stringify(GameState.to_dict()) == before_j)

# ---------------- ETAPA 1 - posledne drobnosti pred QA ----------------
func _e1_final() -> void:
	# (a) embargo sa zrusuje lift_embargo (nie lift_sanction)
	_new()
	GeopoliticsSystem.impose_embargo("CZ")
	_chk("e1_embargo_blocks", GeopoliticsSystem.blocked("SK", "CZ"))
	var ls = GeopoliticsSystem.lift_sanction("CZ")
	_chk("e1_lift_sanction_does_not_lift_embargo", ls != "" and GeopoliticsSystem.blocked("SK", "CZ"), ls)
	var le = GeopoliticsSystem.lift_embargo("CZ")
	_chk("e1_lift_embargo_unblocks", le == "" and not GeopoliticsSystem.blocked("SK", "CZ"), le)
	_new()
	_run_days(30)
	var war_open = MarketSystem._openness()
	var phi0 = float(war_open.get("SK", 1.0))
	GeopoliticsSystem.impose_embargo("CZ")
	GeopoliticsSystem.impose_sanction("DE")
	_run_days(100)
	var phi1 = float(MarketSystem._openness().get("SK", 1.0))
	var bw = _band_share(["SK"])
	GeopoliticsSystem.lift_embargo("CZ")
	GeopoliticsSystem.lift_sanction("DE")
	_run_days(365)
	_chk("e1_embargo_sanction_recovers", _band_share() >= 0.95 and not GeopoliticsSystem.blocked("SK", "CZ") and not GeopoliticsSystem.blocked("SK", "DE"), "pasmo po 365 d %.3f; openness SK %.3f -> %.3f pocas, pasmo SK pocas %.2f" % [_band_share(), phi0, phi1, bw])
	# (b) save v1, v2, v3 a pokazeny v3
	_new()
	_run_days(40)
	var good: Dictionary = GameState.to_dict()
	_chk("e1_save_version_is_3", int(good.v) == 3 and GameState.SAVE_VERSION == 3)
	var mk = func(mut: Callable) -> Dictionary:
		var c: Dictionary = JSON.parse_string(JSON.stringify(good))
		mut.call(c)
		return c
	var strip = func(c):
		for iso in c.world.keys():
			for k in ["cpi_hist", "cpi_acc", "cpi_n"]:
				c.world[iso].erase(k)
		for iso2 in c.central.keys():
			c.central[iso2].erase("prev_rate")
			c.central[iso2].erase("upd_day")
		for iso3 in c.markets.keys():
			for cid in c.markets[iso3].keys():
				c.markets[iso3][cid].erase("dref")
	var v1: Dictionary = mk.call(func(c):
		c["v"] = 1
		strip.call(c))
	var v2: Dictionary = mk.call(func(c):
		c["v"] = 2
		strip.call(c))
	var e1 = GameState.from_dict(v1)
	_chk("e1_load_v1", e1 == "", e1)
	_chk("e1_v1_migrated_fields", GameState.world["SK"].has("cpi_hist") and GameState.markets["SK"]["wheat"].has("dref") and GameState.central["SK"].has("prev_rate"))
	var e2 = GameState.from_dict(v2)
	_chk("e1_load_v2", e2 == "", e2)
	var snap1 = JSON.stringify(GameState.to_dict())
	GameState._migrate_v2_to_v3()
	_chk("e1_migration_idempotent", JSON.stringify(GameState.to_dict()) == snap1)
	_run_days(5)
	var ok_px = true
	for iso in DataLoader.country_ids:
		for cid in DataLoader.commodity_ids:
			if EconMath.is_bad(MarketSystem.price(iso, cid)) or float(GameState.markets[iso][cid].dref) <= 0.0:
				ok_px = false
	_chk("e1_v2_loaded_runs_and_dref_initialized", ok_px)
	var e3 = GameState.from_dict(mk.call(func(c): pass))
	_chk("e1_load_v3", e3 == "", e3)
	var v3_bad = {
		"v3_missing_cpi_hist": func(c): c.world["SK"].erase("cpi_hist"),
		"v3_missing_dref": func(c): c.markets["SK"]["wheat"].erase("dref"),
		"v3_missing_prev_rate": func(c): c.central["SK"].erase("prev_rate"),
		"v3_missing_upd_day": func(c): c.central["SK"].erase("upd_day"),
		"v3_cpi_hist_str": func(c): c.world["SK"].cpi_hist = "x",
		"v3_dref_str": func(c): c.markets["SK"]["wheat"].dref = "x",
		"v3_future_v4": func(c): c["v"] = 4,
	}
	for name in v3_bad.keys():
		_chk("e1_reject_" + name, GameState.from_dict(mk.call(v3_bad[name])) != "")
	# (c) dve suberzne vojny, 12 mesiacov po konci: sadzba SK nekolise (rozsah za poslednych 6 mesiacov <= 0.02)
	_new()
	_run_days(30)
	GeopoliticsSystem._start_war("SK", "CZ")
	GeopoliticsSystem._start_war("SK", "PL")
	_run_days(120)
	var rate_war_max = 0.0
	while not GameState.wars.is_empty():
		GeopoliticsSystem._end_war(GameState.wars[0])
	var rmin = 9.0
	var rmax = -9.0
	var r_start = float(GameState.central["SK"].base_rate)
	for dd in 365:
		GameState.simulate_day()
		if dd >= 182:
			var rr = float(GameState.central["SK"].base_rate)
			rmin = min(rmin, rr)
			rmax = max(rmax, rr)
	_chk("e1_two_wars_rate_stable_after_12m", rmax - rmin <= 0.02, "rozsah %.4f (min %.4f max %.4f), sadzba pri konci vojen %.4f, infl %.4f" % [rmax - rmin, rmin, rmax, r_start, float(GameState.world["SK"].inflation)])
	# (d) sucho: rozklad vrcholu ceny SK (SK sucho 22 d; ponuka SK x0.62 pre wheat/coffee/meat, dopyt pseniece x1.2*1.05)
	_new()
	_run_days(20)
	GameState.world["SK"].weather = "drought"
	GameState.world["SK"].weather_left = 22
	var pk = {"wheat": 0.0, "coffee": 0.0, "meat": 0.0}
	var pk_de = 0.0
	for i in 40:
		GameState.simulate_day()
		for cid in pk.keys():
			pk[cid] = max(pk[cid], MarketSystem.price("SK", cid) / float(DataLoader.commodity(cid).base_price))
		pk_de = max(pk_de, MarketSystem.price("DE", "wheat") / float(DataLoader.commodity("wheat").base_price))
	_chk("e1_drought_decomposition", pk["wheat"] > pk["coffee"], "vrchol SK pszenica %.3f kava %.3f maso %.3f ; DE pszenica %.3f" % [pk["wheat"], pk["coffee"], pk["meat"], pk_de])

func _ai_ids() -> PackedStringArray:
	var ids = PackedStringArray()
	for firm in GameState.firms:
		if str(firm.get("owner", "")) == "ai":
			ids.append("%s|%s|%s" % [str(firm.get("id", "")), str(firm.get("country", "")), str(firm.get("industry", ""))])
	return ids

func _m1_ai_minister() -> void:
	_new()
	var ids_a = _ai_ids()
	var saved: Dictionary = GameState.to_dict()
	_new()
	var ids_b = _ai_ids()
	_chk("ai_firm_spawn_deterministic", ids_a == ids_b and ids_a.size() > 0, str(ids_a.size()))
	var err = GameState.from_dict(saved)
	var ids_c = _ai_ids()
	_chk("ai_firms_in_save_roundtrip", err == "" and ids_c == ids_a, err)
	var sheet: Dictionary = LawSystem.minister_sheet("SK")
	var clean = true
	for key in ["tax", "rate", "cpi", "pi", "unemployment", "stability", "debt", "rating"]:
		if EconMath.is_bad(float(sheet.get(key, NAN))):
			clean = false
	_chk("minister_data_not_nan", clean and int(sheet.get("n_laws", -1)) >= 0 and int(sheet.get("n_ai_firms", -1)) > 0)

func _read_text(path: String) -> String:
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()

func _catalog_signature() -> String:
	var lines: PackedStringArray = PackedStringArray()
	for i in range(1, 71):
		var id = "T%02d" % i
		var node: Dictionary = DataLoader.tech_by_id.get(id, {})
		var reqs: PackedStringArray = PackedStringArray()
		for req in node.get("prerequisites", []):
			reqs.append(str(req))
		lines.append("\t".join(PackedStringArray([
			"TECH", id, str(node.get("name", "")), str(node.get("year", "")), str(node.get("category", "")),
			",".join(reqs), str(node.get("effect", "")), str(node.get("source", "")), str(node.get("status", "")),
		])))
	for tree_name in ["USA", "SU", "CN", "UK", "FR", "DE", "JP", "IN", "generic"]:
		for row in DataLoader.focus_trees.get(tree_name, []):
			var focus: Dictionary = row
			var reqs2: PackedStringArray = PackedStringArray()
			for req2 in focus.get("prerequisites", []):
				reqs2.append(str(req2))
			var ex: PackedStringArray = PackedStringArray()
			for item in focus.get("exclusive", []):
				ex.append(str(item))
			var opt: PackedStringArray = PackedStringArray()
			for item2 in focus.get("options", []):
				opt.append(str(item2))
			lines.append("\t".join(PackedStringArray([
				"FOCUS", str(focus.get("id", "")), str(focus.get("name", "")), str(focus.get("year", "")),
				",".join(reqs2), ",".join(ex), ",".join(opt), str(focus.get("source", "")), str(focus.get("status", "")),
			])))
	for j in range(1, 14):
		var fid = "F%d" % j
		var cast: Dictionary = DataLoader.forecast_by_id.get(fid, {})
		lines.append("\t".join(PackedStringArray([
			"FORECAST", fid, str(cast.get("name", "")), str(cast.get("class", "")), str(cast.get("estimate", "")),
			str(cast.get("source", "")), str(cast.get("note", "")), str(cast.get("status", "")),
		])))
	return "\n".join(lines) + "\n"

func _history_catalog() -> void:
	var errs: PackedStringArray = DataLoader.history_catalog_errors()
	_chk("history_catalog_errors", errs.is_empty(), " ".join(errs))
	var t01: Dictionary = DataLoader.tech_by_id.get("T01", {})
	_chk("tech_t01", str(t01.get("year", "")) == "1951" and str(t01.get("category", "")) == "IT" and t01.get("prerequisites", ["x"]).is_empty() and str(t01.get("source", "")) == "https://en.wikipedia.org/wiki/Transistor" and str(t01.get("name", "")) == "Tranzistor (sériová výroba)")
	var t05: Dictionary = DataLoader.tech_by_id.get("T05", {})
	_chk("tech_t05_req", t05.get("prerequisites", []) == ["T03"])
	_chk("tech_t12_year", str(DataLoader.tech_by_id.get("T12", {}).get("year", "")) == "1955")
	var t21: Dictionary = DataLoader.tech_by_id.get("T21", {})
	_chk("tech_t21", str(t21.get("year", "")) == "1969" and str(t21.get("source", "")) == "https://www.nasa.gov/mission/apollo-11/")
	_chk("tech_t50_year", str(DataLoader.tech_by_id.get("T50", {}).get("year", "")).find("1999") >= 0)
	var t57: Dictionary = DataLoader.tech_by_id.get("T57", {})
	_chk("tech_t57", str(t57.get("status", "")) == "OVERENE" and str(t57.get("name", "")).find("NEOVERENE ako presný rok") >= 0)
	var t63 = str(DataLoader.tech_by_id.get("T63", {}).get("status", ""))
	var t68 = str(DataLoader.tech_by_id.get("T68", {}).get("status", ""))
	_chk("tech_t63_note", t63.begins_with("NEOVERENE") and t63.find("Wikipédia uvádza oznámenie 2018") >= 0)
	_chk("tech_t68_note", t68.begins_with("NEOVERENE") and t68.find("rok masového nasadenia FPV nemá jednoznačný zdroj") >= 0)
	var pairs = [["US2", "US2A"], ["US5", "US5A"], ["US7", "US7A"], ["US10", "US10A"], ["SU2", "SU2A"], ["SU5", "SU5A"], ["SU7", "SU7A"], ["SU8", "SU8A"], ["SU12", "SU12A"], ["CN3", "CN3A"], ["CN7", "CN7A"], ["CN8", "CN8A"], ["UK2", "UK2A"], ["UK4", "UK4A"], ["UK10", "UK10A"], ["FR3", "FR3A"], ["FR6", "FR6A"], ["DE2", "DE2A"], ["DE6", "DE6A"], ["DE9", "DE9A"], ["JP2", "JP2A"], ["JP7", "JP7A"], ["IN3", "IN3A"], ["IN8", "IN8A"], ["G1A", "G1B"]]
	var mex_ok = true
	for pair in pairs:
		var left: Dictionary = DataLoader.focus_by_id.get(pair[0], {})
		var right: Dictionary = DataLoader.focus_by_id.get(pair[1], {})
		if not (pair[1] in left.get("exclusive", []) and pair[0] in right.get("exclusive", [])):
			mex_ok = false
	_chk("focus_mutual_exclusion", mex_ok)
	var g2: Dictionary = DataLoader.focus_by_id.get("G2", {})
	var g3: Dictionary = DataLoader.focus_by_id.get("G3", {})
	var g4: Dictionary = DataLoader.focus_by_id.get("G4", {})
	_chk("focus_bloc_exclusion", "G3" in g2.get("exclusive", []) and "G4" in g2.get("exclusive", []) and "G2" in g3.get("exclusive", []) and "G4" in g3.get("exclusive", []) and "G2" in g4.get("exclusive", []) and "G3" in g4.get("exclusive", []))
	_chk("focus_g6_options", DataLoader.focus_by_id.get("G6", {}).get("options", []) == ["plávajúci kurz", "fixácia"])
	_chk("focus_g7_options", DataLoader.focus_by_id.get("G7", {}).get("options", []) == ["šetrenie", "jadro", "nové náleziská"])
	var reforma: Dictionary = {}
	for fid in DataLoader.focus_by_id.keys():
		var row: Dictionary = DataLoader.focus_by_id[fid]
		if str(row.get("name", "")) == "Trhová reforma":
			reforma = row
	_chk("focus_trhova_g10", "G10" in reforma.get("prerequisites", []) and str(reforma.get("audience", "")) == "socialist")
	var f_ok = true
	for i in range(1, 14):
		var fid = "F%d" % i
		var row: Dictionary = DataLoader.forecast_by_id.get(fid, {})
		if str(row.get("class", "")) != "ODHAD" or DataLoader.tech_by_id.has(fid):
			f_ok = false
		var st = str(row.get("status", ""))
		if (fid == "F6" or fid == "F9"):
			if not st.begins_with("NEOVERENE"):
				f_ok = false
		elif st != "OVERENE":
			f_ok = false
	_chk("forecasts_odhad", f_ok and DataLoader.forecasts.size() == 13)
	_chk("forecast_f3_name", str(DataLoader.forecast_by_id.get("F3", {}).get("name", "")) == "AI na úrovni človeka (HLMI)")
	_chk("forecast_f10_name", str(DataLoader.forecast_by_id.get("F10", {}).get("name", "")) == "Otepľovanie 1,5 °C prekročené")
	_chk("forecast_f13_name", str(DataLoader.forecast_by_id.get("F13", {}).get("name", "")) == "EÚ klimatická neutralita")
	var names_ok = true
	for j in range(1, 14):
		if str(DataLoader.forecast_by_id.get("F%d" % j, {}).get("name", "")) == "":
			names_ok = false
	_chk("forecast_names_present", names_ok)
	var fnames = {
		"F1": "ITER – začiatok výskumnej prevádzky",
		"F2": "Fúzna demo elektráreň (DEMO, komerčná fúzia)",
		"F3": "AI na úrovni človeka (HLMI)",
		"F4": "AGI podľa Metaculus",
		"F5": "Kvantový počítač odolný voči chybám",
		"F6": "Kvantové prelomenie RSA-2048",
		"F7": "Návrat človeka na Mesiac (Artemis)",
		"F8": "Koniec ISS, komerčné stanice",
		"F9": "Pilotovaný let na Mars",
		"F10": "Otepľovanie 1,5 °C prekročené",
		"F11": "Vrchol dopytu po fosílnych palivách",
		"F12": "Čisté nulové emisie energetiky",
		"F13": "EÚ klimatická neutralita",
	}
	var all_names = true
	for key in fnames.keys():
		if str(DataLoader.forecast_by_id.get(key, {}).get("name", "")) != str(fnames[key]):
			all_names = false
	_chk("forecast_all_names", all_names)
	_chk("forecast_f1_source", str(DataLoader.forecast_by_id.get("F1", {}).get("source", "")) == "https://www.iter.org/few-lines (nová baseline 2024)")
	_chk("forecast_f2_source", str(DataLoader.forecast_by_id.get("F2", {}).get("source", "")) == "https://en.wikipedia.org/wiki/DEMOnstration_Power_Plant (IAEA World Fusion Outlook)")
	_chk("forecast_f3_source", str(DataLoader.forecast_by_id.get("F3", {}).get("source", "")) == "Grace et al. 2024, „Thousands of AI Authors on the Future of AI“ https://arxiv.org/abs/2401.02843")
	_chk("forecast_f6_source", str(DataLoader.forecast_by_id.get("F6", {}).get("source", "")) == "Wikipédia: Post-quantum cryptography (GRI report nedostupný) https://en.wikipedia.org/wiki/Post-quantum_cryptography")
	_chk("forecast_f9_source", str(DataLoader.forecast_by_id.get("F9", {}).get("source", "")).begins_with("NASA Moon to Mars "))
	_chk("forecast_f10_source", str(DataLoader.forecast_by_id.get("F10", {}).get("source", "")).begins_with("IPCC AR6 SYR "))
	_chk("forecast_f11_source", str(DataLoader.forecast_by_id.get("F11", {}).get("source", "")).begins_with("IEA World Energy Outlook "))
	_chk("forecast_f12_source", str(DataLoader.forecast_by_id.get("F12", {}).get("source", "")).begins_with("IEA Net Zero Roadmap "))
	_chk("catalog_fields_match_brief", _catalog_signature() == _read_text("res://tests/catalog_field_lock.txt"))
	_new()
	GameState.player.cash = 1000000.0
	var start_err = GameState.start_research("logistics1")
	for _i in 28:
		GameState.simulate_day()
	_chk("logistics1_freight_still_0_9", start_err == "" and is_equal_approx(float(GameState.player.modifiers.get("freight_mult", 0.0)), 0.9) and DataLoader.research.size() >= 8 and ["logistics1", "logistics2", "auto1", "agro1", "chem1", "arms1", "energy1", "score1"].all(func(i): return not GameState.research_def(i).is_empty()), start_err)  # JUAN5: strom ma 21 uzlov, povodnych 8 ostava

# JUAN-FIX (K0c4): dividendy z hracovych firiem
func _juan2_setup() -> Array:
	_new()
	GameState.player.cash = 5000000.0
	var ids: Array = []
	for ind in ["cafe", "finance_office", "textile_mill", "wheat_farm"]:
		var err = GameState.found_firm(ind, "", "SK")
		if err.begins_with("f"):
			ids.append(err)
	return ids

func _juan2_dividends() -> void:
	var ids = _juan2_setup()
	var n_firms = GameState.player_firms().size()
	while int(GameState.day_index) < 30:
		GameState.simulate_day()
	var d30 = float(GameState.player.cash)
	var paid = 0.0
	var below = false
	while int(GameState.day_index) < 60:
		var m = int(GameState.date.m)
		GameState.simulate_day()
		if int(GameState.date.m) != m:
			paid += IndustrySystem.last_dividends
			for f in GameState.player_firms():
				if float(f.get("last_dividend", 0.0)) > 0.0 and float(f.cash) < IndustrySystem.firm_reserve(f) - 0.01:
					below = true
	var d60 = float(GameState.player.cash)
	var rev_ok = true
	for f in GameState.player_firms():
		if float(IndustrySystem.firm_summary(f).rev) <= 0.0:
			rev_ok = false
	_chk("juan2_firms_founded", n_firms == 4, "n=%d ids=%s" % [n_firms, str(ids)])
	_chk("juan2_firm_income", rev_ok)
	_chk("juan2_dividend_paid", paid > 0.0 and d60 > d30, "P47_DIVIDEND d30=%.0f d60=%.0f paid=%.0f" % [d30, d60, paid])
	_chk("juan2_dividend_never_below_reserve", not below)
	# strata -> 0
	var f: Dictionary = GameState.player_firms()[0]
	f.history = [{"rev": 0.0, "cogs": 10.0, "wages": 10.0, "rent": 0.0, "tax": 0.0, "profit": -20.0, "day": GameState.day_index}]
	f.last_div_day = -1
	f.cash = 100000.0
	var cash_p = float(GameState.player.cash)
	IndustrySystem.pay_dividends()
	_chk("juan2_dividend_loss_zero", abs(float(f.cash) - 100000.0) < 0.01 and float(f.last_dividend) == 0.0)
	# plny prebytok
	f.history = [{"rev": 1000.0, "cogs": 100.0, "wages": 100.0, "rent": 50.0, "tax": 50.0, "profit": 700.0, "day": GameState.day_index + 1}]
	f.last_div_day = -1
	f.cash = 50000.0
	var reserve = IndustrySystem.firm_reserve(f)
	cash_p = float(GameState.player.cash)
	IndustrySystem.pay_dividends()
	_chk("juan2_dividend_full_surplus", abs(float(f.cash) - reserve) < 0.01 and abs(reserve - 9000.0) < 0.01 and float(GameState.player.cash) - cash_p >= 41000.0 - 0.01, "reserve %.2f cash %.2f" % [reserve, float(f.cash)])

func _juan2_save_load() -> void:
	_juan2_setup()
	for _i in 35:
		GameState.simulate_day()
	var cash = float(GameState.player.cash)
	var nf = GameState.player_firms().size()
	var fcash = float(GameState.player_firms()[0].cash)
	var day = int(GameState.day_index)
	var date_s = str(GameState.date)
	var path = SaveSystem.save_slot(3)
	_juan2_setup()
	GameState.player.cash = 1.0
	var err = SaveSystem.load_slot(3)
	_chk("juan2_save_load_roundtrip", path.ends_with(".json") and err == "" and abs(float(GameState.player.cash) - cash) < 0.01 and GameState.player_firms().size() == nf and abs(float(GameState.player_firms()[0].cash) - fcash) < 0.01 and int(GameState.day_index) == day and str(GameState.date) == date_s, "err=%s cash %.0f/%.0f firms %d date %s" % [err, float(GameState.player.cash), cash, GameState.player_firms().size(), str(GameState.date)])
	_chk("juan2_save_keeps_last_div_day", GameState.player_firms()[0].has("last_div_day"))


# ===== JUAN3 =====
func _juan3_loans() -> void:
	var pay = BankingSystem.annuity_payment(10000.0, 0.12, 12)
	_chk("juan3_annuity", abs(pay - 888.49) < 0.05, "%.2f" % pay)
	_chk("juan3_annuity_zero_rate", abs(BankingSystem.annuity_payment(1200.0, 0.0, 12) - 100.0) < 0.001)
	_new()
	GameState.player.cash = 2000000.0
	var err = BankingSystem.found_player_bank("Test", "SK")
	var bank: Dictionary = BankingSystem._player_bank()
	_chk("juan3_bank_found", err == "" and not bank.is_empty(), err)
	var r = BankingSystem.set_consumer_rate(0.10)
	var res0 = float(bank.reserves)
	var st1 = BankingSystem.consumer_month(bank)
	_chk("juan3_loans_issued", float(st1.new) > 0.0 and abs(float(bank.reserves) - (res0 - float(st1.new))) < 0.01 and float(st1.new) <= res0 * 0.5 + 0.01, "new %.0f" % float(st1.new))
	var eq = float(bank.equity)
	var res1 = float(bank.reserves)
	var st2 = BankingSystem.consumer_month(bank)
	var expect_i = (float(st1.new) * (1.0 - float(st2.default_rate))) * r / 12.0
	_chk("juan3_loans_interest", abs(float(st2.interest) - expect_i) < 0.01 and float(st2.repaid) > float(st2.interest), "i %.2f exp %.2f" % [float(st2.interest), expect_i])
	_chk("juan3_loans_defaults", float(st2.loss) > 0.0 and abs(float(st2.loss) - float(st1.new) * float(st2.default_rate)) < 0.01 and float(st2.default_rate) > 0.0 and float(st2.default_rate) < 0.05)
	_chk("juan3_loans_equity", abs(float(bank.equity) - (eq + float(st2.interest) - float(st2.loss))) < 0.01 and abs(float(bank.reserves) - (res1 + float(st2.repaid) - float(st2.new))) < 0.01)
	var hi = BankingSystem.consumer_demand(bank)
	BankingSystem.set_consumer_rate(0.30)
	_chk("juan3_rate_cuts_demand_raises_risk", BankingSystem.consumer_demand(bank) < hi and BankingSystem.consumer_default_rate(bank) > float(st2.default_rate))
	# uver splateny do konca: 36 mesiacov bez noveho pozicania
	var b2 = {"country": "SK", "reserves": 0.0, "deposits": 1.0e12, "reserve_ratio": 0.1, "equity": 0.0, "strictness": 1.0, "cons_rate": 0.0, "cons_loans": [{"p": 3600.0, "n": 36}]}
	var paid = 0.0
	for _i in 36:
		paid += float(BankingSystem.consumer_month(b2).repaid)
	_chk("juan3_loan_amortizes", (b2.cons_loans as Array).is_empty() and paid < 3600.0 and paid > 3000.0, "paid %.0f" % paid)

func _juan3_firm() -> Dictionary:
	_new()
	GameState.player.cash = 5000000.0
	GameState.found_firm("cafe", "", "SK")
	return GameState.player_firms()[0]

func _juan3_manager() -> void:
	var f = _juan3_firm()
	var e0 = IndustrySystem.firm_efficiency(f)
	_chk("juan3_baseline_management", abs(e0 - IndustrySystem.NO_MANAGER_EFF) < 0.001 and IndustrySystem.buy_share(f) == IndustrySystem.NO_MANAGER_BUY)
	var cands = IndustrySystem.manager_candidates(f)
	_chk("juan3_candidates", cands.size() == 3 and float(cands[0].salary) > 0.0)
	IndustrySystem.hire_manager(str(f.id), {"name": "A", "skill": 0.8, "salary": 3000.0})
	_chk("juan3_manager_eff", abs(IndustrySystem.firm_efficiency(f) - 1.14) < 0.001 and IndustrySystem.buy_share(f) == 1.0)
	f.workers = 1.0
	IndustrySystem.close_month(2024, 1)
	_chk("juan3_manager_hires", abs(float(f.workers) - IndustrySystem.target_workers(f)) < 0.001)
	var c0 = float(f.cash)
	GameState.running = true
	GameState.paused = false
	f.history = []
	GameState.simulate_day()
	var h: Dictionary = f.history[f.history.size() - 1]
	_chk("juan3_salary_cost", float(h.wages) >= 100.0 - 0.01, "wages %.2f" % float(h.wages))
	IndustrySystem.fire_manager(str(f.id))
	var w0 = float(f.workers)
	IndustrySystem.close_month(2024, 2)
	_chk("juan3_fire_keeps_baseline_staff", not IndustrySystem.has_manager(f) and is_equal_approx(float(f.workers), w0) and is_equal_approx(IndustrySystem.firm_efficiency(f), 1.0))
	# porovnanie produkcie s/bez pravej ruky
	var f2 = _juan3_firm()
	for _i in 20:
		GameState.simulate_day()
	var rev_no = IndustrySystem.firm_summary(f2).rev
	var f3 = _juan3_firm()
	IndustrySystem.hire_manager(str(f3.id), {"name": "B", "skill": 0.9, "salary": 0.0})
	for _i in 20:
		GameState.simulate_day()
	var rev_yes = IndustrySystem.firm_summary(f3).rev
	_chk("juan3_manager_more_revenue", rev_yes > rev_no, "%.0f vs %.0f" % [rev_yes, rev_no])
	_chk("juan3_needs_listed", IndustrySystem.firm_needs(f3).size() >= 1 and float(IndustrySystem.firm_needs(f3)[0].cost) >= 0.0)

func _juan3_history_save() -> void:
	var f = _juan3_firm()
	GameState.running = true
	for _i in 70:
		GameState.simulate_day()
	var mh: Array = f.get("month_hist", [])
	_chk("juan3_month_hist", mh.size() >= 2 and mh[0].has("rev") and mh[0].has("costs") and mh[0].has("profit"), "n=%d" % mh.size())
	f.month_hist = []
	for i in 30:
		f.month_acc = {"rev": float(i)}
		IndustrySystem.close_month(2024, 1)
	_chk("juan3_month_hist_cap24", (f.month_hist as Array).size() == 24 and float(f.month_hist[23].rev) == 29.0)
	IndustrySystem.hire_manager(str(f.id), {"name": "C", "skill": 0.5, "salary": 2000.0})
	f.pos = [700.5, 150.25]
	SaveSystem.save_slot(3)
	_new()
	var err = SaveSystem.load_slot(3)
	var g: Dictionary = GameState.player_firms()[0] if GameState.player_firms().size() > 0 else {}
	_chk("juan3_save_hist_manager_pos", err == "" and (g.get("month_hist", []) as Array).size() == 24 and str(g.get("manager", {}).get("name", "")) == "C" and IndustrySystem.firm_pos(g) == Vector2(700.5, 150.25), err)
	# stary save bez novych klucov
	var d = GameState.to_dict()
	for fr in d.firms:
		fr.erase("month_hist"); fr.erase("manager"); fr.erase("workers"); fr.erase("pos"); fr.erase("month_acc")
	_chk("juan3_old_save_loads", GameState.from_dict(d) == "")
	var old: Dictionary = GameState.player_firms()[0]
	GameState.running = true
	for _i in 35:
		GameState.simulate_day()
	_chk("juan3_old_save_runs", (old.get("month_hist", []) as Array).size() >= 1 and IndustrySystem.firm_pos(old) == null)

func _juan3_placement() -> void:
	_new()
	GameState.player.cash = 2000000.0
	var r1 = IndustrySystem.place_at("SK", "cafe", Vector2(787.9, 167.2))
	var f = GameState.firm_by_id(str(r1.id))
	_chk("juan3_place_cafe_pos", bool(r1.ok) and str(f.industry) == "cafe" and IndustrySystem.firm_pos(f) == Vector2(787.9, 167.2))
	var r2 = IndustrySystem.place_at("SK", "office", Vector2(788.2, 167.4))
	_chk("juan3_place_office", bool(r2.ok) and str(GameState.firm_by_id(str(r2.id)).industry) == "finance_office")
	var r3 = IndustrySystem.place_at("SK", "bank", Vector2(788.5, 167.0))
	var b = BankingSystem._player_bank()
	_chk("juan3_place_bank_pos", bool(r3.ok) and typeof(b.get("pos", null)) == TYPE_ARRAY and is_equal_approx(float(b.pos[0]), 788.5))
	GameState.player.cash = 10.0
	var r4 = IndustrySystem.place_at("SK", "cafe", Vector2(1, 1))
	_chk("juan3_place_no_money", not bool(r4.ok) and str(r4.reason) != "")
	_chk("juan3_place_bad_kind", not bool(IndustrySystem.place_at("SK", "xyz", Vector2.ZERO).ok))
