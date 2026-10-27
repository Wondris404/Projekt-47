Warning: truncated output (original token count: 46049)
Total output lines: 4632

extends Control

const WorldMapScript = preload("res://scripts/ui/world_map.gd")
const BusinessDescriptions = preload("res://scripts/business_descriptions.gd")
const GoodsIcons = preload("res://scripts/ui/goods_icons.gd")
var map
var info: Label
var play = false
var acc = 0.0
var exit_code = 0
var _description_test_runner
var _toolbar_test_runner
var _atlas_test_runner
var _fund_test_runner
var _atlas_visual_runner

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if _headless():
		map = WorldMapScript.new()
		add_child(map)
		var args = OS.get_cmdline_user_args()
		if args.size() > 0 and str(args[0]) == "stability":
			var days: Array = [1, 30, 365]
			var home_iso = "SK"
			if args.size() > 1:
				days = []
				for a in args.slice(1):
					if str(a).begins_with("home="):
						home_iso = str(a).substr(5)
					else:
						days.append(int(a))
			exit_code = load("res://tests/stability.gd").new().run(days, home_iso)
		elif args.size() > 0 and str(args[0]) == "unit":
			exit_code = load("res://tests/unit.gd").new().run()
		elif args.size() > 0 and str(args[0]) == "audit_unit":
			var unit = load("res://tests/unit.gd").new()
			load("res://tests/audit_regressions.gd").new().run(unit)
			exit_code = 1 if unit.fails > 0 else 0
		elif args.size() > 0 and str(args[0]) == "fund_unit":
			var unit = load("res://tests/unit.gd").new()
			load("res://tests/fund_realty.gd").new().run(unit)
			exit_code = 1 if unit.fails > 0 else 0
		elif args.size() > 0 and str(args[0]) == "flow_unit":
			var unit = load("res://tests/unit.gd").new()
			load("res://tests/goods_flow.gd").new().run(unit)
			exit_code = 1 if unit.fails > 0 else 0
		elif args.size() > 0 and str(args[0]) == "goods_icons_unit":
			var unit = load("res://tests/unit.gd").new()
			load("res://tests/goods_icons_test.gd").new().run(unit)
			exit_code = 1 if unit.fails > 0 else 0
		elif args.size() > 0 and str(args[0]) == "bank_audit_unit":
			var unit = load("res://tests/unit.gd").new()
			load("res://tests/bank_audit.gd").new().run(unit)
			exit_code = 1 if unit.fails > 0 else 0
		elif args.size() > 0 and str(args[0]) == "bank_advisor_unit":
			var unit = load("res://tests/unit.gd").new()
			load("res://tests/bank_advisor.gd").new().run(unit)
			exit_code = 1 if unit.fails > 0 else 0
		elif args.size() > 0 and str(args[0]) == "sovereign_unit":
			var unit = load("res://tests/unit.gd").new()
			load("res://tests/sovereign.gd").new().run(unit)
			exit_code = 1 if unit.fails > 0 else 0
		elif args.size() > 0 and str(args[0]) == "employment_stats_unit":
			var unit = load("res://tests/unit.gd").new()
			load("res://tests/employment_stats.gd").new().run(unit)
			exit_code = 1 if unit.fails > 0 else 0
		elif args.size() > 0 and str(args[0]) == "society_unit":  # JUAN-P47
			var unit = load("res://tests/unit.gd").new()
			load("res://tests/society.gd").new().run(unit)
			exit_code = 1 if unit.fails > 0 else 0
		elif args.size() > 0 and str(args[0]) == "local_comp_unit":
			var unit = load("res://tests/unit.gd").new()
			load("res://tests/local_comp.gd").new().run(unit)
			exit_code = 1 if unit.fails > 0 else 0
		elif args.size() > 0 and str(args[0]) == "performance_audit":
			load("res://tests/performance_audit.gd").new().run()
		elif args.size() > 0 and str(args[0]) == "profile_sim":
			load("res://tests/profile_sim.gd").new().run()
		elif args.size() > 0 and str(args[0]) == "phase_routes_unit":
			var unit = load("res://tests/unit.gd").new()
			load("res://tests/phase_routes.gd").new().run(unit)
			exit_code = 1 if unit.fails > 0 else 0
		elif args.size() > 0 and str(args[0]) == "bench":
			GameState.new_game({"country": "SK", "seed": 47, "wars": false, "loan": 0.0})
			var t0 = Time.get_ticks_msec()
			for i in 30:
				GameState.simulate_day()
			print("P47_BENCH countries=%d ms_per_day=%.1f" % [DataLoader.country_ids.size(), (Time.get_ticks_msec() - t0) / 30.0])
		elif args.size() > 0 and str(args[0]) == "bench_flow":
			for enabled in [false, true]:
				GameState.new_game({"country": "SK", "seed": 47, "wars": false, "loan": 0.0})
				IndustrySystem.record_goods_flow = enabled
				var started = Time.get_ticks_usec()
				for i in 30:
					GameState.simulate_day()
				print("P47_BENCH_FLOW enabled=%d ms_per_day=%.2f" % [int(enabled), (Time.get_ticks_usec() - started) / 30000.0])
			IndustrySystem.record_goods_flow = true
		elif args.size() > 0 and str(args[0]) == "bench_distance":
			GameState.new_game({"country": "SK", "seed": 47, "wars": false, "loan": 0.0})
			MarketSystem._distance_cache.wait_for_completion()
			var ids = DataLoader.country_ids
			var sum = 0.0
			var started = Time.get_ticks_usec()
			for i in 20000:
				var a: Dictionary = DataLoader.countries[ids[i % ids.size()]]
				var b: Dictionary = DataLoader.countries[ids[(i * 7 + 1) % ids.size()]]
				sum += EconMath.haversine(float(a.get("lat", 0.0)), float(a.get("lon", 0.0)), float(b.get("lat", 0.0)), float(b.get("lon", 0.0)))
			var direct_us = Time.get_ticks_usec() - started
			started = Time.get_ticks_usec()
			for i in 20000:
				sum += MarketSystem._distance_cache.distance(str(ids[i % ids.size()]), str(ids[(i * 7 + 1) % ids.size()]), -1.0)
			print("P47_BENCH_DISTANCE direct_ms=%.2f cache_ms=%.2f sum=%.1f" % [direct_us / 1000.0, (Time.get_ticks_usec() - started) / 1000.0, sum])
		elif args.size() > 0 and str(args[0]) == "uitest":
			_uitest()
			return
		elif args.size() > 0 and str(args[0]) == "society_ui":  # JUAN-P47: GUI skuska novych panelov
			_society_ui()
			return
		else:
			exit_code = _probe()
		call_deferred("_quit_probe")
		return
	if OS.get_cmdline_user_args().size() > 0 and str(OS.get_cmdline_user_args()[0]) == "intropreview":
		_intro_preview()  # JUAN4: render nahladov intra (xvfb)
		return
	_build_play()

func _headless() -> bool:
	return OS.has_feature("headless") or DisplayServer.get_name() == "headless"

func _quit_probe() -> void:
	get_tree().quit(exit_code)

func _probe() -> int:
	return load("res://tests/probe.gd").new().run(self, map)

var cash_label: Label
var top_date: Label
var top_cash: Label
var market_label: Label
var bank_label: Label
var news_label: Label
var paper_label: Label
var climate_label: Label
var minister_label: Label
var minister_tax: SpinBox
var fps_label: Label
var _fps_show: bool = false
var _fps_acc: float = 0.0
var _soak: bool = false
var _soak_mark: int = -1
var law_label: Label
var book_label: Label
var diplo_label: Label
var diplo_target: OptionButton
var firm_label: Label
var my_firms_label: Label
var _menu_was_paused = true
var _menu_paused_game = false
var bond_price: SpinBox
var bond_qty: SpinBox
var stock_price: SpinBox
var stock_qty: SpinBox
var region_view
var build_menu
var _ui_scale: float = 1.0
var _view_redraws: int = 0
var feedback_label: Label
var feedback_left: float = 0.0
var feedback_count: int = 0
var hover_label: Label
var _hover_debug: bool = false

func industry_button_ids() -> Array:
	return IndustrySystem.industry_button_ids()

func research_button_ids() -> Array:
	return ["logistics2", "auto1", "agro1", "chem1", "arms1", "energy1", "score1"]

func apply_production_slider(value: float) -> float:
	return IndustrySystem.set_production(value)

func play_diplomacy(action: String, target: String) -> String:
	if not GameState.running:
		_on_start()
	var err = ""
	if action == "embargo":
		err = GeopoliticsSystem.impose_embargo(target)
	elif action == "lift_embargo":
		err = GeopoliticsSystem.lift_embargo(target)
	elif action == "alliance":
		err = GeopoliticsSystem.form_alliance(target)
	elif action == "break_alliance":
		err = GeopoliticsSystem.break_alliance(target)
	elif action == "treaty":
		err = GeopoliticsSystem.sign_treaty(target)
	elif action == "break_treaty":
		err = GeopoliticsSystem.break_treaty(target)
	elif action == "relief":
		err = GeopoliticsSystem.grant_relief(target)
	elif action == "revoke_relief":
		err = GeopoliticsSystem.revoke_relief(target)
	elif action == "war":
		# JUAN4: hrac je podnikatel, vojnu vyhlasit nemoze (vojny vedu AI staty, hrac moze len lobovat).
		if bool(GameState.config.get("dev_player_war", false)):
			err = GeopoliticsSystem.declare_war(target)
		else:
			err = "Ako podnikateľ nemôžeš vyhlásiť vojnu. Skús lobing v záložke Politika."
	elif action == "peace":
		err = GeopoliticsSystem.make_peace(target)
	elif action == "sanction":
		err = GeopoliticsSystem.impose_sanction(target)
	elif action == "un":
		err = GeopoliticsSystem.security_council(target)
	elif action == "lift_sanction":
		err = GeopoliticsSystem.lift_sanction(target)
	else:
		err = "Neznáma akcia."
	_refresh_label()
	return err

func diplomacy_text() -> String:
	var text = ""
	for row in GeopoliticsSystem.relation_rows():
		var flag_text = ""
		for flag in row.get("flags", []):
			flag_text += str(flag) + " "
		text += "%s (%s): vzťah %+d, clo %s %s\n" % [str(DataLoader.countries.get(str(row.get("iso", "")), {}).get("name_sk", "")), str(row.get("iso", "")), int(row.get("relation", 0)), EconMath.pct(float(row.get("tariff", 0.0))), flag_text]
	return text

func post_play_bond(side: String, price: float, qty: float = 1.0) -> Dictionary:
	if not GameState.running:
		_on_start()
	var res: Dictionary = BankingSystem.post_bond_order(side, price, qty)
	GameState.post_news("Kniha %s %.0f: filled %s, otvorené %s." % [side, price, str(res.get("filled", 0)), str(res.get("open", 0))])
	_refresh_label()
	return res

func post_play_stock(side: String, ticker: String, price: float, qty: float) -> Dictionary:
	if not GameState.running:
		_on_start()
	var res: Dictionary = BankingSystem.post_stock_order(side, ticker, price, qty)
	GameState.post_news("Akcie %s %s %.2f x %.0f." % [side, ticker, price, qty])
	_refresh_label()
	return res

