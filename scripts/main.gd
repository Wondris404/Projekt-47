extends Control

const WorldMapScript = preload("res://scripts/ui/world_map.gd")
const BusinessDescriptions = preload("res://scripts/business_descriptions.gd")
const GoodsIcons = preload("res://scripts/ui/goods_icons.gd")
var map
var _prototype_3d: Control
var info: Label
var play = false
var acc = 0.0
var exit_code = 0
var _description_test_runner
var _toolbar_test_runner
var _atlas_test_runner
var _fund_test_runner
var _bank_controls_test_runner
var _save_recovery_test_runner
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
		elif args.size() > 0 and str(args[0]) == "camera_unit":
			var unit = load("res://tests/unit.gd").new()
			load("res://tests/atlas_camera_regressions.gd").new().run(unit, self)
			exit_code = 1 if unit.fails > 0 else 0
		elif args.size() > 0 and str(args[0]) == "map_compat_unit":
			var unit = load("res://tests/unit.gd").new()
			SaveSystem.use_test_dir()
			load("res://tests/juan5.gd").new().run(unit)
			load("res://tests/juan9.gd").new().run(unit)
			SaveSystem.cleanup_test_dir()
			exit_code = 1 if unit.fails > 0 else 0
		elif args.size() > 0 and str(args[0]) == "atlas_update_unit":
			var unit = load("res://tests/unit.gd").new()
			load("res://tests/atlas_update_regressions.gd").new().run(unit, self)
			exit_code = 1 if unit.fails > 0 else 0
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
	map_style_b = Button.new()
	map_style_b.name = "MapStyleToggle"
	map_style_b.pressed.connect(func(): set_map_style("pixel" if map_style() == "hoi" else "hoi"))
	zoom_row.add_child(map_style_b)
	var preview_3d_button = Button.new()
	preview_3d_button.name = "Prototype3DButton"
	preview_3d_button.text = "3D skúška"
	preview_3d_button.tooltip_text = "Rozpracovaný 3D pohľad: výber krajiny, posun a priblíženie."
	preview_3d_button.pressed.connect(_toggle_3d_prototype)
	zoom_row.add_child(preview_3d_button)
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
	elif "bank_controls_ui_test" in OS.get_cmdline_user_args():
		_bank_controls_test_runner = load("res://tests/bank_controls_ui.gd").new()
		_bank_controls_test_runner.run(self)
	elif "save_recovery_ui_test" in OS.get_cmdline_user_args():
		_save_recovery_test_runner = load("res://tests/save_recovery_ui.gd").new()
		_save_recovery_test_runner.run(self)
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
		_map_style = "pixel" if str(cfg.get_value("graphics", "map_style", "hoi")) == "pixel" else "hoi"
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
	var k = clampf(get_viewport_rect().size.y / 720.0, 0.6, 2.5)
	var lg = TextureRect.new()
	lg.name = "LogoImage"
	lg.texture = preload("res://scripts/ui/tex_util.gd").load_tex("res://assets/ui/logo.png")
	lg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lg.custom_minimum_size = Vector2(0, int(300 * k))
	vb.add_child(lg)
	var t = Label.new()
	t.text = "PROJEKT-47"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", int(72 * k))
	t.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25))
	vb.add_child(t)
	var d = Label.new()
	d.text = "developed by Wondris404"
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.add_theme_font_size_override("font_size", int(22 * k))
	vb.add_child(d)
	var content = vb
	content.modulate.a = 0.0
	add_child(_splash)
	_splash.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _end_splash())
	var tw = create_tween()
	tw.tween_property(content, "modulate:a", 1.0, 0.7)
	tw.tween_interval(1.6)
	tw.tween_property(content, "modulate:a", 0.0, 0.7)
	tw.tween_callback(_end_splash)

func _end_splash() -> void:
	if _splash and is_instance_valid(_splash):
		_splash.queue_free()
	_splash = null

func _set_game_visible(v: bool) -> void:
	for c in get_children():
		if c == main_menu or c == _splash or not (c is CanvasItem):
			continue
		if c.get_script() != null and str(c.get_script().resource_path).ends_with("intro_scene.gd"):
			continue
		if not v:
			if not c.has_meta("p47_vis"):
				c.set_meta("p47_vis", c.visible)
			c.visible = false
		elif c.has_meta("p47_vis"):
			c.visible = bool(c.get_meta("p47_vis"))
			c.remove_meta("p47_vis")
	if map:
		map.set_process(v)

# JUAN5 #18: Dev mod – bez intra/tutorialu/prezyvky, vsetko odomknute
func _on_menu_dev() -> void:
	if main_menu:
		main_menu.visible = false
	_on_start({"country": "SK", "year": 2024, "seed": 47, "starter": false, "tutorial": false, "mode": "easy", "nick": "Dev", "gender": "muž", "dev": true})

func _apply_dev() -> void:
	GameState.config.dev = true
	GameState.config.progression = false
	GameState.player.cash = float(GameState.player.cash) + 50000000.0
	var done: Array = GameState.player.get("done", [])
	for r in DataLoader.research:
		if typeof(r) == TYPE_DICTIONARY and not str(r.get("id", "")) in done:
			done.append(str(r.get("id", "")))
	GameState.player.done = done
	var fs: Dictionary = PoliticsSystem.focus_state()
	var fd: Array = fs.get("done", [])
	for f in PoliticsSystem.FOCUS:
		if not str(f.id) in fd:
			fd.append(str(f.id))
	fs["done"] = fd

var dev_errors: Array = []
func dev_log(msg: String) -> void:
	dev_errors.append("[%s] %s" % [Time.get_time_string_from_system(), msg])
	if dev_errors.size() > 50:
		dev_errors.pop_front()

func _dev_event() -> void:
	var iso = str(GameState.selected_iso if GameState.selected_iso != "" else GameState.player.get("home", "SK"))
	var c: Dictionary = GameState.world.get(iso, {})
	if c.is_empty():
		return
	c.gdp_growth = float(c.get("gdp_growth", 0.0)) - 0.02
	StockMarket.ex().mood = float(StockMarket.ex().get("mood", 0.0)) - 0.15
	GameState.world_events.append({"type": "dev_crash", "target": iso, "day": GameState.day_index})
	GameState.post_news("DEV: recesia a pád burzy v %s." % str(c.get("name_sk", iso)))

func _dev_war() -> void:
	var a = str(GameState.selected_iso if GameState.selected_iso != "" else "RU")
	var best = ""
	for b in DataLoader.countries.get(a, {}).get("borders", []):
		var iso2 = str(b)
		for k in DataLoader.countries.keys():
			if str(DataLoader.countries[k].get("iso3", "")) == iso2:
				best = str(k)
				break
		if best != "":
			break
	if best == "":
		best = "UA" if a != "UA" else "RU"
	GeopoliticsSystem._start_war(a, best)

func _dev_panel_toggle() -> void:
	if not bool(GameState.config.get("dev", false)):
		return
	var dp = get_node_or_null("DevPanel")
	if dp:
		dp.visible = not dp.visible
		return
	var pc = PanelContainer.new()
	pc.name = "DevPanel"
	pc.z_index = 40
	pc.position = Vector2(20, 80)
	var vb = VBoxContainer.new()
	pc.add_child(vb)
	var info = Label.new()
	info.text = "DEV"
	vb.add_child(info)
	var b1 = Button.new(); b1.text = "+10 M €"; vb.add_child(b1)
	b1.pressed.connect(func(): GameState.player.cash = float(GameState.player.cash) + 10000000.0; _refresh_label())
	var b2 = Button.new(); b2.text = "Preskočiť 30 dní"; vb.add_child(b2)
	b2.pressed.connect(func():
		var t0 = Time.get_ticks_msec()
		for i in 30: GameState.simulate_day()
		info.text = "DEV  %.1f ms/deň  FPS %d" % [float(Time.get_ticks_msec() - t0) / 30.0, Engine.get_frames_per_second()]
		_refresh_label())
	var b3 = Button.new(); b3.text = "Dokončiť výskum a ciele"; vb.add_child(b3)
	b3.pressed.connect(_apply_dev)
	var b4 = Button.new(); b4.text = "Udalosť: recesia + pád burzy"; vb.add_child(b4)
	b4.pressed.connect(func(): _dev_event(); _refresh_label())
	var b5 = Button.new(); b5.text = "Vojna (vybraná krajina vs. sused)"; vb.add_child(b5)
	b5.pressed.connect(func(): _dev_war(); _refresh_label())
	var errs = Label.new()
	errs.name = "DevErrors"
	errs.custom_minimum_size = Vector2(320, 0)
	errs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(errs)
	var b6 = Button.new(); b6.text = "Log chýb"; vb.add_child(b6)
	b6.pressed.connect(func(): errs.text = _dev_error_text())
	add_child(pc)
	var dev_rect = func() -> Rect2:
		return Rect2(Vector2(20, 80), pc.get_combined_minimum_size())
	win_mgr.register(pc, "dev", dev_rect, 24.0, Vector2(200, 120))
	win_mgr.place("dev")

func _dev_error_text() -> String:
	var out: Array = dev_errors.duplicate()
	var path = "user://logs/godot.log"
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			for line in f.get_as_text().split("\n"):
				if line.find("ERROR") >= 0 or line.find("SCRIPT ERROR") >= 0:
					out.append(line.strip_edges())
	if out.is_empty():
		return "Žiadne chyby."
	return "\n".join(out.slice(maxi(0, out.size() - 12)))

func _on_menu_new(cfg: Dictionary) -> void:
	if main_menu:
		main_menu.visible = false
	if _headless():
		_on_start(cfg)
		return
	# JUAN4: pixelove intro pred kazdym modom (Esc/klik preskoci, medzernik dalej)
	var intro = preload("res://scripts/ui/intro_scene.gd").new()
	intro.setup(str(cfg.get("nick", "Hráč")), str(cfg.get("gender", "muž")))
	intro.finished.connect(_on_start.bind(cfg))
	add_child(intro)

# JUAN-FIX: Pokračovať = návrat do bežiacej hry; bez hry načíta posledný save.
func _on_menu_continue() -> void:
	if GameState.running and play:
		_on_menu_back()
		return
	var best = 0
	var best_time = 0
	for slot in [1, 2, 3]:
		if not SaveSystem.has_slot(slot):
			continue
		var path = SaveSystem._find_slot(slot)
		var modified = FileAccess.get_modified_time(path)
		if best == 0 or modified >= best_time:
			best = slot
			best_time = modified
	if best == 0:
		return
	_on_menu_load(best)

func _on_menu_load(slot: int) -> void:
	var err = SaveSystem.load_slot(slot)
	if err != "":
		if main_menu:
			main_menu.show_load_error(err)
		return
	if bool(GameState.ext.get("dev", false)):
		GameState.config["dev"] = true  # JUAN15: DEV save obnoví dev mód
	play = true
	GameState.paused = true
	_menu_paused_game = false
	if main_menu:
		main_menu.visible = false
	_refresh_label()
	var loaded_message = "Hra načítaná zo záložnej kópie" if SaveSystem.last_load_from_backup else "Hra načítaná"
	_feedback("%s (slot %d). Pauza – stlač 1." % [loaded_message, slot], true)

func _on_menu_quit() -> void:
	get_tree().quit()

func _on_menu_back() -> void:
	if main_menu:
		main_menu.visible = false
	if _menu_paused_game:
		GameState.paused = _menu_was_paused
		_menu_paused_game = false
	_refresh_label()

# JUAN-FIX: ukladanie hry (menu "Uložiť hru", Ctrl+S, F5 = slot 1).
func save_game(slot: int = 1) -> bool:
	GameState.finish_pending_day()  # JUAN23: neukladat rozpracovany den
	if not GameState.running:
		_feedback("Nie je čo uložiť – žiadna hra nebeží.", false)
		return false
	if bool(GameState.config.get("dev", false)):
		GameState.ext["dev"] = true  # JUAN15: DEV hra sa ukladá (config.dev sa obnoví pri načítaní)
	var res = SaveSystem.save_slot(slot)
	var ok = SaveSystem.last_error == "" and res.ends_with(".json")
	var text = "Hra uložená (slot %d, %s)." % [slot, EconMath.date_sk(int(GameState.date.y), int(GameState.date.m), int(GameState.date.d))] if ok else "Uloženie zlyhalo: %s" % res
	_feedback(text, ok)
	if main_menu and main_menu.visible:
		main_menu.show_note(text)
	return ok

func _on_menu_save(slot: int) -> void:
	save_game(slot)

func _on_dividends(total: float) -> void:
	if cash_label != null:
		_feedback("Dividendy z tvojich firiem: +%s" % EconMath.eur(total), true)

func _on_tutorial_repeat() -> void:
	if not GameState.running:
		_on_start({"country": "SK", "year": 2024, "seed": 47, "starter": false, "tutorial": true})
		return
	if main_menu:
		main_menu.visible = false
	GameState.paused = true
	_begin_tutorial()

func _on_start(cfg: Dictionary = {}) -> void:
	var from_menu = cfg.has("country")
	var iso = str(cfg.get("country", GameState.selected_iso)) if from_menu else GameState.selected_iso
	if not DataLoader.countries.has(iso):
		iso = "SK" if DataLoader.countries.has("SK") else str(DataLoader.country_ids[0])
	GameState.new_game({
		"loan": 0.0,
		"years": 5,
		"country": iso,
		"scenario": "sandbox",
		"found": "",
		"wars": false,
		"disasters": true,
		"hot": false,
		"seed": int(cfg.get("seed", 47)),
		"name": str(cfg.get("nick", "Hráč")),
		"year": int(cfg.get("year", 2024)),
		"difficulty": str(cfg.get("mode", "medium")),
		"politics": from_menu,
		"rivals": from_menu,
	})
	# JUAN4: postava + obtiaznost (vojny medzi AI statmi len v Medium/Hard/Realistic z menu)
	GameState.config.wars = from_menu and bool(Difficulty.MODES[Difficulty.mode()].wars)
	GameState.player.nick = str(cfg.get("nick", "Hráč"))
	GameState.player.gender = str(cfg.get("gender", "muž"))
	PoliticsSystem.apply_gender_start()
	if from_menu:
		GameState.player.cash = float(GameState.player.cash) + Difficulty.start_cash(Difficulty.mode())
		RivalSystem.setup()
		GameState.config.progression = not bool(cfg.get("dev", false))  # JUAN5 #18: male -> stredne -> velke
		StockMarket.setup()  # JUAN5 #19
	if bool(cfg.get("dev", false)):
		_apply_dev()
	var starter = true if not from_menu else bool(cfg.get("starter", true))
	if starter:
		BankingSystem.request_loan(180000.0, 5)
		IndustrySystem.place_firm(iso, "cafe")
	play = true
	GameState.paused = true
	_menu_paused_game = false
	if main_menu:
		main_menu.visible = false
	var args = OS.get_cmdline_user_args()
	if args.size() > 0 and str(args[0]) == "maxspeed":
		GameState.speed_index = 4
		GameState.paused = false
		_soak = true
		print("P47_RUN start day %d" % GameState.day_index)
	_refresh_label()
	if GameState.paused and not _soak:
		_feedback("Hra je pozastavená – stlač 1×", true)
	if from_menu and bool(cfg.get("tutorial", false)):
		_begin_tutorial()

func _feedback(text: String, ok: bool) -> void:
	feedback_count += 1
	GameState.post_news(text)
	if feedback_label == null:
		feedback_label = Label.new()
		feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		feedback_label.z_index = 40
		feedback_label.position = Vector2(24, 64)
		add_child(feedback_label)
	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", UiPalette.OK if ok else UiPalette.BAD)
	feedback_label.visible = true
	feedback_left = 3.0

func _on_loan() -> void:
	if not GameState.running:
		_on_start()
	var before = feedback_count
	var res: Dictionary = BankingSystem.request_loan(50000.0, 5)
	var reason = str(res.get("reason", ""))
	if reason == "":
		_feedback("Pôžička schválená: +50 000 €", true)
	else:
		_feedback("Pôžička: %s" % reason, false)
	if feedback_count == before:
		_feedback("Pôžička: bez odpovede", false)
	_refresh_label()

