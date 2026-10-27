extends RefCounted
# JUAN4: unit testy (obtiaznost, teren, politika, focus tree, AI konkurenti, save, intro texty, krajiny)
var u

func run(host) -> void:
	u = host
	_difficulty()
	_terrain()
	_politics()
	_focus()
	_rivals()
	_save_ext()
	_intro_text()
	_bank_products()
	_pmc()
	_gender()
	_gender_focus()
	_countries()

func _difficulty() -> void:
	u._new()
	u._chk("j4_diff_default_neutral", Difficulty.mode() == "medium" and Difficulty.cost_mult() == 1.0 and Difficulty.rate_add() == 0.0)
	GameState.config.difficulty = "hard"
	u._chk("j4_diff_hard", Difficulty.cost_mult() > 1.2 and Difficulty.event_mult() > 1.5 and Difficulty.ai_mult() > 1.4)
	GameState.player.cash = 1.0e6
	GameState.found_firm("cafe", "", "SK")
	var paid_hard = 1.0e6 - float(GameState.player.cash)
	GameState.config.difficulty = "easy"
	GameState.player.cash = 1.0e6
	GameState.found_firm("cafe", "", "SK")
	var paid_easy = 1.0e6 - float(GameState.player.cash)
	u._chk("j4_diff_cost", paid_hard > paid_easy * 1.4, "%.0f vs %.0f" % [paid_hard, paid_easy])
	u._chk("j4_diff_cash", Difficulty.start_cash("easy") > Difficulty.start_cash("hard") and Difficulty.start_cash("realistic") == 0.0)

func _terrain() -> void:
	u._new()
	var ba: Dictionary = TerrainSystem.cities("SK")[0]
	u._chk("j4_cities_sk", TerrainSystem.cities("SK").size() >= 3 and bool(ba.capital), str(ba.get("name", "")))
	u._chk("j4_no_mine_in_city", not bool(TerrainSystem.can_place("coal_mine", "SK", ba.pos).ok))
	var moscow: Dictionary = TerrainSystem.cities("RU")[0] if TerrainSystem.cities("RU").size() > 0 else {}
	u._chk("j4_no_coal_moscow", not moscow.is_empty() and not bool(TerrainSystem.can_place("coal_mine", "RU", moscow.pos).ok), str(moscow.get("name", "")))
	u._chk("j4_cafe_in_city", bool(TerrainSystem.can_place("cafe", "SK", ba.pos).ok))
	var iron: Dictionary = {}
	for d in TerrainSystem.deposits("SK"):
		if str(d.res) == "iron":
			iron = d
	u._chk("j4_sk_iron_deposit", not iron.is_empty() and TerrainSystem.inside("SK", iron.pos))
	if not iron.is_empty():
		u._chk("j4_cafe_not_on_field", not bool(TerrainSystem.can_place("cafe", "SK", iron.pos).ok))
		u._chk("j4_iron_ok", bool(TerrainSystem.can_place("iron_mine", "SK", iron.pos).ok))
		GameState.player.cash = 5.0e6
		var r = IndustrySystem.place_at("SK", "iron_mine", iron.pos)
		u._chk("j4_place_mine", bool(r.ok), str(r.reason))
	var r2 = IndustrySystem.place_at("SK", "cafe", ba.pos + Vector2(30, 30))
	u._chk("j4_place_cafe_outside_city_refused", not bool(r2.ok))
	u._chk("j4_valid_spots", TerrainSystem.valid_spots("iron_mine", "SK").size() > 0 and TerrainSystem.valid_spots("cafe", "SK").size() >= 3)
	var t = TerrainSystem.terrain_at(Vector2(800, 30))
	u._chk("j4_terrain_north_tundra", t == "tundra", t)