func bond_book_text() -> String:
	var text = ""
	var rows: Array = BankingSystem.open_bond_orders()
	if rows.is_empty():
		text = "žiadny dlhopis\n"
	for row in rows:
		text += "dlhopis %s %.0f × %.0f\n" % [str(row.get("side", "")), float(row.get("price", 0.0)), float(row.get("qty", 0.0))]
	for row2 in BankingSystem.open_stock_orders():
		text += "akcia %s %s %.2f × %.0f\n" % [str(row2.get("side", "")), str(row2.get("ticker", "")), float(row2.get("price", 0.0)), float(row2.get("qty", 0.0))]
	if text == "":
		return "žiadny bid ani ask"
	return text

func _sprite_colors(path: String) -> int:
	var img = Image.new()
	if img.load(path) != OK:
		return 0
	var seen = {}
	var step_x = maxi(1, int(img.get_width() / 8))
	var step_y = maxi(1, int(img.get_height() / 8))
	var y = 0
	while y < img.get_height():
		var x = 0
		while x < img.get_width():
			var px = img.get_pixel(x, y)
			var key = "%d-%d-%d" % [int(px.r * 16.0), int(px.g * 16.0), int(px.b * 16.0)]
			seen[key] = true
			x += step_x
		y += step_y
	return seen.size()

var speed_bar
var side_tabs: TabContainer
var main_menu
var tutorial
var tutorial_saw_country: bool = false

func _tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll = ScrollContainer.new()
	scroll.name = title
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	scroll.follow_focus = false
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	tabs.add_child(scroll)
	tabs.set_tab_title(tabs.get_tab_count() - 1, title)
	return box

