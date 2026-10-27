extends RefCounted
# Headless sonda Projektu-47 (presunuta z scripts/main.gd). Vypisuje riadky P47_*.
# Volanie: main.gd (headless) -> preload("res://tests/probe.gd").new().run(self, map)

var host
var map

func run(p_host, p_map) -> int:
	host = p_host
	map = p_map
	SaveSystem.use_test_dir()  # sonda nesmie pisat do skutocnych slotov user://saves
	var rc = _probe()
	SaveSystem.cleanup_test_dir()
	return rc

func _probe() -> int:
	var ok = true
	if not DataLoader.errors.is_empty():
		print("P47_FAIL loader ", ", ".join(DataLoader.errors))
		ok = false
	if DataLoader.commodity_ids.is_empty() or DataLoader.industry_ids.is_empty() or DataLoader.recipes.is_empty():
		print("P47_FAIL empty datasets")
		ok = false
	for ind_id in DataLoader.industry_ids:
		var ind: Dictionary = DataLoader.industries[ind_id]
		if not DataLoader.recipes.has(str(ind.get("recipe", ""))):
			print("P47_FAIL industry recipe ", ind_id)
			ok = false
	for recipe_id in DataLoader.recipes.keys():
		var recipe: Dictionary = DataLoader.recipes[recipe_id]
		for key in recipe.get("inputs", {}).keys():
			if not DataLoader.commodities.has(str(key)):
				print("P47_FAIL input ", recipe_id, " ", key)
				ok = false
		for key2 in recipe.get("outputs", {}).keys():
			if not DataLoader.commodities.has(str(key2)):
				print("P47_FAIL output ", recipe_id, " ", key2)
				ok = false
	var wheat: Dictionary = DataLoader.recipes.get("wheat_farm", {})
	var per_in = float(wheat.get("inputs", {}).get("electricity", 0.0))
	var per_out = float(wheat.get("outputs", {}).get("wheat", 0.0))
	var full_inv = {"electricity": per_in}
	var full: Dictionary = IndustrySystem.apply_recipe(full_inv, "wheat_farm", 1.0, 1.0)
	var full_qty = float(full.get("produced", {}).get("wheat", -1.0))
	var short_inv = {"electricity": per_in * 0.4}
	var short: Dictionary = IndustrySystem.apply_recipe(short_inv, "wheat_farm", 1.0, 1.0)
	var short_qty = float(short.get("produced", {}).get("wheat", -1.0))
	var empty_inv = {}
	var empty: Dictionary = IndustrySystem.apply_recipe(empty_inv, "wheat_farm", 1.0, 1.0)
	if abs(full_qty - per_out) > 0.0001 or abs(float(full_inv.get("electricity", -1.0))) > 0.0001:
		print("P47_FAIL full recipe ", full_qty)
		ok = false
	if short_qty >= full_qty - 0.0001 or abs(short_qty - per_out * 0.4) > 0.0001:
		print("P47_FAIL short recipe ", short_qty)
		ok = false
	if empty.get("produced", {}).size() != 0 or empty_inv.has("wheat"):
		print("P47_FAIL invented output")
		ok = false
	for prod_key in short.get("produced", {}).keys():
		if not wheat.get("outputs", {}).has(prod_key):
			print("P47_FAIL invented good ", prod_key)
			ok = false
	print("P47_RECIPE %.6f %.6f" % [full_qty, short_qty])
	var spec = {
		"id": "spec_batch",
		"inputs": [{"commodity": "electricity", "amount": 2.0}],
		"outputs": [{"commodity": "wheat", "amount": 4.0}],
		"labor": 1, "energy": 1, "tech_level": 0,
	}
	var spec_full = {"electricity": 2.0}
	var spec_a: Dictionary = IndustrySystem.apply_spec(spec_full, spec, 1.0, 1.0)
	var spec_short = {"electricity": 0.8}
	var spec_b: Dictionary = IndustrySystem.apply_spec(spec_short, spec, 1.0, 1.0)
	var spec_qty = float(spec_a.get("produced", {}).get("wheat", -1))
	var spec_low = float(spec_b.get("produced", {}).get("wheat", -1))
	if abs(spec_qty - 4.0) > 0.0001 or spec_low >= spec_qty or abs(spec_low - 1.6) > 0.0001:
		print("P47_FAIL spec recipe ", spec_qty, " ", spec_low)
		ok = false
	if DataLoader.commodity_ids.size() < 15 or not DataLoader.commodities.has("arms") or not DataLoader.commodities.has("chemicals") or not DataLoader.commodities.has("pmc_services"):
		print("P47_FAIL commodities ", DataLoader.commodity_ids.size())
		ok = false
	var arms_out: Dictionary = DataLoader.recipes.get("arms_plant", {}).get("outputs", {})
	var chem_out: Dictionary = DataLoader.recipes.get("chem_plant", {}).get("outputs", {})
	var pmc_in: Dictionary = DataLoader.recipes.get("pmc_unit", {}).get("inputs", {})
	var pmc_out: Dictionary = DataLoader.recipes.get("pmc_unit", {}).get("outputs", {})
	if not arms_out.has("arms") or not chem_out.has("chemicals") or not pmc_in.has("arms") or not pmc_out.has("pmc_services"):
		print("P47_FAIL contract ids ", arms_out, chem_out, pmc_in, pmc_out)
		ok = false
	print("P47_COMMODITIES %d" % DataLoader.commodity_ids.size())
	if LawSystem.statutes("SK").size() < 5 or LawSystem.international_law().size() < 6:
		print("P47_FAIL laws ", LawSystem.statutes("SK").size(), " ", LawSystem.international_law().size())
		ok = false
	if abs(LawSystem.corporate_tax("SK") - 0.21) > 0.0001 or LawSystem.corporate_tax("DE") <= LawSystem.corporate_tax("HU"):
		print("P47_FAIL tax law ", LawSystem.corporate_tax("SK"), " ", LawSystem.corporate_tax("DE"), " ", LawSystem.corporate_tax("HU"))
		ok = false
	if not LawSystem.arms_export_allowed("SK", "SK"):
		print("P47_FAIL arms license")
		ok = false
	print("P47_LAW %d %d %.2f" % [LawSystem.statutes("SK").size(), LawSystem.international_law().size(), LawSystem.corporate_tax("DE")])
	var law = MarketSystem.power_price(100.0, 4.0, 2.0, 1.0)
	var law2 = MarketSystem.power_price(100.0, 4.0, 2.0, 2.0)
	if EconMath.is_bad(law) or EconMath.is_bad(law2) or law <= 0.0 or law2 <= 0.0 or abs(law / 100.0 - 2.0) > 0.0001 or law2 <= law:
		print("P47_FAIL price law ", law, " ", law2)
		ok = false
	print("P47_PRICE_LAW %.6f %.6f" % [law, law2])
	if map == null or map.shapes.is_empty():
		print("P47_FAIL map empty")
		ok = false
	else:
		var shape: Dictionary = {}
		for sh in map.shapes:
			if str(sh.get("iso", "")) == "SK":
				shape = sh
		if shape.is_empty():
			print("P47_FAIL no SK")
			ok = false
		else:
			var poly: PackedVector2Array = shape.polys[0]
			var sk_row: Dictionary = DataLoader.countries["SK"]
			var center = map.project(float(sk_row.get("capital_lat", 0.0)), float(sk_row.get("capital_lon", 0.0)))
			var hits: Array = map.regions_containing(center)
			var picked = map.region_at_world(center)
			if hits.size() != 1 or picked != "SK" or picked != str(hits[0]):
				print("P47_FAIL region ", picked, " ", hits)
				ok = false
			if map.regions_containing(Vector2(-10000, -10000)).size() != 0:
				print("P47_FAIL outside hit")
				ok = false
			var min_p = poly[0]
			var max_p = poly[0]
			for point in poly:
				min_p.x = min(min_p.x, point.x)
				min_p.y = min(min_p.y, point.y)
				max_p.x = max(max_p.x, point.x)
				max_p.y = max(max_p.y, point.y)
			var found_notch = false
			var sx = min_p.x
			while sx <= max_p.x and not found_notch:
				var sy = min_p.y
				while sy <= max_p.y and not found_notch:
					if map.region_at_world(Vector2(sx, sy)) == "":
						found_notch = true
					sy += 1.0
				sx += 1.0
			var sk_regions = 0
			for row in DataLoader.map.get("countries", []):
				if str(row.get("iso2", "")) == "SK":
					sk_regions = row.get("regions", []).size()
			if poly.size() < 5 or not found_notch or sk_regions < 2 or DataLoader.country_ids.size() <= 16:
				print("P47_FAIL outline ", poly.size(), " ", found_notch, " ", sk_regions, " ", DataLoader.country_ids.size())
				ok = false
			var port = map.site_at(center, 80.0)
			if str(port.get("iso", "")) != "SK":
				print("P47_FAIL site ", port)
				ok = false
			var roads = map.sites_of_kind("SK", "road").size()
			var ports = map.sites_of_kind("SK", "port").size()
			var energy = map.sites_of_kind("SK", "energy").size()
			var infra = map.sites_of_kind("SK", "infra").size()
			var region_draw = preload("res://scripts/ui/region_view.gd").new()
			var drawn: PackedVector2Array = region_draw._outline("SK")
			if roads < 1 or ports < 1 or energy < 1 or infra < 1 or drawn.size() != poly.size():
				print("P47_FAIL places ", roads, " ", ports, " ", energy, " ", infra, " ", drawn.size())
				ok = false
			print("P47_PLACES %d %d %d %d %d" % [roads, ports, energy, infra, drawn.size()])
			print("P47_REGION %s" % picked)
			print("P47_OUTLINE %d" % poly.size())
			print("P47_WORLD %d" % DataLoader.country_ids.size())
	var home = "SK" if DataLoader.countries.has("SK") else str(DataLoader.country_ids[0])
	GameState.new_game({
		"loan": 0.0,
		"years": 5,
		"country": home,
		"scenario": "sandbox",
		"found": "",
		"wars": false,
		"disasters": false,
		"hot": false,
		"seed": 47,
		"name": "Probe",
		"year": 2024,
	})
	var region: Dictionary = GameState.world[home]
	var stab0 = float(region.get("stability", 70.0))
	var infl0 = float(region.get("inflation", 0.05))
	var growth0 = float(region.get("gdp_growth", 0.02))
	for key in ["population", "gdp_per_capita", "resources", "infrastructure", "risk"]:
		if not region.has(key):
			print("P47_FAIL region field ", key)
			ok = false
	GameState.world[home].inflation = 0.25
	GameState.world[home].stability = 10.0
	GameState.world[home].gdp_growth = -0.04
	var other = "CZ" if GameState.world.has("CZ") else home
	if other != home:
		GameState.world[other].inflation = 0.01
		GameState.world[other].stability = 95.0
		GameState.world[other].gdp_growth = 0.03
	BankingSystem.update_rates()
	var hi = float(GameState.central[home].base_rate)
	var lo = float(GameState.central[other].base_rate)
	if other != home and not (hi > lo):
		print("P47_FAIL rates ", hi, " ", lo)
		ok = false
	print("P47_RATE %.6f %.6f" % [hi, lo])
	GameState.world[home].inflation = infl0
	GameState.world[home].stability = stab0
	GameState.world[home].gdp_growth = growth0
	BankingSystem.update_rates()
	var cash_before = float(GameState.player.cash)
	var cap = BankingSystem.max_loan_amount(0.0, float(GameState.player.credit_score), float(GameState.world[home].stability))
	var denied: Dictionary = BankingSystem.request_loan(cap + 1000.0, 5)
	if bool(denied.get("ok", true)) or abs(float(GameState.player.cash) - cash_before) > 0.01:
		print("P47_FAIL over cap")
		ok = false
	for b in GameState.banks:
		b.reserves = 1.0
	var broke: Dictionary = BankingSystem.request_loan(5000.0, 5)
	if bool(broke.get("ok", true)) or abs(float(GameState.player.cash) - cash_before) > 0.01:
		print("P47_FAIL underfunded")
		ok = false
	if GameState.banks.size() > 0:
		GameState.banks[0].reserves = 1000000000.0
	var granted: Dictionary = BankingSystem.request_loan(min(cap, 250000.0), 5)
	if not bool(granted.get("ok", false)) or float(granted.amount) > float(granted.cap) + 0.01:
		print("P47_FAIL grant ", granted)
		ok = false
	var base = float(GameState.central[home].base_rate)
	var premium = BankingSystem.risk_premium_for(float(GameState.player.credit_score), float(GameState.world[home].stability))
	if abs(float(granted.get("rate", -1.0)) - (base + premium)) > 0.0001:
		print("P47_FAIL rate mix ", granted.get("rate"), " ", base + premium)
		ok = false
	print("P47_CAP %.4f %.6f" % [float(granted.get("amount", 0.0)), float(granted.get("rate", 0.0))])
	var loan: Dictionary = GameState.player.loans[0]
	var debt_mid = float(loan.remaining)
	GameState.date = {"y": 2024, "m": 1, "d": 10}
	GameState.simulate_day()
	if abs(float(loan.remaining) - debt_mid) > 0.05:
		print("P47_FAIL intra-month charge ", loan.remaining)
		ok = false
	GameState.date = {"y": 2024, "m": 1, "d": 31}
	var cash_m = float(GameState.player.cash)
	var debt_m = float(loan.remaining)
	var pay = float(loan.monthly_payment)
	var rate = float(loan.annual_rate)
	GameState.simulate_day()
	var interest = debt_m * rate / 12.0
	var principal = max(0.0, pay - interest)
	if abs(float(loan.remaining) - (debt_m - principal)) > 0.08 or abs(float(GameState.player.cash) - (cash_m - pay)) > 1.0:
		print("P47_FAIL month ", loan.remaining, " ", GameState.player.cash, " pay ", pay)
		ok = false
	print("P47_MONTH_DEBT %.4f" % float(loan.remaining))
	var placed_bad: Dictionary = IndustrySystem.place_firm(home, "oil_well")
	var count_bad = GameState.player_firms().size()
	if bool(placed_bad.get("ok", true)) or count_bad != 0:
		print("P47_FAIL unavailable place ", placed_bad)
		ok = false
	var placed: Dictionary = IndustrySystem.place_firm(home, "cafe")
	if not bool(placed.get("ok", false)) or GameState.player_firms().size() != 1 or str(GameState.player_firms()[0].get("country", "")) != home:
		print("P47_FAIL place ", placed)
		ok = false
	print("P47_PLACE %d" % GameState.player_firms().size())
	var cash_law = float(GameState.player.cash)
	var thin: Dictionary = BankingSystem.create_bank(0.02, 0.08, 0.01)
	if bool(thin.get("ok", true)) or str(thin.get("reason", "")) != "law" or abs(float(GameState.player.cash) - cash_law) > 0.01:
		print("P47_FAIL reserve law ", thin)
		ok = false
	var bank_res: Dictionary = BankingSystem.create_bank(0.02, 0.08, 0.10)
	if not bool(bank_res.get("ok", false)):
		print("P47_FAIL create bank ", bank_res)
		ok = false
	var pb: Dictionary = bank_res.get("bank", {})
	if abs(float(pb.get("deposit_rate", -1)) - 0.02) > 0.0001 or abs(float(pb.get("loan_rate", -1)) - 0.08) > 0.0001 or abs(float(pb.get("reserve_ratio", -1)) - 0.10) > 0.0001:
		print("P47_FAIL bank rates")
		ok = false
	if float(pb.get("deposits", 0)) <= 0.0 or float(pb.get("npc_loans", 0)) <= 0.0:
		print("P47_FAIL bank book")
		ok = false
	pb.reserves = 1000.0
	pb.deposits = 100000.0
	pb.reserve_ratio = 0.10
	if not BankingSystem.flag_liquidity(pb):
		print("P47_FAIL expected run")
		ok = false
	pb.reserves = 50000.0
	if BankingSystem.flag_liquidity(pb):
		print("P47_FAIL unexpected run")
		ok = false
	print("P47_BANK_RUN 1 0")
	pb.bank_run = false
	pb.reserves = 0.0
	pb.deposits = 1000000.0
	pb.reserve_ratio = 0.5
	pb.failed = false
	GameState.date = {"y": 2024, "m": 12, "d": 31}
	var rate_live = float(GameState.central[home].base_rate)
	var debt_live = float(loan.remaining)
	var tb_live = float(GameState.world["DE"].get("trade_balance", 0.0))
	var infl_live = float(GameState.world["DE"].get("inflation", 0.0))
	GameState.world["DE"].infra_damage = false
	GameState.world["PL"].infra_damage = false
	GameState.config.shock_war = ["DE", "PL"]
	var px_prev = float(GameState.markets[home]["food_service"].get("price", 0.0))
	var stock_prev = float(GameState.markets[home]["food_service"].get("stock", 0.0))
	GameState.simulate_day()
	var book: Dictionary = GameState.markets[home]["food_service"]
	var expect_prod = float(book.get("f_pop", 0.0)) * float(book.get("f_income", 0.0)) * float(book.get("f_tod", 0.0))
	expect_prod *= float(book.get("f_weather", 0.0)) * float(book.get("f_holiday", 0.0))
	expect_prod *= float(book.get("f_comp", 0.0)) * float(book.get("f_geo", 0.0))
	var base_px = float(DataLoader.commodity("food_service").get("base_price", 1.0))
	var elas_px = float(DataLoader.commodity("food_service").get("elasticity", 1.0))
	# etapa 1: cena sa pocita adaptivnym krokom z predosleho dna (adjust_price), nie bezpamatovym power_price
	var expect_px = MarketSystem.adjust_price(px_prev, max(float(book.get("last_dem", 0.0)), 0.0001), max(float(book.get("last_sup", 0.0)), 0.0001), stock_prev, base_px)
	var fin: Dictionary = GameState.markets[home]["finance"]
	var cafe_live: Dictionary = GameState.player_firms()[0]
	var expect_inv = BankingSystem.investment_factor(rate_live)
	if float(book.get("f_holiday", 0.0)) <= 1.0 or abs(float(book.get("demand_product", -1.0)) - expect_prod) > max(1.0, abs(expect_prod) * 0.000001):
		print("P47_FAIL live factors ", book.get("f_holiday"), " ", book.get("demand_product"), " ", expect_prod)
		ok = false
	if abs(float(book.get("price", 0.0)) - expect_px) > 0.001:
		print("P47_FAIL live price ", book.get("price"), " ", expect_px)
		ok = false
	if float(fin.get("capital_add", 0.0)) <= 0.0:
		print("P47_FAIL live capital ", fin.get("capital_add"))
		ok = false
	if not bool(pb.get("bank_run", false)) or float(pb.get("liquidity", 1.0)) >= float(pb.get("reserve_ratio", 0.0)) or float(pb.get("deposits", 0.0)) >= 1000000.0 or float(pb.get("run_withdrawn", 0.0)) <= 0.0:
		print("P47_FAIL live run ", pb.get("bank_run"), " ", pb.get("liquidity"), " ", pb.get("deposits"))
		ok = false
	if float(loan.remaining) >= debt_live - 0.05:
		print("P47_FAIL live installment ", loan.remaining, " ", debt_live)
		ok = false
	var expect_tb = tb_live - abs(tb_live) * 0.25 - 1.0
	var infl_after = float(GameState.world["DE"].get("inflation", 0.0))
	var infl_at = float(GameState.world["DE"].get("inflation_at_shock", infl_live))
	if not bool(GameState.world["DE"].get("infra_damage", false)) or abs(float(GameState.world["DE"].trade_balance) - expect_tb) > 1.0 or infl_after + 0.000001 < infl_at + 0.03:
		print("P47_FAIL live war ", GameState.world["DE"].get("trade_balance"), " ", infl_after, " ", expect_tb)
		ok = false
	if abs(float(cafe_live.get("last_invest", -1.0)) - expect_inv) > 0.000001:
		print("P47_FAIL live invest day ", cafe_live.get("last_invest"), " ", expect_inv)
		ok = false
	print("P47_LIVE %.4f %.4f %d %.4f %.4f" % [float(book.get("f_holiday", 0.0)), float(loan.remaining), 1 if bool(pb.get("bank_run", false)) else 0, float(cafe_live.get("last_invest", 0.0)), infl_after - infl_at])
	var geo_peace_arms = float(GameState.markets["DE"]["arms"].get("f_geo", 0.0))
	var geo_peace_chem = float(GameState.markets["DE"]["chemicals"].get("f_geo", 0.0))
	var geo_peace_pmc = float(GameState.markets["DE"]["pmc_services"].get("f_geo", 0.0))
	GameState.simulate_day()
	var geo_war_arms = float(GameState.markets["DE"]["arms"].get("f_geo", 0.0))
	var geo_war_chem = float(GameState.markets["DE"]["chemicals"].get("f_geo", 0.0))
	var geo_war_pmc = float(GameState.markets["DE"]["pmc_services"].get("f_geo", 0.0))
	var spec_arms = GeopoliticsSystem.conflict_demand(true, "arms")
	var spec_chem = GeopoliticsSystem.conflict_demand(true, "chemicals")
	var spec_pmc = GeopoliticsSystem.conflict_demand(true, "pmc_services")
	if geo_war_arms <= geo_peace_arms or geo_war_chem <= geo_peace_chem or geo_war_pmc <= geo_peace_pmc:
		print("P47_FAIL live ids ", geo_war_arms, " ", geo_war_chem, " ", geo_war_pmc)
		ok = false
	if abs(geo_war_arms - spec_arms) > 0.0001 or abs(geo_war_chem - spec_chem) > 0.0001 or abs(geo_war_pmc - spec_pmc) > 0.0001:
		print("P47_FAIL id factors ", geo_war_arms, " ", geo_war_chem, " ", geo_war_pmc)
		ok = false
	print("P47_IDS %.4f %.4f %.4f" % [geo_war_arms, geo_war_chem, geo_war_pmc])
	if LawSystem.arms_export_allowed("SK", "DE"):
		print("P47_FAIL att export")
		ok = false
	GameState.wars.clear()
	GameState.world["DE"].infra_damage = false
	GameState.world["PL"].infra_damage = false
	var cash_hold = float(GameState.player.cash)
	var bond_n = GameState.player.bonds.size()
	var bond_msg = BankingSystem.buy_bond(home, 1000.0)
	if bond_msg != "" or GameState.player.bonds.size() != bond_n + 1 or float(GameState.player.cash) >= cash_hold - 0.01:
		print("P47_FAIL bond ", bond_msg)
		ok = false
	var share_firm = {}
	for firm in GameState.firms:
		if str(firm.get("owner", "")) == "ai":
			share_firm = firm
			break
	if share_firm.is_empty():
		print("P47_FAIL no share firm")
		ok = false
	else:
		share_firm.share_price = 10.0
		var cash_s = float(GameState.player.cash)
		var owned0 = int(GameState.player.stocks.get(share_firm.id, 0))
		var share_msg = BankingSystem.buy_stock(str(share_firm.id), 1)
		if share_msg != "" or int(GameState.player.stocks.get(share_firm.id, 0)) != owned0 + 1 or float(GameState.player.cash) >= cash_s - 0.01:
			print("P47_FAIL share ", share_msg)
			ok = false
	print("P47_HOLDINGS %d %d" % [GameState.player.bonds.size(), GameState.player.stocks.size()])
	var inv_lo = BankingSystem.investment_factor(0.01)
	var inv_hi = BankingSystem.investment_factor(0.2)
	var cap_lo = BankingSystem.capital_demand(0.01, 1000000.0)
	var cap_hi = BankingSystem.capital_demand(0.2, 1000000.0)
	if inv_hi >= inv_lo or abs(cap_hi - cap_lo) < 0.001:
		print("P47_FAIL capital channel ", inv_lo, " ", inv_hi, " ", cap_lo, " ", cap_hi)
		ok = false
	var saved_cash = float(GameState.player.cash)
	var saved_firms = GameState.player_firms().size()
	var saved_dep = float(pb.get("deposit_rate", -1.0))
	var save_msg = SaveSystem.save_slot(9)
	GameState.player.cash = -50.0
	var load_msg = SaveSystem.load_slot(9)
	if load_msg != "" or abs(float(GameState.player.cash) - saved_cash) > 0.05 or GameState.player_firms().size() != saved_firms:
		print("P47_FAIL save ", save_msg, " ", load_msg)
		ok = false
	var restored = {}
	for b2 in GameState.banks:
		if str(b2.get("owner", "")) == "player":
			restored = b2
	if abs(float(restored.get("deposit_rate", -1)) - saved_dep) > 0.0001:
		print("P47_FAIL bank restore")
		ok = false
	print("P47_SAVE ok")
	GameState.firms.append({
		"id": "probe_mill",
		"name": "Oceliareň",
		"owner": "player",
		"country": home,
		"industry": "steel_mill",
		"cash": 10.0,
		"closed": false,
		"history": [],
		"facilities": [],
	})
	GameState.player.cash = -1000000000.0
	GameState.player.bankrupt = false
	GameState.date = {"y": 2025, "m": 1, "d": 31}
	var score0 = float(GameState.player.credit_score)
	var open0 = GameState.player_firms().size()
	GameState.simulate_day()
	var mill_open = false
	var cafe_open = false
	for firm_left in GameState.player_firms():
		if str(firm_left.get("industry", "")) == "steel_mill":
			mill_open = true
		if str(firm_left.get("industry", "")) == "cafe":
			cafe_open = true
	if float(GameState.player.credit_score) >= score0 or GameState.player_firms().size() >= open0 or mill_open or not cafe_open:
		print("P47_FAIL bankruptcy path ", GameState.player.credit_score, " ", GameState.player_firms().size(), " ", mill_open, " ", cafe_open)
		ok = false
	var has_event = false
	for ev in GameState.player.events:
		if str(ev.get("type", "")) == "bankruptcy":
			has_event = true
	if not has_event:
		print("P47_FAIL no bankruptcy event")
		ok = false
	var peace_arms = GeopoliticsSystem.conflict_demand(false, "arms")
	var war_arms = GeopoliticsSystem.conflict_demand(true, "arms")
	var peace_ch = GeopoliticsSystem.conflict_demand(false, "chemicals")
	var war_ch = GeopoliticsSystem.conflict_demand(true, "chemicals")
	var peace_pmc = GeopoliticsSystem.conflict_demand(false, "pmc_services")
	var war_pmc = GeopoliticsSystem.conflict_demand(true, "pmc_services")
	if war_arms <= peace_arms or war_ch <= peace_ch or war_pmc <= peace_pmc:
		print("P47_FAIL war demand")
		ok = false
	var intact = 1.0
	GameState.world[home].infra_damage = true
	var damaged = GeopoliticsSystem.supply_mult(home, "wheat")
	GameState.world[home].infra_damage = false
	var healed = GeopoliticsSystem.supply_mult(home, "wheat")
	if damaged > healed or damaged > intact:
		print("P47_FAIL supply mult ", damaged, " ", healed)
		ok = false
	var shock = {"inflation": 0.02, "trade_balance": 100.0}
	GeopoliticsSystem.apply_war_shock(shock)
	if float(shock.inflation) <= 0.02 or float(shock.trade_balance) >= 100.0:
		print("P47_FAIL war shock")
		ok = false
	var tb_before = float(GameState.world["DE"].get("trade_balance", 0.0))
	GeopoliticsSystem._start_war("DE", "PL")
	if not bool(GameState.world["DE"].get("infra_damage", false)) or float(GameState.world["DE"].trade_balance) >= tb_before:
		print("P47_FAIL live war")
		ok = false
	var infra_hit = false
	for site in GameState.sites:
		if str(site.get("iso", "")) == "DE" and str(site.get("kind", "")) == "infra" and bool(site.get("damaged", false)):
			infra_hit = true
	if not infra_hit:
		print("P47_FAIL infra site")
		ok = false
	GameState.wars.clear()
	GameState.world["DE"].infra_damage = false
	GameState.world["PL"].infra_damage = false
	print("P47_WAR %.4f %.4f" % [war_arms, damaged])
	GameState.date = {"y": 2024, "m": 3, "d": 1}
	GameState.simulate_day()
	if int(GameState.date.d) != 2 or int(GameState.date.m) != 3:
		print("P47_FAIL date ", GameState.date)
		ok = false
	print("P47_DATE %d-%02d-%02d" % [int(GameState.date.y), int(GameState.date.m), int(GameState.date.d)])
	GameState.player.cash = 100000.0
	GameState.player.bankrupt = false
	var research_err = GameState.start_research("logistics1")
	if research_err != "":
		print("P47_FAIL research start ", research_err)
		ok = false
	GameState.player.research.left = 1
	GameState.simulate_day()
	if abs(float(GameState.player.modifiers.get("freight_mult", 1.0)) - 0.9) > 0.0001 or not GameState.player.done.has("logistics1"):
		print("P47_FAIL research ", GameState.player.modifiers.get("freight_mult"), " ", GameState.player.done)
		ok = false
	var util_set = IndustrySystem.set_production(0.5)
	var util_read = -1.0
	for firm_u in GameState.player_firms():
		if str(firm_u.get("industry", "")) != "cafe":
			continue
		for fac_u in firm_u.get("facilities", []):
			util_read = float(fac_u.get("util", -1.0))
	if abs(util_set - 0.5) > 0.0001 or abs(util_read - 0.5) > 0.0001:
		print("P47_FAIL production ", util_set, " ", util_read)
		ok = false
	print("P47_PLAY %.4f %.4f" % [float(GameState.player.modifiers.freight_mult), util_read])
	GameState.date = {"y": 2024, "m": 12, "d": 24}
	var hol = EventSystem.holiday_factor(home, "food_service")
	var wx = EventSystem.weather_factor("storm", "construction")
	var dummy = {"gdp_growth": 0.03}
	var grown = EventSystem.apply_recession(dummy)
	if hol <= 1.0 or wx >= 1.0 or grown >= 0.03:
		print("P47_FAIL events ", hol, " ", wx, " ", grown)
		ok = false
	var dem_hol = MarketSystem._one_demand(home, "food_service")
	GameState.date.d = 10
	var dem_plain = MarketSystem._one_demand(home, "food_service")
	if dem_hol <= dem_plain:
		print("P47_FAIL live demand ", dem_hol, " ", dem_plain)
		ok = false
	var recipe_w: Dictionary = DataLoader.recipes["wheat_farm"]
	var fac_w = {"util": 1.0, "scale": 1.0, "auto": false, "country": home}
	var firm_w = {"owner": "player", "country": home}
	GameState.central[home].base_rate = 0.01
	var thru_lo = IndustrySystem._throughput(firm_w, fac_w, recipe_w)
	GameState.central[home].base_rate = 0.25
	var thru_hi = IndustrySystem._throughput(firm_w, fac_w, recipe_w)
	if thru_hi >= thru_lo:
		print("P47_FAIL live invest ", thru_lo, " ", thru_hi)
		ok = false
	print("P47_EVENT %.4f %.4f %.4f" % [hol, wx, grown])
	var ai = {"country": home, "cash": 9000.0, "decision": "", "owner": "ai"}
	var decision = AgentSystem.month_decision(ai)
	if decision != "invest" or str(ai.decision) != "invest":
		print("P47_FAIL ai ", decision)
		ok = false
	print("P47_AI %s" % decision)
	GameState.set_view("region")
	var zoom_a = GameState.view_mode
	GameState.set_view("world")
	var zoom_b = GameState.view_mode
	if zoom_a != "region" or zoom_b != "world":
		print("P47_FAIL zoom")
		ok = false
	print("P47_ZOOM %s %s" % [zoom_a, zoom_b])
	if not DataLoader.errors.is_empty():
		print("P47_FAIL loader after ", ", ".join(DataLoader.errors))
		ok = false
	print("P47_LOADER %d" % DataLoader.errors.size())
	var factors: Dictionary = MarketSystem.demand_factors(home, "wheat")
	for fk in ["population", "income_factor", "time_of_day_factor", "weather_factor", "holiday_factor", "competition_factor", "geopolitics_factor"]:
		if not factors.has(fk):
			print("P47_FAIL factor ", fk)
			ok = false
	GameState.player.cash = 800000.0
	var t0 = GeopoliticsSystem.tariff("SK", "CZ")
	var sanc = GeopoliticsSystem.impose_sanction("CZ")
	var t1 = GeopoliticsSystem.tariff("SK", "CZ")
	if sanc != "" or not GeopoliticsSystem.blocked("SK", "CZ") or t1 <= t0:
		print("P47_FAIL sanction ", sanc, " ", t0, " ", t1)
		ok = false
	var slot8 = SaveSystem.save_slot(8)
	var lifted = GeopoliticsSystem.lift_sanction("CZ")
	var loaded = SaveSystem.load_slot(8)
	if lifted != "" or loaded != "" or slot8 == "" or not GeopoliticsSystem.is_sanctioned("SK", "CZ"):
		print("P47_FAIL sanction save ", lifted, " ", loaded)
		ok = false
	GeopoliticsSystem.lift_sanction("CZ")
	if GeopoliticsSystem.is_sanctioned("SK", "CZ") or GeopoliticsSystem.blocked("SK", "CZ"):
		print("P47_FAIL sanction lift")
		ok = false
	print("P47_DIPLO %.4f %.4f" % [t0, t1])
	var rows: Array = GeopoliticsSystem.relation_rows()
	var base_us = GeopoliticsSystem.tariff("SK", "US")
	var emb = host.play_diplomacy("embargo", "US")
	var emb_t = GeopoliticsSystem.tariff("SK", "US")
	host.play_diplomacy("lift_embargo", "US")
	var ally = host.play_diplomacy("alliance", "US")
	var ally_t = GeopoliticsSystem.tariff("SK", "US")
	host.play_diplomacy("break_alliance", "US")
	var pact = host.play_diplomacy("treaty", "US")
	var pact_t = GeopoliticsSystem.tariff("SK", "US")
	host.play_diplomacy("break_treaty", "US")
	var cut = host.play_diplomacy("relief", "US")
	var cut_t = GeopoliticsSystem.tariff("SK", "US")
	host.play_diplomacy("revoke_relief", "US")
	GameState.config.dev_player_war = true  # JUAN4: hrac v hre vojnu vyhlasit nemoze, sonda testuje system
	var war_err = host.play_diplomacy("war", "US")
	var at_war = GeopoliticsSystem.at_war("SK") and GeopoliticsSystem.blocked("SK", "US")
	var peace_err = host.play_diplomacy("peace", "US")
	var at_peace = not GeopoliticsSystem.at_war("SK") and not GeopoliticsSystem.blocked("SK", "US")
	if host.diplomacy_text().find("US") < 0 or rows.size() != DataLoader.country_ids.size() - 1 or emb != "" or ally != "" or pact != "" or cut != "" or war_err != "" or peace_err != "":
		print("P47_FAIL diplo act ", rows.size(), " ", emb, " ", war_err, " ", peace_err)
		ok = false
	if emb_t <= base_us or ally_t > 0.0001 or pact_t > 0.0001 or cut_t >= base_us or not at_war or not at_peace:
		print("P47_FAIL diplo tariff ", base_us, " ", emb_t, " ", ally_t, " ", pact_t, " ", cut_t, " ", at_war, " ", at_peace)
		ok = false
	print("P47_ACT %d %.4f %.4f %.4f" % [rows.size(), emb_t, ally_t, cut_t])
	GameState.world["RU"].political_risk = 0.2
	var ai_trade = AgentSystem.country_policy("RU")
	GameState.world["RU"].political_risk = 0.7
	var ai_sanc = AgentSystem.country_policy("RU")
	var declared = host.play_diplomacy("war", "JP")
	var battle: Dictionary = GeopoliticsSystem.war_between("SK", "JP")
	var inten0 = float(battle.get("intensity", 0.0))
	GeopoliticsSystem.daily()
	GeopoliticsSystem.daily()
	var lasting: Dictionary = GeopoliticsSystem.war_between("SK", "JP")
	var armed = AgentSystem.country_policy("SK")
	var inten1 = float(GeopoliticsSystem.war_between("SK", "JP").get("intensity", 0.0))
	var ended = host.play_diplomacy("peace", "JP")
	var un_err = host.play_diplomacy("un", "TR")
	var un_tariff = GeopoliticsSystem.tariff("SK", "TR")
	var un_type = ""
	if GameState.world_events.size() > 0:
		un_type = str(GameState.world_events[GameState.world_events.size() - 1].get("type", ""))
	GeopoliticsSystem.lift_security_council("TR")
	if ai_trade != "trade" or ai_sanc != "sanction" or declared != "" or ended != "" or un_err != "":
		print("P47_FAIL state ", ai_trade, " ", ai_sanc, " ", declared, " ", ended, " ", un_err)
		ok = false
	if inten0 <= 0.0 or int(lasting.get("days", 0)) != 2 or armed != "militarize" or inten1 <= inten0 or GeopoliticsSystem.at_war("SK") or un_tariff < 0.8 or un_type != "un_sanction":
		print("P47_FAIL war stay ", inten0, " ", lasting.get("days", 0), " ", armed, " ", inten1, " ", un_tariff, " ", un_type)
		ok = false
	print("P47_STATE %s %s %d %.3f" % [ai_trade, armed, int(lasting.get("days", 0)), inten1])
	var ids: Array = host.research_button_ids()
	if ids.size() != 7:
		print("P47_FAIL research ids ", ids.size())
		ok = false
	GameState.player.cash = 2000000.0
	var started = GameState.start_research("auto1")
	var queued = GameState.start_research("agro1")
	if started != "" or queued != "":
		print("P47_FAIL research queue ", started, " ", queued)
		ok = false
	GameState.player.research.left = 1
	GameState.simulate_day()
	if str(GameState.player.research.get("id", "")) != "agro1":
		print("P47_FAIL research next ", GameState.player.research)
		ok = false
	var slid = host.apply_production_slider(0.75)
	var slid_read = -1.0
	for firm_s in GameState.player_firms():
		if str(firm_s.get("industry", "")) != "cafe":
			continue
		for fac_s in firm_s.get("facilities", []):
			slid_read = float(fac_s.get("util", -1.0))
	if abs(slid - 0.75) > 0.0001 or abs(slid_read - 0.75) > 0.0001:
		print("P47_FAIL slider ", slid, " ", slid_read)
		ok = false
	print("P47_UI %d %.2f" % [ids.size(), slid_read])
	var edges: Array = GameState.research_edges()
	var linked = false
	for edge in edges:
		if str(edge.get("from", "")) == "logistics1" and str(edge.get("to", "")) == "logistics2":
			linked = true
		if str(edge.get("from", "")) == "auto1" and str(edge.get("to", "")) == "arms1":
			linked = linked and true
	if edges.size() < 2 or not linked:
		print("P47_FAIL edges ", edges)
		ok = false
	GameState.player.cash = 5000000.0
	GameState.player.research.left = 1
	GameState.simulate_day()
	var steps = ["chem1", "arms1", "energy1", "logistics2", "score1"]
	for rid_step in steps:
		var step_err = GameState.start_research(str(rid_step))
		if step_err != "" and step_err != "Už beží." and step_err != "Už vo fronte.":
			print("P47_FAIL tech start ", rid_step, " ", step_err)
			ok = false
		if not GameState.player.research.is_empty():
			GameState.player.research.left = 1
			GameState.simulate_day()
		elif GameState.player.research_queue.size() > 0:
			GameState.simulate_day()
	var mods_now: Dictionary = GameState.player.modifiers
	if float(mods_now.get("freight_mult", 1.0)) >= 0.9 or float(mods_now.get("labor_mult", 1.0)) >= 1.0 or float(mods_now.get("yield_agro", 1.0)) <= 1.0 or float(mods_now.get("yield_chem", 1.0)) <= 1.0 or float(mods_now.get("yield_weapons", 1.0)) <= 1.0 or float(mods_now.get("power_mult", 1.0)) >= 1.0 or float(mods_now.get("default_mult", 1.0)) >= 1.0:
		print("P47_FAIL effects ", mods_now)
		ok = false
	if host.firm_screen_text().find("Doprava") < 0:
		print("P47_FAIL firm surface")
		ok = false
	print("P47_TECH %.2f %.2f %.2f %.2f %.2f %.2f %.2f" % [float(mods_now.freight_mult), float(mods_now.labor_mult), float(mods_now.yield_agro), float(mods_now.yield_chem), float(mods_now.yield_weapons), float(mods_now.power_mult), float(mods_now.default_mult)])
	var firm_ids: Array = host.industry_button_ids()
	var cafe_id = ""
	for firm_row in GameState.player_firms():
		if str(firm_row.get("industry", "")) == "cafe":
			cafe_id = str(firm_row.get("id", ""))
	var made_u = IndustrySystem.set_firm_production(cafe_id, "food_service", 0.4)
	var made_px = IndustrySystem.set_sale_price(cafe_id, "food_service", 9.5)
	var made_sh = IndustrySystem.set_shifts(cafe_id, 2)
	var pmc_ok = IndustrySystem.sign_pmc(cafe_id, "SK")
	var pmc_off = IndustrySystem.cancel_pmc(cafe_id)
	var trade_ok = IndustrySystem.set_trade_route(cafe_id, "wheat", "import", 5.0)
	var ledger: Dictionary = IndustrySystem.firm_ledger(cafe_id)
	if firm_ids.size() != DataLoader.industry_ids.size() or cafe_id == "" or abs(made_u - 0.4) > 0.0001 or abs(made_px - 9.5) > 0.0001 or made_sh != 2:
		print("P47_FAIL firm ", firm_ids.size(), " ", made_u, " ", made_px, " ", made_sh)
		ok = false
	if pmc_ok != "" or pmc_off != "" or trade_ok != "" or str(ledger.get("trade", "")) != "import" or int(ledger.get("shifts", 0)) != 2:
		print("P47_FAIL firm desk ", pmc_ok, " ", pmc_off, " ", trade_ok, " ", ledger)
		ok = false
	print("P47_FIRM %d %.1f %d" % [firm_ids.size(), made_px, made_sh])
	GameState.player.cash = 5000.0
	var rest: Dictionary = host.post_play_bond("ask", 100.0)
	var below: Dictionary = host.post_play_bond("bid", 90.0)
	var cash_rest = float(GameState.player.cash)
	var bonds_rest = GameState.player.bonds.size()
	if int(below.get("filled", 1)) != 0 or int(below.get("open", 0)) < 2 or abs(cash_rest - 5000.0) > 0.01:
		print("P47_FAIL book rest ", rest, " ", below)
		ok = false
	var shown = host.bond_book_text()
	if shown.find("bid") < 0 or shown.find("ask") < 0:
		print("P47_FAIL book text ", shown)
		ok = false
	var cross: Dictionary = host.post_play_bond("bid", 110.0)
	if int(cross.get("filled", 0)) < 1 or GameState.player.bonds.size() <= bonds_rest or float(GameState.player.cash) >= cash_rest:
		print("P47_FAIL book fill ", cross, " ", GameState.player.cash)
		ok = false
	var still = 0
	for row in BankingSystem.open_bond_orders():
		if str(row.get("side", "")) == "bid" and abs(float(row.get("price", 0.0)) - 90.0) < 0.01:
			still += 1
	if still != 1:
		print("P47_FAIL book open ", still)
		ok = false
	print("P47_BOOK %d %d" % [int(cross.get("filled", 0)), still])
	var rest_eq: Dictionary = host.post_play_stock("ask", "CAFE", 4.0, 3.0)
	var low_eq: Dictionary = host.post_play_stock("bid", "CAFE", 2.5, 3.0)
	var cash_eq = float(GameState.player.cash)
	var shares0 = int(GameState.player.stocks.get("CAFE", 0))
	if int(low_eq.get("filled", 1)) != 0 or int(low_eq.get("open", 0)) < 2:
		print("P47_FAIL equity rest ", rest_eq, " ", low_eq)
		ok = false
	var hit_eq: Dictionary = host.post_play_stock("bid", "CAFE", 4.0, 2.0)
	if int(hit_eq.get("filled", 0)) < 1 or int(GameState.player.stocks.get("CAFE", 0)) < shares0 + 2 or float(GameState.player.cash) >= cash_eq:
		print("P47_FAIL equity fill ", hit_eq, " ", GameState.player.stocks.get("CAFE", 0))
		ok = false
	print("P47_EQ %d %d" % [int(hit_eq.get("filled", 0)), int(GameState.player.stocks.get("CAFE", 0))])
	var cash_issue = float(GameState.player.cash)
	var issue_count = GameState.player.bonds.size()
	var issue_err = BankingSystem.issue_bond(500.0, 0.08, 2.0)
	var cafe_for_issue = ""
	var shares_before = 0
	for firm_issue in GameState.player_firms():
		if str(firm_issue.get("industry", "")) == "cafe":
			cafe_for_issue = str(firm_issue.get("id", ""))
			shares_before = int(firm_issue.get("shares", 0))
	var share_err = BankingSystem.issue_shares(cafe_for_issue, 10, 3.0)
	var shares_after = 0
	for firm_issue2 in GameState.player_firms():
		if str(firm_issue2.get("id", "")) == cafe_for_issue:
			shares_after = int(firm_issue2.get("shares", 0))
	if issue_err != "" or share_err != "" or float(GameState.player.cash) < cash_issue + 500.0 + 30.0 - 0.01 or GameState.player.bonds.size() != issue_count + 1 or shares_after != shares_before + 10:
		print("P47_FAIL issue ", issue_err, " ", share_err, " ", GameState.player.cash, " ", shares_after)
		ok = false
	GameState.player.bonds.append({
		"country": "SK",
		"face": 100.0,
		"coupon": 0.365,
		"years_left": 0.001,
		"issuer": "state",
	})
	var cash_before_coupon = float(GameState.player.cash)
	var bond_before_coupon = GameState.player.bonds.size()
	var serv: Dictionary = BankingSystem.service_bonds()
	var short_left = false
	for bond_row in GameState.player.bonds:
		if abs(float(bond_row.get("face", 0.0)) - 100.0) < 0.01 and float(bond_row.get("years_left", 1.0)) <= 0.0:
			short_left = true
	if int(serv.get("matured", 0)) < 1 or short_left or float(GameState.player.cash) <= cash_before_coupon or GameState.player.bonds.size() >= bond_before_coupon:
		print("P47_FAIL mature ", serv, " ", GameState.player.cash)
		ok = false
	print("P47_ISSUE %d %d" % [shares_after - shares_before, int(serv.get("matured", 0))])
	var art_n = host._sprite_colors("res://assets/sprites/cafe.png")
	for art_path in ["res://assets/sprites/factory.png", "res://assets/sprites/bank.png", "res://assets/sprites/arms_plant.png", "res://assets/sprites/chem_plant.png", "res://assets/sprites/ui_chrome.png", "res://assets/tilesets/terrain.png", "res://assets/tilesets/border.png", "res://assets/tilesets/city.png"]:
		art_n = mini(art_n, host._sprite_colors(art_path))
	if art_n < 2:
		print("P47_FAIL art ", art_n)
		ok = false
	print("P47_ART %d" % art_n)
	EventSystem.apply_recession(GameState.world["SK"])
	GameState.world["SK"].weather = "storm"
	EventSystem.announce_weather("SK")
	var saved_date = GameState.date.duplicate()
	GameState.date = {"y": 2024, "m": 12, "d": 24}
	EventSystem.announce_holiday("SK")
	GameState.date = saved_date
	var kinds = {}
	for story in GameState.stories:
		kinds[str(story.get("kind", ""))] = true
	for kind_name in ["war", "sanction", "holiday", "storm", "recession", "bankruptcy", "research"]:
		if not kinds.has(kind_name):
			print("P47_FAIL news ", kind_name)
			ok = false
	if EventSystem.climate_board().find("christian_west") < 0:
		print("P47_FAIL climate")
		ok = false
	print("P47_NEWS %d" % kinds.size())
	var site_id = AgentSystem.found_site("CZ")
	var move_err = AgentSystem.move_production(site_id, "AT")
	var moved_firm = GameState.firm_by_id(site_id)
	moved_firm.cash = -50.0
	var shut_err = AgentSystem.close_failed(site_id)
	var shut_firm = GameState.firm_by_id(site_id)
	var tax_before = IndustrySystem.tax_due("HU", 1000.0)
	var raised = LawSystem.set_tax("HU", tax_before / 1000.0 + 0.1)
	var tax_after = IndustrySystem.tax_due("HU", 1000.0)
	var sheet: Dictionary = LawSystem.minister_sheet("HU")
	if site_id == "" or move_err != "" or str(moved_firm.get("country", "")) != "AT" or shut_err != "" or not bool(shut_firm.get("closed", false)):
		print("P47_FAIL ai firm ", site_id, " ", move_err, " ", shut_err)
		ok = false
	if tax_after <= tax_before or abs(float(sheet.get("tax", 0.0)) - raised) > 0.0001 or not sheet.has("debt") or not sheet.has("stability") or not sheet.has("rating"):
		print("P47_FAIL minister ", tax_before, " ", tax_after, " ", sheet)
		ok = false
	print("P47_MIN %.2f %.2f" % [tax_before, tax_after])
	var home_iso = str(GameState.player.get("home", "SK"))
	var min_sheet: Dictionary = LawSystem.minister_sheet(home_iso)
	print("P47_MIN_DATA %s %.4f %.4f %d %d" % [
		home_iso,
		float(min_sheet.get("rate", 0.0)),
		float(min_sheet.get("cpi", 0.0)),
		int(min_sheet.get("n_laws", 0)),
		int(min_sheet.get("n_ai_firms", 0)),
	])
	if ok:
		print("P47_PROBE_OK")
		return 0
	print("P47_FAIL")
	return 1