func _politics() -> void:
	u._new()
	var c = PoliticsSystem.country("SK")
	u._chk("j4_pol_setup", not c.is_empty() and PoliticsSystem.GOV_NAMES.has(str(c.gov)))
	GameState.player.cash = 1.0e7
	var tax0 = LawSystem.corporate_tax("SK")
	var cash0 = float(GameState.player.cash)
	var res = PoliticsSystem.act("SK", "lobby_tax", "", 0.0, 0.99)
	u._chk("j4_lobby_tax", bool(res.success) and not bool(res.scandal) and LawSystem.corporate_tax("SK") < tax0 and float(GameState.player.cash) < cash0)
	u._chk("j4_bribe_locked", not bool(PoliticsSystem.act("SK", "bribe").ok))
	PoliticsSystem.focus_state().done.append("dirty")
	var rating0 = int(GameState.player.rating)
	var res2 = PoliticsSystem.act("SK", "bribe", "", 0.99, 0.0)
	u._chk("j4_bribe_scandal", not bool(res2.success) and bool(res2.scandal) and int(GameState.player.rating) < rating0)
	u._chk("j4_bribe_riskier", PoliticsSystem.scandal_chance("SK", "bribe") > PoliticsSystem.scandal_chance("SK", "lobby_tax"))
	GameState.player.cash = 0.0
	u._chk("j4_lobby_needs_cash", not bool(PoliticsSystem.act("SK", "lobby_reg").ok))
	var win = PoliticsSystem.election("SK", 0.0)
	# JUAN5: volby beru strany krajiny (data/politics_juan5.json); roll 0 = prva strana zoznamu
	var first = str(c.parties[0].id)
	u._chk("j4_election", win == first and is_equal_approx(LawSystem.corporate_tax("SK"), clamp(float(c.base_tax) + float(PoliticsSystem.party_def(first).tax), 0.05, 0.45)), win)
	GameState.wars.clear()
	GeopoliticsSystem._start_war("DE", "FR")
	GameState.player.cash = 1.0e8
	PoliticsSystem.act("DE", "lobby_peace", "", 0.0, 0.99)
	u._chk("j4_lobby_peace", not GeopoliticsSystem.at_war("DE"))
	GameState.config.politics = true
	for i in 70:
		GameState.simulate_day()
	u._chk("j4_pol_monthly_runs", float(PoliticsSystem.country("SK").approval) > 0.0)

func _focus() -> void:
	u._new()
	u._chk("j4_focus_locked", not PoliticsSystem.focus_available("lob2") and PoliticsSystem.start_focus("lob2") != "")
	u._chk("j4_focus_start", PoliticsSystem.start_focus("lob1") == "" and PoliticsSystem.start_focus("med1") != "")
	var ch0 = PoliticsSystem.action_chance("SK", "lobby_tax")
	for i in 35:
		PoliticsSystem.daily()
	u._chk("j4_focus_done", PoliticsSystem.focus_done("lob1") and PoliticsSystem.focus_available("lob2"))
	u._chk("j4_focus_bonus", PoliticsSystem.action_chance("SK", "lobby_tax") > ch0)
	PoliticsSystem.focus_state().done.append("ind1")
	u._chk("j4_focus_cost", PoliticsSystem.cost_mult("SK") < 1.0)
	u._chk("j4_focus_durations", PoliticsSystem.FOCUS.all(func(f): return int(f.days) >= 35 and int(f.days) <= 70))
	u._chk("j4_focus_progress", PoliticsSystem.start_focus("clean") == "" and PoliticsSystem.focus_progress() == 0.0)
	u._chk("j4_focus_excl_running", not PoliticsSystem.focus_available("dirty"))
	for i in 20:
		PoliticsSystem.daily()
	u._chk("j4_focus_progress_half", abs(PoliticsSystem.focus_progress() - 0.5) < 0.03)
	var r0 = int(GameState.player.rating)
	for i in 20:
		PoliticsSystem.daily()
	u._chk("j4_focus_on_done", PoliticsSystem.focus_done("clean") and int(GameState.player.rating) == mini(100, r0 + 5))
	u._chk("j4_focus_exclusive", not PoliticsSystem.focus_available("dirty") and PoliticsSystem.focus_available("clean2"))