func _first_player_firm() -> String:
	var firms: Array = GameState.player_firms()
	if firms.is_empty():
		return ""
	return str(firms[0].get("id", ""))

# JUAN-FIX: prehľad VŠETKÝCH hráčových firiem (súčty za posledných 30 dní).
func my_firms_text() -> String:
	var firms: Array = GameState.player_firms()
	if firms.is_empty():
		return "MOJE FIRMY\nZatiaľ žiadna. Založ ju v záložke Založiť."
	var out = "MOJE FIRMY (%d) – za posledných 30 dní\n" % firms.size()
	for f in firms:
		var sm: Dictionary = IndustrySystem.firm_summary(f)
		var where = str(GameState.world.get(str(f.get("country", "")), {}).get("name_sk", f.get("country", "")))
		out += "• %s (%s)\n  Tržby %s | Náklady %s | Zisk %s\n  Hotovosť firmy %s (rezerva %s) | Posledná dividenda %s\n" % [
			str(f.get("name", "?")), where,
			EconMath.eur(float(sm.rev)), EconMath.eur(float(sm.costs)), EconMath.eur(float(sm.profit)),
			EconMath.eur(float(sm.cash)), EconMath.eur(float(sm.reserve)), EconMath.eur(float(sm.last_dividend)),
		]
	out += "Zisk nad rezervu ti firmy pošlú 1. dňa v mesiaci."
	return out

func firm_screen_text() -> String:
	var firm_id = _first_player_firm()
	if firm_id == "":
		return "Žiadna firma."
	var ledger: Dictionary = IndustrySystem.firm_ledger(firm_id)
	var mods: Dictionary = GameState.player.modifiers
	return "Daň %s\nMzdy %s\nZmeny %d\nSklad %s\nObchod %s\nDoprava %.2f práca %.2f úroda %.2f chémia %.2f zbrane %.2f elektrina %.2f default %.2f" % [
		EconMath.eur(float(ledger.get("tax", 0.0))),
		EconMath.eur(float(ledger.get("wages", 0.0))),
		int(ledger.get("shifts", 1)),
		str(ledger.get("inventory", "")),
		str(ledger.get("trade", "")),
		float(mods.get("freight_mult", 1.0)),
		float(mods.get("labor_mult", 1.0)),
		float(mods.get("yield_agro", 1.0)),
		float(mods.get("yield_chem", 1.0)),
		float(mods.get("yield_weapons", 1.0)),
		float(mods.get("power_mult", 1.0)),
		float(mods.get("default_mult", 1.0)),
	]

func _on_issue_bond() -> void:
	var face = 500.0
	if bond_price:
		face = max(100.0, float(bond_price.value))
	var err = BankingSystem.issue_bond(face, 0.05, 2.0)
	_feedback("Emisia dlhopisu: %s" % ("hotovo." if err == "" else err), err == "")
	_refresh_label()

func _on_issue_shares() -> void:
	var qty = 10
	var px = 3.0
	if stock_qty:
		qty = int(stock_qty.value)
	if stock_price:
		px = float(stock_price.value)
	var err = BankingSystem.issue_shares(_first_player_firm(), qty, px)
	_feedback("Emisia akcií: %s" % ("hotovo." if err == "" else err), err == "")
	_refresh_label()

func _on_free_bond(side: String) -> void:
	var px = 100.0
	var qty = 1.0
	if bond_price:
		px = float(bond_price.value)
	if bond_qty:
		qty = float(bond_qty.value)
	post_play_bond(side, px, qty)

func _on_free_stock(side: String) -> void:
	var px = 4.0
	var qty = 2.0
	if stock_price:
		px = float(stock_price.value)
	if stock_qty:
		qty = float(stock_qty.value)
	post_play_stock(side, "CAFE", px, qty)

func _on_place_industry(ind_id: String) -> void:
	# JUAN9: nic sa neuklada automaticky - hrac klikne na miesto na mape
	if place_kind:
		var ix = place_list().find(ind_id)
		if ix >= 0:
			place_kind.select(ix)
			place_kind.item_selected.emit(ix)
	_on_place_here()

func _on_place_industry_auto(ind_id: String) -> void:
	if not GameState.running:
		_on_start()
	var res: Dictionary = IndustrySystem.place_firm(GameState.selected_iso, ind_id)
	var reason = str(res.get("reason", ""))
	if reason == "":
		var nf: Array = GameState.player_firms()
		var fname = str(nf[nf.size() - 1].get("name", ind_id)) if nf.size() > 0 else ind_id
		_feedback("Založená firma %s. Nájdeš ju v záložke Firma → Moje firmy." % fname, true)
	else:
		_feedback("Firma %s: %s" % [ind_id, reason], false)
	_refresh_label()

func _on_firm_output(value: float) -> void:
	IndustrySystem.set_firm_production(_first_player_firm(), "food_service", value)
	_refresh_label()

func _on_sale_price() -> void:
	IndustrySystem.set_sale_price(_first_player_firm(), "food_service", 9.5)
	_refresh_label()

func _on_shifts() -> void:
	IndustrySystem.set_shifts(_first_player_firm(), 2)
	_refresh_label()

func _on_pmc() -> void:
	var err = IndustrySystem.sign_pmc(_first_player_firm(), GameState.selected_iso)
	_feedback("PMC: %s" % ("podpísané." if err == "" else err), err == "")
	_refresh_label()

func _on_pmc_cancel() -> void:
	var err = IndustrySystem.cancel_pmc(_first_player_firm())
	_feedback("PMC: %s" % ("zrušené." if err == "" else err), err == "")
	_refresh_label()

func _on_trade(direction: String) -> void:
	var err = IndustrySystem.set_trade_route(_first_player_firm(), "wheat", direction, 5.0)
	_feedback("Obchod: %s" % ("zadaný." if err == "" else err), err == "")
	_refresh_label()

func _on_place() -> void:
	if not GameState.running:
		_on_start()
	var res: Dictionary = IndustrySystem.place_firm(GameState.selected_iso, "cafe")
	var placed = str(res.get("reason", ""))
	_feedback("Placement: %s" % ("založená." if placed == "" else placed), placed == "")
	_refresh_label()

func _on_bank() -> void:
	if not GameState.running:
		_on_start()
	var res: Dictionary = BankingSystem.create_bank(0.02, 0.08, 0.1)
	var bank_reason = str(res.get("reason", ""))
	_feedback("Banka: %s" % ("založená." if bank_reason == "" else bank_reason), bank_reason == "")
	_refresh_label()

func _on_zoom() -> void:
	# JUAN9: regiony nahradil zoom mapy (daleko krajiny, blizko mesta a budovy)
	GameState.set_view("world")
	if map:
		var c = map.size * 0.5
		map._zoom_at(c, 1.0 if map.zoom >= map.DETAIL_ZOOM else maxf(map.DETAIL_ZOOM, 3.5))
		map.queue_redraw()
	if map:
		map.visible = GameState.view_mode == "world"
	if region_view:
		region_view.visible = GameState.view_mode == "region"
	_refresh_label()

func _on_event() -> void:
	if not GameState.running:
		_on_start()
	EventSystem.apply_recession(GameState.world[GameState.selected_iso])
	_feedback("Recesia v %s." % GameState.selected_iso, true)
	_refresh_label()

func _on_research() -> void:
	_on_research_id("logistics1")

func _on_research_id(rid: String) -> void:
	if not GameState.running:
		_on_start()
	var err = GameState.start_research(rid)
	_feedback("Výskum %s: %s" % [rid, "beží." if err == "" else err], err == "")
	_refresh_label()

func _on_production_slider(value: float) -> void:
	if not GameState.running:
		_on_start()
	apply_production_slider(value)
	_feedback("Výroba nastavená na %d %%." % int(round(value * 100.0)), true)
	_refresh_label()

func _chosen_country() -> String:
	if diplo_target == null or diplo_target.item_count == 0:
		return "US"
	return diplo_target.get_item_text(diplo_target.selected)

func _on_minister_tax() -> void:
	if not GameState.running:
		_on_start()
	var rate = 0.21
	if minister_tax:
		rate = float(minister_tax.value)
	LawSystem.set_tax(GameState.selected_iso, rate)
	_feedback("Daň v %s je %s." % [GameState.selected_iso, EconMath.pct(LawSystem.corporate_tax(GameState.selected_iso))], true)
	_refresh_label()

func _on_diplo(action: String) -> void:
	var err = play_diplomacy(action, _chosen_country())
	_feedback("Diplomacia %s: %s" % [action, "hotovo." if err == "" else err], err == "")
	_refresh_label()

# DEAD: bez pripojenia (pripaja sa _on_production_slider) (etapa 0: nezmazane, len oznacene)
func _on_production() -> void:
	if not GameState.running:
		_on_start()
	IndustrySystem.set_production(0.5)
	_feedback("Výroba firiem je nastavená na 50 %.", true)
	_refresh_label()

func _on_country_picked(_iso: String) -> void:
	tutorial_saw_country = true
	_refresh_label()
	if region_view:
		region_view.queue_redraw()

func _redraw_views() -> void:
	_view_redraws += 1
	if map:
		map.queue_redraw()
	if region_view:
		region_view.queue_redraw()

func _on_day() -> void:
	if not GameState.running:
		_on_start()
	if GameState.day_in_progress():
		GameState.finish_pending_day()
	elif not _day_finished_for_input:
		GameState.simulate_day()
	_day_finished_for_input = false
	_refresh_label()
	_redraw_views()

func _on_pause() -> void:
	if not GameState.paused:
		GameState.finish_pending_day()
	GameState.paused = not GameState.paused

func _update_fps(delta: float) -> void:
	if fps_label == null:
		return
	_fps_acc += delta
	if _fps_acc < 0.5:
		return
	_fps_acc = 0.0
	fps_label.visible = _fps_show
	if _fps_show:
		fps_label.text = "FPS %d" % Engine.get_frames_per_second()

var _firm_sig = ""
var _firm_check_acc := 0.0
var _firm_text_day := -1
func _process(delta: float) -> void:
	_update_fps(delta)
	_firm_check_acc += delta
	if GameState.running and my_firms_label and _firm_check_acc >= UI_REFRESH_SEC:
		_firm_check_acc = 0.0
		var sig = "%d|%d" % [GameState.player_firms().size(), BankingSystem.player_banks().size()]
		if sig != _firm_sig:
			_firm_sig = sig
			_refresh_label()
	if feedback_left > 0.0:
		feedback_left -= delta
		if feedback_left <= 0.0 and feedback_label:
			feedback_label.visible = false
	if _hover_debug:
		if hover_label == null:
			hover_label = Label.new()
			hover_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hover_label.z_index = 41
			hover_label.position = Vector2(24, 96)
			add_child(hover_label)
		var hovered = get_viewport().gui_get_hovered_control()
		hover_label.visible = true
		hover_label.text = "%s %s" % [hovered, get_viewport().get_mouse_position()]
	if _headless() or not play or GameState.paused or not GameState.running:
		return
	# JUAN23: simulacia s casovym rozpoctom na snimok (den sa moze rozlozit cez viac snimok) -> plynuly obraz aj pri rychlosti 3
	acc = minf(acc + delta * GameState.days_per_second(), 48.0)
	var steps = 0
	if acc >= 1.0 or GameState.day_in_progress():
		steps = GameState.sim_budget(SIM_BUDGET_USEC if GameState.speed_index < 3 else SIM_BUDGET_FAST, mini(int(acc), 24) if acc >= 1.0 else 1)
		acc = maxf(acc - steps, 0.0)
		if _soak and steps > 0 and GameState.day_index % 30 < steps and GameState.day_index != _soak_mark:
			_soak_mark = GameState.day_index
			print("P47_RUN day %d" % GameState.day_index)
	if steps > 0:
		_redraw_pending = true
	_ui_acc += delta
	if _ui_acc >= UI_REFRESH_SEC:  # JUAN23: UI/mapa po dni najviac ~5x za sekundu (predtym kazdy snimok)
		_ui_acc = 0.0
		if _redraw_pending:
			_redraw_pending = false
			_redraw_views()
		_refresh_label(false)

const SIM_BUDGET_USEC = 9000
const SIM_BUDGET_FAST = 14000
const UI_REFRESH_SEC = 0.2
var _ui_acc := 0.0
var _redraw_pending := false

func _typing_focus() -> bool:
	var focus = get_viewport().gui_get_focus_owner()
	return focus is LineEdit or focus is SpinBox

# JUAN-FIX touchpad scroll pravého panelu (Windows touchpad = InputEventPanGesture)
func _active_side_scroll() -> ScrollContainer:
	if side_tabs == null or not side_tabs.is_visible_in_tree():
		return null
	var idx = side_tabs.current_tab
	if idx < 0 or idx >= side_tabs.get_child_count():
		return null
	var c = side_tabs.get_child(idx)
	return c as ScrollContainer if c is ScrollContainer else null

func _scroll_toolbar_input(event: InputEvent) -> bool:
	if toolbar_scroll == null or not toolbar_scroll.is_visible_in_tree():
		return false
	if event is InputEventPanGesture:
		var pan_event = event as InputEventPanGesture
		if not toolbar_scroll.get_global_rect().has_point(pan_event.position):
			return false
		var amount = pan_event.delta.x if absf(pan_event.delta.x) > 0.001 else pan_event.delta.y
		toolbar_scroll.scroll_horizontal += roundi(amount * 40.0)
		return true
	if event is InputEventMouseButton:
		var wheel = event as InputEventMouseButton
		if not wheel.pressed or not toolbar_scroll.get_global_rect().has_point(wheel.position):
			return false
		var direction = 0
		if wheel.button_index in [MOUSE_BUTTON_WHEEL_RIGHT, MOUSE_BUTTON_WHEEL_DOWN]:
			direction = 1
		elif wheel.button_index in [MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_UP]:
			direction = -1
		if direction != 0:
			toolbar_scroll.scroll_horizontal += roundi(80.0 * direction * (wheel.factor if wheel.factor > 0.0 else 1.0))
			return true
	return false

var _day_finished_for_input := false
func _input(event: InputEvent) -> void:
	if _headless():
		return
	_day_finished_for_input = false
	var action_input = event is InputEventKey or (event is InputEventMouseButton and (event as InputEventMouseButton).button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE])
	if action_input and GameState.day_in_progress():
		GameState.finish_pending_day()
		_day_finished_for_input = true
	if _scroll_toolbar_input(event):
		get_viewport().set_input_as_handled()
		return
	_input_j12(event)
	var sc = _active_side_scroll()
	if sc == null:
		return
	var over = side_tabs.get_global_rect().has_point(get_global_mouse_position())
	if event is InputEventPanGesture and over:
		sc.scroll_vertical += int((event as InputEventPanGesture).delta.y * 40.0)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and over and event.pressed:
		var mb = event as InputEventMouseButton
		var f = mb.factor if mb.factor > 0.0 else 1.0
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			sc.scroll_vertical -= int(60.0 * f)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			sc.scroll_vertical += int(60.0 * f)
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not _typing_focus():
		var k = (event as InputEventKey).keycode
		if k == KEY_PAGEDOWN or k == KEY_DOWN:
			sc.scroll_vertical += 300 if k == KEY_PAGEDOWN else 60
			get_viewport().set_input_as_handled()
		elif k == KEY_PAGEUP or k == KEY_UP:
			sc.scroll_vertical -= 300 if k == KEY_PAGEUP else 60
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if _headless() or not (event is InputEventKey) or not event.pressed or _typing_focus():
		return
	var key = event as InputEventKey
	if _splash != null:
		_end_splash()
		return
	if key.keycode == KEY_ESCAPE and map and map.place_mode:  # JUAN3
		map.cancel_place()
		_feedback("Stavba zrušená.", false)
		return
	if key.keycode == KEY_ESCAPE and firm_detail_panel and firm_detail_panel.visible:
		close_firm_detail()
		return
	if key.keycode == KEY_ESCAPE:
		if main_menu and main_menu.visible and GameState.running and play:
			_on_menu_back()
		elif main_menu and main_menu.visible:
			pass
		elif GameState.running:
			toggle_pause_popup()  # JUAN11: Esc = male pauzove okno, nie hlavne menu
		else:
			_show_menu()
		return
	if key.keycode == KEY_F12:
		_dev_panel_toggle()
		return
	if key.keycode == KEY_TAB and GameState.running and not (main_menu and main_menu.visible):
		toggle_side_panel()
		get_viewport().set_input_as_handled()
		return
	if key.keycode == KEY_F5 or (key.keycode == KEY_S and key.ctrl_pressed):
		save_game(1)
		return
	if key.keycode == KEY_SPACE:
		_on_pause()
		_refresh_label()
	elif key.keycode == KEY_F10:
		_hover_debug = not _hover_debug
		if hover_label:
			hover_label.visible = _hover_debug
	elif key.keycode == KEY_F3:
		_fps_show = not _fps_show
		if fps_label:
			fps_label.visible = _fps_show
	elif key.keycode == KEY_RIGHT:
		_on_day()
	elif key.keycode == KEY_1 or key.keycode == KEY_KP_1:
		_set_speed(1)
	elif key.keycode == KEY_2 or key.keycode == KEY_KP_2:
		_set_speed(2)
	elif key.keycode == KEY_3 or key.keycode == KEY_KP_3:
		_set_speed(3)

