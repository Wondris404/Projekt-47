extends RefCounted

func run(u) -> void:
	var j4 = load("res://tests/juan4.gd").new()
	j4.u = u
	j4._bank_products()
	var j9 = load("res://tests/juan9.gd").new()
	j9.u = u
	j9._banks()
	u._new()
	GameState.player.cash = 5.0e6
	BankingSystem.found_player_bank("Banka A", "SK")
	var first: Dictionary = BankingSystem._player_bank()
	BankingSystem.found_player_bank("Banka B", "SK")
	var active_id = str(GameState.player.bank_id)
	first.equity = -1.0e9
	BankingSystem._tick_player_bank(first)
	u._chk("bank_other_failure_preserves_active", first.failed and str(GameState.player.bank_id) == active_id)
	var b: Dictionary = BankingSystem._player_bank()
	BankProducts.ensure(b)
	b.savings = 10000.0
	b.reserves = 500000.0
	b.equity = 490000.0
	var delta_before = float(b.reserves) - float(b.savings) - float(b.equity)
	BankProducts.monthly(b)
	var loans = BankProducts.sum_p(b.mort_loans) + BankProducts.sum_p(b.corp_loans)
	var delta_after = float(b.reserves) + loans - float(b.savings) - float(b.equity)
	u._chk("bank_savings_balance", absf(delta_after - delta_before) < 0.01, "%f / %f" % [delta_before, delta_after])
	var fixed = BankProducts._book([{"p": 12000.0, "n": 12, "rate": 0.06}], 0.20, 0.0, b)
	u._chk("bank_existing_fixed_rate", is_equal_approx(float(fixed.interest), 60.0) and is_equal_approx(float(fixed.keep[0].rate), 0.06))
	var legacy = BankProducts._book([{"p": 12000.0, "n": 12}], 0.20, 0.0, b)
	u._chk("bank_legacy_rate_default", is_equal_approx(float(legacy.interest), 200.0) and is_equal_approx(float(legacy.keep[0].rate), 0.20))
	b.cons_rate = 0.20
	b.cons_loans = [{"p": 12000.0, "n": 12, "rate": 0.06}]
	b.reserves = 0.0
	var dr = BankingSystem.consumer_default_rate(b, 0.06)
	var stats = BankingSystem.consumer_month(b)
	u._chk("bank_consumer_fixed_rate", is_equal_approx(float(stats.interest), 12000.0 * (1.0 - dr) * 0.06 / 12.0))
	u._chk("bank_consumer_rate_preserved", is_equal_approx(float(b.cons_loans[0].rate), 0.06))
	u._chk("bank_consumer_risk_uses_contract", BankingSystem.consumer_default_rate(b, 0.06) < BankingSystem.consumer_default_rate(b, 0.20))
	var mortgage = BankProducts._book([{"p": 12000.0, "n": 12, "rate": 0.03}], 0.20, BankProducts.mort_default(b), b, "mortgage")
	u._chk("bank_mortgage_risk_uses_contract", is_equal_approx(float(mortgage.loss), 12000.0 * BankProducts.mort_default(b, 0.03)))
	var corporate = BankProducts._book([{"p": 12000.0, "n": 12, "rate": 0.05}], 0.20, BankProducts.corp_default(b), b, "corporate")
	u._chk("bank_corporate_risk_uses_contract", is_equal_approx(float(corporate.loss), 12000.0 * BankProducts.corp_default(b, 0.05)))
	var state = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	var load_error = GameState.from_dict(state)
	u._chk("bank_loan_rate_save_v3", load_error == "" and int(state.v) == 3 and is_equal_approx(float(BankingSystem._player_bank().cons_loans[0].rate), 0.06), load_error)
	var exposure = {"equity": 80000.0, "npc_loans": 1000000.0, "explicit": 500000.0}
	u._chk("bank_capital_counts_all_loans", is_equal_approx(BankProducts.rwa(exposure), 1500000.0) and not BankProducts.can_lend(exposure))
	var bank: Dictionary = BankingSystem._player_bank()
	bank.equity = 100.0
	bank.reserves = 1.0e6
	bank.npc_loans = 10000.0
	bank.cons_loans = []
	bank.mort_loans = []
	bank.corp_loans = []
	var consumer = BankingSystem.consumer_month(bank)
	var products = BankProducts.monthly(bank)
	var before_daily = float(bank.npc_loans)
	BankingSystem._tick_player_bank(bank)
	u._chk("bank_capital_limit_without_advisor", float(consumer.new) == 0.0 and float(products.mort_new) == 0.0 and float(products.corp_new) == 0.0 and float(bank.npc_loans) <= before_daily)
