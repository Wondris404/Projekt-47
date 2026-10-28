extends RefCounted
# Reprodukcia aktualizácie nastavení pri otvorenom detaile banky.
func run(host) -> void:
	host._on_menu_dev()
	for i in 3:
		await host.get_tree().process_frame
	var result: Dictionary = BankingSystem.create_bank(0.02, 0.08, 0.8)
	if not bool(result.get("ok", false)):
		print("P47_BANK_SETUP_FAIL ", result)
		host.get_tree().quit(1)
		return
	var bank: Dictionary = result.bank
	host.open_firm_detail(str(bank.id))
	for i in 3:
		await host.get_tree().process_frame
	# Vonkajšia zmena napodobňuje zmenu poradcu počas otvoreného panelu.
	bank.cons_rate = 0.20
	bank.mort_rate = 0.175
	host._fill_bank_detail()
	var clean_ok = is_equal_approx(host._bank_cons.value, 20.0) and is_equal_approx(host._bank_mort.value, 17.5)
	host._bank_sav.value = 12.5
	bank.cons_rate = 0.22
	host._fill_bank_detail()
	var dirty_ok = is_equal_approx(host._bank_sav.value, 12.5)
	host._on_bank_apply()
	var apply_ok = is_equal_approx(float(bank.cons_rate), 0.22) and is_equal_approx(float(bank.mort_rate), 0.175) and is_equal_approx(float(bank.sav_rate), 0.125)
	for row in [["clean_refresh", clean_ok], ["preserve_edit", dirty_ok], ["apply_current", apply_ok]]:
		print("P47_BANK_%s %s" % ["OK" if row[1] else "FAIL", row[0]])
	host.get_tree().quit(0 if clean_ok and dirty_ok and apply_ok else 1)
