extends RefCounted
# Dokoncenie banky: anuita bez chvosta, predcasne splatenie, jeden bankrot, sporenie, save v3.

func run(u) -> void:
	_annuity(u)
	_lender(u)
	_early(u)
	_miss(u)
	_miss_schedule(u)
	_savings(u)
	_savings_worth(u)
	_save(u)

func _annuity(u) -> void:
	u._new()
	GameState.player.cash = 5.0e6
	var res: Dictionary = BankingSystem.request_unsecured_loan(30000.0, 3)
	u._chk("bf_annuity_opened", bool(res.get("ok", false)), str(res))
	if not bool(res.get("ok", false)):
		return
	var loan: Dictionary = GameState.player.loans[GameState.player.loans.size() - 1]
	var lender = BankingSystem._bank(str(loan.get("lender", "")))
	u._chk("bf_lender_home", str(lender.get("country", "")) == str(GameState.player.get("home", "")) and str(lender.get("owner", "")) != "player", str(lender.get("id", "")))
	var months = int(loan.get("months_left", 0))
	GameState.player.cash = 5.0e6
	for i in months - 1:
		BankingSystem.process_monthly_interest()
	u._chk("bf_before_last", float(loan.remaining) > 1.0 and int(loan.months_left) == 1 and not bool(loan.get("paid", false)), "rem %s m %s" % [str(loan.remaining), str(loan.months_left)])
	BankingSystem.process_monthly_interest()
	u._chk("bf_annuity_cleared", float(loan.remaining) == 0.0 and int(loan.months_left) == 0 and bool(loan.get("paid", false)), "rem %s m %s paid %s" % [str(loan.remaining), str(loan.months_left), str(loan.get("paid", false))])
	u._chk("bf_unsecured_repaid_once", int(GameState.player.get("loans_repaid", 0)) == 1 and GameState.player.loans.has(loan))
	u._chk("bf_history_once", GameState.player.get("loans_history", []).size() == 1)

func _lender(u) -> void:
	u._new()
	var home = str(GameState.player.get("home", ""))
	var home_best = ""
	var home_res = -1.0
	var foreign: Dictionary = {}
	for b in GameState.banks:
		if bool(b.get("failed", false)) or str(b.get("owner", "")) == "player":
			continue
		if str(b.get("country", "")) == home and float(b.get("reserves", 0.0)) > home_res:
			home_res = float(b.get("reserves", 0.0))
			home_best = str(b.get("id", ""))
		elif foreign.is_empty() and str(b.get("country", "")) != home:
			foreign = b
	if not foreign.is_empty():
		foreign.reserves = home_res + 1.0e9
	GameState.player.cash = 1.0e6
	var home_loan: Dictionary = BankingSystem._make_loan(10000.0, 2, 0.0)
	var hid = ""
	if bool(home_loan.get("ok", false)):
		hid = str(GameState.player.loans[GameState.player.loans.size() - 1].get("lender", ""))
	u._chk("bf_lender_prefers_home", hid == home_best and hid != str(foreign.get("id", "")), hid)
	for b in GameState.banks:
		if str(b.get("country", "")) == home:
			b.reserves = 0.0
	var big = ""
	var big_res = -1.0
	for b2 in GameState.banks:
		if bool(b2.get("failed", false)) or str(b2.get("owner", "")) == "player":
			continue
		if float(b2.get("reserves", 0.0)) > big_res:
			big_res = float(b2.get("reserves", 0.0))
			big = str(b2.get("id", ""))
	var far: Dictionary = BankingSystem._make_loan(10000.0, 2, 0.0)
	var fid = ""
	if bool(far.get("ok", false)):
		fid = str(GameState.player.loans[GameState.player.loans.size() - 1].get("lender", ""))
	u._chk("bf_lender_largest_reserves", fid == big and fid != "", "%s vs %s" % [fid, big])

