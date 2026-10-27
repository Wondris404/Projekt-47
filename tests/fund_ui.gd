extends RefCounted

func run(host: Node) -> void:
	host._on_menu_dev()
	await host.get_tree().process_frame
	GameState.player.cash = 1.0e8
	var err = GameState.found_firm("invest_fund", "Skúšobný fond", "SK")
	var errors: Array[String] = []
	if err != "":
		errors.append("cannot create fund: " + err)
	else:
		var f: Dictionary = GameState.player_firms()[-1]
		host.open_firm_detail(str(f.id))
		var target: SpinBox = host.firm_detail_panel.find_child("FundRealtyTarget", true, false)
		var summary: Label = host.firm_detail_panel.find_child("FundRealtySummary", true, false)
		if target == null or summary == null or not is_equal_approx(target.value, 30.0):
			errors.append("missing target or summary")
		else:
			target.value = 45.0
			if not is_equal_approx(float(Empire.fund_state(f).realty_target), 0.45) or not summary.text.contains("45 %"):
				errors.append("target did not update")
		var before = float(f.cash)
		var deposit: Button = host.firm_detail_panel.find_child("FundDeposit", true, false)
		deposit.pressed.emit()
		await host.get_tree().process_frame
		if not is_equal_approx(float(f.cash), before + 100000.0):
			errors.append("deposit did not reach the fund")
		var withdraw: Button = host.firm_detail_panel.find_child("FundWithdraw", true, false)
		withdraw.pressed.emit()
		await host.get_tree().process_frame
		if not is_equal_approx(float(f.cash), before):
			errors.append("withdrawal did not return capital")
		f.cash = 1.0e7
		Empire.fund_monthly(f)
		var owned: Array = Empire.st().buildings.filter(func(b): return str(b.get("fund_id", "")) == str(f.id))
		if owned.is_empty():
			errors.append("fund did not buy a building")
		else:
			var b: Dictionary = owned[0]
			if int(host.city_share("SK", str(b.city), 0, 0).buildings) != 1:
				errors.append("city ownership omitted fund building")
			if int(Empire.realty_rows("city").total.count) < 1:
				errors.append("portfolio omitted fund building")
		host._fill_firm_detail()
		await host.get_tree().process_frame
		await RenderingServer.frame_post_draw
		host.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/fund_ui.png"))
		host.close_firm_detail()
		host.toggle_empire()
		await host.get_tree().process_frame
		var view = host.empire_win.find_child("EmpireView", true, false)
		if view == null or not view.fund_l.text.contains("Budovy 1"):
			errors.append("fund overview omitted real estate")
	if errors.is_empty():
		print("P47_FUND_UI_OK target=1 deposit=1 withdraw=1 city=1 portfolio=1")
	else:
		for error in errors:
			print("P47_FUND_UI_FAIL ", error)
	host.get_tree().quit(0 if errors.is_empty() else 1)