func _build_play() -> void:
	_apply_theme()
	_load_ui_scale()
	var bg = ColorRect.new()
	bg.color = UiPalette.BG_0
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(outer)
	var top_shell = PanelContainer.new()
	top_shell.custom_minimum_size = Vector2(0, 40)
	outer.add_child(top_shell)
	speed_bar = preload("res://scripts/ui/top_bar.gd").new()
	speed_bar.pause_pressed.connect(_on_pause)
	speed_bar.speed_pressed.connect(_set_speed)
	speed_bar.day_pressed.connect(_on_day)
	top_shell.add_child(speed_bar)
	top_date = speed_bar.date_label
	top_cash = speed_bar.cash_label
	get_window().title = "Projekt-47 — Wondris404"
	fps_label = Label.new()
	fps_label.visible = false
	fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fps_label.position = Vector2(12, 48)
	fps_label.z_index = 20
	add_child(fps_label)
	var split = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(split)
	var side_slot = Control.new()  # JUAN9: ovladaci panel je VLAVO (vlozi sa sem nizsie)
	split.add_child(side_slot)
	var map_shell = PanelContainer.new()
	map_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(map_shell)
	var map_col = VBoxContainer.new()
	map_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_shell.add_child(map_col)
	var map_title = Label.new()
	map_title.text = "Mapa"
	map_title.name = "StatStrip"  # JUAN10: HOI4 styl - osobne staty nad mapou
	stat_strip = map_title
	map_title.theme_type_variation = "HeaderLabel"
	map_col.add_child(map_title)
	map_shell.size_flags_stretch_ratio = 1.6
	map = WorldMapScript.new()
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_col.add_child(map)
	map.country_selected.connect(_on_country_picked)
	map.place_requested.connect(_on_place_requested)  # JUAN3
	map.hq_clicked.connect(open_portfolio_corp)  # JUAN15
	map.firm_clicked.connect(open_firm_detail)  # JUAN3
	map.country_firms.connect(open_country_firms)  # JUAN9
	map.city_clicked.connect(open_city_panel)  # JUAN9
	region_view = preload("res://scripts/ui/region_view.gd").new()
	region_view.visible = false
	region_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	region_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_col.add_child(region_view)
	var toolbar_shell = HBoxContainer.new()
	map_col.add_child(toolbar_shell)
	var scroll_left = Button.new()
	scroll_left.name = "ToolbarScrollLeft"
	scroll_left.text = "◀"
	scroll_left.tooltip_text = "Posunúť ovládací panel doľava."
	toolbar_shell.add_child(scroll_left)
	toolbar_scroll = ScrollContainer.new()
	toolbar_scroll.name = "MapToolbarScroll"
	toolbar_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	toolbar_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	toolbar_shell.add_child(toolbar_scroll)
	var scroll_right = Button.new()
	scroll_right.name = "ToolbarScrollRight"
	scroll_right.text = "▶"
	scroll_right.tooltip_text = "Posunúť ovládací panel doprava."
	toolbar_shell.add_child(scroll_right)
	scroll_left.pressed.connect(func(): toolbar_scroll.scroll_horizontal -= 220)
	scroll_right.pressed.connect(func(): toolbar_scroll.scroll_horizontal += 220)
	var zoom_row = HBoxContainer.new()
	toolbar_scroll.add_child(zoom_row)
	var zoom = Button.new()
	zoom.text = "Priblížiť / oddialiť"
	zoom.tooltip_text = "Ďaleko vidíš krajiny (jedna ikonka = tvoje firmy v krajine). Priblíž (koliesko) a uvidíš mestá a jednotlivé budovy."
	zoom.pressed.connect(_on_zoom)
	var burza_b = Button.new()  # JUAN9: burza ako okno nad mapou
	burza_b.text = "Burza"
	burza_b.name = "BurzaButton"
	burza_b.pressed.connect(toggle_burza)
	zoom_row.add_child(burza_b)
	var emp_b = Button.new()  # JUAN10
	emp_b.text = "Portfólio"
	emp_b.name = "EmpireButton"
	emp_b.tooltip_text = "Osobné štatistiky, kúpa štátu, charita, centrála korporácie a finančná divízia, fondy."
	emp_b.pressed.connect(toggle_empire)
	zoom_row.add_child(emp_b)
	var inf_b = Button.new()
	inf_b.text = "Infraštruktúra"
	inf_b.name = "InfraToggle"
	inf_b.toggle_mode = true
	inf_b.tooltip_text = "Diaľnice, letiská, prístavy a námorné trasy."
	inf_b.toggled.connect(func(on): map.infra = on; map.queue_redraw())
	zoom_row.add_child(inf_b)
	zoom_row.add_child(zoom)
	var terr_b = Button.new()  # JUAN4: prekrytie terenu a surovin
	terr_b.text = "Terén / suroviny"
	terr_b.name = "TerrainToggle"
	terr_b.toggle_mode = true
	terr_b.toggled.connect(_on_terrain_toggle)
	zoom_row.add_child(terr_b)
	var cust_b = Button.new()  # JUAN17: mapovy mod Odberatelia
	cust_b.text = "Odberatelia"
	cust_b.name = "CustomersMapToggle"
	cust_b.toggle_mode = true
	cust_b.tooltip_text = "Zafarbí krajiny podľa toho, koľko od teba kupujú (€/mesiac): zelená najviac, žltá stredne, červená nič."
	cust_b.toggled.connect(func(on): map.cust_mode = on; map._cust_day = -99; map.queue_redraw())
	zoom_row.add_child(cust_b)
	map_style_b = Button.new()  # zachovane pre stare diagnosticke scenare; v hre sa nezobrazuje
	map_style_b.name = "MapStyleToggle"
	map_style_b.visible = false
	zoom_row.add_child(map_style_b)
	for spec in [["rail", "Železnica", "Postav železnicu: klikni na začiatok a koniec. %s €/km. Napojené firmy (do ~17 km) majú dopravu tovaru o 60 %% lacnejšiu." % EconMath.eur(Transport.RAIL_KM)], ["pipe", "Ropovod / plynovod", "Postav potrubie: klikni na začiatok a koniec. %s €/km. Ropa, plyn a palivá pre napojené firmy o 85 %% lacnejšie." % EconMath.eur(Transport.PIPE_KM)]]:
		var lb = Button.new()  # JUAN19
		lb.text = str(spec[1])
		lb.name = "Build_" + str(spec[0])
		lb.tooltip_text = str(spec[2])
		var kind = str(spec[0])
		lb.pressed.connect(func():
			map.start_line(kind)
			_feedback("%s: klikni na mape na začiatok a potom na koniec trasy." % str(spec[1]), true))
		zoom_row.add_child(lb)
	map.line_requested.connect(_on_line_requested)
	region_view.city_picked.connect(open_city_panel)  # JUAN4
	var side_shell = PanelContainer.new()
	side_shell.custom_minimum_size = Vector2(300, 0)
	side_shell.size_flags_stretch_ratio = 1.0
	side_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.remove_child(side_slot)
	side_slot.free()
	split.add_child(side_shell)
	split.move_child(side_shell, 0)
	side_panel = side_shell  # JUAN12: zbalitelny ovladaci panel
	var pb = Button.new()
	pb.name = "PanelToggle"
	pb.text = "◀ Skryť panel"
	pb.tooltip_text = "Skryje/ukáže ovládací panel (Tab). Mapa sa roztiahne na celú šírku."
	pb.pressed.connect(toggle_side_panel)
	zoom_row.add_child(pb)
	zoom_row.move_child(pb, 0)
	panel_btn = pb
	zoom_lbl = Label.new()
	zoom_lbl.name = "ZoomLevel"
	zoom_row.add_child(zoom_lbl)
	var tabs = TabContainer.new()
	side_tabs = tabs
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_shell.add_child(tabs)
	tabs.tab_changed.connect(_reset_tab_scroll)
	var firm_tab = _tab(tabs, "Firma")
	var found_tab = _tab(tabs, "Založiť")
	var loans_tab = _tab(tabs, "Pôžičky")  # JUAN13: uvery + dlhopisy (namiesto starej zalozky Financie)
	var money_tab = VBoxContainer.new()  # stare Bid/Ask polia – skryte, nikde sa nezobrazuju
	money_tab.name = "OldFinanceHidden"
	money_tab.visible = false
	add_child(money_tab)
	var diplo_tab = _tab(tabs, "Vplyv")  # JUAN8: namiesto statnej diplomacie
	var market_tab = _tab(tabs, "Trh & banky")
	var state_tab = _tab(tabs, "Štát & správy")
	var pol_tab = _tab(tabs, "Politika")  # JUAN4
	var focus_tab = _tab(tabs, "Ciele")  # JUAN4
	_build_juan4_tabs(pol_tab, focus_tab)
	_build_research_tab(_tab(tabs, "Výskum"))  # JUAN5
	win_mgr = preload("res://scripts/ui/window_drag.gd").new()  # JUAN-P47: presuvatelne a zvacsitelne okna
	win_mgr.name = "WindowDrag"
	add_child(win_mgr)
	_build_burza_window()  # JUAN9: burza nie je v paneli, ale v zatvaratelnom okne nad mapou
	var side = firm_tab
	var cash_panel = side
	cash_label = Label.new()
	cash_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cash_panel.add_child(cash_label)
	var lh = Label.new()
	lh.text = "ÚVER Z BANKY"
	lh.theme_type_variation = "HeaderLabel"
	loans_tab.add_child(lh)
	var loan_b = Button.new()
	loan_b.text = "Pôžička"
	loan_b.tooltip_text = BankingSystem.HELP
	loan_b.pressed.connect(_on_loan)
	loans_tab.add_child(loan_b)
	var credit = preload("res://scripts/ui/credit_panel.gd").new()  # JUAN5 #18
	credit.name = "CreditPanel"
	var help_l = Label.new()  # JUAN9: vysvetlenie uverov priamo v hre
	help_l.name = "LoanHelp"
	help_l.text = BankingSystem.HELP
	help_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_l.add_theme_font_size_override("font_size", 11)
	help_l.visible = false
	var help_b = Button.new()
	help_b.text = "Ako fungujú úvery a banky?"
	help_b.toggle_mode = true
	help_b.toggled.connect(func(on): help_l.visible = on)
	loans_tab.add_child(help_b)
	loans_tab.add_child(help_l)
	credit.host = self
	loans_tab.add_child(credit)
	var bonds = preload("res://scripts/ui/bonds_view.gd").new()
	bonds.name = "BondsView"
	bonds.host = self
	loans_tab.add_child(bonds)
	var place_b = Button.new()
	place_b.text = "Založiť firmu"
	place_b.pressed.connect(_on_place)
	cash_panel.add_child(place_b)
	_build_place_panel(found_tab)  # JUAN3
	build_menu = preload("res://scripts/ui/build_menu.gd").new()
	build_menu.name = "BuildMenu"
	build_menu.setup(self)
	found_tab.add_child(build_menu)
	my_firms_label = Label.new()
	my_firms_label.name = "MojeFirmy"
	my_firms_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cash_panel.add_child(my_firms_label)
	my_firms_buttons = VBoxContainer.new()  # JUAN3: klik = detail firmy
	my_firms_buttons.name = "MojeFirmyDetail"
	cash_panel.add_child(my_firms_buttons)
	if not IndustrySystem.dividends_paid.is_connected(_on_dividends):
		IndustrySystem.dividends_paid.connect(_on_dividends)
	firm_label = Label.new()
	firm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cash_panel.add_child(firm_label)
	var firm_slider = HSlider.new()
	firm_slider.min_value = 0.25
	firm_slider.max_value = 1.0
	firm_slider.step = 0.05
	firm_slider.value = 1.0
	firm_slider.value_changed.connect(_on_firm_output)
	cash_panel.add_child(firm_slider)
	var price_b = Button.new()
	price_b.text = "Cena predaja"
	price_b.pressed.connect(_on_sale_price)
	cash_panel.add_child(price_b)
	var shift_b = Button.new()
	shift_b.text = "Zmena 2"
	shift_b.pressed.connect(_on_shifts)
	cash_panel.add_child(shift_b)
	var pmc_b = Button.new()
	pmc_b.text = "PMC kontrakt"
	pmc_b.pressed.connect(_on_pmc)
	cash_panel.add_child(pmc_b)
	var pmc_x = Button.new()
	pmc_x.text = "Zrušiť PMC"
	pmc_x.pressed.connect(_on_pmc_cancel)
	cash_panel.add_child(pmc_x)
	var imp_b = Button.new()
	imp_b.text = "Dovoz pšenice"
	imp_b.pressed.connect(_on_trade.bind("import"))
	cash_panel.add_child(imp_b)
	var exp_b = Button.new()
	exp_b.text = "Vývoz pšenice"
	exp_b.pressed.connect(_on_trade.bind("export"))
	cash_panel.add_child(exp_b)
	var research_b = Button.new()
	research_b.text = "Výskum: Logistika I"
	research_b.pressed.connect(_on_research)
	cash_panel.add_child(research_b)
	for rid in research_button_ids():
		var rb = Button.new()
		rb.text = "Výskum: %s" % str(rid)
		rb.pressed.connect(_on_research_id.bind(str(rid)))
		cash_panel.add_child(rb)
	var tree = preload("res://scripts/ui/research_tree.gd").new()
	cash_panel.add_child(tree)
	var prod_slider = HSlider.new()
	prod_slider.min_value = 0.25
	prod_slider.max_value = 1.0
	prod_slider.step = 0.05
	prod_slider.value = 1.0
	prod_slider.custom_minimum_size = Vector2(160, 16)
	prod_slider.value_changed.connect(_on_production_slider)
	cash_panel.add_child(prod_slider)
	var book_panel = money_tab
	book_label = Label.new()
	book_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	book_panel.add_child(book_label)
	bond_price = SpinBox.new()
	bond_price.min_value = 1.0
	bond_price.max_value = 10000.0
	bond_price.step = 1.0
	bond_price.value = 100.0
	book_panel.add_child(bond_price)
	bond_qty = SpinBox.new()
	bond_qty.min_value = 1.0
	bond_qty.max_value = 1000.0
	bond_qty.step = 1.0
	bond_qty.value = 1.0
	book_panel.add_child(bond_qty)
	var bid_free = Button.new()
	bid_free.text = "Bid dlhopis"
	bid_free.pressed.connect(_on_free_bond.bind("bid"))
	book_panel.add_child(bid_free)
	var ask_free = Button.new()
	ask_free.text = "Ask dlhopis"
	ask_free.pressed.connect(_on_free_bond.bind("ask"))
	book_panel.add_child(ask_free)
	stock_price = SpinBox.new()
	stock_price.min_value = 0.1
	stock_price.max_value = 10000.0
	stock_price.step = 0.1
	stock_price.value = 4.0
	book_panel.add_child(stock_price)
	stock_qty = SpinBox.new()
	stock_qty.min_value = 1.0
	stock_qty.max_value = 1000.0
	stock_qty.step = 1.0
	stock_qty.value = 2.0
	book_panel.add_child(stock_qty)
	var stock_bid = Button.new()
	stock_bid.text = "Bid akcie"
	stock_bid.pressed.connect(_on_free_stock.bind("bid"))
	book_panel.add_child(stock_bid)
	var stock_ask = Button.new()
	stock_ask.text = "Ask akcie"
	stock_ask.pressed.connect(_on_free_stock.bind("ask"))
	book_panel.add_child(stock_ask)
	var issue_bond_b = Button.new()
	issue_bond_b.text = "Vydať dlhopis"
	issue_bond_b.pressed.connect(_on_issue_bond)
	book_panel.add_child(issue_bond_b)
	var issue_share_b = Button.new()
	issue_share_b.text = "Vydať akcie"
	issue_share_b.pressed.connect(_on_issue_shares)
	book_panel.add_child(issue_share_b)
	# JUAN8: hrac uz statom nic neprikazuje (embargo/spojenectvo/... rozhoduju vlady); len vplyv a lobing
	var inf_view = preload("res://scripts/ui/influence_view.gd").new()
	inf_view.name = "InfluenceView"
	inf_view.host = self
	diplo_tab.add_child(inf_view)
	var market_panel = market_tab
	market_label = Label.new()
	market_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	market_panel.add_child(market_label)
	var bank_panel = market_tab
	bank_label = Label.new()
	bank_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bank_panel.add_child(bank_label)
	var bank_help = Label.new()  # JUAN9: banka sa zaklada len ako firma (Zalozit -> Banka), urok v detaile banky
	bank_help.text = "Vlastnú banku založíš v záložke Založiť → Postaviť na mape → Banka (v meste). Úroky nastavíš v detaile banky (Firma → Moje firmy)."
	bank_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bank_help.tooltip_text = BankingSystem.HELP
	bank_help.mouse_filter = Control.MOUSE_FILTER_PASS
	bank_panel.add_child(bank_help)
	var cons_row = HBoxContainer.new()  # JUAN3: (skryte, nastavuje sa v detaile banky)
	cons_row.visible = false
	bank_panel.add_child(cons_row)
	var cons_l = Label.new()
	cons_l.text = "Úrok pre ľudí %"
	cons_row.add_child(cons_l)
	cons_rate_box = SpinBox.new()
	cons_rate_box.min_value = 1.0
	cons_rate_box.max_value = 40.0
	cons_rate_box.step = 0.5
	cons_rate_box.value = 9.0
	cons_row.add_child(cons_rate_box)
	var cons_b = Button.new()
	cons_b.text = "Nastaviť úrok"
	cons_b.pressed.connect(_on_cons_rate)
	cons_row.add_child(cons_b)
	var law_panel = state_tab
	law_label = Label.new()
	law_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	law_panel.add_child(law_label)
	var paper = state_tab
	paper_label = Label.new()
	paper_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paper.add_child(paper_label)
	var climate = state_tab
	climate_label = Label.new()
	climate_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	climate.add_child(climate_label)
	var minister = state_tab
	minister_label = Label.new()
	minister_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	minister.add_child(minister_label)
	minister_tax = SpinBox.new()
	minister_tax.min_value = 0.0
	minister_tax.max_value = 0.6
	minister_tax.step = 0.01
	minister_tax.value = 0.21
	minister.add_child(minister_tax)
	var tax_b = Button.new()
	tax_b.text = "Nastaviť daň"
	tax_b.pressed.connect(_on_minister_tax)
	minister.add_child(tax_b)
	var news_panel = state_tab
	news_label = Label.new()
	news_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	news_panel.add_child(news_label)
	var event_b = Button.new()
	event_b.text = "Reagovať na recesiu"
	event_b.pressed.connect(_on_event)
	news_panel.add_child(event_b)
	var scale_label = Label.new()
	scale_label.text = "Mierka UI"
	scale_label.theme_type_variation = "HeaderLabel"
	state_tab.add_child(scale_label)
	var scale_box = OptionButton.new()
	scale_box.add_item("1.0")
	scale_box.add_item("1.25")
	scale_box.add_item("1.5")
	scale_box.set_block_signals(true)
	if is_equal_approx(_ui_scale, 1.25):
		scale_box.select(1)
	elif is_equal_approx(_ui_scale, 1.5):
		scale_box.select(2)
	else:
		scale_box.select(0)
	scale_box.set_block_signals(false)
	scale_box.item_selected.connect(_on_ui_scale)
	state_tab.add_child(scale_box)
	_wrap_labels(self)
	info = cash_label
	side_tabs.tab_changed.connect(func(_index): _refresh_label())
	_show_menu()
	if "menu_new" in OS.get_cmdline_user_args():  # JUAN7: nahlad panelu Nova hra (screenshot)
		main_menu._pick_mode("medium")
	elif OS.get_cmdline_user_args().size() > 0 and str(OS.get_cmdline_user_args()[0]).begins_with("tab_shot="):  # JUAN8: nahlad zalozky
		_on_menu_dev()
		show_tab(str(OS.get_cmdline_user_args()[0]).substr(9))
	elif "description_ui_test" in OS.get_cmdline_user_args():
		_description_test_runner = load("res://tests/descriptions_ui.gd").new()
		_description_test_runner.run(self)
	elif "toolbar_ui_test" in OS.get_cmdline_user_args():
		_toolbar_test_runner = load("res://tests/toolbar_ui.gd").new()
		_toolbar_test_runner.run(self)
	elif "atlas_only_ui_test" in OS.get_cmdline_user_args():
		_atlas_test_runner = load("res://tests/atlas_only_ui.gd").new()
		_atlas_test_runner.run(self)
	elif "fund_ui_test" in OS.get_cmdline_user_args():
		_fund_test_runner = load("res://tests/fund_ui.gd").new()
		_fund_test_runner.run(self)
	elif "window_ui" in OS.get_cmdline_user_args():  # JUAN-P47: presuvatelne okna (GUI + screenshot)
		_window_ui()
	elif "atlas_visual_audit" in OS.get_cmdline_user_args():
		_atlas_visual_runner = load("res://tests/atlas_visual_audit.gd").new()
		_atlas_visual_runner.run(self)
	elif "perf23" in OS.get_cmdline_user_args():  # JUAN23
		_perf23()
	elif "j22_shot" in OS.get_cmdline_user_args():  # JUAN22
		_j22_shot()
	elif "j21_shot" in OS.get_cmdline_user_args():  # JUAN21
		_j21_shot()
	elif "j20_shot" in OS.get_cmdline_user_args():  # JUAN20
		_j20_shot()
	elif "j19_shot" in OS.get_cmdline_user_args():  # JUAN19
		_j19_shot()
	elif "j18_ui" in OS.get_cmdline_user_args():  # JUAN18
		_j18_ui()
	elif "j17_shot" in OS.get_cmdline_user_args():  # JUAN17
		_j17_shot()
	elif "j16_shot" in OS.get_cmdline_user_args():  # JUAN16 pred/po nahlady
		_j16_shots()
	elif "j15_ui" in OS.get_cmdline_user_args():  # JUAN15
		await _j15_uitest()
		get_tree().quit(0)
	elif "j15_shot" in OS.get_cmdline_user_args():  # JUAN15
		_j15_shot()
	elif "j14_shot" in OS.get_cmdline_user_args():  # JUAN14
		_j14_shot()
	elif "j13_shot" in OS.get_cmdline_user_args():  # JUAN13
		_j13_shots()
	elif "zoom_shot" in OS.get_cmdline_user_args():  # JUAN12
		_zoom_shots()
	elif "pause_shot" in OS.get_cmdline_user_args():  # JUAN11
		_pause_shot()
	elif "phaseA_shot" in OS.get_cmdline_user_args():  # JUAN9: nahlady fazy A
		_phase_a_shots()
	elif OS.get_cmdline_user_args().size() > 0 and str(OS.get_cmdline_user_args()[0]).begins_with("intro_shot="):  # JUAN7: nahlad intra
		var spec = str(OS.get_cmdline_user_args()[0]).substr(11).split(":")
		var intro = preload("res://scripts/ui/intro_scene.gd").new()
		intro.setup("Wondris", "žena" if spec[0] == "f" else "muž")
		add_child(intro)
		intro.scene_i = int(spec[1]) if spec.size() > 1 else 0
		intro.typed = 999.0
	elif not _headless() and not "dev" in OS.get_cmdline_user_args():
		_show_splash()
	print("P47_UI_BUILT")