func _rivals() -> void:
	u._new()
	GameState.config.rivals = true
	RivalSystem.setup(3)
	u._chk("j4_rivals_setup", RivalSystem.rivals().size() == 3)
	GameState.player.cash = 1.0e6
	GameState.found_firm("cafe", "", "SK")
	var n0 = GameState.firms.size()
	var id = RivalSystem.found_for(RivalSystem.rivals()[0])
	u._chk("j4_rival_found", id != "" and GameState.firms.size() == n0 + 1 and str(GameState.firm_by_id(id).owner) == "ai")
	for i in 65:
		GameState.simulate_day()
	var sh = RivalSystem.market_share("SK", "cafe")
	u._chk("j4_market_share", float(sh.player) + float(sh.rivals) <= 1.0001 and float(sh.total) > 0.0, str(sh))
	u._chk("j4_rival_text", RivalSystem.text().find("AI KONKURENTI") >= 0)

func _save_ext() -> void:
	u._new()
	GameState.player.nick = "Wondris"
	GameState.player.gender = "žena"
	PoliticsSystem.start_focus("fin1")
	RivalSystem.setup(2)
	var d = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	u._new()
	var err = GameState.from_dict(d)
	u._chk("j4_save_ext", err == "" and str(GameState.player.get("nick", "")) == "Wondris" and str(GameState.player.gender) == "žena" and str(PoliticsSystem.focus_state().current) == "fin1" and RivalSystem.rivals().size() == 2, err)
	d.erase("ext")
	err = GameState.from_dict(d)
	u._chk("j4_old_save_no_ext", err == "" and not PoliticsSystem.country("SK").is_empty())

func _intro_text() -> void:
	var S = load("res://scripts/ui/intro_scene.gd")
	var m: Array = S.story_lines("Ondo", "muž")
	var z: Array = S.story_lines("Ema", "žena")
	var o: Array = S.story_lines("X", "iné")
	u._chk("j4_intro_gender", str(m[0]).find("VYHODENÝ") >= 0 and str(z[0]).find("VYHODENÁ") >= 0 and str(m[1]).find("PARTNERKA") >= 0 and str(z[1]).find("PARTNER ") >= 0 and str(o[0]).find("VYHODILI") >= 0)
	var all = " ".join(m)
	u._chk("j4_intro_parody", all.find("ALONOM MOSKOM") >= 0 and all.find("ELON") < 0 and all.find("MUSK") < 0 and str(m[2]) == "BUDEM NAJBOHATŠÍ ČLOVEK NA SVETE!")

func _countries() -> void:
	u._chk("j4_countries", DataLoader.country_ids.size() >= 26, str(DataLoader.country_ids.size()))

func _bank_setup() -> Dictionary:
	u._new()
	GameState.player.cash = 5.0e6
	var ba: Dictionary = TerrainSystem.cities("SK")[0]
	var r = IndustrySystem.place_at("SK", "bank", ba.pos)
	u._chk("j4_bank_placed", bool(r.ok), str(r.reason))
	return BankingSystem._player_bank()

