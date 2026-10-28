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
	var sc: ScrollContainer = host.firm_detail_panel.find_children("*", "ScrollContainer", true, false)[0]
	for i in 3:
		await host.get_tree().process_frame
	sc.ensure_control_visible(host._bank_cons)
	for i in 3:
		await host.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var args = OS.get_cmdline_user_args()
	if args.size() > 1:
		var shot_dir = "res://audit/screenshots/bank-audit"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(shot_dir))
		host.get_viewport().get_texture().get_image().save_png(shot_dir.path_join("bank_%s.png" % str(args[1]).validate_filename()))
	var clean_ok = is_equal_approx(host._bank_cons.value, 20.0) and is_equal_approx(host._bank_mort.value, 17.5)
	host._bank_sav.value = 12.5
	bank.cons_rate = 0.22
	host._fill_bank_detail()
	var dirty_ok = is_equal_approx(host._bank_sav.value, 12.5)
	host._on_bank_apply()
	var apply_ok = is_equal_approx(float(bank.cons_rate), 0.22) and is_equal_approx(float(bank.mort_rate), 0.175) and is_equal_approx(float(bank.sav_rate), 0.125)
	bank.sav_rate = 0.1273
	bank.deposit_rate = 0.1273
	host._fill_bank_detail()
	host._bank_cons.value = 23.0
	host._on_bank_apply()
	var precision_ok = is_equal_approx(float(bank.sav_rate), 0.1273)
	var hired = BankingSystem.hire_advisor(bank)
	BankingSystem._advisor_month(bank)
	host._fill_bank_detail()
	var advisor_ok = hired == "" and absf(host._bank_cons.value - BankingSystem.consumer_rate(bank) * 100.0) <= 0.251 and absf(host._bank_sav.value - float(bank.sav_rate) * 100.0) <= 0.126
	var line: LineEdit = host._bank_cons.get_line_edit()
	line.grab_focus()
	await host.get_tree().process_frame
	line.text = "19"
	bank.cons_rate = 0.24
	host._fill_bank_detail()
	var typing_ok = line.has_focus() and line.text == "19"
	line.release_focus()
	for row in [["clean_refresh", clean_ok], ["preserve_edit", dirty_ok], ["apply_current", apply_ok], ["preserve_precision", precision_ok], ["advisor_refresh", advisor_ok], ["preserve_typing", typing_ok]]:
		print("P47_BANK_%s %s" % ["OK" if row[1] else "FAIL", row[0]])
	host.get_tree().quit(0 if clean_ok and dirty_ok and apply_ok and precision_ok and advisor_ok and typing_ok else 1)