func _early(u) -> void:
	u._new()
	GameState.player.cash = 5.0e6
	var lim0 = BankingSystem.loan_limit()
	var res: Dictionary = BankingSystem.request_unsecured_loan(20000.0, 5)
	u._chk("bf_early_opened", bool(res.get("ok", false)), str(res))
	if not bool(res.get("ok", false)):
		return
	var loan: Dictionary = GameState.player.loans[GameState.player.loans.size() - 1]
	var bank = BankingSystem._bank(str(loan.get("lender", "")))
	var old_pay = float(loan.monthly_payment)
	var cash0 = float(GameState.player.cash)
	var res0 = float(bank.reserves)
	var exp0 = float(bank.get("explicit", 0.0))
	var part: Dictionary = BankingSystem.repay_loan(str(loan.id), 5000.0)
	var expect = BankingSystem.annuity_payment(float(loan.remaining), float(loan.annual_rate), int(loan.months_left))
	u._chk("bf_partial", bool(part.get("ok", false)) and absf(float(loan.remaining) - 15000.0) < 0.02 and absf(float(loan.monthly_payment) - expect) < 0.02 and absf(float(loan.monthly_payment) - old_pay) > 1.0, str(part))
	u._chk("bf_partial_books", absf(float(GameState.player.cash) - (cash0 - 5000.0)) < 0.02 and absf(float(bank.reserves) - (res0 + 5000.0)) < 0.02 and absf(float(bank.explicit) - (exp0 - 5000.0)) < 0.02)
	u._chk("bf_partial_not_closed", not bool(loan.get("paid", false)) and int(GameState.player.get("loans_repaid", 0)) == 0)
	var full: Dictionary = BankingSystem.repay_loan(str(loan.id), 1.0e9)
	u._chk("bf_full", bool(full.get("ok", false)) and float(loan.remaining) == 0.0 and int(loan.months_left) == 0 and bool(loan.get("paid", false)))
	u._chk("bf_full_once", int(GameState.player.get("loans_repaid", 0)) == 1 and GameState.player.get("loans_history", []).size() == 1)
	var again: Dictionary = BankingSystem.repay_loan(str(loan.id), 100.0)
	u._chk("bf_full_no_double", not bool(again.get("ok", false)) and int(GameState.player.get("loans_repaid", 0)) == 1)
	u._chk("bf_limit_up", BankingSystem.loan_limit() > lim0 + 20000.0 and GameState.debt() <= 1.0, "%s -> %s" % [str(lim0), str(BankingSystem.loan_limit())])

func _miss(u) -> void:
	u._new()
	GameState.player.cash = 5.0e6
	var a: Dictionary = BankingSystem._make_loan(12000.0, 4, 0.0)
	var b: Dictionary = BankingSystem._make_loan(8000.0, 2, 0.0)
	u._chk("bf_two_loans", bool(a.get("ok", false)) and bool(b.get("ok", false)) and GameState.player.loans.size() >= 2, str(a) + str(b))
	if GameState.player.loans.size() < 2:
		return
	var l0: Dictionary = GameState.player.loans[GameState.player.loans.size() - 2]
	var l1: Dictionary = GameState.player.loans[GameState.player.loans.size() - 1]
	var r0 = float(l0.remaining)
	var r1 = float(l1.remaining)
	var m0 = int(l0.months_left)
	var m1 = int(l1.months_left)
	GameState.player.cash = 0.0
	var score0 = float(GameState.player.get("credit_score", 55.0))
	var bust0 = 0
	for ev in GameState.player.get("events", []):
		if str(ev.get("type", "")) == "bankruptcy":
			bust0 += 1
	BankingSystem.process_monthly_interest()
	var bust1 = 0
	for ev2 in GameState.player.get("events", []):
		if str(ev2.get("type", "")) == "bankruptcy":
			bust1 += 1
	var i0 = r0 * float(l0.annual_rate) / 12.0
	var i1 = r1 * float(l1.annual_rate) / 12.0
	u._chk("bf_miss_interest", absf(float(l0.remaining) - (r0 + i0)) < 0.05 and absf(float(l1.remaining) - (r1 + i1)) < 0.05, "%s %s" % [str(l0.remaining), str(l1.remaining)])
	u._chk("bf_miss_months", int(l0.months_left) == m0 and int(l1.months_left) == m1 and m0 >= 0 and m1 >= 0)
	u._chk("bf_one_bankruptcy", bust1 == bust0 + 1 and absf(float(GameState.player.credit_score) - (score0 - 15.0)) < 0.01, "events %d score %s" % [bust1 - bust0, str(GameState.player.credit_score)])