func _bank_products() -> void:
	var b = _bank_setup()
	BankProducts.ensure(b)
	u._chk("j4_bank_defaults", b.has("sav_rate") and b.has("mort_rate") and b.has("corp_rate") and float(b.reserve_target) >= LawSystem.min_reserve("SK"))
	b.reserves = float(b.reserves) + 2.0e6
	b.equity = float(b.equity) + 2.0e6
	var st = BankProducts.monthly(b)
	u._chk("j4_bank_mortgage_corp", float(st.mort_out) > 0.0 and float(st.corp_out) > 0.0, str(st.mort_out))
	u._chk("j4_bank_mort_safer", BankProducts.mort_default(b) < BankProducts.corp_default(b))
	u._chk("j4_bank_car", BankProducts.car(b) > BankProducts.MIN_CAR and BankProducts.can_lend(b))
	b.equity = 1.0
	u._chk("j4_bank_car_blocks", not BankProducts.can_lend(b))
	var n0 = (b.mort_loans as Array).size()
	BankProducts.monthly(b)
	u._chk("j4_bank_no_new_when_car_low", (b.mort_loans as Array).size() <= n0)
	b.equity = 3.0e6
	BankProducts.set_rates(b, 0.05, 0.03, 0.07, 0.01)
	u._chk("j4_bank_set_rates", is_equal_approx(float(b.sav_rate), 0.05) and float(b.reserve_target) >= LawSystem.min_reserve("SK"))
	var s0 = float(b.savings)
	BankProducts.monthly(b)
	u._chk("j4_bank_savings_inflow", float(b.savings) > s0)
	for i in 65:
		GameState.simulate_day()
	var mh: Array = b.get("month_hist", [])
	u._chk("j4_bank_history", mh.size() >= 2 and mh[mh.size() - 1].has("dr_mort") and mh[mh.size() - 1].has("loans"), str(mh.size()))
	u._chk("j4_bank_text", BankProducts.text(b).find("Kapitálová primeranosť") >= 0)
	var d = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	u._chk("j4_bank_save", GameState.from_dict(d) == "" and BankingSystem._player_bank().has("mort_loans"))

func _pmc() -> void:
	var b = _bank_setup()
	b.defaults_total = 200000.0
	u._chk("j4_pmc_needs_pmc", not bool(BankProducts.collect_check(b).ok))
	var cities = TerrainSystem.cities("SK")
	var far: Vector2 = cities[0].pos + Vector2(40, 0)
	var r = IndustrySystem.place_at("SK", "pmc", cities[2].pos + Vector2(0, 2.5))
	u._chk("j4_pmc_built", bool(r.ok), str(r.reason))
	var near = BankProducts.nearest_pmc(b)
	u._chk("j4_pmc_distance", not near.is_empty() and float(near.km) < 400.0 and BankProducts.km_between(cities[0].pos, far) > 300.0, str(near.get("km", -1)))
	var chk = BankProducts.collect_check(b)
	u._chk("j4_pmc_needs_focus", not bool(chk.ok) and str(chk.reason).find("Kontakty") >= 0, str(chk.reason))
	PoliticsSystem.focus_state().done.append("dirty")
	PoliticsSystem.focus_state().done.append("lob_gov")
	u._chk("j4_pmc_needs_bribe", str(BankProducts.collect_check(b).reason).find("podplatená") >= 0)
	GameState.player.cash = 1.0e7
	PoliticsSystem.act("SK", "bribe", "", 0.0, 0.99)
	u._chk("j4_pmc_ready", bool(BankProducts.collect_check(b).ok), str(BankProducts.collect_check(b).reason))
	var eq0 = float(b.equity)
	var res = BankProducts.collect_debts(b, 0.5, 0.99)
	u._chk("j4_pmc_collect", bool(res.ok) and float(res.recovered) > 50000.0 and float(b.equity) > eq0 and not bool(res.scandal))
	u._chk("j4_pmc_no_double", BankProducts.recoverable(b) < 1.0)
	b.defaults_total = float(b.defaults_total) + 100000.0
	var rating0 = int(GameState.player.rating)
	var res2 = BankProducts.collect_debts(b, 0.0, 0.0)
	u._chk("j4_pmc_scandal", bool(res2.scandal) and int(GameState.player.rating) < rating0)
	b.pos = [float(far.x) + 60.0, float(far.y)]
	u._chk("j4_pmc_too_far", str(BankProducts.collect_check(b).reason).find("km") >= 0, str(BankProducts.collect_check(b).reason))

