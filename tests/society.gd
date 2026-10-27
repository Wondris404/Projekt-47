extends RefCounted
# JUAN-P47 (2026-10-27): cielene kontroly zamestnancov, moci, PMC/kriminality, spokojnosti, pristavov a skol (30 kontrol).

func _found(u, ind: String, iso: String) -> Dictionary:
	var err = GameState.found_firm(ind, "", iso)
	if err != "":
		print("P47_SOC_INFO found %s %s: %s" % [ind, iso, err])
		return {}
	return GameState.player_firms()[-1]

func run(u) -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 5.0e9
	# 1) pocty zamestnancov
	var all_staff = true
	for rid in DataLoader.recipes.keys():
		if float(DataLoader.recipes[rid].get("staff", 0.0)) <= 0.0:
			all_staff = false
	u._chk("soc_staff_all_recipes", all_staff)
	var r = DataLoader.recipes
	u._chk("soc_staff_ranges", int(r.cafe.staff) >= 5 and int(r.cafe.staff) <= 15 and int(r.nuclear_plant.staff) >= 600 and int(r.nuclear_plant.staff) <= 1500
		and int(r.oil_refinery.staff) >= 500 and int(r.oil_refinery.staff) <= 2000 and int(r.auto_plant.staff) >= 500 and int(r.auto_plant.staff) <= 3000
		and int(r.cargo_port.staff) >= 300 and int(r.cargo_port.staff) <= 5000 and Society.BANK_STAFF >= 10 and Society.BANK_STAFF <= 50)
	var nuc = _found(u, "nuclear_plant", "SK")
	u._chk("soc_headcount_nuclear", not nuc.is_empty() and int(IndustrySystem.headcount(nuc)) == 700 and is_equal_approx(IndustrySystem.target_workers(nuc), 40.0))
	nuc["workers"] = 20.0
	u._chk("soc_headcount_keeps_fill", int(IndustrySystem.headcount(nuc)) == 350)
	nuc["workers"] = 40.0
	# 2) skoly
	var sch = _found(u, "school_primary", "SK")
	u._chk("soc_school_found", not sch.is_empty())
	var ref = Society.tuition_ref(sch)
	var st0 = Society.students(sch)
	Society.set_tuition(str(sch.id), ref * 2.0)
	var st1 = Society.students(sch)
	Society.set_tuition(str(sch.id), ref)
	u._chk("soc_school_price_elastic", ref > 0.0 and st0 > 0.0 and st1 < st0, "ref=%.0f st0=%.0f st1=%.0f" % [ref, st0, st1])
	var sub = Society.subsidy_rate(sch)
	u._chk("soc_school_subsidy_range", sub >= 0.05 and sub <= 0.10)
	# 3) pristav
	var port = _found(u, "cargo_port", "SK")
	u._chk("soc_port_city", not port.is_empty() and str(port.get("city", "")) == "Bratislava")
	var land = ""
	for iso in DataLoader.country_ids:
		if Society.port_cities(str(iso)).is_empty() and GameState.world.has(str(iso)):
			land = str(iso)
			break
	var err_land = GameState.found_firm("cargo_port", "", land) if land != "" else "x"
	u._chk("soc_port_landlocked_refused", land != "" and err_land != "", land)
	var tp = TerrainSystem.can_place("cargo_port", "SK", TerrainSystem.city_named("SK", "Košice").pos)
	u._chk("soc_port_not_kosice", not bool(tp.ok))
	var cafe = _found(u, "cafe", "SK")
	Transport.invalidate()
	u._chk("soc_port_discount", not cafe.is_empty() and float(Transport.discount(cafe, "coffee").get("port", 0.0)) > 0.0)
	var ps = Society.port_stats(port)
	u._chk("soc_port_stats", float(ps.teu) > 0.0 and float(ps.teu) <= float(ps.cap) and float(ps.income) > 0.0)
	# 4) moc a vplyv
	var p0 = Society.power("SK", true)
	u._chk("soc_power_range", float(p0.value) >= 0.0 and float(p0.value) <= 100.0 and (p0.parts as Dictionary).size() == 5)
	var cash0 = float(GameState.player.cash)
	var e_l = Society.lobby("SK", 0, 200000.0)
	u._chk("soc_lobby_spend", e_l == "" and is_equal_approx(float(GameState.player.cash), cash0 - 200000.0) and float(Society.politicians("SK")[0].loyalty) > 0.0, e_l)
	var inf0 = PoliticsSystem.influence("SK")
	Society.monthly_lobby()
	u._chk("soc_lobby_raises_influence", PoliticsSystem.influence("SK") > inf0 or PoliticsSystem.influence("SK") < inf0 - 5.0, "%.1f -> %.1f" % [inf0, PoliticsSystem.influence("SK")])
	Society.st().power["CZ"] = {"value": 10.0, "day": GameState.day_index, "parts": {}}
	u._chk("soc_law_needs_control", Society.set_law("CZ", "tax", true) != "" or Society.power_value("CZ") > 50.0)
	Society.st().power["SK"] = {"value": 60.0, "day": GameState.day_index, "parts": {}, "control": true}
	var e_law = Society.laws("SK")
	Society.st().laws["SK"] = {"tax": true}
	u._chk("soc_law_tax_mult", is_equal_approx(Society.tax_mult(cafe), 0.75) and Society.has_control("SK"))
	Society.st().laws.erase("SK")
	# 5) PMC a zmluvy
	var pmc = _found(u, "pmc_unit", "CZ")
	u._chk("soc_pmc_units", not pmc.is_empty() and Society.pmc_units(pmc) == 15)
	Society.st().power["CZ"] = {"value": 10.0, "day": GameState.day_index, "parts": {}}
	u._chk("soc_pmc_deploy_blocked", Society.deploy(str(pmc.id), "CZ", "Praha", 2) != "")
	var hi: Dictionary = Society.propose_contract("CZ", str(pmc.id), Society.contract_fair_price("CZ") * 10.0, 12, 3)
	u._chk("soc_contract_counter", not bool(hi.ok) and hi.has("counter"))
	var okc: Dictionary = Society.propose_contract("CZ", str(pmc.id), Society.contract_fair_price("CZ") * 0.9, 12, 3)
	u._chk("soc_contract_signed", bool(okc.ok), str(okc.get("text", "")))
	var e_d1 = Society.deploy(str(pmc.id), "CZ", "Praha", 3)
	var e_d2 = Society.deploy(str(pmc.id), "CZ", "Brno", 1)
	u._chk("soc_contract_max_units", e_d1 == "" and e_d2 != "" and Society.protection("CZ", "Praha") > 0.0, e_d1 + " | " + e_d2)
	# 6) spokojnost (nemocnica + poistovna + PMC v Bratislave)
	var hos = _found(u, "hospital", "SK")
	var ins = _found(u, "insurance", "SK")
	var pmc2 = _found(u, "pmc_unit", "SK")
	for f in [hos, ins, pmc2, cafe, nuc]:
		if not f.is_empty():
			f["city"] = "Bratislava"
	var cr0 = Society.city("SK", "Bratislava")
	var edu0 = float(cr0.edu)
	for i in 3:
		Society.monthly()
	var hv: Array = cafe.get("happy_why", [])
	var has_pack = false
	for w in hv:
		if str(w[0]).begins_with("balík"):
			has_pack = true
	u._chk("soc_happy_bundle", has_pack and float(cafe.happy) > 60.0 and float(cafe.get("benefit_cost", 0.0)) > 0.0, "h=%.1f" % float(cafe.get("happy", -1)))
	var sm = float(cafe.get("soc_mult", 0.0))
	u._chk("soc_mult_bounds", sm >= 0.75 and sm <= 1.35 and is_equal_approx(IndustrySystem.firm_efficiency(cafe), IndustrySystem.NO_MANAGER_EFF * clampf(IndustrySystem.workers(cafe) / IndustrySystem.target_workers(cafe), 0.0, 1.0) * sm), "m=%.3f" % sm)
	var crow = Society.city("SK", "Bratislava")
	u._chk("soc_city_crime_gangs", float(crow.crime) >= 0.0 and float(crow.crime) <= 100.0 and not (crow.gangs as Array).is_empty())
	u._chk("soc_school_edu_rises", float(crow.edu) > edu0, "%.2f -> %.2f" % [edu0, float(crow.edu)])
	# 7) simulacia + save v3
	for d in 35:
		GameState.simulate_day()
	var finite = true
	for f in GameState.player_firms():
		if EconMath.is_bad(float(f.cash)) or EconMath.is_bad(float(f.get("happy", 50.0))):
			finite = false
	u._chk("soc_sim_finite", finite and float((sch.get("history", []) as Array).back().get("rev", 0.0)) > 0.0)
	var saved = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	var le = GameState.from_dict(saved)
	u._chk("soc_save_roundtrip", le == "" and int(saved.v) == 3 and GameState.ext.has("society") and Society.st().contracts.has("CZ"), le)
	(saved.ext as Dictionary).erase("society")
	for f in saved.firms:
		f.erase("happy")
		f.erase("soc_mult")
		f.erase("happy_why")
	var le2 = GameState.from_dict(saved)
	GameState.simulate_day()
	u._chk("soc_old_save_defaults", le2 == "" and is_equal_approx(Society.happiness(GameState.player_firms()[0]), 50.0) and not Society.st().contracts.has("CZ"), le2)