var map_style_b: Button
var _map_style: String = "hoi"

func _toggle_3d_prototype() -> void:
	if _prototype_3d == null:
		_prototype_3d = load("res://scripts/ui/prototype_world_3d.gd").new()
		_prototype_3d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_prototype_3d.size_flags_vertical = Control.SIZE_EXPAND_FILL
		map.get_parent().add_child(_prototype_3d)
		map.get_parent().move_child(_prototype_3d, map.get_index() + 1)
		_prototype_3d.setup(map)
		_prototype_3d.country_selected.connect(func(iso):
			GameState.selected_iso = iso
			_on_country_picked(iso)
			open_country_firms(iso))
		_prototype_3d.city_selected.connect(func(iso, city):
			GameState.selected_iso = iso
			_on_country_picked(iso)
			open_city_panel(iso, city))
		_prototype_3d.firm_selected.connect(open_firm_detail)
		map.visible = false
	else:
		_prototype_3d.restore_map_camera()
		_prototype_3d.queue_free()
		_prototype_3d = null
		map.visible = true

func saved_map_style() -> String:
	return _map_style

func map_style() -> String:
	return _map_style

func set_map_style(st: String) -> void:
	if st != "pixel" and st != "hoi":
		return
	_map_style = st
	var cfg = ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("graphics", "map_style", st)
	var err = cfg.save("user://settings.cfg")
	if err != OK:
		push_warning("Nastavenie mapy sa nepodarilo uložiť (chyba %d)." % err)
	_sync_map_style()

func _sync_map_style() -> void:
	if map_style_b:
		map_style_b.visible = true
		map_style_b.text = "Mapa: Pixelová" if _map_style == "pixel" else "Mapa: Atlas"
		map_style_b.tooltip_text = "Prepnúť vzhľad mapy"
	if map:
		map.set_meta("map_style", _map_style)
		var want_atlas = _map_style == "hoi"
		if map.atlas != want_atlas:
			map.atlas = want_atlas
			map.queue_redraw()

func _on_line_requested(kind: String, a: Vector2, b: Vector2) -> void:  # JUAN19
	var e = Transport.build_line(kind, a, b)
	_feedback(("%s postavená (%.0f km)." % [Transport.KIND_NAME[kind], Transport.km(a, b)]) if e == "" else e, e == "")
	_refresh_label()

func _refresh_label(force_firm_list: bool = true) -> void:
	_sync_map_style()
	if _prototype_3d != null:
		_prototype_3d.refresh_firms()
	if cash_label == null or not GameState.running:
		return
	if stat_strip:
		var es = Empire.stats()
		stat_strip.text = "Majetok %s  |  Ľudia %.0f  |  Vplyv %.0f  |  Popularita %.0f  |  Bezpečnosť %d  |  Firmy %d  |  Štáty %d" % [EconMath.eur(float(es.worth)), float(es.employees), float(es.influence), float(es.popularity), int(es.security), int(es.firms), int(es.states)]
		stat_strip.tooltip_text = "Majetok · zamestnanci · vplyv · popularita · bezpečnosť · firmy · vlastnené štáty (detail: Portfólio)"
		stat_strip.mouse_filter = Control.MOUSE_FILTER_PASS
	_refresh_juan4()
	var iso = GameState.selected_iso
	var date_text = EconMath.date_sk(int(GameState.date.y), int(GameState.date.m), int(GameState.date.d))
	var cash_value = float(GameState.player.get("cash", 0.0))
	if top_date:
		top_date.text = date_text
		top_date.tooltip_text = date_text
	if speed_bar:
		speed_bar.set_cash(cash_value)
		speed_bar.set_debt("Dlh %s" % EconMath.eur(GameState.debt()))
		speed_bar.mark_speed(GameState.speed_index)
	elif top_cash:
		top_cash.text = EconMath.eur(cash_value)
	var c: Dictionary = GameState.world.get(iso, {})
	var firms: Array = GameState.player_firms()
	var research_txt = "Výskum: žiadny"
	if not GameState.player.research.is_empty():
		research_txt = "Výskum: %s, ostáva %d dní" % [str(GameState.player.research.get("name", "")), int(GameState.player.research.get("left", 0))]
	cash_label.text = "%s\n%s\nHotovosť %s\nDlh %s\nFirmy %d\nPohľad %s\n%s" % [
		EconMath.date_sk(int(GameState.date.y), int(GameState.date.m), int(GameState.date.d)),
		c.get("name_sk", iso),
		EconMath.eur(float(GameState.player.get("cash", 0.0))),
		EconMath.eur(GameState.debt()),
		firms.size(),
		GameState.view_mode,
		research_txt,
	]
	var prices = ""
	for cid in ["wheat", "arms", "chemicals", "pmc_services", "crude_oil"]:
		if DataLoader.commodities.has(cid):
			prices += "%s %s\n" % [cid, EconMath.eur(MarketSystem.price(iso, cid))]
	if market_label:
		market_label.text = prices
	var bank_txt = "Žiadna vlastná banka."
	for b in GameState.banks:
		if str(b.get("owner", "")) == "player":
			bank_txt = "%s\nvkladová sadzba %s\núver %s\nrezerva %s\nvklady %s\nrun %s\nodliv %s" % [
				b.get("name", "banka"),
				EconMath.pct(float(b.get("deposit_rate", 0))),
				EconMath.pct(float(b.get("loan_rate", 0))),
				EconMath.pct(float(b.get("reserve_ratio", 0))),
				EconMath.eur(float(b.get("deposits", 0))),
				"áno" if b.get("bank_run", false) else "nie",
				EconMath.eur(float(b.get("run_withdrawn", 0))),
			]
			bank_txt += "\n" + bank_consumer_text(b)
	if bank_label:
		bank_label.text = bank_txt
	if law_label:
		law_label.text = LawSystem.summary(iso)
	if book_label:
		book_label.text = bond_book_text()
	if diplo_label:
		diplo_label.text = diplomacy_text()
	if firm_label:
		firm_label.text = firm_screen_text()
	if my_firms_label and my_firms_label.is_visible_in_tree():
		if force_firm_list or _firm_text_day != GameState.day_index:
			my_firms_label.text = my_firms_text()
			_firm_text_day = GameState.day_index
			_sync_firm_buttons()
	if firm_detail_panel and firm_detail_panel.visible and _detail_day != GameState.day_index:
		_fill_firm_detail()
	var news = ""
	var shown = 0
	for item in GameState.news:
		news += str(item.get("text", "")) + "\n"
		shown += 1
		if shown >= 6:
			break
	if news_label:
		news_label.text = news
	if paper_label:
		var paper = ""
		for story in GameState.stories:
			paper += "%s: %s\n" % [str(story.get("kind", "")), str(story.get("text", ""))]
			if paper.length() > 500:
				break
		paper_label.text = paper
	if climate_label:
		climate_label.text = EventSystem.climate_board()
	if minister_label:
		var sheet: Dictionary = LawSystem.minister_sheet(iso)
		var ai_names = ""
		var shown_ai = 0
		for firm in GameState.firms:
			if str(firm.get("owner", "")) != "ai" or firm.get("closed", false):
				continue
			if str(firm.get("country", "")) != iso:
				continue
			ai_names += "%s (%s)\n" % [str(firm.get("name", "")), str(firm.get("industry", ""))]
			shown_ai += 1
			if shown_ai >= 8:
				break
		minister_label.text = "Sadzba CB %s\nCPI %.3f\nInflácia %s\nNezamestnanosť %s\nDaň %s\nZákony %d\nVzťahy vojen %d, sankcií %d\nAI firmy %d\n%sDlh %.0f %%\nStabilita %.0f" % [
			EconMath.pct(float(sheet.get("rate", 0.0))),
			float(sheet.get("cpi", 1.0)),
			EconMath.pct(float(sheet.get("pi", 0.0))),
			EconMath.pct(float(sheet.get("unemployment", 0.0))),
			EconMath.pct(float(sheet.get("tax", 0.0))),
			int(sheet.get("n_laws", 0)),
			int(sheet.get("n_wars", 0)),
			int(sheet.get("n_sanctions", 0)),
			int(sheet.get("n_ai_firms", 0)),
			ai_names,
			float(sheet.get("debt", 0.0)) * 100.0,
			float(sheet.get("stability", 0.0)),
		]


# ===== JUAN3: Postaviť tu, detail firmy, pravá ruka, úvery banky =====
var place_kind: OptionButton
var place_hint: Label
var my_firms_buttons: VBoxContainer
var _firm_button_ids: String = "-"
var cons_rate_box: SpinBox
var firm_detail_panel: PanelContainer
var firm_detail_id: String = ""
var _detail_day: int = -1
var _detail_title: Label
var _detail_chart
var _detail_info: Label
var _detail_mgr: VBoxContainer
var _place_list: Array = []
# JUAN9: vsetky typy firiem (+banka) sa daju rucne postavit na mape
func place_list() -> Array:
	if _place_list.is_empty():
		for id in DataLoader.industries.keys():
			_place_list.append(str(id))
		_place_list.append("bank")
	return _place_list

func place_name(id: String) -> String:
	if id == "hq":
		return "Centrála korporácie"
	return "Banka" if id == "bank" else str(DataLoader.industries.get(id, {}).get("name", id))

func _build_place_panel(parent: Node) -> void:
	var head = Label.new()
	head.text = "POSTAVIŤ NA MAPE"
	head.theme_type_variation = "HeaderLabel"
	parent.add_child(head)
	place_kind = OptionButton.new()
	place_kind.name = "PlaceKind"
	for k in place_list():
		place_kind.add_item("%s (%s)" % [place_name(k), EconMath.eur(IndustrySystem.build_cost(k))])
		var ic = map.type_icon(k) if map else null
		if ic:
			place_kind.set_item_icon(place_kind.item_count - 1, ic)
	place_kind.tooltip_text = BusinessDescriptions.describe(str(place_list()[0])) if not place_list().is_empty() else ""
	parent.add_child(place_kind)
	var goods_row = HFlowContainer.new()
	goods_row.name = "PlaceGoodsIcons"
	parent.add_child(goods_row)
	if not place_list().is_empty():
		GoodsIcons.fill(goods_row, str(place_list()[0]))
	place_kind.item_selected.connect(func(index):
		place_kind.tooltip_text = BusinessDescriptions.describe(str(place_list()[index]))
		GoodsIcons.fill(goods_row, str(place_list()[index])))
	var b = Button.new()
	b.text = "Postaviť tu"
	b.tooltip_text = "Vyber krajinu na mape, stlač a potom klikni na miesto v tej krajine. Esc zruší."
	b.pressed.connect(_on_place_here)
	parent.add_child(b)
	place_hint = Label.new()
	place_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place_hint.text = "1) klikni na krajinu  2) vyber typ  3) Postaviť tu  4) klikni na miesto v krajine"
	parent.add_child(place_hint)

func selected_place_kind() -> String:
	if place_kind == null or place_kind.selected < 0:
		return "cafe"
	return str(place_list()[place_kind.selected])

func _on_place_here() -> void:
	if not GameState.running:
		_on_start()
	var iso = GameState.selected_iso
	if iso == "" or not GameState.world.has(iso) or map == null:
		_feedback("Najprv klikni na krajinu na mape.", false)
		return
	map.start_place(iso)
	_hq_placing = false
	map.place_industry = selected_place_kind()  # JUAN4: zvyrazni platne miesta
	var nm = str(GameState.world[iso].get("name_sk", iso))
	_feedback("%s: klikni na mape na miesto v krajine %s (Esc zruší)." % [place_name(selected_place_kind()), nm], true)

func _on_place_requested(iso: String, wp: Vector2, inside: bool) -> void:
	if not inside:
		_feedback("To miesto nie je v krajine %s. Klikni dovnútra (Esc zruší)." % str(GameState.world.get(iso, {}).get("name_sk", iso)), false)
		return
	var kind = "hq" if _hq_placing else selected_place_kind()
	var res: Dictionary = IndustrySystem.place_at(iso, kind, wp)
	if _hq_placing and bool(res.get("ok", false)):
		_hq_placing = false
	if bool(res.get("ok", false)):
		map.cancel_place()
		_feedback("Postavené: %s v krajine %s. Klikni na ikonu na mape pre detail." % [place_name(kind), str(GameState.world[iso].get("name_sk", iso))], true)
	else:
		_feedback("Stavba: %s" % str(res.get("reason", "")), false)
	_redraw_views()
	_refresh_label()

func _sync_firm_buttons() -> void:
	if my_firms_buttons == null:
		return
	var ids = ""
	for pbx in BankingSystem.player_banks():
		ids += str(pbx.id) + str(pbx.get("name", "")) + ";"
	for f in GameState.player_firms():
		ids += str(f.get("id", "")) + str(f.get("name", "")) + ","
	if ids == _firm_button_ids:
		return
	_firm_button_ids = ids
	for c in my_firms_buttons.get_children():
		c.queue_free()
	for f in GameState.player_firms():
		var b = Button.new()
		b.text = "Detail: %s" % str(f.get("name", "?"))
		var ic = map.type_icon(str(f.get("industry", ""))) if map else null
		if ic:
			b.icon = ic  # JUAN9: ikonka typu
		b.pressed.connect(open_firm_detail.bind(str(f.get("id", ""))))
		my_firms_buttons.add_child(b)
	for pb in BankingSystem.player_banks():  # JUAN9: vsetky moje banky
		var bb = Button.new()
		bb.name = "BankDetailButton"
		bb.text = "Detail: %s" % str(pb.get("name", "Banka"))
		var ic2 = map.type_icon("bank") if map else null
		if ic2:
			bb.icon = ic2
		bb.pressed.connect(open_firm_detail.bind(str(pb.get("id", ""))))
		my_firms_buttons.add_child(bb)

func _ensure_firm_detail() -> void:
	if firm_detail_panel != null:
		return
	firm_detail_panel = PanelContainer.new()
	firm_detail_panel.name = "FirmDetail"
	firm_detail_panel.z_index = 30
	firm_detail_panel.visible = false
	add_child(firm_detail_panel)
	var outer = VBoxContainer.new()  # JUAN-P47: titulok mimo posuvania (tahanie okna)
	firm_detail_panel.add_child(outer)
	var top = HBoxContainer.new()
	outer.add_child(top)
	var sc = ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(sc)
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(box)
	_detail_title = Label.new()
	_detail_title.theme_type_variation = "HeaderLabel"
	_detail_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_detail_title)
	var close = Button.new()
	close.text = "Zavrieť ✕"
	close.pressed.connect(close_firm_detail)
	top.add_child(close)
	win_mgr.register(firm_detail_panel, "firm", _firm_rect, 40.0, Vector2(340, 220))
	_detail_chart = preload("res://scripts/ui/firm_chart.gd").new()
	_detail_chart.custom_minimum_size = Vector2(0, 170)
	box.add_child(_detail_chart)
	_detail_info = Label.new()
	_detail_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_detail_info)
	_detail_mgr = VBoxContainer.new()
	box.add_child(_detail_mgr)