func _gender() -> void:
	u._new()
	GameState.player.gender = "muž"
	var l0 = float(GameState.player.modifiers.labor_mult)
	PoliticsSystem.apply_gender_start()
	u._chk("j4_gender_male_authority", is_equal_approx(float(GameState.player.modifiers.labor_mult), l0 * 0.95))
	GameState.player.cash = 1.0e6
	var r0 = int(GameState.player.rating)
	var c = PoliticsSystem.gender_action("campaign", 0.1)
	u._chk("j4_gender_campaign", bool(c.success) and int(GameState.player.rating) == mini(100, r0 + 5))
	u._chk("j4_gender_cooldown", not bool(PoliticsSystem.gender_action("campaign", 0.1).ok))
	u._chk("j4_gender_male_no_charm", not bool(PoliticsSystem.gender_action("charm", 0.1).ok))
	u._new()
	GameState.player.gender = "žena"
	GameState.player.cash = 1.0e6
	var ch = PoliticsSystem.gender_action("charm", 0.1)
	GameState.player.cash = 1.0e6
	GameState.found_firm("cafe", "", "SK")
	var paid = 1.0e6 - float(GameState.player.cash)
	GameState.player.cash = 1.0e6
	GameState.found_firm("cafe", "", "SK")
	var paid2 = 1.0e6 - float(GameState.player.cash)
	u._chk("j4_gender_charm_discount", bool(ch.success) and paid < paid2 * 0.95 and paid > paid2 * 0.9, "%.0f %.0f" % [paid, paid2])
	var f: Dictionary = GameState.player_firms()[0]
	f.month_hist = [{"rev": 10000.0, "costs": 0.0, "profit": 0.0}]
	var cash0 = float(GameState.player.cash)
	u._chk("j4_gender_female_entrepreneur", is_equal_approx(PoliticsSystem.gender_monthly(), 500.0) and float(GameState.player.cash) > cash0)
	GameState.player.gender = "iné"
	u._chk("j4_gender_other_neutral", PoliticsSystem.gender_monthly() == 0.0 and not bool(PoliticsSystem.gender_action("charm").ok))

func _gender_focus() -> void:
	u._new()
	GameState.player.gender = "muž"
	u._chk("j4_gfocus_male_only", PoliticsSystem.focus_available("g_m1") and not PoliticsSystem.focus_available("g_f1"))
	var c0 = PoliticsSystem.action_cost("SK", "bribe")
	var s0 = PoliticsSystem.scandal_chance("SK", "bribe")
	PoliticsSystem.focus_state().done.append("g_m1")
	u._chk("j4_gfocus_oldboys", PoliticsSystem.action_cost("SK", "bribe") < c0 * 0.95 and PoliticsSystem.scandal_chance("SK", "bribe") < s0)
	PoliticsSystem.focus_state().done.append("g_m2")
	u._chk("j4_gfocus_negotiator", is_equal_approx(PoliticsSystem.rate_bonus(), -0.006))
	u._new()
	GameState.player.gender = "žena"
	u._chk("j4_gfocus_female_only", PoliticsSystem.focus_available("g_f2") and not PoliticsSystem.focus_available("g_m2"))
	PoliticsSystem.focus_state().done.append("g_f1")
	GameState.player.cash = 1.0e6
	GameState.found_firm("cafe", "", "SK")
	var f: Dictionary = GameState.player_firms()[0]
	IndustrySystem.hire_manager(str(f.id), {"name": "X", "skill": 0.5, "salary": 1000.0})
	u._chk("j4_gfocus_network", is_equal_approx(float(f.manager.salary), 920.0))
	PoliticsSystem.focus_state().done.append("g_f2")
	GameState.config.politics = true
	var r0 = int(GameState.player.rating)
	PoliticsSystem.monthly()
	u._chk("j4_gfocus_media_icon", int(GameState.player.rating) == mini(100, r0 + 1), "pol=%s r0=%d r=%d g=%s" % [str(GameState.config.get("politics")), r0, int(GameState.player.rating), PoliticsSystem.gender()])