func _miss_schedule(u) -> void:
	u._new()
	GameState.player.cash = 5.0e6
	var opened: Dictionary = BankingSystem.request_unsecured_loan(20000.0, 5)
	u._chk("bf_miss_sched_open", bool(opened.get("ok", false)), str(opened))
	if not bool(opened.get("ok", false)):
		return
	var loan: Dictionary = GameState.player.loans[GameState.player.loans.size() - 1]
	GameState.player.cash = 0.0
	BankingSystem.process_monthly_interest()
	var expect = BankingSystem.annuity_payment(float(loan.remaining), float(loan.get("annual_rate", 0.0)), maxi(1, int(loan.get("months_left", 1))))
	u._chk("bf_miss_sched_recalc", absf(float(loan.monthly_payment) - expect) < 0.02, str(loan.monthly_payment))
	GameState.player.cash = 5.0e6
	var pays: Array = []
	var guard = 0
	while float(loan.get("remaining", 0.0)) > 1.0 and not bool(loan.get("paid", false)) and guard < 80:
		var before = float(GameState.player.cash)
		BankingSystem.process_monthly_interest()
		pays.append(before - float(GameState.player.cash))
		guard += 1
	var last = float(pays[pays.size() - 1]) if pays.size() > 0 else 0.0
	var peak = 0.0
	for i in maxi(0, pays.size() - 1):
		peak = maxf(peak, float(pays[i]))
	u._chk("bf_miss_sched_tail", pays.size() > 2 and last <= peak * 1.01 + 0.02, "last %.4f peak %.4f n %d" % [last, peak, pays.size()])

func _savings(u) -> void:
	u._new()
	GameState.player.cash = 80000.0
	var dep_before = {}
	var res_before = {}
	for b in GameState.banks:
		dep_before[str(b.id)] = float(b.get("deposits", 0.0))
		res_before[str(b.id)] = float(b.get("reserves", 0.0))
	var dep: Dictionary = BankingSystem.deposit(10000.0)
	var sav: Dictionary = GameState.player.get("savings", {})
	var bank = BankingSystem._bank(str(sav.get("bank_id", "")))
	u._chk("bf_deposit", bool(dep.get("ok", false)) and absf(float(sav.get("balance", 0.0)) - 10000.0) < 0.02 and absf(float(GameState.player.cash) - 70000.0) < 0.02, str(dep))
	u._chk("bf_deposit_bank", not bank.is_empty() and str(bank.get("owner", "")) != "player" and str(bank.get("country", "")) == "SK")
	if not bank.is_empty():
		var id = str(bank.id)
		u._chk("bf_deposit_books", absf(float(bank.deposits) - float(dep_before[id]) - 10000.0) < 0.02 and absf(float(bank.reserves) - float(res_before[id]) - 10000.0) < 0.02)
	var wd: Dictionary = BankingSystem.withdraw(4000.0)
	u._chk("bf_withdraw", bool(wd.get("ok", false)) and absf(float(GameState.player.savings.balance) - 6000.0) < 0.02 and absf(float(GameState.player.cash) - 74000.0) < 0.02, str(wd))
	if bank.is_empty():
		return
	GameState.central[str(bank.country)].base_rate = 0.03
	var bal = float(GameState.player.savings.balance)
	var dep0 = float(bank.deposits)
	var eq0 = float(bank.equity)
	var res1 = float(bank.reserves)
	BankingSystem.process_savings_interest()
	var expect = bal * 0.025 / 12.0
	u._chk("bf_interest", absf(float(GameState.player.savings.balance) - (bal + expect)) < 0.05 and absf(float(GameState.player.savings.rate) - 0.025) < 0.000001, str(GameState.player.savings))
	u._chk("bf_interest_books", absf(float(bank.deposits) - (dep0 + expect)) < 0.05 and absf(float(bank.equity) - (eq0 - expect)) < 0.05 and absf(float(bank.reserves) - res1) < 0.02)
	bank.reserves = 10.0
	var blocked: Dictionary = BankingSystem.withdraw(100.0)
	u._chk("bf_withdraw_reserves", not bool(blocked.get("ok", false)) and absf(float(GameState.player.savings.balance) - (bal + expect)) < 0.05, str(blocked))
	GameState.player.savings.balance = 150000.0
	bank.failed = true
	var cash0 = float(GameState.player.cash)
	BankingSystem.process_savings_interest()
	var covered = false
	for row in GameState.news:
		if str(row.get("text", "")).find("Garančný") >= 0 and str(row.get("text", "")).find("stratené") >= 0:
			covered = true
	u._chk("bf_guarantee", absf(float(GameState.player.cash) - (cash0 + 100000.0)) < 0.02 and float(GameState.player.savings.balance) == 0.0 and str(GameState.player.savings.bank_id) == "" and covered)

