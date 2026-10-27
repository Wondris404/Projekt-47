extends RefCounted

func run(u) -> void:
	u._new()
	GameState.player.cash = 2.0e7
	BankingSystem.found_player_bank("Štátna banka", "SK")
	BankingSystem.inject(5.0e6)
	var bank: Dictionary = BankingSystem._player_bank()
	var country: Dictionary = GameState.world.SK
	var before_risk = SovereignLoans.risk("SK")
	var before_rate = SovereignLoans.suggested_rate("SK")
	var old_debt = float(country.debt_gdp)
	country.debt_gdp = 2.0
	u._chk("sovereign_debt_increases_risk", SovereignLoans.risk("SK") > before_risk and SovereignLoans.suggested_rate("SK") > before_rate)
	country.debt_gdp = old_debt
	var reserves = float(bank.reserves)
	var equity = float(bank.equity)
	var rate = SovereignLoans.suggested_rate("SK")
	var err = SovereignLoans.lend(bank, "SK", 120000.0, rate, 12)
	u._chk("sovereign_issue", err == "" and is_equal_approx(float(bank.reserves), reserves - 120000.0) and is_equal_approx(float(bank.equity), equity), err)
	u._chk("sovereign_records_debt", float(country.debt_gdp) > old_debt and is_equal_approx(SovereignLoans.outstanding(bank), 120000.0))
	u._chk("sovereign_counts_in_bank_capital", BankProducts.rwa(bank) >= 120000.0 and BankProducts.text(bank).contains("štátne úvery"))
	u._chk("sovereign_refuse_low_rate", SovereignLoans.lend(bank, "SK", 1000.0, 0.0, 12) != "")
	u._chk("sovereign_refuse_nan", SovereignLoans.lend(bank, "SK", NAN, rate, 12) != "")
	u._chk("sovereign_refuse_liquidity", SovereignLoans.lend(bank, "SK", 1.0e10, rate, 12) != "")
	u._chk("sovereign_refuse_bad_term", SovereignLoans.lend(bank, "SK", 1000.0, rate, 0) != "")
	var monthly = SovereignLoans.monthly(bank, 1.0)
	u._chk("sovereign_interest", is_equal_approx(float(monthly.interest), 120000.0 * rate / 12.0) and float(monthly.loss) == 0.0)
	u._chk("sovereign_amortizes", is_equal_approx(SovereignLoans.outstanding(bank), 110000.0) and float(country.debt_gdp) < old_debt + 120000.0 / (float(country.gdp_usd) / GameState.usd_per_eur))
	var state = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	var load_err = GameState.from_dict(state)
	bank = BankingSystem._player_bank()
	u._chk("sovereign_save_v3", load_err == "" and int(state.v) == 3 and is_equal_approx(SovereignLoans.outstanding(bank), 110000.0), load_err)
	var capital_before_default = float(bank.equity)
	var defaulted = SovereignLoans.monthly(bank, 0.0)
	u._chk("sovereign_default_loss", is_equal_approx(float(defaulted.loss), 55000.0) and is_equal_approx(float(bank.equity), capital_before_default - 55000.0) and SovereignLoans.outstanding(bank) == 0.0)
	bank.erase("sovereign_loans")
	u._chk("sovereign_old_save_empty", SovereignLoans.outstanding(bank) == 0.0)
	BankingSystem.hire_advisor(bank)
	bank.advisor.sovereign_enabled = true
	bank.advisor.sovereign_country = "SK"
	bank.advisor.sovereign_limit = 0.1
	bank.advisor.sovereign_max_risk = 1.0
	SovereignLoans.advisor_invest(bank)
	u._chk("sovereign_advisor_with_limit", SovereignLoans.outstanding(bank) >= 1000.0 and SovereignLoans.outstanding(bank) <= float(bank.equity) * 0.1 + 0.01)
	var amount = SovereignLoans.outstanding(bank)
	bank.advisor.sovereign_max_risk = 0.0
	SovereignLoans.advisor_invest(bank)
	u._chk("sovereign_advisor_risk_limit", is_equal_approx(SovereignLoans.outstanding(bank), amount))
	u._new()
	GameState.player.cash = 2.0e7
	BankingSystem.found_player_bank("Splátkový test", "SK")
	BankingSystem.inject(5.0e6)
	bank = BankingSystem._player_bank()
	country = GameState.world.SK
	old_debt = float(country.debt_gdp)
	reserves = float(bank.reserves)
	rate = SovereignLoans.suggested_rate("SK")
	SovereignLoans.lend(bank, "SK", 120000.0, rate, 12)
	var interest_sum = 0.0
	for i in 12:
		interest_sum += float(SovereignLoans.monthly(bank, 1.0).interest)
	u._chk("sovereign_full_repayment", SovereignLoans.outstanding(bank) == 0.0 and absf(float(country.debt_gdp) - old_debt) < 0.000000001)
	u._chk("sovereign_cash_conservation", absf(float(bank.reserves) - reserves - interest_sum) < 0.01)
	var high_stability = SovereignLoans.risk("SK")
	country.stability = 5.0
	u._chk("sovereign_instability_risk", SovereignLoans.risk("SK") > high_stability)
	u._new()
	GameState.player.cash = 2.0e7
	BankingSystem.found_player_bank("Kalendárny test", "SK")
	BankingSystem.inject(5.0e6)
	bank = BankingSystem._player_bank()
	rate = SovereignLoans.suggested_rate("SK")
	SovereignLoans.lend(bank, "SK", 120000.0, rate, 12)
	GameState.date = {"y": 2024, "m": 1, "d": 31}
	GameState.simulate_day()
	u._chk("sovereign_calendar_repayment", is_equal_approx(SovereignLoans.outstanding(bank), 110000.0), str(bank.get("sovereign_loans", [])))
	var history: Array = bank.get("month_hist", [])
	u._chk("sovereign_interest_in_chart", not history.is_empty() and float(history[-1].get("rev", 0.0)) >= 120000.0 * rate / 12.0)
	BankingSystem.hire_advisor(bank)
	bank.advisor.sovereign_enabled = true
	bank.advisor.sovereign_country = "SK"
	bank.advisor.sovereign_limit = 0.1
	bank.advisor.sovereign_max_risk = 1.0
	GameState.date = {"y": 2024, "m": 2, "d": 29}
	GameState.simulate_day()
	u._chk("sovereign_calendar_advisor", SovereignLoans.outstanding(bank) > 100000.0 and bank.sovereign_loans.size() > 1, str(bank.get("sovereign_loans", [])))