func _apply_theme() -> void:
	theme = load("res://ui/theme_factorio.tres")

func _load_ui_scale() -> void:
	preload("res://scripts/gfx.gd").apply()  # JUAN23
	var cfg = ConfigFile.new()
	var scale = 1.0
	if cfg.load("user://settings.cfg") == OK:
		scale = float(cfg.get_value("ui", "scale", 1.0))
	if not is_equal_approx(scale, 1.0) and not is_equal_approx(scale, 1.25) and not is_equal_approx(scale, 1.5):
		scale = 1.0
	_ui_scale = scale
	get_window().content_scale_factor = scale

func _on_ui_scale(index: int) -> void:
	var values = [1.0, 1.25, 1.5]
	var scale = values[clampi(index, 0, 2)]
	_ui_scale = scale
	get_window().content_scale_factor = scale
	var cfg = ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("ui", "scale", scale)
	cfg.save("user://settings.cfg")

func _wrap_labels(node: Node) -> void:
	if node is Label and node != fps_label and not (node.get_parent() is HBoxContainer):
		var label = node as Label
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for child in node.get_children():
		_wrap_labels(child)

func _panel(parent: Node, title: String, expand_v: bool = false) -> VBoxContainer:
	var shell = PanelContainer.new()
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if expand_v:
		shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(shell)
	var box = VBoxContainer.new()
	shell.add_child(box)
	var title_l = Label.new()
	title_l.text = title
	box.add_child(title_l)
	return box

func _set_speed(index: int) -> void:
	GameState.speed_index = index
	GameState.paused = false
	if speed_bar:
		speed_bar.mark_speed(index)
	_refresh_label()

func _reset_tab_scroll(tab_index: int) -> void:
	if side_tabs == null or tab_index < 0 or tab_index >= side_tabs.get_child_count():
		return
	var control = side_tabs.get_child(tab_index)
	if control is ScrollContainer:
		(control as ScrollContainer).scroll_vertical = 0

func _uitest() -> void:
	if map and is_instance_valid(map):
		remove_child(map)
		map.free()
		map = null
	get_window().content_scale_factor = 1.0
	_build_play()
	var scales = [1.0, 1.25, 1.5]
	for scale_value in scales:
		get_window().content_scale_factor = scale_value
		size = get_viewport().get_visible_rect().size
		await get_tree().process_frame
		await get_tree().process_frame
		var bad = _fit_bad(self, get_viewport().get_visible_rect())
		print("P47_UI_FIT 1280x720@%s %d" % [scale_value, bad])
	get_window().content_scale_factor = 1.0
	if main_menu:
		main_menu.visible = false
	if side_tabs:
		side_tabs.size_flags_vertical = Control.SIZE_SHRINK_END
		side_tabs.custom_minimum_size = Vector2(300, 180)
		side_tabs.size.y = 180
	await get_tree().process_frame
	for scroll in _scrolls():
		if scroll.get_child_count() > 0:
			var filler = Control.new()
			filler.custom_minimum_size = Vector2(0, 800)
			var box = scroll.get_child(0)
			box.add_child(filler)
			box.move_child(filler, 0)
		await get_tree().process_frame
		var before = scroll.scroll_vertical
		var center = scroll.get_global_rect().get_center()
		var motion = InputEventMouseMotion.new()
		motion.position = center
		motion.global_position = center
		get_viewport().push_input(motion)
		var ev = InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_WHEEL_DOWN
		ev.pressed = true
		ev.factor = 1.0
		ev.position = center
		ev.global_position = center
		Input.parse_input_event(ev)
		get_viewport().push_input(ev.duplicate())
		await get_tree().process_frame
		var last = _last_button(scroll)
		if last != null:
			scroll.ensure_control_visible(last)
		await get_tree().process_frame
		var inside = last != null and scroll.get_global_rect().grow(4).intersects(last.get_global_rect())
		var mark = "ok" if inside and scroll.scroll_vertical > 0 else "fail"
		print("P47_UI_SCROLL %s max=%d %s" % [scroll.name, scroll.scroll_vertical, mark])
	await _click_checks()
	await _juan3_ui_checks()
	await _juan4_ui_checks()
	get_tree().quit(0)

func _click_checks() -> void:
	if main_menu:
		main_menu.visible = false
	for fragment in ["Pôžička", "Založiť firmu", "Logistika I", "Dovoz"]:
		var button = _find_button(self, fragment)
		var before = feedback_count
		if button != null:
			var ev = InputEventMouseButton.new()
			ev.button_index = MOUSE_BUTTON_LEFT
			ev.pressed = true
			ev.position = button.get_global_rect().get_center()
			ev.global_position = ev.position
			Input.parse_input_event(ev)
			get_viewport().push_input(ev.duplicate())
			await get_tree().process_frame
			if feedback_count == before:
				button.emit_signal("pressed")
		var hit = 1 if feedback_count > before else 0
		print("P47_UI_CLICK %s pressed=%d feedback=%d" % [fragment, hit, hit])

func _find_button(node: Node, fragment: String) -> Button:
	if node is Button and str((node as Button).text).find(fragment) >= 0:
		return node
	for child in node.get_children():
		var found = _find_button(child, fragment)
		if found != null:
			return found
	return null

func _scrolls() -> Array:
	var found: Array = []
	if side_tabs == null:
		return found
	for child in side_tabs.get_children():
		if child is ScrollContainer:
			found.append(child)
	return found

func _last_button(node: Node) -> Button:
	var found: Button = null
	if node is Button:
		found = node
	for child in node.get_children():
		var deeper = _last_button(child)
		if deeper != null:
			found = deeper
	return found

func _fit_bad(node: Node, view: Rect2) -> int:
	var bad = 0
	if node is Control and node != self and (node as Control).visible and not _in_scrolled_content(node):
		var rect = (node as Control).get_global_rect()
		if rect.size.x > 2.0 and rect.size.y > 2.0 and not view.grow(1.0).encloses(rect):
			bad += 1
	for child in node.get_children():
		bad += _fit_bad(child, view)
	return bad

func _in_scrolled_content(node: Node) -> bool:
	var parent = node.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			return node != parent
		parent = parent.get_parent()
	return false

func _show_menu() -> void:
	if main_menu == null:
		main_menu = preload("res://scripts/ui/main_menu.gd").new()
		main_menu.new_game_requested.connect(_on_menu_new)
		main_menu.continue_requested.connect(_on_menu_continue)
		main_menu.load_requested.connect(_on_menu_load)
		main_menu.save_requested.connect(_on_menu_save)
		main_menu.quit_requested.connect(_on_menu_quit)
		main_menu.back_requested.connect(_on_menu_back)
		main_menu.tutorial_repeat_requested.connect(_on_tutorial_repeat)
		main_menu.scale_selected.connect(_on_ui_scale)
		main_menu.dev_requested.connect(_on_menu_dev)
		main_menu.visibility_changed.connect(func(): _set_game_visible(not main_menu.visible))
		add_child(main_menu)
	if tutorial:
		tutorial.visible = false
	main_menu.show_home(GameState.running)
	_set_game_visible(false)
	if GameState.running and main_menu.visible:
		if not _menu_paused_game:
			_menu_was_paused = GameState.paused
		_menu_paused_game = true
		GameState.paused = true

func show_tab(title: String) -> void:
	if side_tabs == null:
		return
	for i in side_tabs.get_tab_count():
		if side_tabs.get_tab_title(i) == title:
			side_tabs.current_tab = i
			return

func _begin_tutorial() -> void:
	if tutorial == null:
		tutorial = preload("res://scripts/ui/tutorial_overlay.gd").new()
		add_child(tutorial)
	tutorial_saw_country = false
	tutorial.start(self)

# JUAN5: celoobrazovkove menu – mapa a herne UI sa skryju (a hra je pauznuta), po zatvoreni sa vrati presne povodna viditelnost
# JUAN5: splash ~3 s (fade in/out), preskocitelny klikom/klavesou; v headless/dev sa neukazuje
var _splash: Control = null
func _show_splash() -> void:
	_splash = ColorRect.new()
	_splash.name = "Splash"
	_splash.color = Color(0.02, 0.02, 0.04)
	_splash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_splash.z_index = 100
	_splash.mouse_filter = Control.MOUSE_FILTER_STOP
	var vb = VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	_splash.add_child(vb)
	var k = cl…26049 tokens truncated…eringServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/workspace/projekt47/preview/j14_country_click.png")
	print("P47_J14_SHOT_OK")
	get_tree().quit(0)

# JUAN15: DEV hra sa uloží a po načítaní ostane DEV
func _dev_save_roundtrip() -> bool:
	SaveSystem.use_test_dir()
	var ok = save_game(3)
	var cash = float(GameState.player.cash)
	GameState.config["dev"] = false
	var err = SaveSystem.load_slot(3)
	var res = ok and err == "" and bool(GameState.config.get("dev", false)) and bool(GameState.ext.get("dev", false)) and absf(float(GameState.player.cash) - cash) < 1.0
	print("P47_UI_J15_DEVSAVE saved=%d loaded=%d dev=%d" % [int(ok), int(err == ""), int(bool(GameState.config.get("dev", false)))])
	SaveSystem.cleanup_test_dir()
	return res

func _j15_setup() -> Dictionary:
	_on_menu_dev()
	await get_tree().process_frame
	var cap = map.capital_of("SK")
	GameState.found_firm("power_coal", "", "SK")
	GameState.found_firm("bakery", "", "SK")
	var pe = IndustrySystem.place_at("SK", "stock_broker", cap + Vector2(0.35, -0.25))
	if GameState.player_firms().filter(func(f): return str(f.industry) == "stock_broker").is_empty():
		print("P47_J15 place_err ", pe)
		GameState.found_firm("stock_broker", "", "SK")
	var ids = []
	var broker = {}
	for f in GameState.player_firms():
		if str(f.industry) == "stock_broker":
			broker = f
		else:
			ids.append(str(f.id))
	StockMarket.create_corp("Wondris Holding", ids)
	var cid = str(StockMarket.ex().corps.keys()[0])
	Empire.set_hq(cid, "SK", cap)
	broker.cash = 3.0e7
	for _d in 35:
		GameState.simulate_day()
	return {"cid": cid, "broker": broker, "cap": cap}