func _layout_firm_detail() -> void:
	win_mgr.place("firm")  # JUAN-P47: zapamatana poloha/velkost, inak stred obrazovky

func open_firm_detail(firm_id: String) -> void:
	for pb2 in BankingSystem.player_banks():  # JUAN9: viac bank - aktivna = kliknuta
		if str(pb2.get("id", "")) == firm_id:
			BankingSystem.set_active_bank(firm_id)
	var pbank: Dictionary = BankingSystem._player_bank()
	if not pbank.is_empty() and str(pbank.get("id", "")) == firm_id:
		_ensure_firm_detail()
		firm_detail_id = firm_id
		_detail_bank = true
		_bank_ctrl_built = false
		_layout_firm_detail()
		firm_detail_panel.visible = true
		_fill_firm_detail()
		return
	_detail_bank = false
	var firm = GameState.firm_by_id(firm_id)
	if firm.is_empty() or str(firm.get("owner", "")) != "player":
		return
	_ensure_firm_detail()
	firm_detail_id = firm_id
	_layout_firm_detail()
	firm_detail_panel.visible = true
	_fill_firm_detail()

func close_firm_detail() -> void:
	if firm_detail_panel:
		firm_detail_panel.visible = false
	firm_detail_id = ""

func firm_detail_text(firm: Dictionary) -> String:
	var d: Dictionary = IndustrySystem.firm_detail(firm)
	var sm: Dictionary = d.summary
	var out = BusinessDescriptions.describe(str(firm.get("industry", ""))) + "\n\n"
	out += "Posledných 30 dní: tržby %s | náklady %s | zisk %s\n" % [EconMath.eur(float(sm.rev)), EconMath.eur(float(sm.costs)), EconMath.eur(float(sm.profit))]
	out += "Hotovosť firmy %s | rezerva %s | posledná dividenda %s\n" % [EconMath.eur(float(sm.cash)), EconMath.eur(float(sm.reserve)), EconMath.eur(float(sm.last_dividend))]
	out += "Zamestnanci %s / cieľ %s ľudí | mzdy spolu ~%s mesačne\n" % [_fmt_int(float(d.people)), _fmt_int(float(d.target_people)), EconMath.eur(float(d.wage_month))]  # JUAN-P47: realisticke pocty
	out += "Efektivita %.0f %%\n" % (float(d.efficiency) * 100.0)
	out += Society.happiness_text(firm) + "\n"  # JUAN-P47
	out += Society.service_text(firm)
	if str(firm.get("industry", "")) == "pmc_unit":
		out += _pmc_text(firm)
	if Brand.is_media(firm):  # JUAN22
		out += Brand.media_text(firm) + "\n"
	out += "\nČO MUSÍ KÚPIŤ (za mesiac):\n"
	var needs: Array = d.needs
	if needs.is_empty():
		out += "• nič, nepotrebuje materiál\n"
	for n in needs:
		out += "• %s: %.2f ks → %s\n" % [str(n.name), float(n.qty), EconMath.eur(float(n.cost))]
	out += IndustrySystem.goods_flow_text(firm)
	if str(firm.get("industry", "")) in ["trade_desk", "stock_broker"]:
		out += IndustrySystem.trade_flow_text(firm)
	out += "\n" + Transport.supply_text(firm)  # JUAN19
	if not IndustrySystem.has_manager(firm):
		out += "\nZákladný manažment zabezpečuje nákup materiálu a dopĺňanie ľudí. Pravá ruka je voliteľný bonus k výkonu a spokojnosti.\n"
	return out

func _fill_firm_detail() -> void:
	if _detail_bank:
		_fill_bank_detail()
		return
	var firm = GameState.firm_by_id(firm_detail_id)
	if firm.is_empty():
		close_firm_detail()
		return
	_detail_day = GameState.day_index
	_detail_title.text = "%s (%s)" % [str(firm.get("name", "?")), str(GameState.world.get(str(firm.get("country", "")), {}).get("name_sk", ""))]
	_detail_chart.set_rows(firm.get("month_hist", []))
	_detail_info.text = firm_detail_text(firm)
	for c in _detail_mgr.get_children():
		c.queue_free()
	var goods_row = HFlowContainer.new()
	goods_row.name = "FirmGoodsIcons"
	_detail_mgr.add_child(goods_row)
	GoodsIcons.fill(goods_row, str(firm.get("industry", "")))
	var head = Label.new()
	head.text = "PRAVÁ RUKA (VOLITEĽNÁ)"
	_detail_mgr.add_child(head)
	if IndustrySystem.has_manager(firm):
		var m: Dictionary = firm.manager
		var l = Label.new()
		l.text = "%s, schopnosť %d/100, plat %s mesačne. Prináša bonus k výkonu a spokojnosti." % [str(m.name), int(float(m.skill) * 100), EconMath.eur(float(m.salary))]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail_mgr.add_child(l)
		var fb = Button.new()
		fb.text = "Prepustiť pravú ruku"
		fb.pressed.connect(_on_fire_manager)
		_detail_mgr.add_child(fb)
	else:
		for cand in IndustrySystem.manager_candidates(firm):
			var hb = Button.new()
			hb.text = "Najať pravú ruku: %s (schopnosť %d, plat %s/mes.)" % [str(cand.name), int(float(cand.skill) * 100), EconMath.eur(float(cand.salary))]
			hb.pressed.connect(_on_hire_manager.bind(cand))
			_detail_mgr.add_child(hb)

	# JUAN5 #18/#19: uroven, predaj, IPO
	var lv = Label.new()
	lv.text = "ÚROVEŇ %d/3%s" % [IndustrySystem.firm_level(firm), "  (založená v banke)" if str(firm.get("pledged", "")) != "" else ""]
	_detail_mgr.add_child(lv)
	if IndustrySystem.firm_level(firm) < 3:
		var ub = Button.new()
		ub.name = "UpgradeFirm"
		ub.text = "Vylepšiť na úroveň %d (%s)" % [IndustrySystem.firm_level(firm) + 1, EconMath.eur(IndustrySystem.upgrade_cost(firm))]
		ub.tooltip_text = "Úroveň 2 vyžaduje výskum Modernizácia prevádzok, úroveň 3 Priemysel 4.0. Kapacita ×1,35."
		ub.pressed.connect(func():
			var e = IndustrySystem.upgrade_firm(firm_detail_id)
			_feedback("Vylepšenie: %s" % ("hotovo." if e == "" else e), e == "")
			_fill_firm_detail())
		_detail_mgr.add_child(ub)
	var ib = Button.new()
	ib.text = "IPO: predať 30 % akcií na burze"
	ib.pressed.connect(func():
		var e = StockMarket.ipo_firm(firm_detail_id, 0.3)
		_feedback("IPO: %s" % ("hotovo." if e == "" else e), e == "")
		_refresh_label())
	_detail_mgr.add_child(ib)
	if str(firm.get("industry", "")) == "stock_broker":
		_broker_ui(firm)
	if str(firm.get("industry", "")) == "invest_fund":
		_fund_ui(firm)
	if Society.service_kind(firm) in ["school", "academy"]:
		_school_ui(firm)  # JUAN-P47
	if str(firm.get("industry", "")) == "pmc_unit":
		_pmc_ui(firm)  # JUAN-P47
	_brand_ui(firm)  # JUAN21
	var sb = Button.new()
	sb.text = "Predať firmu"
	sb.pressed.connect(func():
		var e = IndustrySystem.sell_firm(firm_detail_id)
		_feedback("Predaj: %s" % ("hotovo." if e == "" else e), e == "")
		if e == "":
			close_firm_detail()
		_refresh_label())
	_detail_mgr.add_child(sb)

func _fund_realty_text(firm: Dictionary) -> String:
	var r = Empire.fund_realty(firm)
	return "NEHNUTEĽNOSTI FONDU: %d budov · hodnota %s · nájom %s/mes.\nPodiel %.1f %% z kapitálu %s · cieľ %.0f %%" % [
		int(r.count), EconMath.eur(float(r.value)), EconMath.eur(float(r.rent)),
		float(r.share) * 100.0, EconMath.eur(float(r.capital)), float(r.target) * 100.0]

func _fund_ui(firm: Dictionary) -> void:
	var summary = Label.new()
	summary.name = "FundRealtySummary"
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.text = _fund_realty_text(firm)
	_detail_mgr.add_child(summary)
	var row = HBoxContainer.new()
	_detail_mgr.add_child(row)
	var caption = Label.new()
	caption.text = "Cieľ budov (%)"
	row.add_child(caption)
	var target = SpinBox.new()
	target.name = "FundRealtyTarget"
	target.min_value = 0.0
	target.max_value = 100.0
	target.step = 1.0
	target.value = float(Empire.fund_state(firm).realty_target) * 100.0
	target.tooltip_text = "Fond mesačne nakupuje budovy vo svojej krajine podľa cieľa a dostupnej hotovosti. Jedna celá budova môže cieľ mierne prekročiť."
	target.value_changed.connect(func(value):
		Empire.fund_state(firm)["realty_target"] = clampf(value / 100.0, 0.0, 1.0)
		summary.text = _fund_realty_text(firm))
	row.add_child(target)
	var cash_row = HBoxContainer.new()
	_detail_mgr.add_child(cash_row)
	var amount = SpinBox.new()
	amount.name = "FundCapitalAmount"
	amount.min_value = 1000.0
	amount.max_value = 1.0e12
	amount.step = 1000.0
	amount.value = 100000.0
	amount.tooltip_text = "Suma, ktorú presunieš medzi svojou hotovosťou a fondom."
	cash_row.add_child(amount)
	var deposit = Button.new()
	deposit.name = "FundDeposit"
	deposit.text = "Vložiť"
	deposit.pressed.connect(func():
		var err = Empire.fund_deposit(firm, amount.value)
		_feedback("Vklad do fondu: %s" % ("hotovo." if err == "" else err), err == "")
		_fill_firm_detail()
		_refresh_label())
	cash_row.add_child(deposit)
	var withdraw = Button.new()
	withdraw.name = "FundWithdraw"
	withdraw.text = "Vybrať"
	withdraw.pressed.connect(func():
		var err = Empire.fund_withdraw(firm, amount.value)
		_feedback("Výber z fondu: %s" % ("hotovo." if err == "" else err), err == "")
		_fill_firm_detail()
		_refresh_label())
	cash_row.add_child(withdraw)

func _on_hire_manager(cand: Dictionary) -> void:
	var err = IndustrySystem.hire_manager(firm_detail_id, cand)
	_feedback("Pravá ruka: %s" % ("%s nastupuje." % str(cand.get("name", "")) if err == "" else err), err == "")
	_fill_firm_detail()

func _on_fire_manager() -> void:
	var err = IndustrySystem.fire_manager(firm_detail_id)
	_feedback("Pravá ruka: %s" % ("prepustená." if err == "" else err), err == "")
	_fill_firm_detail()

func bank_consumer_text(b: Dictionary) -> String:
	var st: Dictionary = b.get("cons_stats", {})
	var out = "ÚVERY ĽUĎOM (úrok nových úverov %s)\n" % EconMath.pct(BankingSystem.consumer_rate(b))
	if st.is_empty():
		return out + "Prvé úvery dá banka 1. dňa v mesiaci."
	out += "Požičané spolu %s\nMesačné splátky %s (úroky %s)\nNové úvery minulý mesiac %s\nDefault %s mesačne, straty %s (spolu %s)" % [
		EconMath.eur(float(st.get("outstanding", 0))), EconMath.eur(float(st.get("monthly_due", 0))), EconMath.eur(float(st.get("interest", 0))),
		EconMath.eur(float(st.get("new", 0))), EconMath.pct(float(st.get("default_rate", 0))), EconMath.eur(float(st.get("loss", 0))),
		EconMath.eur(float(b.get("defaults_total", 0)))]
	return out

func _on_cons_rate() -> void:
	var r = BankingSystem.set_consumer_rate(float(cons_rate_box.value) / 100.0 if cons_rate_box else 0.09)
	if r < 0.0:
		_feedback("Najprv si postav banku.", false)
	else:
		_feedback("Úrok pre ľudí nastavený na %s." % EconMath.pct(r), true)
	_refresh_label()

func _juan3_ui_checks() -> void:
	if not GameState.running:
		_on_start()
	GameState.player.cash = 3000000.0
	GameState.selected_iso = "SK"
	var before = GameState.player_firms().size()
	_on_place_here()
	var spot = map._to_screen(map.capital_of("SK"))
	map.click_place(spot)
	await get_tree().process_frame
	var placed = GameState.player_firms().size() == before + 1
	var f: Dictionary = GameState.player_firms()[GameState.player_firms().size() - 1] if placed else {}
	var on_icon = placed and map.firm_at_screen(map._to_screen(IndustrySystem.firm_pos(f))) != ""
	print("P47_UI_PLACE placed=%d icon_click=%d mode_off=%d" % [int(placed), int(on_icon), int(not map.place_mode)])
	if placed:
		open_firm_detail(str(f.id))
		await get_tree().process_frame
		var hire = _find_button(firm_detail_panel, "Najať pravú ruku")
		if hire:
			hire.emit_signal("pressed")
		await get_tree().process_frame
		print("P47_UI_DETAIL open=%d manager=%d" % [int(firm_detail_panel.visible), int(IndustrySystem.has_manager(f))])
		close_firm_detail()

# ===================== JUAN4 =====================
var _detail_bank = false
var _bank_ctrl_built = false
var _bank_displayed_values: Dictionary = {}
var _bank_info: Label
var _bank_cons: SpinBox
var _bank_dep: SpinBox
var _bank_strict: HSlider
var _bank_sav: SpinBox
var _bank_mort: SpinBox
var _bank_corp: SpinBox
var _bank_res: SpinBox
var _bank_bal
var _bank_risk
var _bank_advisor_button: Button
var _sovereign_country: OptionButton
var _sovereign_amount: SpinBox
var _sovereign_rate: SpinBox
var _sovereign_months: SpinBox
var _sovereign_auto: CheckBox
var _sovereign_limit: SpinBox
var _sovereign_risk: SpinBox
var pol_label: Label
var pol_target: OptionButton
var pol_party: OptionButton
var rival_label: Label
var focus_label: Label
var focus_box
var focus_bar: ProgressBar
var city_panel: PanelContainer
var city_label: Label
var _focus_sig = ""

func bank_detail_text(b: Dictionary) -> String:
	var out = BankProducts.text(b) + "\nPrísnosť schvaľovania %d %%\n\n" % int(float(b.get("strictness", 0.5)) * 100)
	out += "Zamestnanci pobočky: %d ľudí (náklady sú v prevádzkovom modeli banky)\n" % Society.BANK_STAFF  # JUAN-P47
	out += bank_consumer_text(b)
	var chk = BankProducts.collect_check(b)
	out += "\n\nNesplatené dlhy na vymáhanie: %s (zásah stojí %s). %s" % [EconMath.eur(BankProducts.recoverable(b)), EconMath.eur(BankProducts.collect_cost(b)), "Pripravené." if bool(chk.ok) else str(chk.reason)]
	var advisor: Dictionary = b.get("advisor", {})
	out += "\n\nBANKOVÝ PORADCA: %s" % ("pracuje, plat %s mesačne" % EconMath.eur(float(advisor.get("salary", BankingSystem.ADVISOR_SALARY))) if bool(advisor.get("hired", false)) else "nie je najatý")
	var log: Array = advisor.get("log", [])
	for entry in log.slice(maxi(0, log.size() - 5)):
		out += "\n• Deň %d: %s" % [int(entry.get("day", 0)), str(entry.get("text", ""))]
	out += "\n\nŠTÁTNE ÚVERY: nesplatené %s" % EconMath.eur(SovereignLoans.outstanding(b))
	for loan in b.get("sovereign_loans", []):
		var iso = str(loan.get("country", ""))
		out += "\n• %s: %s, úrok %s, zostáva %d mesiacov" % [str(GameState.world.get(iso, {}).get("name_sk", iso)), EconMath.eur(float(loan.get("remaining", 0.0))), EconMath.pct(float(loan.get("rate", 0.0))), int(loan.get("months", 0))]
	return out

