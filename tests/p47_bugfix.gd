extends RefCounted
# P47 bugfixy z auditu 13.11.2026 (V1–V5). Spusta sa z tests/unit.gd (-- unit).
var u

func run(host) -> void:
	u = host
	_v1_savings_first()
	_v1_one_miss_no_seize()
	_v1_three_miss_seize()
	_v1_one_firm_per_month()
	_v2_credits()
	_v3_paid_missed_rating()
	_v4_failed_lender()
	_b01_load_keeps_slot()
	_b17_ui_bond_ex()
	_b04_debt_bonds()

func _firm(id: String, industry: String, cash: float = 0.0) -> Dictionary:
	var f = {"id": id, "name": id, "owner": "player", "country": str(GameState.player.home), "industry": industry,
		"cash": cash, "closed": false, "history": [], "facilities": []}
	GameState.firms.append(f)
	return f

func _setup_loan(amount: float = 30000.0) -> Dictionary:
	u._new()
	GameState.player.loans.clear()
	var r = BankingSystem._make_loan(amount, 5, 0.0)
	if not bool(r.get("ok", false)):
		return {}
	GameState.player.cash = 0.0
	GameState.player.bankrupt = false
	return GameState.player.loans[GameState.player.loans.size() - 1]

func _v1_savings_first() -> void:
	var loan = _setup_loan()
	u._chk("p47_v1_setup", not loan.is_empty())
	if loan.is_empty():
		return
	var f = _firm("v1_mill", "steel_mill")
	GameState.player.savings = {"balance": 1000000.0}
	var rem0 = float(loan.remaining)
	BankingSystem.process_monthly_interest()
	u._chk("p47_v1_savings_pays", int(loan.missed) == 0 and float(loan.remaining) < rem0 and not bool(f.closed),
		"missed=%d rem=%.0f closed=%s" % [int(loan.missed), float(loan.remaining), str(f.closed)])
	u._chk("p47_v1_savings_debited", float(GameState.player.savings.balance) < 1000000.0, "%.2f" % float(GameState.player.savings.balance))
	GameState.player.erase("savings")

func _v1_one_miss_no_seize() -> void:
	var loan = _setup_loan()
	if loan.is_empty():
		return
	var f = _firm("v1_mill2", "steel_mill")
	BankingSystem.process_monthly_interest()
	u._chk("p47_v1_one_miss_no_seize", int(loan.missed) == 1 and not bool(f.closed) and not bool(GameState.player.get("bankrupt", false)),
		"missed=%d closed=%s" % [int(loan.missed), str(f.closed)])
	BankingSystem.process_monthly_interest()
	u._chk("p47_v1_two_miss_no_seize", int(loan.missed) == 2 and not bool(f.closed))

func _v1_three_miss_seize() -> void:
	var loan = _setup_loan()
	if loan.is_empty():
		return
	var f = _firm("v1_mill3", "steel_mill", 500.0)
	var lender = BankingSystem._bank(str(loan.lender))
	BankingSystem.process_monthly_interest()
	BankingSystem.process_monthly_interest()
	var rem_before = float(loan.remaining)
	var res_before = float(lender.reserves)
	var r = BankingSystem.check_bankruptcy()
	u._chk("p47_v1_two_no_seize_direct", not bool(r.get("seized", false)) and not bool(f.closed))
	BankingSystem.process_monthly_interest()
	u._chk("p47_v1_three_miss_seize", bool(f.closed) and float(loan.remaining) < rem_before - 0.01 and int(loan.missed) == 0,
		"closed=%s rem %.0f -> %.0f" % [str(f.closed), rem_before, float(loan.remaining)])
	u._chk("p47_v1_proceeds_to_lender", float(lender.reserves) > res_before + 0.01, "%.0f -> %.0f" % [res_before, float(lender.reserves)])

func _v1_one_firm_per_month() -> void:
	var a = _setup_loan(20000.0)
	if a.is_empty():
		return
	BankingSystem._make_loan(20000.0, 5, 0.0)
	GameState.player.cash = 0.0
	var b: Dictionary = GameState.player.loans[GameState.player.loans.size() - 1]
	var f1 = _firm("v1_f1", "steel_mill")
	var f2 = _firm("v1_f2", "steel_mill")
	a.missed = 2
	b.missed = 2
	BankingSystem.process_monthly_interest()
	var closed = int(bool(f1.closed)) + int(bool(f2.closed))
	u._chk("p47_v1_one_firm_per_month", closed == 1, "closed=%d" % closed)
	# zabezpeceny uver sa exekuciou nerobi (riesi collateral_monthly)
	var c = _setup_loan()
	if c.is_empty():
		return
	c.secured = true
	c.missed = 5
	var f3 = _firm("v1_f3", "steel_mill")
	var r = BankingSystem.check_bankruptcy()
	u._chk("p47_v1_secured_skip", not bool(r.get("seized", false)) and not bool(f3.closed))

