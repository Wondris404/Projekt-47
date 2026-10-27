extends RefCounted

func run(u) -> void:
	u._new()
	GameState.player.cash = 5.0e6
	var err = BankingSystem.found_player_bank("Poradenská banka", "SK")
	u._chk("advisor_bank_created", err == "", err)
	if err != "":
		return
	var bank: Dictionary = BankingSystem._player_bank()
	u._chk("advisor_legacy_default", not bool(bank.get("advisor", {}).get("hired", false)))
	u._chk("advisor_hire", BankingSystem.hire_advisor(bank) == "" and bool(bank.advisor.hired))
	u._chk("advisor_no_duplicate", BankingSystem.hire_advisor(bank) != "")
	var cash_before = float(bank.reserves)
	var equity_before = float(bank.equity)
	var cost = BankingSystem._advisor_month(bank)
	u._chk("advisor_salary_paid_once", is_equal_approx(cost, BankingSystem.ADVISOR_SALARY) and is_equal_approx(float(bank.reserves), cash_before - cost) and is_equal_approx(float(bank.equity), equity_before - cost))
	u._chk("advisor_sets_reserves", float(bank.reserve_target) >= LawSystem.min_reserve("SK") and float(bank.reserve_target) >= 0.18)
	u._chk("advisor_rates_and_risk", float(bank.cons_rate) > float(bank.deposit_rate) and float(bank.strictness) >= 0.4 and not bank.advisor.log.is_empty())
	bank.cons_rate = 0.33
	BankingSystem.advisor_override(bank)
	BankingSystem._advisor_month(bank)
	u._chk("advisor_manual_override", is_equal_approx(float(bank.cons_rate), 0.33))
	GameState.day_index += 30
	BankingSystem._advisor_month(bank)
	u._chk("advisor_resumes", not is_equal_approx(float(bank.cons_rate), 0.33))
	var saved = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	var load_error = GameState.from_dict(saved)
	bank = BankingSystem._player_bank()
	u._chk("advisor_save_v3", load_error == "" and int(saved.v) == 3 and bool(bank.get("advisor", {}).get("hired", false)), load_error)
	u._chk("advisor_fire", BankingSystem.fire_advisor(bank) == "" and not bool(bank.advisor.hired))
	u._chk("advisor_no_salary_after_fire", BankingSystem._advisor_month(bank) == 0.0)
	bank.reserves = BankingSystem.ADVISOR_SALARY - 1.0
	u._chk("advisor_no_hire_without_salary", BankingSystem.hire_advisor(bank) != "")
	bank.reserves = BankingSystem.ADVISOR_SALARY * 2.0
	BankingSystem.hire_advisor(bank)
	bank.reserves = 0.0
	u._chk("advisor_unpaid_leaves", BankingSystem._advisor_month(bank) == 0.0 and not bool(bank.advisor.hired))
	var host = load("res://scripts/main.gd").new()
	u._chk("advisor_detail_log", host.bank_detail_text(bank).contains("BANKOVÝ PORADCA") and host.bank_detail_text(bank).contains("plat"))
	host.free()
	u._new()
	GameState.player.cash = 5.0e6
	BankingSystem.found_player_bank("Kapitálový test", "SK")
	bank = BankingSystem._player_bank()
	BankingSystem.hire_advisor(bank)
	BankingSystem._advisor_month(bank)
	bank.equity = 0.0
	bank.reserves = 1.0e6
	var consumer = BankingSystem.consumer_month(bank)
	var products = BankProducts.monthly(bank)
	u._chk("advisor_capital_stops_new_loans", float(consumer.new) == 0.0 and float(products.mort_new) == 0.0 and float(products.corp_new) == 0.0)
	bank.npc_loans = 0.0
	bank.equity = 0.0
	BankingSystem._tick_player_bank(bank)
	u._chk("advisor_capital_stops_daily_loans", float(bank.npc_loans) == 0.0)
	u._new()
	GameState.player.cash = 2.0e7
	BankingSystem.found_player_bank("Dlhodobý test", "SK")
	bank = BankingSystem._player_bank()
	BankingSystem.inject(1.0e7)
	BankingSystem.hire_advisor(bank)
	var equity_start = float(bank.equity)
	for i in 120:
		GameState.simulate_day()
	var history: Array = bank.get("month_hist", [])
	u._chk("advisor_calendar_months", history.size() >= 3 and not bank.get("advisor", {}).get("log", []).is_empty(), str(history.size()))
	u._chk("advisor_salary_in_chart", not history.is_empty() and float(history[-1].get("costs", 0.0)) >= BankingSystem.ADVISOR_SALARY)
	u._chk("advisor_viable_scenario", not bool(bank.get("failed", false)) and float(bank.equity) > equity_start, "equity %.2f -> %.2f" % [equity_start, float(bank.equity)])