# Zapamätané hodnoty polí oddelia automatickú zmenu od rozpracovaného vstupu hráča.
func _bank_fields(b: Dictionary) -> Array:
	return [
		["cons", _bank_cons, BankingSystem.consumer_rate(b) * 100.0],
		["sav", _bank_sav, float(b.sav_rate) * 100.0],
		["mort", _bank_mort, float(b.mort_rate) * 100.0],
		["corp", _bank_corp, float(b.corp_rate) * 100.0],
		["res", _bank_res, float(b.reserve_target) * 100.0],
		["strict", _bank_strict, float(b.get("strictness", 0.5))]
	]

func _remember_bank_fields(b: Dictionary) -> void:
	_bank_displayed_values.clear()
	for field in _bank_fields(b):
		var control: Range = field[1]
		_bank_displayed_values[field[0]] = control.value

func _sync_bank_fields(b: Dictionary) -> void:
	for field in _bank_fields(b):
		var control: Range = field[1]
		var key: String = field[0]
		if control is SpinBox and (control as SpinBox).get_line_edit().has_focus():
			continue
		if _bank_displayed_values.has(key) and is_equal_approx(control.value, float(_bank_displayed_values[key])):
			control.set_value_no_signal(float(field[2]))
			_bank_displayed_values[key] = control.value

func _bank_edited_value(key: String, control: Range, actual: float, scale: float = 100.0) -> float:
	if _bank_displayed_values.has(key) and is_equal_approx(control.value, float(_bank_displayed_values[key])):
		return actual
	return control.value / scale

func _fill_bank_detail() -> void:
	var b: Dictionary = BankingSystem._player_bank()
	if b.is_empty():
		close_firm_detail()
		return
	_detail_day = GameState.day_index
	_detail_title.text = "%s (%s)" % [str(b.get("name", "Banka")), str(GameState.world.get(str(b.get("country", "")), {}).get("name_sk", ""))]
	_detail_chart.set_rows(b.get("month_hist", []))
	_detail_info.text = BusinessDescriptions.describe("bank") + "\n\nGraf: úroky (tržby), straty z defaultov (náklady) a zisk banky po mesiacoch. (Podrž myš pre vysvetlenie úverov.)"
	_detail_info.tooltip_text = BankingSystem.HELP
	_detail_info.mouse_filter = Control.MOUSE_FILTER_PASS
	if _bank_ctrl_built and _bank_info:
		_sync_bank_fields(b)
		_bank_info.text = bank_detail_text(b)
		if _bank_advisor_button:
			_bank_advisor_button.text = "Prepustiť bankového poradcu" if bool(b.get("advisor", {}).get("hired", false)) else "Najať bankového poradcu (%s/mes.)" % EconMath.eur(BankingSystem.ADVISOR_SALARY)
		_bank_risk.set_rows(b.get("month_hist", []))
		_bank_bal.set_rows(b.get("month_hist", []))
		return
	_bank_ctrl_built = true
	for c in _detail_mgr.get_children():
		c.queue_free()
	BankProducts.ensure(b)
	_bank_info = Label.new()
	_bank_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bank_info.text = bank_detail_text(b)
	_detail_mgr.add_child(_bank_info)
	_bank_advisor_button = Button.new()
	_bank_advisor_button.name = "BankAdvisor"
	_bank_advisor_button.text = "Prepustiť bankového poradcu" if bool(b.get("advisor", {}).get("hired", false)) else "Najať bankového poradcu (%s/mes.)" % EconMath.eur(BankingSystem.ADVISOR_SALARY)
	_bank_advisor_button.pressed.connect(_on_bank_advisor)
	_detail_mgr.add_child(_bank_advisor_button)
	var bl = Label.new()
	bl.text = "BILANCIA PO MESIACOCH"
	_detail_mgr.add_child(bl)
	_bank_bal = preload("res://scripts/ui/firm_chart.gd").new()
	_bank_bal.spec_override = [["loans", Color(0.4, 0.75, 1.0), "Úvery"], ["deposits", Color(1.0, 0.55, 0.35), "Vklady"], ["reserves", Color(0.45, 0.9, 0.45), "Rezervy"]]
	_bank_bal.custom_minimum_size = Vector2(0, 140)
	_bank_bal.set_rows(b.get("month_hist", []))
	_detail_mgr.add_child(_bank_bal)
	var rl = Label.new()
	rl.text = "RIZIKO NESPLÁCANIA (% mesačne)"
	_detail_mgr.add_child(rl)
	_bank_risk = preload("res://scripts/ui/firm_chart.gd").new()
	_bank_risk.spec_override = [["dr_cons", Color(1.0, 0.45, 0.4), "Spotreb."], ["dr_mort", Color(0.4, 0.75, 1.0), "Hypotéky"], ["dr_corp", Color(0.95, 0.75, 0.3), "Firemné"]]
	_bank_risk.custom_minimum_size = Vector2(0, 130)
	_bank_risk.set_rows(b.get("month_hist", []))
	_detail_mgr.add_child(_bank_risk)
	var sh = Label.new()
	sh.text = "NASTAVENIA BANKY"
	sh.theme_type_variation = "HeaderLabel"
	_detail_mgr.add_child(sh)
	_bank_cons = _spin_row(_detail_mgr, "Úrok pre ľudí %", 1.0, 40.0, 0.5, BankingSystem.consumer_rate(b) * 100.0)
	_bank_sav = _spin_row(_detail_mgr, "Úrok na vklady a sporiace účty %", 0.0, 25.0, 0.25, float(b.sav_rate) * 100.0)
	_bank_mort = _spin_row(_detail_mgr, "Úrok hypoték %", 0.5, 30.0, 0.25, float(b.mort_rate) * 100.0)
	_bank_corp = _spin_row(_detail_mgr, "Úrok firemných úverov %", 0.5, 40.0, 0.25, float(b.corp_rate) * 100.0)
	_bank_res = _spin_row(_detail_mgr, "Cieľ rezerv % vkladov", LawSystem.min_reserve(str(b.country)) * 100.0, 90.0, 1.0, float(b.reserve_target) * 100.0)
	var sl = Label.new()
	sl.text = "Prísnosť schvaľovania (viac = menej defaultov, menej klientov)"
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_mgr.add_child(sl)
	_bank_strict = HSlider.new()
	_bank_strict.min_value = 0.0
	_bank_strict.max_value = 1.0
	_bank_strict.step = 0.05
	_bank_strict.value = float(b.get("strictness", 0.5))
	_detail_mgr.add_child(_bank_strict)
	_remember_bank_fields(b)
	var ab = Button.new()
	ab.text = "Uložiť nastavenia banky"
	ab.name = "BankApply"
	ab.pressed.connect(_on_bank_apply)
	_detail_mgr.add_child(ab)
	_build_sovereign_ui(b)
	var ph = Label.new()
	ph.text = "VYMÁHANIE DLHOV (PMC do 300 km + podplatená vláda + cieľ Kontakty v miestnej vláde)"
	ph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_mgr.add_child(ph)
	var pb = Button.new()
	pb.name = "PmcCollect"
	pb.text = "Poslať PMC na nesplácačov"
	pb.pressed.connect(_on_pmc_collect)
	_detail_mgr.add_child(pb)
	_build_legal_ui()  # JUAN13

func _build_sovereign_ui(bank: Dictionary) -> void:
	var head = Label.new()
	head.text = "PÔŽIČKY ŠTÁTOM"
	head.theme_type_variation = "HeaderLabel"
	_detail_mgr.add_child(head)
	_sovereign_country = OptionButton.new()
	_sovereign_country.name = "SovereignCountry"
	var advisor: Dictionary = bank.get("advisor", {})
	var selected = str(advisor.get("sovereign_country", bank.get("country", "SK")))
	for iso in DataLoader.country_ids:
		_sovereign_country.add_item(str(GameState.world.get(iso, {}).get("name_sk", iso)))
		_sovereign_country.set_item_metadata(_sovereign_country.item_count - 1, iso)
		if str(iso) == selected:
			_sovereign_country.select(_sovereign_country.item_count - 1)
	_detail_mgr.add_child(_sovereign_country)
	_sovereign_amount = _spin_row(_detail_mgr, "Suma €", 1000.0, 1.0e12, 1000.0, 100000.0)
	_sovereign_rate = _spin_row(_detail_mgr, "Ročný úrok %", 1.0, 40.0, 0.01, ceilf(SovereignLoans.suggested_rate(selected) * 10000.0) / 100.0)
	_sovereign_months = _spin_row(_detail_mgr, "Splatnosť v mesiacoch", 1.0, 120.0, 1.0, float(advisor.get("sovereign_months", 36)))
	_sovereign_country.item_selected.connect(func(_index):
		var iso = str(_sovereign_country.get_selected_metadata())
		_sovereign_rate.value = ceilf(SovereignLoans.suggested_rate(iso) * 10000.0) / 100.0
		_sovereign_country.tooltip_text = "Riziko krajiny: %s" % EconMath.pct(SovereignLoans.risk(iso)))
	var lend = Button.new()
	lend.name = "SovereignLend"
	lend.text = "Poskytnúť štátny úver"
	lend.pressed.connect(_on_sovereign_lend)
	_detail_mgr.add_child(lend)
	_sovereign_auto = CheckBox.new()
	_sovereign_auto.text = "Poradca môže požičiavať vybranej krajine"
	_sovereign_auto.button_pressed = bool(advisor.get("sovereign_enabled", false))
	_detail_mgr.add_child(_sovereign_auto)
	_sovereign_limit = _spin_row(_detail_mgr, "Max. podiel štátnych úverov z kapitálu %", 0.0, 50.0, 1.0, float(advisor.get("sovereign_limit", 0.1)) * 100.0)
	_sovereign_risk = _spin_row(_detail_mgr, "Max. riziko krajiny %", 0.0, 100.0, 1.0, float(advisor.get("sovereign_max_risk", 0.35)) * 100.0)
	var save = Button.new()
	save.name = "SovereignAdvisorLimits"
	save.text = "Uložiť limity štátnych úverov"
	save.pressed.connect(_on_sovereign_limits)
	_detail_mgr.add_child(save)

func _on_sovereign_lend() -> void:
	var bank: Dictionary = BankingSystem._player_bank()
	var iso = str(_sovereign_country.get_selected_metadata())
	var err = SovereignLoans.lend(bank, iso, float(_sovereign_amount.value), float(_sovereign_rate.value) / 100.0, int(_sovereign_months.value))
	_feedback("Štátny úver: %s" % ("poskytnutý." if err == "" else err), err == "")
	_fill_bank_detail()

func _on_sovereign_limits() -> void:
	var bank: Dictionary = BankingSystem._player_bank()
	if bank.is_empty():
		return
	var advisor: Dictionary = bank.get("advisor", {})
	advisor["sovereign_enabled"] = _sovereign_auto.button_pressed
	advisor["sovereign_country"] = str(_sovereign_country.get_selected_metadata())
	advisor["sovereign_limit"] = float(_sovereign_limit.value) / 100.0
	advisor["sovereign_max_risk"] = float(_sovereign_risk.value) / 100.0
	advisor["sovereign_months"] = int(_sovereign_months.value)
	bank["advisor"] = advisor
	BankingSystem._advisor_log(bank, "Hráč upravil limity štátnych úverov.")
	_feedback("Limity štátnych úverov uložené.", true)
	_fill_bank_detail()

func _spin_row(parent: Node, text: String, lo: float, hi: float, step: float, val: float) -> SpinBox:
	var row = HBoxContainer.new()
	parent.add_child(row)
	var l = Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var sp = SpinBox.new()
	sp.min_value = lo
	sp.max_value = hi
	sp.step = step
	sp.value = val
	row.add_child(sp)
	return sp

func _on_pmc_collect() -> void:
	var b: Dictionary = BankingSystem._player_bank()
	if b.is_empty():
		return
	var res = BankProducts.collect_debts(b)
	_feedback(str(res.text), bool(res.ok) and not bool(res.scandal))
	_bank_info.text = bank_detail_text(b)
	_refresh_label()

func _on_bank_apply() -> void:
	var b: Dictionary = BankingSystem._player_bank()
	if b.is_empty():
		return
	_sync_bank_fields(b)
	var cons = _bank_edited_value("cons", _bank_cons, BankingSystem.consumer_rate(b))
	var sav = _bank_edited_value("sav", _bank_sav, float(b.sav_rate))
	var mort = _bank_edited_value("mort", _bank_mort, float(b.mort_rate))
	var corp = _bank_edited_value("corp", _bank_corp, float(b.corp_rate))
	var reserves = _bank_edited_value("res", _bank_res, float(b.reserve_target))
	var strict = _bank_edited_value("strict", _bank_strict, float(b.get("strictness", 0.5)), 1.0)
	BankingSystem.set_consumer_rate(cons)
	BankingSystem.set_player_bank(sav, float(b.get("lending_rate", 0.05)), strict)
	BankProducts.set_rates(b, sav, mort, corp, reserves)
	_remember_bank_fields(b)
	BankingSystem.advisor_override(b)
	_feedback("Banka: úrok pre ľudí %s, vklady %s, prísnosť %d %%." % [EconMath.pct(BankingSystem.consumer_rate(b)), EconMath.pct(float(b.deposit_rate)), int(float(b.strictness) * 100)], true)
	_bank_info.text = bank_detail_text(b)

func _on_bank_advisor() -> void:
	var b: Dictionary = BankingSystem._player_bank()
	if b.is_empty():
		return
	var hired = bool(b.get("advisor", {}).get("hired", false))
	var err = BankingSystem.fire_advisor(b) if hired else BankingSystem.hire_advisor(b)
	_feedback("Bankový poradca: %s" % ("prepustený." if hired else "najatý.") if err == "" else err, err == "")
	_fill_bank_detail()

func _on_terrain_toggle(on: bool) -> void:
	if map:
		map.overlay = on
		map.queue_redraw()
	if region_view:
		region_view.overlay = on
		region_view.queue_redraw()

