extends RefCounted

func run(u) -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 2.0e8
	var err = GameState.found_firm("invest_fund", "Testovací fond", "SK")
	u._chk("fund_realty_create", err == "", err)
	if err != "":
		return
	var fund: Dictionary = GameState.player_firms()[-1]
	var fund_id = str(fund.id)
	var description = preload("res://scripts/business_descriptions.gd").describe("invest_fund")
	u._chk("fund_realty_description", description.contains("nehnuteľnosti") and description.contains("nájom"))
	fund["fund"] = {"own": {}, "log": []}  # stary save bez ciela
	var initial = Empire.fund_realty(fund)
	u._chk("fund_realty_old_default", is_equal_approx(float(initial.target), 0.30))
	Empire.fund_state(fund)["realty_target"] = NAN
	u._chk("fund_realty_invalid_target", is_equal_approx(float(Empire.fund_realty(fund).target), 0.30))
	Empire.fund_state(fund)["realty_target"] = 5.0
	u._chk("fund_realty_target_bounds", is_equal_approx(float(Empire.fund_realty(fund).target), 1.0))
	Empire.fund_state(fund)["realty_target"] = 0.0
	fund.cash = 1.0e7
	var player_cash = float(GameState.player.cash)
	Empire.fund_monthly(fund)
	u._chk("fund_realty_zero_target", int(Empire.fund_realty(fund).count) == 0 and float(GameState.player.cash) == player_cash)
	Empire.fund_state(fund)["realty_target"] = 0.30
	var capital_before = float(Empire.fund_realty(fund).capital)
	Empire.fund_monthly(fund)
	var after = Empire.fund_realty(fund)
	var buildings: Array = Empire.st().buildings.filter(func(b): return str(b.get("fund_id", "")) == fund_id)
	u._chk("fund_realty_purchases", buildings.size() == 1 and int(after.count) == 1, str(after))
	if not buildings.is_empty():
		var b: Dictionary = buildings[0]
		u._chk("fund_realty_local_city", str(b.iso) == "SK" and not TerrainSystem.city_named("SK", str(b.city)).is_empty())
		u._chk("fund_realty_city_and_portfolio", Empire.buildings_in("SK", str(b.city)).has(b) and int(Empire.realty_rows("city").total.count) >= 1)
		u._chk("fund_realty_positive_rent", float(b.rent) > 0.0)
	u._chk("fund_realty_no_free_money", absf(float(after.capital) - capital_before) < 0.1 and float(GameState.player.cash) == player_cash, "%s -> %s" % [capital_before, after.capital])
	var remaining_cash = float(fund.cash)
	fund.cash = 0.0
	var count_before = int(after.count)
	Empire.fund_monthly(fund)
	u._chk("fund_realty_no_unfunded_purchase", int(Empire.fund_realty(fund).count) == count_before and float(fund.cash) >= 0.0)
	fund.cash = remaining_cash
	Empire.fund_state(fund)["realty_target"] = 1.0
	Empire.fund_monthly(fund)
	Empire.fund_monthly(fund)
	var later = Empire.fund_realty(fund)
	u._chk("fund_realty_gradual", int(later.count) >= 2 and int(later.count) <= 3, str(later))
	var city_names: Array = Empire.st().buildings.filter(func(b): return str(b.get("fund_id", "")) == fund_id).map(func(b): return str(b.city))
	var unique_cities := {}
	for city in city_names:
		unique_cities[city] = true
	u._chk("fund_realty_multiple_cities", unique_cities.size() >= 2, str(city_names))
	var fund_cash = float(fund.cash)
	var player_before = float(GameState.player.cash)
	var expected_rent = float(later.rent)
	Empire.st().buildings.append({"iso": "SK", "city": "Bratislava", "price": 100000.0, "rent": 999.0, "day": 0})
	Empire._pay_building_rents()
	u._chk("fund_realty_rent_once", is_equal_approx(float(fund.cash), fund_cash + expected_rent) and is_equal_approx(float(GameState.player.cash), player_before + 999.0))
	var before_deposit = float(fund.cash)
	var before_player = float(GameState.player.cash)
	u._chk("fund_deposit", Empire.fund_deposit(fund, 100000.0) == "" and float(fund.cash) == before_deposit + 100000.0 and float(GameState.player.cash) == before_player - 100000.0)
	u._chk("fund_withdraw", Empire.fund_withdraw(fund, 100000.0) == "" and float(fund.cash) == before_deposit and float(GameState.player.cash) == before_player)
	u._chk("fund_no_invalid_money", Empire.fund_deposit(fund, NAN) != "" and Empire.fund_withdraw(fund, INF) != "")
	u._chk("fund_no_overdraw", Empire.fund_withdraw(fund, float(fund.cash) + 1.0) != "" and Empire.fund_deposit(fund, float(GameState.player.cash) + 1.0) != "")
	var state = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	var load_error = GameState.from_dict(state)
	var restored = GameState.firm_by_id(fund_id)
	u._chk("fund_realty_save_v3", load_error == "" and int(state.v) == 3 and int(Empire.fund_realty(restored).count) == int(later.count), load_error)
	var old_cash = float(restored.cash)
	var old_player = float(GameState.player.cash)
	restored.owner = "sold"
	restored.closed = true
	Empire._pay_building_rents()
	u._chk("fund_realty_closed_fund", float(restored.cash) == old_cash and is_equal_approx(float(GameState.player.cash), old_player + expected_rent + 999.0))
	# Kalendárna mesačná uzávierka musí investovať bez priamych volaní funkcie fondu.
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 2.0e8
	GameState.found_firm("invest_fund", "Mesačný fond", "SK")
	var monthly_fund: Dictionary = GameState.player_firms()[-1]
	monthly_fund.cash = 1.0e7
	monthly_fund.history = [{"day": -1, "profit": 1000.0, "cogs": 0.0, "wages": 0.0, "rent": 0.0, "tax": 0.0}]
	GameState.date = {"y": 2024, "m": 1, "d": 31}
	GameState.simulate_day()
	u._chk("fund_realty_calendar_month", int(Empire.fund_realty(monthly_fund).count) == 1 and float(monthly_fund.cash) > 0.0, str(Empire.fund_realty(monthly_fund)))
