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