func _savings_worth(u) -> void:
	u._new()
	GameState.player.cash = 2.0e5
	var opened: Dictionary = BankingSystem.request_unsecured_loan(20000.0, 5)
	u._chk("bf_worth_loan", bool(opened.get("ok", false)), str(opened))
	if not bool(opened.get("ok", false)):
		return
	BankingSystem._refresh_rating()
	var worth0 = GameState.net_worth()
	var limit0 = BankingSystem.loan_limit()
	var rating0 = int(GameState.player.get("rating", 0))
	var score0 = float(GameState.player.get("credit_score", 0.0))
	var put: Dictionary = BankingSystem.deposit(10000.0)
	BankingSystem._refresh_rating()
	u._chk("bf_worth_same", bool(put.get("ok", false)) and absf(GameState.net_worth() - worth0) < 0.01, "nw %.4f -> %.4f" % [worth0, GameState.net_worth()])
	u._chk("bf_worth_limit", absf(BankingSystem.loan_limit() - limit0) < 0.01, "lim %.4f -> %.4f" % [limit0, BankingSystem.loan_limit()])
	u._chk("bf_worth_score", int(GameState.player.get("rating", 0)) == rating0 and absf(float(GameState.player.get("credit_score", 0.0)) - score0) < 0.01)

func _save(u) -> void:
	u._new()
	GameState.player.cash = 2.0e5
	var opened: Dictionary = BankingSystem.request_unsecured_loan(15000.0, 3)
	var deposited: Dictionary = BankingSystem.deposit(8000.0)
	u._chk("bf_save_setup", bool(opened.get("ok", false)) and bool(deposited.get("ok", false)), str(opened) + str(deposited))
	if not bool(opened.get("ok", false)):
		return
	var loan: Dictionary = GameState.player.loans[GameState.player.loans.size() - 1]
	BankingSystem.repay_loan(str(loan.id), 1000.0)
	var rem = float(loan.remaining)
	var pay = float(loan.monthly_payment)
	var rate = float(loan.annual_rate)
	var bal = float(GameState.player.savings.balance)
	var srate = float(GameState.player.savings.rate)
	var bid = str(GameState.player.savings.bank_id)
	var repaid = int(GameState.player.get("loans_repaid", 0))
	var state = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	u._chk("bf_save_v3", int(state.get("v", 0)) == 3 and GameState.SAVE_VERSION == 3)
	var err = GameState.from_dict(state)
	var back: Dictionary = {}
	for l in GameState.player.loans:
		if str(l.get("id", "")) == str(loan.id):
			back = l
	u._chk("bf_roundtrip", err == "" and absf(float(back.get("remaining", -1)) - rem) < 0.02 and absf(float(back.get("monthly_payment", -1)) - pay) < 0.02 and absf(float(back.get("annual_rate", -1)) - rate) < 0.000001 and absf(float(GameState.player.savings.balance) - bal) < 0.02 and absf(float(GameState.player.savings.rate) - srate) < 0.000001 and str(GameState.player.savings.bank_id) == bid and int(GameState.player.get("loans_repaid", 0)) == repaid, err)
	var old = JSON.parse_string(JSON.stringify(state))
	old.player.erase("savings")
	old.player.erase("loans_history")
	old.player.erase("loans_repaid")
	for ln in old.player.loans:
		ln.erase("paid")
	u._chk("bf_old_valid", GameState.validate_save(old) == "")
	var err_old = GameState.from_dict(old)
	u._chk("bf_old_v3", err_old == "" and float(GameState.player.get("savings", {}).get("balance", -1)) == 0.0, err_old)
	var bad = JSON.parse_string(JSON.stringify(state))
	bad.player.savings.balance = "x"
	var before = JSON.stringify(GameState.to_dict())
	u._chk("bf_bad_balance", GameState.validate_save(bad) != "" and GameState.from_dict(bad) != "" and JSON.stringify(GameState.to_dict()) == before)
	GameState.player.cash = 1.0e6
	BankingSystem.process_monthly_interest()
	BankingSystem.process_savings_interest()
	u._chk("bf_old_runs", GameState.running and float(GameState.player.savings.balance) == 0.0)