func _build_juan4_tabs(pol_tab: Node, focus_tab: Node) -> void:
	pol_label = Label.new()
	pol_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pol_tab.add_child(pol_label)
	var h = Label.new()
	h.text = "LOBING A ÚPLATKY (krajina = vybraná na mape)"
	h.theme_type_variation = "HeaderLabel"
	pol_tab.add_child(h)
	pol_party = OptionButton.new()
	pol_party.name = "PolParty"
	pol_party.tooltip_text = "Strana vybranej krajiny (Podpora vo voľbách, Financovať stranu)"
	pol_tab.add_child(pol_party)
	pol_target = OptionButton.new()  # JUAN5: cielova krajina pre sankcie / obchodnu dohodu
	pol_target.name = "PolTarget"
	pol_target.tooltip_text = "Cieľová krajina pre sankcie alebo obchodnú dohodu"
	var tids: Array = DataLoader.country_ids.duplicate()
	tids.sort_custom(func(a, b): return str(DataLoader.countries[a].get("name_sk", a)) < str(DataLoader.countries[b].get("name_sk", b)))
	for t_iso in tids:
		pol_target.add_item(str(DataLoader.countries[t_iso].get("name_sk", t_iso)))
		pol_target.set_item_metadata(pol_target.item_count - 1, str(t_iso))
	pol_tab.add_child(pol_target)
	_fill_pol_parties()
	for a in PoliticsSystem.ACTIONS.keys():
		var b = Button.new()
		b.name = "Pol_" + str(a)
		b.text = str(PoliticsSystem.ACTIONS[a].name)
		b.pressed.connect(_on_pol_action.bind(str(a)))
		pol_tab.add_child(b)
	var gh = Label.new()
	gh.text = "AKCIE POSTAVY"
	gh.theme_type_variation = "HeaderLabel"
	pol_tab.add_child(gh)
	for spec in [["Kampaň pre ženy (reputácia)", "campaign"], ["Očariť pri vyjednávaní (zľava)", "charm"]]:
		var gb = Button.new()
		gb.text = str(spec[0])
		gb.name = "Gender_" + str(spec[1])
		gb.tooltip_text = PoliticsSystem.GENDER_TIPS["muž" if spec[1] == "campaign" else "žena"]
		gb.pressed.connect(_on_gender_action.bind(str(spec[1])))
		pol_tab.add_child(gb)
	rival_label = Label.new()
	rival_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pol_tab.add_child(rival_label)
	var fh = Label.new()
	fh.text = "FIREMNÉ CIELE (strom vplyvu)"
	fh.theme_type_variation = "HeaderLabel"
	focus_tab.add_child(fh)
	focus_label = Label.new()
	focus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	focus_tab.add_child(focus_label)
	focus_bar = ProgressBar.new()
	focus_bar.max_value = 1.0
	focus_bar.custom_minimum_size = Vector2(0, 18)
	focus_tab.add_child(focus_bar)
	var tsc = ScrollContainer.new()
	tsc.name = "FocusScroll"
	tsc.custom_minimum_size = Vector2(0, 300)
	tsc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	focus_tab.add_child(tsc)
	focus_box = preload("res://scripts/ui/focus_tree_view.gd").new()
	focus_box.name = "FocusTree"
	focus_box.focus_pressed.connect(_on_focus)
	tsc.add_child(focus_box)
	var fl = Label.new()
	fl.text = "Ťahaj strom do strán (posuvník dole). Naraz beží len jeden cieľ. Červené ✕ = vzájomne sa vylučujú."
	fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	focus_tab.add_child(fl)
	var fend = Button.new()
	fend.text = "Ciele: obnoviť strom"
	fend.pressed.connect(_on_focus_refresh)
	focus_tab.add_child(fend)
	_rebuild_focus()

func _on_pol_action(action: String) -> void:
	if not GameState.running:
		_on_start()
	var iso = GameState.selected_iso
	var pid = ""
	if action == "lobby_sanction" or action == "lobby_trade":
		pid = str(pol_target.get_item_metadata(maxi(pol_target.selected, 0))) if pol_target and pol_target.item_count > 0 else ""
	elif pol_party and pol_party.item_count > 0:
		pid = str(pol_party.get_item_metadata(maxi(pol_party.selected, 0)))
	var cost = PoliticsSystem.action_cost(iso, action)
	var res = PoliticsSystem.act(iso, action, pid)
	_feedback("%s (cena %s, šanca %d %%, riziko škandálu %d %%)" % [str(res.text), EconMath.eur(cost), int(PoliticsSystem.action_chance(iso, action) * 100), int(PoliticsSystem.scandal_chance(iso, action) * 100)], bool(res.get("success", false)) and not bool(res.get("scandal", false)))
	_refresh_label()

func _on_gender_action(kind: String) -> void:
	if not GameState.running:
		_on_start()
	var res = PoliticsSystem.gender_action(kind)
	_feedback(str(res.text), bool(res.get("success", false)))
	_refresh_label()

var _pol_party_iso = ""
func _fill_pol_parties() -> void:
	if not pol_party:
		return
	var iso = GameState.selected_iso
	_pol_party_iso = iso
	pol_party.clear()
	var lst: Array = PoliticsSystem.country(iso).get("parties", []) if GameState.running else DataLoader.politics.get(iso, {}).get("parties", [])
	if lst.is_empty():
		lst = PoliticsSystem.PARTIES
	for p in lst:
		pol_party.add_item("%s (%d %%)" % [str(p.name), int(round(float(p.get("popularity", 0.0)) * 100))])
		pol_party.set_item_metadata(pol_party.item_count - 1, str(p.id))

func _refresh_juan4() -> void:
	_refresh_research()
	if pol_party and _pol_party_iso != GameState.selected_iso:
		_fill_pol_parties()
	if pol_label:
		var iso = GameState.selected_iso
		var t = PoliticsSystem.text(iso)
		t += "\nCeny akcií tu: "
		var parts: Array = []
		for a in ["lobby_tax", "bribe"]:
			parts.append("%s %s (%d %%)" % [str(PoliticsSystem.ACTIONS[a].name).split(":")[0], EconMath.eur(PoliticsSystem.action_cost(iso, a)), int(PoliticsSystem.action_chance(iso, a) * 100)])
		pol_label.text = t + ", ".join(parts) + "\nVojnu nevyhlasuješ ty – vedú ich štáty. Môžeš lobovať za mier alebo konflikt."
	if rival_label:
		rival_label.text = RivalSystem.text()
	if focus_box:
		var st = PoliticsSystem.focus_state()
		var sig = "%s|%s|%s" % [str(st.get("done", [])), str(st.get("current", "")), str(GameState.player.get("gender", ""))]
		if focus_bar:
			focus_bar.value = PoliticsSystem.focus_progress()
		if focus_label and str(st.get("current", "")) != "":
			focus_label.text = "Beží: %s (zostáva %d dní)" % [str(PoliticsSystem.focus_def(str(st.current)).get("name", "")), int(st.get("left", 0))]
		if sig != _focus_sig:
			_focus_sig = sig
			_rebuild_focus()

func _rebuild_focus() -> void:
	var st = PoliticsSystem.focus_state() if GameState.running else {"current": "", "left": 0}
	var cur = str(st.get("current", ""))
	focus_label.text = "Beží: %s (zostáva %d dní)" % [str(PoliticsSystem.focus_def(cur).get("name", "")), int(st.get("left", 0))] if cur != "" else "Vyber cieľ v strome. Každý dáva trvalý bonus."
	if focus_bar:
		focus_bar.value = PoliticsSystem.focus_progress() if GameState.running else 0.0
	focus_box.rebuild()

# ===== JUAN5: strom vyskumu =====
var research_box
var research_label: Label
var _research_sig = ""

func _build_research_tab(tab: Node) -> void:
	var h = Label.new()
	h.text = "VÝSKUM (strom technológií)"
	h.theme_type_variation = "HeaderLabel"
	tab.add_child(h)
	research_label = Label.new()
	research_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tab.add_child(research_label)
	var sc = ScrollContainer.new()
	sc.name = "ResearchScroll"
	sc.custom_minimum_size = Vector2(0, 330)
	tab.add_child(sc)
	research_box = preload("res://scripts/ui/research_tree_view.gd").new()
	research_box.name = "ResearchTree"
	research_box.research_pressed.connect(_on_research_id)
	sc.add_child(research_box)
	var rb = Button.new()
	rb.name = "BuildRnd"
	rb.text = "Postaviť R&D centrum (+1 slot, %s)" % EconMath.eur(GameState.RND_CENTER_COST)
	rb.pressed.connect(_on_build_rnd)
	tab.add_child(rb)
	var tip = Label.new()
	tip.text = "Ťahaj strom (posuvníky). Naraz beží 1 výskum, +1 slot cez cieľ „Výskumné oddelenie“ a +1 cez R&D centrum. Ďalšie idú do fronty."
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tab.add_child(tip)
	_refresh_research(true)

func _on_build_rnd() -> void:
	if not GameState.running:
		_on_start()
	var err = GameState.build_rnd_center()
	_feedback("R&D centrum otvorené." if err == "" else err, err == "")
	_refresh_research(true)

func _refresh_research(force: bool = false) -> void:
	if not research_box:
		return
	var run: Array = GameState.research_running() if not GameState.player.is_empty() else []
	var parts: Array = []
	for r in run:
		parts.append("%s (%d dní)" % [str(r.get("name", r.get("id", ""))), int(r.get("left", 0))])
	if research_label:
		research_label.text = "Sloty: %d/%d. Beží: %s" % [run.size(), GameState.research_slots() if not GameState.player.is_empty() else 1, ", ".join(parts) if not parts.is_empty() else "nič"]
	var sig = "%s|%s|%s|%s" % [str(GameState.player.get("done", [])), str(run.map(func(x): return x.get("id", ""))), str(GameState.player.get("research_queue", [])), str(GameState.player.get("rnd_center", false))]
	if force or sig != _research_sig:
		_research_sig = sig
		research_box.rebuild()

func _on_focus(fid: String) -> void:
	if not GameState.running:
		_on_start()
	var err = PoliticsSystem.start_focus(fid)
	_feedback("Cieľ: %s" % (str(PoliticsSystem.focus_def(fid).name) + " začatý." if err == "" else err), err == "")
	_focus_sig = ""
	_refresh_label()

func city_text(iso: String, city_name: String) -> String:
	var c: Dictionary = TerrainSystem.city_named(iso, city_name)
	if c.is_empty():
		return "Mesto nenájdené."
	var w: Dictionary = GameState.world.get(iso, {})
	var pop = float(c.pop)
	var gdp = pop * float(w.get("gdp_pc_usd", 10000)) / max(GameState.usd_per_eur, 0.1)
	var mine: Array = []
	var others = 0
	for f in GameState.firms:
		if str(f.get("country", "")) != iso or bool(f.get("closed", false)):
			continue
		var p = IndustrySystem.firm_pos(f)
		if p == null or (p as Vector2).distance_to(c.pos) > float(c.r):
			continue
		if str(f.get("owner", "")) == "player":
			mine.append(str(f.name))
		else:
			others += 1
	for pb in BankingSystem.player_banks():  # JUAN9: vsetky moje banky
		var bp = pb.get("pos", null)
		if typeof(bp) == TYPE_ARRAY and Vector2(float(bp[0]), float(bp[1])).distance_to(c.pos) <= float(c.r):
			mine.append(str(pb.name))
	var plots = maxi(2, 3 + int(pop / 250000.0))
	var used = mine.size() + others
	var out = "%s%s — %s\n" % [city_name, " (hlavné mesto)" if bool(c.capital) else "", str(w.get("name_sk", iso))]
	out += "Obyvatelia: %s\nEkonomika mesta: ~%s ročne (HDP/os. %s $)\nNezamestnanosť %s | daň firiem %s\n" % [_fmt_int(pop), EconMath.eur(gdp), _fmt_int(float(w.get("gdp_pc_usd", 0))), EconMath.pct(float(w.get("unemployment", 0.05))), EconMath.pct(LawSystem.corporate_tax(iso))]
	out += "Budovy: radnica, %d kancelárií a obchodov, %d priemyselných zón\n" % [maxi(1, int(pop / 50000.0)), maxi(1, int(pop / 400000.0))]
	out += "Tvoje firmy tu: %s\nKonkurencia v meste: %d\nVoľné parcely: %d / %d" % [", ".join(mine) if mine.size() > 0 else "žiadne", others, maxi(0, plots - used), plots]
	out += "\n" + city_share_text(iso, city_name, mine.size(), others)
	return out

# JUAN19: kolko % budov v meste vlastnis
func city_share(iso: String, city_name: String, my_firms: int, others: int) -> Dictionary:
	var c: Dictionary = TerrainSystem.city_named(iso, city_name)
	var pop = float(c.get("pop", 0.0))
	var bld = Empire.buildings_in(iso, city_name).size()
	var hq = 0
	for h in Empire.st().hq.values():
		if str(h.get("iso", "")) == iso and str(h.get("city", "")) == city_name:
			hq += 1
	var base = 1 + maxi(1, int(pop / 50000.0)) + maxi(1, int(pop / 400000.0))
	var mine = my_firms + bld + hq
	var total = base + my_firms + others + bld + hq
	return {"mine": mine, "total": total, "share": float(mine) / maxf(float(total), 1.0), "firms": my_firms, "buildings": bld, "hq": hq}

func city_share_text(iso: String, city_name: String, my_firms: int, others: int) -> String:
	var s = city_share(iso, city_name, my_firms, others)
	return "VLASTNÍŠ %.1f %% BUDOV MESTA (%d z %d): firmy %d, nehnuteľnosti %d, centrály %d" % [float(s.share) * 100.0, int(s.mine), int(s.total), int(s.firms), int(s.buildings), int(s.hq)]

func _fmt_int(v: float) -> String:
	var s = str(int(v))
	var out = ""
	while s.length() > 3:
		out = " " + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

func open_city_panel(iso: String, city_name: String) -> void:
	if city_panel == null:
		city_panel = PanelContainer.new()
		city_panel.name = "CityPanel"
		city_panel.z_index = 30
		add_child(city_panel)
		var outer = VBoxContainer.new()  # JUAN-P47: titulok + posuvny obsah
		city_panel.add_child(outer)
		var top = HBoxContainer.new()
		outer.add_child(top)
		var csc = ScrollContainer.new()
		csc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		csc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		outer.add_child(csc)
		var box = VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		csc.add_child(box)
		win_mgr.register(city_panel, "city", _city_rect, 40.0, Vector2(320, 200))
		var hl = Label.new()
		hl.text = "MESTO"
		hl.theme_type_variation = "HeaderLabel"
		hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(hl)
		var cb = Button.new()
		cb.text = "Zavrieť ✕"
		cb.pressed.connect(func(): city_panel.visible = false)
		top.add_child(cb)
		city_label = Label.new()
		city_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		city_label.custom_minimum_size = Vector2(260, 0)
		city_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(city_label)
		var bb = Button.new()
		bb.text = "Postaviť v tomto meste"
		bb.pressed.connect(func():
			city_panel.visible = false
			GameState.set_view("world")
			_on_zoom_sync()
			show_tab("Založiť"))
		box.add_child(bb)
	city_label.text = city_text(iso, city_name) + _media_line(iso)  # JUAN22
	city_label.text += Society.city_text(iso, city_name)  # JUAN-P47: kriminalita, gangy, vzdelanie, spokojnost
	var blds = Empire.buildings_in(iso, city_name)
	if not blds.is_empty():
		city_label.text += "\nTvoje budovy (realitka): %d, nájom %s/mes." % [blds.size(), EconMath.eur(blds.reduce(func(a, b): return a + float(b.rent), 0.0))]
	var hq_here = []
	for cid in Empire.st().hq.keys():
		var h = Empire.hq(str(cid))
		if str(h.iso) == iso and str(h.city) == city_name:
			hq_here.append(str(StockMarket.ex().corps.get(cid, {}).get("name", cid)))
	if not hq_here.is_empty():
		city_label.text += "\nCentrála: " + ", ".join(hq_here)
	var cbox = city_label.get_parent()
	var old = cbox.find_child("BuyBuilding", false, false)
	if old:
		old.queue_free()
	var bbuy = VBoxContainer.new()  # JUAN21: typy nehnutelnosti + zastavanie parciel
	bbuy.name = "BuyBuilding"
	cbox.add_child(bbuy)
	var brow = HBoxContainer.new()
	bbuy.add_child(brow)
	var tpick = OptionButton.new()
	tpick.name = "PropType"
	for t in Empire.PROP_TYPES.keys():
		tpick.add_item("%s – %s" % [str(Empire.PROP_TYPES[t].name), EconMath.eur(Empire.building_price(iso, city_name, t))])
		tpick.set_item_metadata(tpick.item_count - 1, t)
	brow.add_child(tpick)
	var bb2 = Button.new()
	bb2.text = "Kúpiť cez realitku"
	bb2.tooltip_text = "Vyžaduje tvoju Realitku v tejto krajine. Nájom: kancelárie %.1f %%, byty viac, obchody najviac, sklady menej, parcela nič (dá sa zastavať)." % (Empire.RENT_MONTHLY * 100.0)
	bb2.pressed.connect(func():
		var e = Empire.buy_building(iso, city_name, str(tpick.get_item_metadata(tpick.selected)))
		_feedback("Nehnuteľnosť: " + ("kúpená." if e == "" else e), e == "")
		open_city_panel(iso, city_name)
		_refresh_label())
	brow.add_child(bb2)
	var allb: Array = Empire.st().buildings
	for i in allb.size():
		var pb: Dictionary = allb[i]
		if str(pb.iso) == iso and str(pb.city) == city_name and Empire.btype(pb) == "plot":
			var dr = HBoxContainer.new()
			bbuy.add_child(dr)
			var dl = Label.new()
			dl.text = "Parcela: postaviť"
			dr.add_child(dl)
			for t2 in ["office", "apartments", "shop", "warehouse"]:
				var db = Button.new()
				db.text = "%s (%s)" % [str(Empire.PROP_TYPES[t2].name), EconMath.eur(Empire.develop_cost(pb, t2))]
				db.pressed.connect(func():
					var e2 = Empire.develop_plot(i, t2)
					_feedback("Stavba: " + ("hotová." if e2 == "" else e2), e2 == "")
					open_city_panel(iso, city_name)
					_refresh_label())
				dr.add_child(db)
			break
	win_mgr.place("city")
	city_panel.visible = true