func _v2_credits() -> void:
	var md = FileAccess.get_file_as_string("res://CREDITS.md")
	u._chk("p47_v2_credits_md_bunker", md.contains("aclarke064") and md.contains("CC BY-NC-SA 4.0") and md.contains("sketchfab.com/3d-models/star-wars-endor-bunker"))
	var MM = load("res://scripts/ui/main_menu.gd")
	var txt: String = MM.credits_bbcode()
	u._chk("p47_v2_credits_text", txt.contains("aclarke064") and txt.contains("CC BY-NC-SA 4.0") and txt.contains("Poly by Google") and txt.contains("CC-BY 3.0"))
	var menu = MM.new()
	var home_box: Control = menu._home()
	var btn = home_box.find_child("Credits", false, false)
	u._chk("p47_v2_menu_button", btn is Button and str(btn.text) == "Autori a licencie")
	var panel: Control = menu._credits()
	u._chk("p47_v2_credits_panel", menu.credits_text != null and str(menu.credits_text.text).contains("aclarke064"))
	panel.free()
	home_box.free()
	menu.free()
	var cfg = ConfigFile.new()
	var err = cfg.load("res://export_presets.cfg")
	var inc = str(cfg.get_value("preset.0", "include_filter", "")) if err == OK else ""
	u._chk("p47_v2_export_includes_credits", inc.split(",").has("CREDITS.md") and inc.split(",").has("assets/models/bunker/LICENSE.txt"), inc)

func _v3_paid_missed_rating() -> void:
	var loan = _setup_loan()
	if loan.is_empty():
		return
	GameState.player.cash = 100000.0
	loan.remaining = 0.0
	loan.missed = 0
	BankingSystem._refresh_rating()
	var clean = int(GameState.player.rating)
	loan.missed = 2
	BankingSystem._refresh_rating()
	u._chk("p47_v3_paid_loan_no_penalty", int(GameState.player.rating) == clean, "%d vs %d" % [int(GameState.player.rating), clean])
	loan.remaining = 10000.0
	BankingSystem._refresh_rating()
	u._chk("p47_v3_active_loan_still_penalized", int(GameState.player.rating) < clean, "%d vs %d" % [int(GameState.player.rating), clean])

func _v4_failed_lender() -> void:
	var loan = _setup_loan()
	if loan.is_empty():
		return
	var old = BankingSystem._bank(str(loan.lender))
	old.failed = true
	var moved = BankingSystem.transfer_failed_loans(old)
	var nb = BankingSystem._bank(str(loan.lender))
	u._chk("p47_v4_loan_transferred", moved == 1 and str(nb.get("id", "")) != str(old.id) and not bool(nb.get("failed", false)), str(loan.lender))
	GameState.player.cash = 100000.0
	var old_res = float(old.reserves)
	var nb_res = float(nb.reserves)
	BankingSystem.process_monthly_interest()
	u._chk("p47_v4_failed_reserves_unchanged", absf(float(old.reserves) - old_res) < 0.001 and float(nb.reserves) > nb_res, "%.2f / %.2f" % [float(old.reserves) - old_res, float(nb.reserves) - nb_res])
	# krach bez prevzatia (lazy prevod v process_monthly_interest, ziadna zdrava banka)
	var loan2 = _setup_loan()
	if loan2.is_empty():
		return
	var dead = BankingSystem._bank(str(loan2.lender))
	var saved: Array = []
	for b in GameState.banks:
		saved.append(bool(b.get("failed", false)))
		b.failed = true
	GameState.player.cash = 100000.0
	var dead_res = float(dead.reserves)
	BankingSystem.process_monthly_interest()
	u._chk("p47_v4_no_lender_no_reserves", absf(float(dead.reserves) - dead_res) < 0.001 and str(loan2.lender) == str(dead.id) and bool(loan2.get("lender_failed", false)))
	for i in GameState.banks.size():
		GameState.banks[i].failed = saved[i]

class FakeHost:
	extends RefCounted
	var saved: Array = []
	var loaded: Array = []
	func save_game(slot: int) -> bool:
		saved.append(slot)
		return SaveSystem.save_slot(slot).ends_with(".json")
	func _on_menu_load(slot: int) -> void:
		loaded.append(slot)

func _live(popup, nm: String) -> Node:
	for c in popup.box.get_children():
		if str(c.name) == nm and not c.is_queued_for_deletion():
			return c
	return null

func _popup(host) -> Control:
	var p = load("res://scripts/ui/pause_popup.gd").new()
	p._ready()
	p.host = host
	return p