func _j15_uitest() -> void:
	var r = await _j15_setup()
	map._zoom_at(map._to_screen(r.cap), 6.0)
	map.pan += map.size * 0.5 - map._to_screen(r.cap)
	var hp = r.cap
	for site in map._my_sites():
		if str(site.id).begins_with("hq:"):
			hp = site.wp
	await get_tree().process_frame
	map._click_at(map._to_screen(hp))
	var hq_ok = empire_win != null and empire_win.visible
	var ct = empire_win.find_child("CustomersText", true, false) if empire_win else null
	var cust_ok = ct != null and str(ct.text).find("spolu") >= 0
	open_firm_detail(str(r.broker.id))
	await get_tree().process_frame
	var bi = _detail_mgr.find_child("BrokerInfo", true, false) if _detail_mgr else null
	var br_ok = _detail_mgr.get_children().any(func(c): return c is Label and str(c.text).contains("BURZA / OBCHODNÍK"))
	print("P47_UI_J15 hq_portfolio=%d customers=%d broker=%d" % [int(hq_ok), int(cust_ok), int(br_ok)])

func _j15_shot() -> void:
	var r = await _j15_setup()
	open_portfolio_corp(str(r.cid))
	for _i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/workspace/projekt47/preview/j15_odberatelia.png")
	empire_win.visible = false
	open_firm_detail(str(r.broker.id))
	for _i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/workspace/projekt47/preview/j15_burza_firma.png")
	close_firm_detail()
	toggle_pause_popup()
	pause_popup._save_dlg()
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/workspace/projekt47/preview/j15_dev_save.png")
	print("P47_J15_SHOT_OK")
	get_tree().quit(0)

func _j16_shots() -> void:
	var tag = OS.get_environment("P47_TAG") if OS.get_environment("P47_TAG") != "" else "after"
	var out = "/workspace/projekt47/preview/j16_%s_" % tag
	for _f in 70:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "menu.png")
	var r = await _j15_setup()
	var cp: Vector2 = r.cap
	for k in ["hotel", "cafe", "software", "restaurant"]:
		IndustrySystem.place_at("SK", k, cp + Vector2(randf_range(-0.8, 0.8), randf_range(-0.8, 0.8)))
	toggle_side_panel()
	for z in [[1.0, "world"], [8.0, "region"], [40.0, "city"], [250.0, "city_close"]]:
		map.pan = Vector2.ZERO
		map._zoom_at(map._to_screen(cp), float(z[0]))
		map.pan += map.size * 0.5 - map._to_screen(cp)
		map.queue_redraw()
		for _f in 6:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var t0 = Time.get_ticks_usec()
		map.queue_redraw()
		await RenderingServer.frame_post_draw
		print("P47_J16 %s frame_ms=%.1f" % [str(z[1]), (Time.get_ticks_usec() - t0) / 1000.0])
		get_viewport().get_texture().get_image().save_png(out + str(z[1]) + ".png")
	toggle_side_panel()
	open_firm_detail(str(r.broker.id))
	for _f in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "panels.png")
	close_firm_detail()
	map._zoom_at(map._to_screen(cp), 3.0)
	map.pan += map.size * 0.5 - map._to_screen(cp)
	var bm = find_child("BuildMenu", true, false)
	print("P47_J16_SHOTS_OK")
	get_tree().quit(0)

func _j17_shot() -> void:
	_on_menu_dev()
	await get_tree().process_frame
	for iso in ["SK", "CZ", "DE", "PL", "HU", "AT"]:
		GameState.found_firm("power_coal", "", iso)
	GameState.found_firm("bakery", "", "SK")
	for _d in 32:
		GameState.simulate_day()
	var cb: Button = find_child("CustomersMapToggle", true, false)
	cb.button_pressed = true
	var data = map.cust_data()
	var lv_sk = map.cust_level("SK")
	var lv_none = map.cust_level("AU")
	map._hover_tip("SK")
	var tip_ok = map.tooltip_text.contains("Nakupuje od teba")
	map._hover_tip("AU")
	var tip0_ok = map.tooltip_text.contains("nič nekupuje")
	var cap = map.capital_of("DE")
	map._zoom_at(map._to_screen(cap), 2.2)
	map.pan += map.size * 0.5 - map._to_screen(cap)
	var opened = []
	var cbc = func(iso): opened.append(iso)
	map.country_firms.connect(cbc)
	map._click_at(map._to_screen(map.capital_of("FR")) + Vector2(25, 25))
	map.country_firms.disconnect(cbc)
	if country_win:
		country_win.visible = false
	map.pan = Vector2.ZERO
	map._zoom_at(map._to_screen(cap), 5.0)
	map.pan += map.size * 0.5 - map._to_screen(cap)
	map.queue_redraw()
	print("P47_UI_J17 mode=%d buyers=%d sk=%.2f none=%.2f tip=%d tip0=%d click=%d %s" % [int(map.cust_mode), data.size(), lv_sk, lv_none, int(tip_ok), int(tip0_ok), int(opened.size() > 0), str(opened)])
	for _f in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/workspace/projekt47/preview/j17_odberatelia_map.png")
	print("P47_J17_SHOT_OK")
	get_tree().quit(0)

func _j18_ui() -> void:
	_on_menu_dev()
	await get_tree().process_frame
	_refresh_label()
	var dev_atlas = not map_style_b.visible and map_style() == "hoi" and map.atlas
	set_map_style("pixel")
	var stays_atlas = map_style() == "hoi" and map.atlas
	GameState.config["dev"] = false
	_refresh_label()
	var normal_atlas = not map_style_b.visible and map_style() == "hoi" and map.atlas
	print("P47_UI_J18 dev_atlas=%d stays_atlas=%d normal_atlas=%d" % [int(dev_atlas), int(stays_atlas), int(normal_atlas)])
	get_tree().quit(0 if dev_atlas and stays_atlas and normal_atlas else 1)

func _j19_shot() -> void:
	_on_menu_dev()
	await get_tree().process_frame
	var cap = map.capital_of("SK")
	for k in ["coal_mine", "iron_mine", "steel_mill", "logistics_hub", "gas_plant"]:
		GameState.found_firm(k, "", "SK")
	var pos = {}
	for f in GameState.player_firms():
		pos[str(f.industry)] = Transport.firm_wp(f)
	var a = pos.get("coal_mine", cap)
	var b = pos.get("steel_mill", cap + Vector2(3, 1))
	if a.distance_to(b) < 0.5:
		b = a + Vector2(2.5, 0.8)
	print("P47_J19 rail ", Transport.build_line("rail", a, b))
	print("P47_J19 pipe ", Transport.build_line("pipe", pos.get("gas_plant", cap) + Vector2(-3, 1.5), pos.get("gas_plant", cap)))
	for _d in 12:
		GameState.simulate_day()
	toggle_side_panel()
	var ctr = (a + b) * 0.5
	map.pan = Vector2.ZERO
	map._zoom_at(map._to_screen(ctr), 18.0)
	map.pan += map.size * 0.5 - map._to_screen(ctr)
	map.queue_redraw()
	for _f in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/workspace/projekt47/preview/j19_rail_pipe.png")
	toggle_side_panel()
	for f in GameState.player_firms():
		if str(f.industry) == "steel_mill":
			open_firm_detail(str(f.id))
	for _f in 6:
		await get_tree().process_frame
	var sc = firm_detail_panel.find_child("*", true, false)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/workspace/projekt47/preview/j19_firm_supply.png")
	print("P47_J19_TEXT ", firm_detail_text(GameState.player_firms().filter(func(x): return str(x.industry) == "steel_mill")[0]).replace("\n", " | "))
	close_firm_detail()
	open_city_panel("SK", "Bratislava")
	for _f in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/workspace/projekt47/preview/j19_city_share.png")
	print("P47_J19_CITY ", city_text("SK", "Bratislava").replace("\n", " | "))
	print("P47_J19_SHOT_OK")
	get_tree().quit(0)


# JUAN20: Atlas – nahlady + meranie vykonu + kliky
func _j20_view(ctr: Vector2, z: float, name: String) -> void:
	map.pan = Vector2.ZERO
	map.zoom = 1.0
	map._zoom_at(map._to_screen(ctr), z)
	map.pan += map.size * 0.5 - map._to_screen(ctr)
	map.queue_redraw()
	for _f in 6:
		await get_tree().process_frame
	var tot = 0.0
	var t0 = Time.get_ticks_usec()
	for _f in 20:
		map.queue_redraw()
		await get_tree().process_frame
		tot += map.last_draw_ms
	var frame = float(Time.get_ticks_usec() - t0) / 20000.0
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/workspace/projekt47/preview/j20_atlas_%s.png" % name)
	print("P47_J20_PERF %s zoom=%.1f draw_ms=%.2f frame_ms=%.1f tiles=%d tile_load_ms=%.0f" % [name, z, tot / 20.0, frame, map._atlas_layer.tiles_drawn, map._atlas_layer.load_ms])

func _j20_shot() -> void:
	_on_menu_dev()
	await get_tree().process_frame
	set_map_style("hoi")
	GameState.player.cash = 1.0e10
	var spots = {"coal_mine": [48.75, 18.35], "oil_refinery": [48.2, 17.25], "steel_mill": [48.38, 17.55], "gas_well": [48.7, 21.4], "gas_plant": [48.9, 20.4], "logistics_hub": [48.3, 18.1], "nuclear_plant": [48.5, 17.7], "bank": [48.15, 17.11], "wheat_farm": [48.1, 18.9]}
	for k in spots.keys():
		GameState.found_firm(k, "", "SK")
	for f in GameState.player_firms():
		if spots.has(str(f.industry)):
			var wp = map.project(spots[str(f.industry)][0], spots[str(f.industry)][1])
			f.pos = [wp.x, wp.y]
	GameState.found_firm("oil_well", "", "SK")
	var mill = map.project(48.38, 17.55)
	print("P47_J20 rail ", Transport.build_line("rail", map.project(48.75, 18.35), mill))
	print("P47_J20 pipe ", Transport.build_line("pipe", map.project(48.7, 21.4), map.project(48.9, 20.4)))
	for _d in 3:
		GameState.simulate_day()
	toggle_side_panel()
	_sync_map_style()
	print("P47_J20 atlas=", map.atlas, " style=", map_style())
	var t0 = Time.get_ticks_msec()
	map.atlas_infra()
	print("P47_J20 infra_build_ms=", Time.get_ticks_msec() - t0, " static_ms=", map._ainfra_static.ms, " power=", map._ainfra.power.size(), " plines=", map._ainfra.plines.size(), " pipes=", map._ainfra.pipes.size(), " highways=", map._ainfra_static.highways.size(), " rails=", map._ainfra_static.rails.size())
	var sk = map.project(48.6, 19.3)
	await _j20_view(map.project(48.0, 15.0), 1.0, "far")
	await _j20_view(sk, 4.0, "region")
	await _j20_view(map.project(48.5, 18.2), 22.0, "close")
	await _j20_view(map.project(48.16, 17.12), 45.0, "city_edge")
	await _j20_view(map.project(48.15, 17.11), 140.0, "city_sat")
	# kliky: firma vs krajina v Atlase
	await _j20_view(map.project(48.5, 18.2), 22.0, "close")
	var fp = map._to_screen(map.project(48.75, 18.35))
	var fid = map.firm_at_screen(fp)
	var empty = map._to_screen(map.project(48.95, 19.6))
	print("P47_J20_CLICK firm=", fid != "", " country=", map._pick(empty), " firm_on_empty=", map.firm_at_screen(empty) != "")
	map.cust_mode = true
	await _j20_view(sk, 4.0, "cust")
	map.cust_mode = false
	set_map_style("pixel")
	print("P47_J20 back_pixel atlas=", map.atlas)
	await _j20_view(sk, 4.0, "pixel_region")
	await _j20_view(map.project(48.5, 18.2), 22.0, "pixel_close")
	print("P47_J20_SHOT_OK")
	get_tree().quit(0)