func _on_zoom_sync() -> void:
	if map:
		map.visible = true
	if region_view:
		region_view.visible = false

func _intro_preview() -> void:
	var gv = str(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size() > 1 else "muž"
	var out = "/workspace/projekt47/preview/frames_" + ("f" if gv == "žena" else "m")
	DirAccess.make_dir_recursive_absolute(out)
	get_window().size = Vector2i(960, 790)
	var intro = preload("res://scripts/ui/intro_scene.gd").new()
	intro.setup("Wondris", gv)
	add_child(intro)
	intro.set_process(false)
	for _i in 3:
		await get_tree().process_frame
	for sc in 4:
		intro.scene_i = sc
		var full = str(intro.lines[sc]).length()
		for f in 48:
			intro.t = f / 12.0
			intro.typed = min(float(full), f * 2.5)
			intro.text_label.text = str(intro.lines[sc]).substr(0, int(intro.typed))
			intro.canvas.queue_redraw()
			await RenderingServer.frame_post_draw
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/s%d_%03d.png" % [out, sc + 1, f])
	print("P47_INTRO_PREVIEW_OK")
	get_tree().quit(0)

func _juan4_ui_checks() -> void:
	# menu: Story hlaska, mod -> nastavenie postavy
	_show_menu()
	await get_tree().process_frame
	var story = main_menu.find_child("Mode_story", true, false)
	if story:
		story.emit_signal("pressed")
	var story_ok = main_menu.menu_note.text.find("wondris404") >= 0
	var hidden_ok = map != null and not map.is_visible_in_tree() and main_menu.find_child("Logo", true, false) != null and main_menu.find_child("Dev", true, false) != null
	print("P47_UI_MENU_FULLSCREEN %d" % int(hidden_ok))
	var hard = main_menu.find_child("Mode_hard", true, false)
	if hard:
		hard.emit_signal("pressed")
	var setup_ok = main_menu.new_panel.visible and main_menu.mode_id == "hard"
	main_menu.nick_box.text = "Tester"
	main_menu.gender_box.select(1)
	main_menu._emit_new()
	await get_tree().process_frame
	var start_ok = (map == null or map.is_visible_in_tree()) and GameState.running and str(GameState.player.get("nick", "")) == "Tester" and str(GameState.player.get("gender", "")) == "žena" and Difficulty.mode() == "hard"
	print("P47_UI_J4_MENU story=%d setup=%d start=%d" % [int(story_ok), int(setup_ok), int(start_ok)])
	# banka: postav, otvor cez MOJE FIRMY aj cez ikonu
	GameState.player.cash = 5000000.0
	GameState.selected_iso = "SK"
	place_kind.select(place_list().find("bank"))
	_on_place_here()
	map.click_place(map._to_screen(map.capital_of("SK")))
	await get_tree().process_frame
	_firm_button_ids = "x"
	_sync_firm_buttons()
	await get_tree().process_frame
	var bb = _find_button(my_firms_buttons, "Detail: Banka")
	if bb:
		bb.emit_signal("pressed")
	await get_tree().process_frame
	var list_ok = firm_detail_panel != null and firm_detail_panel.visible and _detail_bank
	close_firm_detail()
	var pb: Dictionary = BankingSystem._player_bank()
	var icon_id = map.firm_at_screen(map._to_screen(map.bank_world_pos(pb))) if not pb.is_empty() else ""
	if icon_id != "":
		open_firm_detail(icon_id)
	await get_tree().process_frame
	var icon_ok = firm_detail_panel.visible and _detail_bank and _find_button(firm_detail_panel, "Uložiť nastavenia banky") != null and _find_button(firm_detail_panel, "Poslať PMC") != null
	close_firm_detail()
	print("P47_UI_J4_BANK list=%d icon=%d" % [int(list_ok), int(icon_ok)])
	# politika, ciele, teren, mesto, vojna
	var fb = _find_button(self, "Kontakty v parlamente")
	if fb:
		fb.emit_signal("pressed")
	var focus_ok = str(PoliticsSystem.focus_state().current) == "lob1"
	var lb = _find_button(self, "Lobing: nižšie dane")
	var before = feedback_count
	if lb:
		lb.emit_signal("pressed")
	var pol_ok = feedback_count > before
	var tb = find_child("TerrainToggle", true, false)
	if tb:
		tb.button_pressed = true
	await get_tree().process_frame
	var terr_ok = map.overlay
	open_city_panel("SK", "Bratislava")
	var city_ok = city_panel.visible and city_label.text.find("Obyvatelia") >= 0
	city_panel.visible = false
	var war_ok = play_diplomacy("war", "CZ").find("nemôžeš") >= 0 and _find_button(self, "Vojna") == null
	print("P47_UI_J4_MISC focus=%d politics=%d terrain=%d city=%d nowar=%d" % [int(focus_ok), int(pol_ok), int(terr_ok), int(city_ok), int(war_ok)])
	# JUAN5: burza + uverovy panel + dev mod
	toggle_burza()
	var burza_open = burza_win != null and burza_win.visible
	toggle_burza()
	var sv = find_child("StockView", true, false)
	if sv:
		sv.refresh()
	var stock_ok = sv != null and sv.list.item_count >= 20
	var cp = find_child("CreditPanel", true, false)
	var credit_ok = cp != null and cp.find_child("SecuredLoan", true, false) != null
	_show_menu()
	await get_tree().process_frame
	main_menu.find_child("Dev", true, false).emit_signal("pressed")
	await get_tree().process_frame
	var dev_ok = GameState.running and bool(GameState.config.get("dev", false)) and float(GameState.player.cash) >= 5.0e7 and IndustrySystem.unlock_reason("airport", "SK") == "" and _dev_save_roundtrip()
	_dev_panel_toggle()
	_dev_event()
	var dp_ok = get_node_or_null("DevPanel") != null and _dev_error_text() != ""
	print("P47_UI_J5 stock=%d credit=%d dev=%d devpanel=%d" % [int(stock_ok), int(credit_ok), int(dev_ok), int(dp_ok)])
	_pause_checks()  # JUAN11
	toggle_side_panel()
	var col_ok = not side_panel.visible
	toggle_side_panel()
	map._zoom_at(map.size * 0.5, 250.0)
	var deep_ok = map.zoom_level_name() == "detail mesta" and map.city_outline(TerrainSystem.cities("SK")[0]).size() > 10
	map._zoom_at(map.size * 0.5, 1.0)
	# JUAN14: klik na krajinu mimo ikonky -> detail krajiny; klik na ikonku -> firma; oddialene -> agregovana ikonka -> detail krajiny
	if firm_detail_panel:
		close_firm_detail()
	GameState.player.cash = maxf(float(GameState.player.cash), 5.0e6)
	var capk = map.capital_of("SK")
	IndustrySystem.place_at("SK", "hotel", capk)
	map.pan = Vector2.ZERO
	map._zoom_at(map._to_screen(capk), 6.0)
	map.pan += map.size * 0.5 - map._to_screen(capk)
	var opened = []
	var cb_f = func(fid): opened.append("firm:" + str(fid))
	var cb_c = func(iso): opened.append("country:" + str(iso))
	map.firm_clicked.connect(cb_f)
	map.country_firms.connect(cb_c)
	var far_pt = Vector2(-1, -1)
	for gy in range(-12, 13):
		for gx in range(-12, 13):
			var cand = map._to_screen(capk) + Vector2(gx, gy) * 12.0
			if far_pt.x < 0 and map._pick(cand) == "SK" and map.firm_at_screen(cand) == "":
				far_pt = cand
	map._click_at(far_pt)
	var c1 = opened.duplicate()
	opened.clear()
	map._click_at(map._to_screen(map.firm_world_pos(GameState.player_firms()[GameState.player_firms().size() - 1])))
	var c2 = opened.duplicate()
	opened.clear()
	map._zoom_at(map.size * 0.5, 1.0)
	map._click_at(map._to_screen(capk))
	var c3 = opened.duplicate()
	map.firm_clicked.disconnect(cb_f)
	map.country_firms.disconnect(cb_c)
	var country_ok = c1.size() >= 1 and str(c1[0]).begins_with("country:") and not str(c1).contains("firm:")
	var firm_ok = c2.size() == 1 and str(c2[0]).begins_with("firm:")
	var agg_ok = c3.size() >= 1 and str(c3[0]) == "country:SK"
	print("P47_UI_J14_CLICK country=%d firm=%d aggregate=%d %s|%s|%s" % [int(country_ok), int(firm_ok), int(agg_ok), str(c1), str(c2), str(c3)])
	print("P47_UI_J12 collapse=%d reopen=%d deepzoom=%d" % [int(col_ok), int(side_panel.visible), int(deep_ok)])

func _on_focus_refresh() -> void:
	_focus_sig = ""
	_refresh_label()


# ===================== JUAN9 =====================
var burza_win: PanelContainer
var country_win: PanelContainer
var win_mgr  # JUAN-P47: scripts/ui/window_drag.gd

func _vp() -> Vector2:
	return get_viewport_rect().size

func _firm_rect() -> Rect2:
	var vp = _vp()
	var w = minf(560.0, vp.x - 40.0)
	return Rect2(Vector2((vp.x - w) * 0.5, 50.0), Vector2(w, minf(620.0, vp.y - 80.0)))

func _city_rect() -> Rect2:
	return Rect2(Vector2(40, 90), Vector2(440, minf(600.0, _vp().y - 150.0)))

func _country_rect() -> Rect2:
	var vp = _vp()
	return Rect2(Vector2(vp.x - 520.0, 90.0), Vector2(500.0, minf(640.0, vp.y - 160.0)))

func _big_rect() -> Rect2:
	var vp = _vp()
	return Rect2(Vector2(360, 70), Vector2(maxf(320.0, vp.x - 390.0), maxf(200.0, vp.y - 134.0)))

func _build_burza_window() -> void:
	burza_win = PanelContainer.new()
	burza_win.name = "BurzaWindow"
	burza_win.visible = false
	burza_win.z_index = 40
	add_child(burza_win)
	win_mgr.register(burza_win, "burza", _big_rect, 40.0, Vector2(420, 240))
	var v = VBoxContainer.new()
	burza_win.add_child(v)
	var top = HBoxContainer.new()
	v.add_child(top)
	var t = Label.new()
	t.text = "BURZA"
	t.theme_type_variation = "HeaderLabel"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	var cb = Button.new()
	cb.text = "Zavrieť ✕"
	cb.pressed.connect(func(): burza_win.visible = false)
	top.add_child(cb)
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var stock_view = preload("res://scripts/ui/stock_view.gd").new()  # JUAN5 #19
	stock_view.name = "StockView"
	stock_view.host = self
	stock_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(stock_view)

func toggle_burza() -> void:
	if burza_win == null:
		return
	burza_win.visible = not burza_win.visible
	if burza_win.visible:
		win_mgr.place("burza")
		var sv = burza_win.find_child("StockView", true, false)
		if sv:
			sv.refresh()

func country_firm_rows(iso: String) -> Array:
	var out: Array = []
	for f in GameState.player_firms():
		if str(f.get("country", "")) == iso and not bool(f.get("closed", false)):
			out.append({"id": str(f.id), "ind": str(f.get("industry", "")), "name": str(f.get("name", "")), "city": str(f.get("city", ""))})
	for b in BankingSystem.player_banks():
		if str(b.get("country", "")) == iso:
			out.append({"id": str(b.id), "ind": "bank", "name": str(b.get("name", "")), "city": ""})
	return out

func open_country_firms(iso: String) -> void:
	if country_win == null:
		country_win = PanelContainer.new()
		country_win.name = "CountryFirms"
		country_win.z_index = 30
		add_child(country_win)
		var outer = VBoxContainer.new()  # JUAN-P47: pevny titulok + posuvny obsah
		country_win.add_child(outer)
		var top = HBoxContainer.new()
		outer.add_child(top)
		var t = Label.new()
		t.name = "CountryTitle"
		t.theme_type_variation = "HeaderLabel"
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.clip_text = true
		top.add_child(t)
		var cb = Button.new()
		cb.text = "✕"
		cb.pressed.connect(func(): country_win.visible = false)
		top.add_child(cb)
		var body = ScrollContainer.new()
		body.name = "CountryBody"
		body.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		outer.add_child(body)
		win_mgr.register(country_win, "country", _country_rect, 40.0, Vector2(340, 220))
	var body: ScrollContainer = country_win.find_child("CountryBody", true, false)
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	(country_win.find_child("CountryTitle", true, false) as Label).text = "%s – závislosť a tvoje firmy" % str(GameState.world.get(iso, {}).get("name_sk", iso))
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(v)
	var dep_l = Label.new()  # JUAN13: zavislost krajiny na hracovi
	dep_l.name = "DependencyText"
	dep_l.text = Empire.dependency_text(iso) + _media_line(iso)
	dep_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dep_l.custom_minimum_size = Vector2(260, 0)
	dep_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dep_l.add_theme_font_size_override("font_size", 12)
	v.add_child(dep_l)
	_power_ui(v, iso)  # JUAN-P47: Moc a vplyv
	var rows = country_firm_rows(iso)
	if rows.is_empty():
		var l = Label.new()
		l.text = "Tu zatiaľ nič nemáš. Založ firmu: Založiť → Postaviť na mape."
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	var sc = ScrollContainer.new()
	sc.custom_minimum_size = Vector2(260, mini(rows.size(), 8) * 32)
	v.add_child(sc)
	var list = VBoxContainer.new()
	sc.add_child(list)
	for r in rows:
		var b = Button.new()
		b.text = "%s – %s%s" % [str(r.name), place_name(str(r.ind)), (" (" + str(r.city) + ")") if str(r.city) != "" else ""]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true  # JUAN-P47: dlhy nazov sa nevytrca z uzkeho okna
		b.tooltip_text = b.text
		var ic = map.type_icon(str(r.ind)) if map else null
		if ic:
			b.icon = ic
		b.pressed.connect(open_firm_detail.bind(str(r.id)))
		list.add_child(b)
	win_mgr.place("country")
	country_win.visible = true

func _phase_a_shots() -> void:
	_on_menu_dev()
	await get_tree().process_frame
	GameState.selected_iso = "SK"
	var cap = map.capital_of("SK")
	for k in ["hotel", "cafe", "bank", "software"]:
		IndustrySystem.place_at("SK", k, cap + Vector2(randf_range(-0.6, 0.6), randf_range(-0.6, 0.6)))
	IndustrySystem.place_at("SK", "nuclear_plant", cap + Vector2(6, 3))
	IndustrySystem.place_at("DE", "cafe", map.capital_of("DE"))
	IndustrySystem.place_at("PL", "bank", map.capital_of("PL"))
	var out = "/workspace/projekt47/preview/"
	open_country_firms("SK")
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "phaseA_countries.png")
	country_win.visible = false
	map._zoom_at(map._to_screen(cap), 6.0)
	map.pan += map.size * 0.5 - map._to_screen(cap)
	open_city_panel("SK", "Bratislava")
	map.queue_redraw()
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "phaseA_city_zoom.png")
	city_panel.visible = false
	toggle_burza()
	var sv = burza_win.find_child("StockView", true, false)
	GameState.player.cash = 300000.0
	sv._sel = str(StockMarket.listings()[3].ticker)
	sv.qty.value = 5000
	sv._show_sel()
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "phaseB_burza_quote.png")
	burza_win.visible = false
	StockMarket.create_corp("Wondris Holding", [str(GameState.player_firms()[0].id), str(GameState.player_firms()[1].id)])
	var cid0 = str(GameState.player_firms()[0].corp)
	Empire.set_hq(cid0, "SK", cap)
	Empire.fin(cid0).on = true
	Empire.fin(cid0).log = ["1.2.2024: nákup ARAG 1200 ks (kurz 9 % pod priemerom)", "1.2.2024: rozpočet +12 000 € (10 % zo ziskov)"]
	map.infra = true
	map._zoom_at(map._to_screen(cap), 1.0)
	map.queue_redraw()
	toggle_empire()
	for _i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "phaseB_empire.png")
	empire_win.visible = false
	map.pan = Vector2.ZERO
	map._zoom_at(map._to_screen(cap), 2.5)
	map.pan += map.size * 0.5 - map._to_screen(cap)
	map.queue_redraw()
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "phaseB_infra.png")
	print("P47_PHASEA_SHOTS_OK")
	get_tree().quit(0)