func _b01_load_keeps_slot() -> void:
	u._new()
	var path1 = SaveSystem.save_slot(1)
	SaveSystem.save_slot(2)
	var before = FileAccess.get_file_as_string(path1)
	GameState.player.cash = float(GameState.player.cash) + 12345.0  # neulozeny postup
	GameState.day_index += 3
	var host = FakeHost.new()
	var p = _popup(host)
	p._load_dlg()
	var l1 = _live(p, "LoadSlot1")
	u._chk("p47_b01_load_button", l1 != null and not l1.disabled)
	if l1 == null:
		p.free()
		return
	l1.pressed.emit()
	u._chk("p47_b01_no_save_over_loading_slot", _live(p, "ConfirmSave") == null)
	var yes = _live(p, "ConfirmYes")
	if yes:
		yes.pressed.emit()
	u._chk("p47_b01_slot1_preserved", host.loaded == [1] and host.saved.is_empty() and FileAccess.get_file_as_string(path1) == before, str(host.loaded))
	p.free()
	# nacitanie slotu 2: "Najprv ulozit (slot 1)" ostava (ulozi do 1, nie do 2)
	var host2 = FakeHost.new()
	var p2 = _popup(host2)
	p2._load_dlg()
	var l2 = _live(p2, "LoadSlot2")
	if l2:
		l2.pressed.emit()
	var cs = _live(p2, "ConfirmSave")
	u._chk("p47_b01_slot2_offers_save1", cs != null)
	if cs:
		cs.pressed.emit()
	u._chk("p47_b01_slot2_saves_slot1_loads_2", host2.saved == [1] and host2.loaded == [2], "%s %s" % [str(host2.saved), str(host2.loaded)])
	p2.free()

func _b17_issue(m, price: float) -> Dictionary:
	m.bond_price.value = price
	var c0 = float(GameState.player.cash)
	var o0 = BankingSystem.player_bond_outstanding()
	var n0 = GameState.player.bonds.size()
	m._on_issue_bond()
	return {"cash": float(GameState.player.cash) - c0, "out": BankingSystem.player_bond_outstanding() - o0, "n": GameState.player.bonds.size() - n0}

func _b17_ui_bond_ex() -> void:
	u._new()
	GameState.player.cash = 100000.0
	var m = load("res://scripts/main.gd").new()
	m.bond_price = SpinBox.new()
	m.bond_price.min_value = 1.0
	m.bond_price.max_value = 10000.0
	m.bond_qty = SpinBox.new()
	m.bond_qty.max_value = 1000.0
	m.bond_qty.value = 1.0
	for px in [1.0, 49.0, 151.0, 10000.0]:
		var r = _b17_issue(m, px)
		u._chk("p47_b17_price_band_reject_%d" % int(px), absf(float(r.cash)) < 0.001 and absf(float(r.out)) < 0.001 and int(r.n) == 0, str(r))
	var coupon = float(BankingSystem.bond_quote(1000.0, 0.0, 2.0).market_yield)
	for px2 in [50.0, 150.0]:
		var r2 = _b17_issue(m, px2)
		u._chk("p47_b17_band_ok_1to1_%d" % int(px2), int(r2.n) == 1 and absf(float(r2.out) - 1000.0) < 0.001 and absf(float(r2.cash) / float(r2.out) - 1.0) < 0.01, str(r2))
	var last: Dictionary = GameState.player.bonds[GameState.player.bonds.size() - 1]
	u._chk("p47_b17_ui_coupon_from_quote", absf(float(last.coupon) - coupon) < 1e-9 and absf(float(last.coupon) - 0.05) > 1e-6, str(last.get("coupon", -1)))
	# nad bond_limit(): odmietnutie, stav sa nezmeni
	GameState.player.bonds.append({"country": "SK", "face": BankingSystem.bond_limit(), "coupon": 0.0, "years_left": 1.0, "issuer": "player"})
	var r3 = _b17_issue(m, 100.0)
	u._chk("p47_b17_over_limit_reject", absf(float(r3.cash)) < 0.001 and absf(float(r3.out)) < 0.001 and int(r3.n) == 0, str(r3))
	GameState.player.bonds.pop_back()
	if m.feedback_label:
		m.feedback_label.visible = false

func _b04_debt_bonds() -> void:
	u._new()
	var d0 = GameState.debt()
	var nw0 = GameState.net_worth()
	BankingSystem.issue_bond(100000.0, 0.05, 2.0)
	u._chk("p47_b04_debt_includes_bonds", absf(GameState.debt() - d0 - 100000.0) < 0.01, "%.0f -> %.0f" % [d0, GameState.debt()])
	u._chk("p47_b04_net_worth_no_double", absf(GameState.net_worth() - nw0) < 0.01, "%.2f -> %.2f" % [nw0, GameState.net_worth()])