# ===================== JUAN21: premenovanie, vyrobky, priblizenie na mesto =====================
func _brand_ui(firm: Dictionary) -> void:
	var rr = HBoxContainer.new()
	rr.name = "RenameRow"
	_detail_mgr.add_child(rr)
	var le = LineEdit.new()
	le.name = "RenameEdit"
	le.text = str(firm.get("name", ""))
	le.custom_minimum_size = Vector2(170, 0)
	rr.add_child(le)
	var rb = Button.new()
	rb.name = "RenameFirm"
	rb.text = "Premenovať firmu"
	rb.pressed.connect(func():
		var e = Brand.rename_firm(str(firm.id), le.text)
		_feedback("Názov: " + ("zmenený." if e == "" else e), e == "")
		_fill_firm_detail()
		_refresh_label())
	rr.add_child(rb)
	var cid = str(firm.get("corp", ""))
	if cid != "" and StockMarket.ex().get("corps", {}).has(cid):
		var cb = Button.new()
		cb.name = "RenameCorpFromFirm"
		cb.text = "Premenovať korporáciu"
		cb.pressed.connect(func():
			var e2 = Brand.rename_corp(cid, le.text)
			_feedback("Korporácia: " + ("premenovaná." if e2 == "" else e2), e2 == "")
			_fill_firm_detail())
		rr.add_child(cb)
	if Brand.makes_vehicles(firm):
		var pl = Label.new()
		pl.name = "ProductsInfo"
		pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pl.text = Brand.products_text(firm)
		_detail_mgr.add_child(pl)
		var mb = Button.new()
		mb.name = "ShowProducts"
		mb.text = "Ukázať na mape, kam sa predali" if map.product_firm != str(firm.id) else "Skryť na mape"
		mb.pressed.connect(func():
			map.product_firm = "" if map.product_firm == str(firm.id) else str(firm.id)
			if map.product_firm != "":
				map.pan = Vector2.ZERO
				map._zoom_at(map.size * 0.5, 1.0)
			map.queue_redraw()
			_fill_firm_detail())
		_detail_mgr.add_child(mb)

func zoom_to_city(iso: String, city_name: String) -> void:
	if empire_win and empire_win.visible:
		toggle_empire()
	var c: Dictionary = TerrainSystem.city_named(iso, city_name) if city_name != "" else {}
	var wp: Vector2 = c.get("pos", map.capital_of(iso)) if not c.is_empty() else map.capital_of(iso)
	var z = 40.0 if city_name != "" else 6.0
	map.pan = Vector2.ZERO
	map._zoom_at(map._to_screen(wp), z)
	map.pan += map.size * 0.5 - map._to_screen(wp)
	map.queue_redraw()
	GameState.selected_iso = iso


func _j21_snap(name: String) -> void:
	for _f in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/workspace/projekt47/preview/j21_%s.png" % name)

func _j21_shot() -> void:
	_on_menu_dev()
	await get_tree().process_frame
	set_map_style("pixel")
	GameState.player.cash = 1.0e10
	var spots = {"auto_plant": [48.3, 17.6], "shipyard": [48.12, 17.2], "aircraft_plant": [48.6, 18.0], "data_center": [48.75, 19.0], "ai_firm": [48.16, 17.1], "real_estate": [48.14, 17.13]}
	for k in spots.keys():
		GameState.found_firm(k, "", "SK")
	var by = {}
	for f in GameState.player_firms():
		if spots.has(str(f.industry)):
			var wp = map.project(spots[str(f.industry)][0], spots[str(f.industry)][1])
			f.pos = [wp.x, wp.y]
			by[str(f.industry)] = f
	StockMarket.setup()
	StockMarket.create_corp("Wondris Motors", [str(by.auto_plant.id), str(by.shipyard.id), str(by.aircraft_plant.id)])
	var cid = str(by.auto_plant.corp)
	Brand.set_logo(cid, {"shape": "shield", "symbol": "bolt", "bg": "1F3A68", "fg": "FFC233", "text": "WM"})
	Empire.set_hq(cid, "SK", map.project(48.15, 17.11))
	Brand.rename_firm(str(by.auto_plant.id), "Wondris Autá Trnava")
	for d in 30:
		for pair in [["auto_plant", "automobiles", 6.0], ["shipyard", "ships", 0.3], ["aircraft_plant", "aircraft", 0.2]]:
			var f2 = by[pair[0]]
			GameState.day_index += 1
			Brand.track(str(f2.id), pair[1], pair[2], "SK")
	for t in [["Bratislava", "office"], ["Bratislava", "apartments"], ["Bratislava", "shop"], ["Košice", "warehouse"], ["Nitra", "plot"], ["Žilina", "apartments"]]:
		Empire.buy_building("SK", t[0], t[1])
	GameState.found_firm("real_estate", "", "CZ")
	for t2 in [["Praha", "office"], ["Brno", "shop"]]:
		Empire.buy_building("CZ", t2[0], t2[1])
	toggle_side_panel()
	# 1) logo editor
	open_portfolio_corp(cid)
	await _j21_snap("portfolio_top")
	var ev = empire_win.find_child("EmpireView", true, false)
	ev.logo_ed.open_for(cid)
	await _j21_snap("logo_editor")
	ev.logo_ed.hide()
	var rl = ev.find_child("RealtyList", true, false)
	var sc = rl.get_parent()
	while sc and not (sc is ScrollContainer):
		sc = sc.get_parent()
	if sc:
		sc.scroll_vertical = int(rl.position.y) - 260
	await _j21_snap("portfolio_realty")
	ev.re_group.select(2)
	ev._fill_realty()
	await _j21_snap("portfolio_realty_type")
	print("P47_J21_REALTY ", ev.re_sum.text.replace("\n", " | "))
	ev.re_group.select(0)
	ev._fill_realty()
	ev._re_go(0)
	await _j21_snap("realty_zoom_city")
	print("P47_J21_ZOOM zoom=%.0f empire_closed=%s" % [map.zoom, str(not empire_win.visible)])
	# 2) burza
	toggle_burza()
	await _j21_snap("burza_parody")
	toggle_burza()
	# 3) firma: premenovanie + vyrobky
	open_firm_detail(str(by.auto_plant.id))
	for _f in 4:
		await get_tree().process_frame
	var rr = _detail_mgr.find_child("RenameRow", true, false)
	var scx = rr.get_parent()
	while scx and not (scx is ScrollContainer):
		scx = scx.get_parent()
	if scx:
		scx.scroll_vertical = int(rr.get_global_rect().position.y - scx.get_global_rect().position.y) + scx.scroll_vertical - 20
	await _j21_snap("firm_rename_products")
	map.product_firm = str(by.auto_plant.id)
	close_firm_detail()
	map.pan = Vector2.ZERO
	map._zoom_at(map.size * 0.5, 1.0)
	map.queue_redraw()
	await _j21_snap("map_products")
	map.product_firm = ""
	# 4) HQ logo na mape (pixel) + atlas modely
	var ctr = map.project(48.3, 17.6)
	map.pan = Vector2.ZERO
	map._zoom_at(map._to_screen(ctr), 20.0)
	map.pan += map.size * 0.5 - map._to_screen(ctr)
	map.queue_redraw()
	await _j21_snap("map_hq_logo")
	set_map_style("hoi")
	_sync_map_style()
	await _j21_snap("atlas_new_models")
	set_map_style("pixel")
	open_city_panel("SK", "Nitra")
	await _j21_snap("city_types")
	print("P47_J21_SHOT_OK")
	get_tree().quit(0)


# JUAN22: dosah medii v krajine (riadok do detailu krajiny / mesta)
func _media_line(iso: String) -> String:
	var rows = Brand.country_media(iso)
	if rows.is_empty():
		return ""
	return "\nTVOJE MÉDIÁ A TELEKOM: " + ", ".join(rows.map(func(r): return "%s %.1f %% obyvateľov" % [str(r.name), float(r.pct) * 100.0]))


func _j22_snap(name: String) -> void:
	for _f in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/workspace/projekt47/preview/j22_%s.png" % name)

func _j22_shot() -> void:
	_on_menu_dev()
	await get_tree().process_frame
	GameState.player.cash = 1.0e10
	for k in ["telecom", "newspaper", "tv_station", "social_network"]:
		GameState.found_firm(k, "", "SK")
	GameState.found_firm("telecom", "", "CZ")
	for _d in 3:
		GameState.simulate_day()
	toggle_side_panel()
	var tel = GameState.player_firms().filter(func(f): return str(f.industry) == "telecom" and str(f.country) == "SK")[0]
	open_firm_detail(str(tel.id))
	await _j22_snap("firm_detail")
	print("P47_J22_FIRM ", Brand.media_text(tel))
	close_firm_detail()
	toggle_empire()
	var ev = empire_win.find_child("EmpireView", true, false)
	var ml = ev.find_child("MediaReach", true, false)
	var sc = ml.get_parent()
	while sc and not (sc is ScrollContainer):
		sc = sc.get_parent()
	for _f in 3:
		await get_tree().process_frame
	if sc:
		sc.scroll_vertical = int(ml.get_global_rect().position.y - sc.get_global_rect().position.y) + sc.scroll_vertical - 40
	await _j22_snap("portfolio")
	print("P47_J22_PORT ", ml.text.replace("\n", " | "))
	toggle_empire()
	open_country_firms("SK")
	await _j22_snap("country")
	print("P47_J22_COUNTRY ", _media_line("SK"))
	print("P47_J22_SHOT_OK")
	get_tree().quit(0)


# JUAN23: benchmark vykonu (stredne velka hra: ~70 firiem v 12 krajinach, linky, media)
func _p23_ms(f: Callable, n: int = 10) -> float:
	var t0 = Time.get_ticks_usec()
	for _i in n:
		f.call()
	return float(Time.get_ticks_usec() - t0) / 1000.0 / n

func _p23_view(ctr: Vector2, z: float, nm: String) -> void:
	map.pan = Vector2.ZERO
	map.zoom = 1.0
	map._zoom_target = 1.0
	map._zoom_at(map._to_screen(ctr), z)
	map._zoom_target = map.zoom
	map.pan += map.size * 0.5 - map._to_screen(ctr)
	for _f in 6:
		map.queue_redraw()
		await get_tree().process_frame
	var tot = 0.0
	var t0 = Time.get_ticks_usec()
	for _f in 20:
		map.queue_redraw()
		await get_tree().process_frame
		tot += map.last_draw_ms
	print("P47_PERF   prof ", map.prof)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/perf_atlas_%s.png" % nm))
	print("P47_PERF view=%s zoom=%.0f draw_ms=%.2f frame_ms=%.1f" % [nm, z, tot / 20.0, float(Time.get_ticks_usec() - t0) / 20000.0])