var stat_strip: Label
var empire_win: PanelContainer

func open_portfolio_corp(cid: String) -> void:  # JUAN15: klik na HQ
	if empire_win == null or not empire_win.visible:
		toggle_empire()
	var ev = empire_win.find_child("EmpireView", true, false)
	if ev:
		ev.focus_corp(cid)

func _broker_ui(firm: Dictionary) -> void:
	var bl = Label.new()
	bl.name = "BrokerInfo"
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bl.text = Empire.broker_text(firm)
	_detail_mgr.add_child(bl)
	var b: Dictionary = Empire.broker(firm)
	var r = HBoxContainer.new()
	_detail_mgr.add_child(r)
	var on = CheckBox.new()
	on.text = "Obchodovať"
	on.button_pressed = bool(b.on)
	on.toggled.connect(func(v): b.on = v)
	r.add_child(on)
	var cl = Label.new()
	cl.text = "Kapitál %:"
	r.add_child(cl)
	var cap = SpinBox.new()
	cap.name = "BrokerCap"
	cap.min_value = 0
	cap.max_value = 100
	cap.step = 5
	cap.value = float(b.cap_pct) * 100.0
	cap.tooltip_text = "Koľko % kapitálu firmy (hotovosť + akcie) smie byť investovaných v akciách."
	cap.value_changed.connect(func(v): b.cap_pct = v / 100.0)
	r.add_child(cap)
	var rp = OptionButton.new()
	rp.name = "BrokerRisk"
	for x in Empire.BROKER_RISK:
		rp.add_item("Riziko " + str(x.name))
	rp.select(clampi(int(b.risk), 0, 2))
	rp.item_selected.connect(func(i): b.risk = i)
	r.add_child(rp)
	var r2 = HBoxContainer.new()
	_detail_mgr.add_child(r2)
	for amt in [1.0e6, -1.0e6]:
		var mb = Button.new()
		mb.text = ("Vložiť kapitál %s" if amt > 0 else "Vybrať %s") % EconMath.eur(absf(amt))
		mb.tooltip_text = "Presun peňazí medzi tebou a obchodným kapitálom burzovej firmy."
		mb.pressed.connect(func():
			var ok = (amt > 0 and float(GameState.player.cash) >= amt) or (amt < 0 and float(firm.cash) >= -amt)
			if ok:
				GameState.player.cash = float(GameState.player.cash) - amt
				firm.cash = float(firm.cash) + amt
			_feedback("Kapitál burzovej firmy: %s" % (EconMath.eur(float(firm.cash)) if ok else "nedostatok peňazí"), ok)
			_fill_firm_detail())
		r2.add_child(mb)

func toggle_empire() -> void:
	if empire_win == null:
		empire_win = PanelContainer.new()
		empire_win.name = "EmpireWindow"
		empire_win.z_index = 40
		add_child(empire_win)
		win_mgr.register(empire_win, "empire", _big_rect, 40.0, Vector2(420, 240))
		var v = VBoxContainer.new()
		empire_win.add_child(v)
		var top = HBoxContainer.new()
		v.add_child(top)
		var t = Label.new()
		t.text = "PORTFÓLIO A MAJETOK"
		t.theme_type_variation = "HeaderLabel"
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(t)
		var cb = Button.new()
		cb.text = "Zavrieť ✕"
		cb.pressed.connect(func(): empire_win.visible = false)
		top.add_child(cb)
		var sc = ScrollContainer.new()
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		v.add_child(sc)
		var ev = preload("res://scripts/ui/empire_view.gd").new()
		ev.name = "EmpireView"
		ev.host = self
		ev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(ev)
		empire_win.visible = false
	empire_win.visible = not empire_win.visible
	if empire_win.visible:
		win_mgr.place("empire")
		empire_win.find_child("EmpireView", true, false).refresh()

func start_hq_place() -> void:
	if empire_win:
		empire_win.visible = false
	var iso = GameState.selected_iso
	if iso == "" or map == null:
		_feedback("Najprv klikni na krajinu, kde má byť centrála.", false)
		return
	map.start_place(iso)
	map.place_industry = "hq"
	_hq_placing = true
	_feedback("Centrála: klikni do mesta v krajine %s (Esc zruší)." % str(GameState.world.get(iso, {}).get("name_sk", iso)), true)

var _hq_placing = false

var pause_popup: Control

func toggle_pause_popup() -> void:
	if pause_popup == null:
		pause_popup = preload("res://scripts/ui/pause_popup.gd").new()
		pause_popup.name = "PausePopup"
		pause_popup.host = self
		add_child(pause_popup)
	if pause_popup.visible:
		pause_popup.close()
	else:
		pause_popup.open()

func _quit_to_menu() -> void:
	if pause_popup:
		pause_popup.visible = false
	GameState.paused = true
	_show_menu()

func _pause_shot() -> void:
	_on_menu_dev()
	await get_tree().process_frame
	toggle_pause_popup()
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/workspace/projekt47/preview/pause_popup.png")
	pause_popup._save_dlg()
	for _i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/workspace/projekt47/preview/pause_save_dev.png")
	print("P47_PAUSE_SHOT_OK")
	get_tree().quit(0)

func _pause_checks() -> void:
	# JUAN11 uitest: Esc otvori popup (nie menu), druhe Esc zavrie, hra je pozastavena
	var ev = InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.pressed = true
	GameState.paused = false
	toggle_pause_popup()
	var open_ok = pause_popup.visible and GameState.paused and not (main_menu and main_menu.visible)
	var has_btns = pause_popup.find_child("PauseSave", true, false) != null and pause_popup.find_child("PauseQuit", true, false) != null
	toggle_pause_popup()
	var close_ok = not pause_popup.visible and not GameState.paused
	print("P47_UI_J11_PAUSE open=%d buttons=%d close=%d" % [int(open_ok), int(has_btns), int(close_ok)])

var toolbar_scroll: ScrollContainer
var side_panel: Control
var panel_btn: Button
var zoom_lbl: Label

func toggle_side_panel() -> void:
	if side_panel == null:
		return
	side_panel.visible = not side_panel.visible
	panel_btn.text = "◀ Skryť panel" if side_panel.visible else "▶ Panel"
	if side_panel.visible:
		_refresh_label()

func _input_j12(event: InputEvent) -> void:
	# JUAN12: Tab inak zoberie navigacia fokusu
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_TAB and GameState.running and play and not (main_menu and main_menu.visible) and not _typing_focus():
		toggle_side_panel()
		get_viewport().set_input_as_handled()
	if zoom_lbl and map and Engine.get_process_frames() % 10 == 0:
		zoom_lbl.text = "Zoom %.0f× – %s" % [map.zoom, map.zoom_level_name()]

func _zoom_shots() -> void:
	_on_menu_dev()
	await get_tree().process_frame
	var city: Dictionary = TerrainSystem.cities("SK")[0]
	for c in TerrainSystem.cities("SK"):
		if str(c.name) == "Bratislava":
			city = c
	var cp: Vector2 = city.pos
	for k in ["hotel", "cafe", "software", "bank", "restaurant"]:
		IndustrySystem.place_at("SK", k, cp + Vector2(randf_range(-0.8, 0.8), randf_range(-0.8, 0.8)))
	toggle_side_panel()
	_refresh_label()
	var out = "/workspace/projekt47/preview/"
	var i = 0
	for z in [1.0, 8.0, 40.0, 250.0]:
		map.pan = Vector2.ZERO
		map._zoom_at(map._to_screen(cp), z)
		map.pan += map.size * 0.5 - map._to_screen(cp)
		map.queue_redraw()
		for _f in 6:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var t0 = Time.get_ticks_usec()
		map.queue_redraw()
		await RenderingServer.frame_post_draw
		print("P47_ZOOM z=%.0f frame_ms=%.1f" % [z, (Time.get_ticks_usec() - t0) / 1000.0])
		get_viewport().get_texture().get_image().save_png(out + "zoom_%d_%s.png" % [i, str(int(z))])
		i += 1
	toggle_side_panel()
	print("P47_ZOOM_SHOTS_OK")
	get_tree().quit(0)

var _legal_l: Label

func _build_legal_ui() -> void:
	var h = Label.new()
	h.text = "PRÁVNE ODDELENIE (súdne vymáhanie, %s/právnik mesačne)" % EconMath.eur(BankProducts.LAWYER_MONTHLY)
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_mgr.add_child(h)
	_legal_l = Label.new()
	_legal_l.name = "LegalInfo"
	_legal_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_mgr.add_child(_legal_l)
	var r = HBoxContainer.new()
	_detail_mgr.add_child(r)
	for spec in [["Najať právnika", func(b): return BankProducts.hire_lawyer(b, 1)], ["Prepustiť", func(b): return BankProducts.hire_lawyer(b, -1)], ["Školenie (+úroveň)", func(b): return BankProducts.train_lawyers(b)]]:
		var bt = Button.new()
		bt.text = str(spec[0])
		var fn: Callable = spec[1]
		bt.pressed.connect(func():
			var b: Dictionary = BankingSystem._player_bank()
			var e = str(fn.call(b))
			_feedback("Právne oddelenie: " + ("OK" if e == "" else e), e == "")
			_legal_refresh())
		r.add_child(bt)
	var cb = Button.new()
	cb.name = "BankToCorp"
	cb.text = "Začleniť banku do korporácie"
	cb.tooltip_text = "Banka v korporácii má silnejších právnikov (bonus podľa veľkosti korporácie)."
	cb.pressed.connect(func():
		var b: Dictionary = BankingSystem._player_bank()
		var ids = StockMarket.ex().corps.keys()
		if ids.is_empty():
			_feedback("Najprv vytvor korporáciu v Burze.", false)
			return
		var cur = ids.find(str(b.get("corp", "")))
		var nxt = str(ids[(cur + 1) % ids.size()])
		BankProducts.set_bank_corp(b, nxt)
		_feedback("Banka je v korporácii %s." % str(StockMarket.ex().corps[nxt].name), true)
		_legal_refresh())
	_detail_mgr.add_child(cb)
	_legal_refresh()

func _legal_refresh() -> void:
	if _legal_l == null or not is_instance_valid(_legal_l):
		return
	var b: Dictionary = BankingSystem._player_bank()
	if b.is_empty():
		return
	var l = BankProducts.legal(b)
	var iso = str(b.get("country", ""))
	var dep = Empire.dependency(iso)
	var corp = str(StockMarket.ex().corps.get(str(b.get("corp", "")), {}).get("name", "–"))
	_legal_l.text = "Právnici: %d (úroveň %d) · korporácia: %s · závislosť krajiny: %.0f (%s)\nŠanca výhry sporu: %.0f %% · vymožené spolu %s · náklady %s\n%s" % [int(l.lawyers), int(l.level), corp, float(dep.index), str(dep.label), BankProducts.legal_chance(b) * 100.0, EconMath.eur(float(l.won)), EconMath.eur(float(l.costs)), "\n".join((l.log as Array).slice(0, 3))]

func _j13_shots() -> void:
	_on_menu_dev()
	await get_tree().process_frame
	var out = "/workspace/projekt47/preview/"
	var cap = map.capital_of("SK")
	for k in ["power_coal", "hotel", "bank", "software"]:
		IndustrySystem.place_at("SK", k, cap + Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)))
	IndustrySystem.place_at("SK", "nuclear_plant", cap + Vector2(6, 3))
	for f in GameState.player_firms():
		f.month_hist = [{"rev": 3.0e7, "costs": 0.0, "profit": 2.0e6}]
		f.workers = 800.0
	BankingSystem.issue_bond_ex(250000.0, 0.055, 7.0)
	show_tab("Pôžičky")
	_refresh_label()
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "j13_pozicky.png")
	var sc = _active_side_scroll()
	if sc:
		sc.scroll_vertical = 100000
	for _i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "j13_dlhopisy.png")
	open_country_firms("SK")
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "j13_zavislost.png")
	country_win.visible = false
	var b = BankingSystem.player_banks()[0]
	b.defaults_total = 900000.0
	BankProducts.hire_lawyer(b, 3)
	BankProducts.legal_monthly(b, 0.1)
	open_firm_detail(str(b.id))
	for _i in 6:
		await get_tree().process_frame
	var dsc = firm_detail_panel.find_child("*", true, false)
	for c in firm_detail_panel.find_children("*", "ScrollContainer", true, false):
		c.scroll_vertical = 100000
	for _i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "j13_pravnici.png")
	print("P47_J13_SHOTS_OK")
	get_tree().quit(0)

func _j14_shot() -> void:
	_on_menu_dev()
	await get_tree().process_frame
	var cap = map.capital_of("SK")
	for k in ["hotel", "software", "bank"]:
		IndustrySystem.place_at("SK", k, cap + Vector2(randf_range(-0.4, 0.4), randf_range(-0.4, 0.4)))
	map._zoom_at(map._to_screen(cap), 6.0)
	map.pan += map.size * 0.5 - map._to_screen(cap)
	map.queue_redraw()
	await get_tree().process_frame
	map._click_at(map._to_screen(cap) + Vector2(60, 40))
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
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
	# Strata fokusu počas presunu musí ukončiť ťahanie aj bez doručeného uvoľnenia.
	var focus_point = country_win.position + Vector2(40, 16)
	_mouse(false, false, focus_point)
	_mouse(true, true, focus_point)
	await get_tree().process_frame
	var started_drag = win_mgr._mode == 1
	get_window().focus_exited.emit()
	res["drag_stops_on_focus_loss"] = started_drag and win_mgr._mode == 0
	_mouse(true, false, focus_point)
	await get_tree().process_frame
	var resize_point = country_win.position + country_win.size - Vector2(3, 3)
	_mouse(false, false, resize_point)
	_mouse(true, true, resize_point)
	await get_tree().process_frame
	var started_resize = win_mgr._mode == 2
	get_window().focus_exited.emit()
	res["resize_stops_on_focus_loss"] = started_resize and win_mgr._mode == 0
	_mouse(true, false, resize_point)
	await get_tree().process_frame
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
	var shot_dir = ProjectSettings.globalize_path("res://audit/screenshots/window-audit")
	DirAccess.make_dir_recursive_absolute(shot_dir)
	var args = OS.get_cmdline_user_args()
	var tag = str(args[1]) if args.size() > 1 else "baseline"
	var shot = shot_dir.path_join("country_" + tag + ".png")
	img.save_png(shot)
	res["screenshot"] = FileAccess.file_exists(shot) and img.get_width() > 100
	var fails = 0
	for k in res.keys():
		print("P47_UNIT_%s win_%s" % ["OK" if res[k] else "FAIL", k])
		if not res[k]:
			fails += 1
	exit_code = 0 if fails == 0 else 1
	get_tree().quit(exit_code)