func _perf23() -> void:
	_on_menu_dev()
	await get_tree().process_frame
	GameState.config.progression = false
	GameState.player.cash = 5.0e10
	var kinds = ["coal_mine", "iron_mine", "steel_mill", "power_coal", "oil_well", "refinery", "car_plant", "telecom", "newspaper", "tv_station", "data_center", "ai_firm", "logistics_hub", "farm", "gas_well", "shipyard"]
	var isos = ["SK", "CZ", "DE", "PL", "AT", "HU", "FR", "IT", "US", "CN", "GB", "ES"]
	var n = 0
	for iso in isos:
		for i in 6:
			if GameState.found_firm(kinds[(n + i) % kinds.size()], "", iso) == "":
				pass
			n += 1
	var ids = GameState.player_firms().slice(0, 8).map(func(f): return str(f.id))
	if StockMarket.has_method("create_corp"):
		StockMarket.create_corp("Perf Corp", ids)
	var cap = map.capital_of("SK")
	Transport.build_line("rail", cap, cap + Vector2(4, 1))
	Transport.build_line("pipe", cap + Vector2(-3, 1), cap)
	for c in ["Bratislava", "Košice"]:
		Empire.buy_building("SK", c, "office")
	print("P47_PERF firms=%d" % GameState.player_firms().size())
	for _d in 5:
		GameState.simulate_day()
	var sim = _p23_ms(func(): GameState.simulate_day(), 30)
	print("P47_PERF sim_day_ms=%.2f" % sim)
	var stages = {"Event.begin": func(): EventSystem.begin_day(), "Market.begin": func(): MarketSystem.begin_day(), "Geo.daily": func(): GeopoliticsSystem.daily(),
		"Ind.plan_post": func(): IndustrySystem.plan_and_post(), "Market.routes": func(): MarketSystem.trade_routes(), "Market.clear": func(): MarketSystem.clear_all(),
		"Ind.settle": func(): IndustrySystem.settle(), "Bank.daily": func(): BankingSystem.daily(), "research": func(): GameState._tick_research(), "Pol.daily": func(): PoliticsSystem.daily(),
		"signal": func(): GameState.day_passed.emit(GameState.day_index), "Stock.weekly": func(): StockMarket.weekly(), "Empire.weekly": func(): Empire.weekly()}
	var pf = GameState.player_firms()
	var allf = GameState.firms
	print("P47_PERF firms_total=%d" % allf.size())
	var fx = {"Transport.discount(pl)": func(): for f in pf: Transport.discount(f, "coal"),
		"yield_mult(all)": func(): for f in allf: IndustrySystem._yield_mult(f, str(f.facilities[0].get("recipe","")) if f.facilities.size() > 0 else ""),
		"ai_boost(all)": func(): for f in allf: Brand.ai_boost(f),
		"plan_for(all)": func(): for f in allf: for i in f.facilities.size(): IndustrySystem._plan_for(f, i),
		"wage(all)": func(): for f in allf: IndustrySystem._wage(str(f.country), f),
		"tax_iso+mult(all)": func(): for f in allf: Empire.tax_iso(f); Empire.tax_mult(f),
		"local_mult(all)": func(): for f in allf: for fac in f.facilities: IndustrySystem._local_mult(f, fac, "coal"),
		"buy_share(all)": func(): for f in allf: IndustrySystem.buy_share(f),
		"run_desks(all)": func(): for f in allf: IndustrySystem._run_desks(f, 0.0),
		"Transport.begin": func(): Transport.begin_day()}
	for k in fx:
		print("P47_PERF fn %s ms=%.2f" % [k, _p23_ms(fx[k], 3)])
	for k in stages:
		print("P47_PERF stage %s ms=%.2f" % [k, _p23_ms(stages[k], 5)])
	print("P47_PERF refresh_label_ms=%.3f" % _p23_ms(func(): _refresh_label(), 20))
	print("P47_PERF redraw_views_ms=%.3f" % _p23_ms(func(): _redraw_views(), 20))
	print("P47_PERF empire_stats_ms=%.3f" % _p23_ms(func(): Empire.stats(), 20))
	print("P47_PERF media_country_ms=%.3f" % _p23_ms(func(): Brand.country_media("SK"), 20))
	print("P47_PERF atlas_infra_ms=%.3f" % _p23_ms(func(): map.atlas_infra(), 20))
	print("P47_PERF realty_ms=%.3f" % _p23_ms(func(): Empire.realty_rows("city"), 20))
	var _ev = find_child("EmpireView", true, false)
	if _ev:
		print("P47_PERF portfolio_refresh_ms=%.2f" % _p23_ms(func(): _ev.refresh(), 5))
	var _sv = find_child("StockView", true, false)
	if _sv:
		print("P47_PERF burza_refresh_ms=%.2f" % _p23_ms(func(): _sv.refresh(), 5))
	var anim = map._anim_live()
	print("P47_PERF anim_live=%d" % int(anim))
	set_map_style("hoi")
	await _p23_view(map.capital_of("DE"), 1.0, "world")
	await _p23_view(map.capital_of("DE"), 6.0, "region")
	await _p23_view(cap, 20.0, "detail")
	await _p23_view(cap, 60.0, "city")
	# Skuska skutocnych snimok na kazdej rychlosti v rovnakom scenari.
	play = true
	GameState.paused = false
	for speed in [1, 2, 3]:
		_set_speed(speed)
		var frames = 0
		var t0 = Time.get_ticks_usec()
		var worst = 0.0
		var spikes = 0
		var tl = Time.get_ticks_usec()
		var d0 = GameState.day_index
		while Time.get_ticks_usec() - t0 < 6000000:
			await get_tree().process_frame
			var tn = Time.get_ticks_usec()
			var frame_ms = float(tn - tl) / 1000.0
			worst = maxf(worst, frame_ms)
			if frame_ms > 16.0:
				spikes += 1
			tl = tn
			frames += 1
		var elapsed_ms = float(Time.get_ticks_usec() - t0) / 1000.0
		print("P47_PERF run_speed%d frames=%d avg_frame_ms=%.1f worst_ms=%.1f spikes_gt_16=%d days=%d" % [speed, frames, elapsed_ms / max(frames, 1), worst, spikes, GameState.day_index - d0])
	print("P47_PERF_DONE")
	get_tree().quit(0)


# ===================== JUAN-P47: PMC, skoly, Moc a vplyv =====================
func _pmc_text(firm: Dictionary) -> String:
	var ps = Society.pmc_state(firm)
	var out = "\nPMC: %d vojakov = %d jednotiek (nasadených %d). Výcvik %.0f/100, vybavenie %.0f/100, kvalita ×%.2f.\n" % [int(Society.pmc_soldiers(firm)), Society.pmc_units(firm), Society.pmc_deployed(firm), float(ps.training), float(ps.equipment), Society.pmc_quality(firm)]
	var d: Dictionary = Society.st().deploy.get(str(firm.get("id", "")), {})
	for k in d.keys():
		out += "• %s: %d jednotiek\n" % [str(k).replace("|", " – "), int(d[k])]
	out += "Mesačné náklady nasadenia: %s. Nasadenie len pri kontrole krajiny nad 50 %% alebo s vládnou zmluvou.\n" % EconMath.eur(float(firm.get("pmc_cost", 0.0)))
	return out

func _pmc_ui(firm: Dictionary) -> void:
	var fid = str(firm.get("id", ""))
	var head = Label.new()
	head.text = "PMC – VÝCVIK, VYBAVENIE, NASADENIE"
	_detail_mgr.add_child(head)
	for what in [["training", "Výcvik +10"], ["equipment", "Vybavenie +10"]]:
		var b = Button.new()
		b.name = "Pmc_" + str(what[0])
		b.text = "%s (%s)" % [str(what[1]), EconMath.eur(Society.pmc_upgrade_cost(firm, str(what[0])))]
		b.pressed.connect(func():
			var e = Society.pmc_upgrade(fid, str(what[0]))
			_feedback("PMC: %s" % ("hotovo." if e == "" else e), e == "")
			_fill_firm_detail())
		_detail_mgr.add_child(b)
	var row = HBoxContainer.new()
	_detail_mgr.add_child(row)
	var pick = OptionButton.new()
	pick.name = "PmcCity"
	pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var isos: Array = [str(firm.get("country", ""))]
	for iso2 in Society.st().contracts.keys():
		if not str(iso2) in isos:
			isos.append(str(iso2))
	for iso3 in Society.st().power.keys():
		if Society.has_control(str(iso3)) and not str(iso3) in isos:
			isos.append(str(iso3))
	for iso in isos:
		for c in TerrainSystem.cities(str(iso)):
			pick.add_item("%s – %s" % [str(GameState.world.get(str(iso), {}).get("name_sk", iso)), str(c.name)])
			pick.set_item_metadata(pick.item_count - 1, [str(iso), str(c.name)])
	row.add_child(pick)
	var units = SpinBox.new()
	units.name = "PmcUnits"
	units.min_value = 0
	units.max_value = 500
	units.value = 1
	units.tooltip_text = "Počet jednotiek (1 jednotka = 10 vojakov). 0 = stiahnuť."
	row.add_child(units)
	var db = Button.new()
	db.name = "PmcDeploy"
	db.text = "Nasadiť"
	db.pressed.connect(func():
		if pick.selected < 0:
			return
		var md: Array = pick.get_item_metadata(pick.selected)
		var e = Society.deploy(fid, str(md[0]), str(md[1]), int(units.value))
		_feedback("Nasadenie PMC: %s" % ("hotovo." if e == "" else e), e == "")
		_fill_firm_detail())
	row.add_child(db)

func _school_ui(firm: Dictionary) -> void:
	var fid = str(firm.get("id", ""))
	var row = HBoxContainer.new()
	_detail_mgr.add_child(row)
	var cap = Label.new()
	cap.text = "Školné €/mes."
	row.add_child(cap)
	var t = SpinBox.new()
	t.name = "SchoolTuition"
	t.min_value = 0.0
	t.max_value = 100000.0
	t.step = 1.0
	t.value = Society.tuition(firm)
	t.tooltip_text = "Vyššie školné = viac peňazí na žiaka, ale menej žiakov a pomalší rast vzdelania mesta."
	row.add_child(t)
	var b = Button.new()
	b.name = "SchoolTuitionSet"
	b.text = "Nastaviť"
	b.pressed.connect(func():
		var e = Society.set_tuition(fid, t.value)
		_feedback("Školné: %s" % ("nastavené." if e == "" else e), e == "")
		_fill_firm_detail())
	row.add_child(b)

func _power_ui(v: VBoxContainer, iso: String) -> void:
	var box = VBoxContainer.new()
	box.name = "PowerPanel"
	v.add_child(box)
	var h = Label.new()
	h.text = "MOC A VPLYV"
	h.theme_type_variation = "HeaderLabel"
	box.add_child(h)
	var pl = Label.new()
	pl.name = "PowerText"
	pl.text = Society.power_text(iso)
	pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pl.custom_minimum_size = Vector2(260, 0)
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pl.add_theme_font_size_override("font_size", 12)
	box.add_child(pl)
	# lobing politikov
	var lr = HFlowContainer.new()  # JUAN-P47: riadok sa zalomi, nic nevytrca z okna
	box.add_child(lr)
	var pp = OptionButton.new()
	pp.name = "LobbyPolitician"
	pp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pp.clip_text = true
	pp.fit_to_longest_item = false
	pp.custom_minimum_size = Vector2(200, 0)
	var pols = Society.politicians(iso)
	for i in pols.size():
		pp.add_item("%s (%s) – lojalita %.0f" % [str(pols[i].name), str(pols[i].role), float(pols[i].loyalty)])
		pp.set_item_metadata(pp.item_count - 1, i)
	lr.add_child(pp)
	var amt = SpinBox.new()
	amt.name = "LobbyAmount"
	amt.min_value = 1000.0
	amt.max_value = 1.0e9
	amt.step = 1000.0
	amt.value = snappedf(Society.lobby_base_cost(iso), 1000.0)
	lr.add_child(amt)
	var lb = Button.new()
	lb.name = "LobbyGo"
	lb.text = "Lobovať"
	lb.tooltip_text = "Peniaze zvýšia lojalitu politika; vplyv rastie postupne každý mesiac. Čím viac minieš, tým vyššie riziko škandálu (pokuta, −vplyv, −reputácia)."
	lb.pressed.connect(func():
		var e = Society.lobby(iso, int(pp.get_item_metadata(pp.selected)) if pp.selected >= 0 else -1, amt.value)
		_feedback("Lobing: %s" % ("hotovo." if e == "" else e), e == "")
		open_country_firms(iso))
	lr.add_child(lb)
	# vyhodne zakony (len pri kontrole)
	if Society.has_control(iso):
		for law in Society.LAWS.keys():
			var cb = CheckBox.new()
			cb.name = "Law_" + str(law)
			cb.text = str(Society.LAWS[law].name)
			cb.button_pressed = bool(Society.laws(iso).get(law, false))
			cb.toggled.connect(func(on):
				var e = Society.set_law(iso, str(law), on)
				_feedback("Zákon: %s" % ("hotovo." if e == "" else e), e == ""))
			box.add_child(cb)
	# vladna bezpecnostna zmluva pre PMC
	var pmcs: Array = GameState.player_firms().filter(func(f): return str(f.get("industry", "")) == "pmc_unit" and not bool(f.get("closed", false)))
	if not pmcs.is_empty():
		var cr = HFlowContainer.new()  # JUAN-P47: zalomenie
		box.add_child(cr)
		var fp = OptionButton.new()
		fp.name = "ContractPmc"
		fp.clip_text = true
		fp.fit_to_longest_item = false
		fp.custom_minimum_size = Vector2(160, 0)
		for f in pmcs:
			fp.add_item(str(f.get("name", "")))
			fp.set_item_metadata(fp.item_count - 1, str(f.id))
		cr.add_child(fp)
		var price = SpinBox.new()
		price.name = "ContractPrice"
		price.min_value = 100.0
		price.max_value = 1.0e7
		price.step = 100.0
		price.value = snappedf(Society.contract_fair_price(iso), 100.0)
		price.tooltip_text = "Cena za jednotku (10 vojakov) mesačne."
		cr.add_child(price)
		var months = SpinBox.new()
		months.name = "ContractMonths"
		months.min_value = 1
		months.max_value = 60
		months.value = 12
		months.tooltip_text = "Trvanie zmluvy v mesiacoch."
		cr.add_child(months)
		var mu = SpinBox.new()
		mu.name = "ContractUnits"
		mu.min_value = 1
		mu.max_value = 500
		mu.value = 5
		mu.tooltip_text = "Najviac jednotiek v krajine."
		cr.add_child(mu)
		var go = Button.new()
		go.name = "ContractPropose"
		go.text = "Navrhnúť bezpečnostnú zmluvu"
		go.pressed.connect(func():
			var res: Dictionary = Society.propose_contract(iso, str(fp.get_item_metadata(fp.selected)), price.value, int(months.value), int(mu.value))
			_feedback("Zmluva: %s" % str(res.get("text", "")), bool(res.get("ok", false)))
			if res.has("counter"):
				price.value = float(res.counter.price)
				mu.value = int(res.counter.max_units)
			else:
				open_country_firms(iso))
		box.add_child(go)

func _society_ui() -> void:
	if map and is_instance_valid(map):
		remove_child(map)
		map.free()
		map = null
	_build_play()
	if main_menu:
		main_menu.visible = false
	_on_start({})
	await get_tree().process_frame
	GameState.config.progression = false
	GameState.player.cash = 5.0e9
	var ids: Array = []
	var errs: Array = []
	for ind in ["school_high", "cargo_port", "hospital", "pmc_unit", "corp_academy", "university", "nuclear_plant"]:
		var e = GameState.found_firm(ind, "", "SK")
		if e != "":
			errs.append(ind + ": " + e)
		else:
			ids.append(str(GameState.player_firms()[-1].id))
	Society.monthly()
	for i in 3:
		GameState.simulate_day()
	var ok = errs.is_empty()
	for id in ids:
		open_firm_detail(id)
		await get_tree().process_frame
		var f = GameState.firm_by_id(id)
		if not _detail_info.text.contains("Spokojnosť") or not _detail_info.text.contains("ľudí"):
			ok = false
			errs.append("detail " + id)
		if Society.service_kind(f) == "school" and firm_detail_panel.find_child("SchoolTuition", true, false) == null:
			ok = false
			errs.append("tuition ui")
		if str(f.get("industry", "")) == "pmc_unit" and firm_detail_panel.find_child("PmcDeploy", true, false) == null:
			ok = false
			errs.append("pmc ui")
	close_firm_detail()
	open_country_firms("SK")
	await get_tree().process_frame
	var pt = country_win.find_child("PowerText", true, false)
	if pt == null or not (pt as Label).text.contains("MOC A VPLYV") or country_win.find_child("LobbyGo", true, false) == null or country_win.find_child("ContractPropose", true, false) == null:
		ok = false
		errs.append("power panel")
	open_city_panel("SK", "Bratislava")
	await get_tree().process_frame
	if not city_label.text.contains("SPOLOČNOSŤ") or not city_label.text.contains("Gangy"):
		ok = false
		errs.append("city panel")
	if not Society.portfolio_text().contains("PRÍSTAVY") or map_has_icons() == false:
		ok = false
		errs.append("portfolio/icons")
	print("P47_UNIT_%s society_ui %s" % ["OK" if ok else "FAIL", "; ".join(errs)])
	exit_code = 0 if ok else 1
	get_tree().quit(exit_code)

func map_has_icons() -> bool:
	for ind in ["cargo_port", "hospital", "school_primary", "school_high", "university", "corp_academy", "pmc_unit"]:
		if not ResourceLoader.exists("res://assets/icons/%s.png" % ind):
			return false
	return true


# JUAN-P47: GUI skuska presuvatelnych okien (skutocne udalosti mysi cez viewport.push_input + screenshot)
func _mouse(btn: bool, pressed: bool, pos: Vector2) -> void:
	var ev
	if btn:
		ev = InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
	else:
		ev = InputEventMouseMotion.new()
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	ev.position = pos
	ev.global_position = pos
	get_viewport().push_input(ev)

func _drag(from: Vector2, to: Vector2) -> void:
	_mouse(false, false, from)
	_mouse(true, true, from)
	for i in 4:
		_mouse(false, false, from.lerp(to, (i + 1) / 4.0))
		await get_tree().process_frame
	_mouse(true, false, to)
	await get_tree().process_frame

func _window_ui() -> void:
	_on_menu_dev()
	for _i in 3:
		await get_tree().process_frame
	win_mgr.persist = false
	win_mgr.rects.clear()
	GameState.config.progression = false
	GameState.player.cash = 5.0e9
	GameState.found_firm("pmc_unit", "", "US")
	var vp = _vp()
	var res = {}
	# 1) country panel: spodny riadok lobingu sa zmesti (aj pri uzkom okne)
	open_country_firms("US")
	for _i in 4:
		await get_tree().process_frame
	var fits = func() -> bool:
		var pr = country_win.get_global_rect()
		for nm in ["LobbyPolitician", "LobbyAmount", "LobbyGo", "ContractPropose"]:
			var c: Control = country_win.find_child(nm, true, false)
			if c == null:
				continue
			var sc: ScrollContainer = country_win.find_child("CountryBody", true, false)
			if c.get_global_rect().end.x > pr.end.x + 0.5 or c.get_global_rect().end.x > sc.get_global_rect().end.x + 0.5:
				return false
		return true
	res["country_row_fits"] = fits.call()
	# 2) presun za titulok
	var p0 = country_win.position
	await _drag(country_win.position + Vector2(60, 16), country_win.position + Vector2(-300, 60))
	res["drag_moves"] = country_win.position.distance_to(p0 + Vector2(-360, 44)) < 2.0
	# 3) zmena velkosti rohom + min velkost + zalomenie v uzkom okne
	var s0 = country_win.size
	var corner = country_win.position + country_win.size - Vector2(3, 3)
	await _drag(corner, corner + Vector2(-140, -120))
	for _i in 3:
		await get_tree().process_frame
	res["resize_corner"] = absf(country_win.size.x - (s0.x - 140.0)) < 2.0 and absf(country_win.size.y - (s0.y - 120.0)) < 2.0
	res["narrow_row_fits"] = fits.call()
	var c2 = country_win.position + country_win.size - Vector2(3, 3)
	await _drag(c2, c2 - Vector2(900, 900))
	res["min_size"] = country_win.size.x >= 339.0 and country_win.size.y >= 219.0
	# 4) orezanie na obrazovku
	await _drag(country_win.position + Vector2(40, 16), Vector2(vp.x + 500, vp.y + 500))
	var r = country_win.get_global_rect()
	res["clamped"] = r.position.x >= 0.0 and r.position.y >= 0.0 and r.end.x <= vp.x + 0.5 and r.end.y <= vp.y + 0.5
	# 5) pamat podla typu okna (zavriet/otvorit inu krajinu)
	var keep = Rect2(country_win.position, country_win.size)
	country_win.visible = false
	open_country_firms("SK")
	await get_tree().process_frame
	res["remembered"] = Rect2(country_win.position, country_win.size).is_equal_approx(keep)
	var cfgp = "user://ui_windows_test.cfg"
	win_mgr._save_cfg(cfgp, true)
	var r_before = win_mgr.rects.duplicate()
	win_mgr.rects.clear()
	win_mgr._load_cfg(cfgp)
	res["cfg_roundtrip"] = win_mgr.rects.has("country") and Rect2(win_mgr.rects.country).is_equal_approx(Rect2(r_before.country))
	# 6) vsetky okna su registrovane a maju posuvny obsah
	toggle_burza()
	toggle_empire()
	open_city_panel("SK", "Bratislava")
	open_firm_detail(str(GameState.player_firms()[0].id))
	for _i in 4:
		await get_tree().process_frame
	var all_ok = true
	for k in ["firm", "city", "country", "burza", "empire"]:
		var pn: Control = win_mgr.wins.get(k, {}).get("panel", null)
		if pn == null or pn.find_children("*", "ScrollContainer", true, false).is_empty():
			all_ok = false
	res["all_windows"] = all_ok
	toggle_burza()
	toggle_empire()
	close_firm_detail()
	city_panel.visible = false
	win_mgr.rects.clear()
	country_win.visible = false
	open_country_firms("US")
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	var shot = "/workspace/projekt47/preview/p47_windows_country.png"
	img.save_png(shot)
	res["screenshot"] = FileAccess.file_exists(shot) and img.get_width() > 100
	var fails = 0
	for k in res.keys():
		print("P47_UNIT_%s win_%s" % ["OK" if res[k] else "FAIL", k])
		if not res[k]:
			fails += 1
	exit_code = 0 if fails == 0 else 1
	get_tree().quit(exit_code)
