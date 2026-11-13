extends RefCounted

func _old_yield(iso: String) -> float:
	var c: Dictionary = GameState.world[iso]
	return EconMath.cl(float(GameState.central[iso].policy) + float(c.political_risk) * 0.35 + max(0.0, float(c.debt_gdp) - 0.6) * 0.04, 0.004, 0.3)

func run(u) -> void:
	u._new()
	var m = P47Mechanics
	var sk = BankingSystem._bond_yield("SK")
	u._chk("m12_parts_sum", absf(m.sum_parts(BankingSystem._bond_yield_parts("SK")) - sk) < 0.000001 and absf(m.sum_parts(SovereignLoans.suggested_rate_parts("SK")) - SovereignLoans.suggested_rate("SK")) < 0.000001)
	u._chk("m12_calibration_sk", sk > 0.01 and sk < 0.12, "SK %.4f" % sk)
	var all_ok = true
	var over = 0
	var old_over = 0
	for iso in GameState.world.keys():
		var y = BankingSystem._bond_yield(iso)
		over += 1 if y > 0.15 else 0
		old_over += 1 if _old_yield(iso) > 0.15 else 0
		all_ok = all_ok and y >= 0.004 and y <= 0.5 and SovereignLoans.suggested_rate(iso) >= y
	u._chk("m12_range_all", all_ok and over <= old_over + 3, "nad 15 %%: %d (stary vzorec %d) z %d" % [over, old_over, GameState.world.size()])
	GameState.world.SK.debt_gdp = 2.0
	u._chk("m12_debt_raises", BankingSystem._bond_yield("SK") > sk)
	GameState.world.SK.debt_gdp = 0.5
	var stab_ht = float(GameState.world.get("HT", {}).get("stability", 0.0))
	m.monthly()
	u._chk("m12_baseline_no_penalty", float(GameState.world.get("HT", {}).get("stability", 0.0)) == stab_ht)
	GameState.world.SK.debt_gdp = 20.0
	GameState.world.SK.political_risk = 1.0
	var stab = float(GameState.world.SK.stability)
	var growth = float(GameState.world.SK.gdp_growth)
	m.monthly()
	m.monthly()
	var pen = float(m.peek("m12").get("gdp_pen", {}).get("SK", 0.0))
	u._chk("m12_penalty", float(GameState.world.SK.stability) < stab and pen > 0.0 and absf(float(GameState.world.SK.gdp_growth) - (growth - pen)) < 0.000001, "pen %.4f" % pen)
	GameState.world.SK.debt_gdp = 0.5
	GameState.world.SK.political_risk = 0.1
	m.monthly()
	u._chk("m12_penalty_restored", absf(float(GameState.world.SK.gdp_growth) - growth) < 0.000001)
	u._new()
	m.set_enabled("M12", false)
	u._chk("m12_off_old_formula", absf(BankingSystem._bond_yield("SK") - _old_yield("SK")) < 0.0000001)
	GameState.world.SK.debt_gdp = 20.0
	var before = GameState.to_dict()
	m.monthly()
	u._chk("m12_off_no_change", before == GameState.to_dict())
	u._new()
	var old = GameState.to_dict()
	old.ext.erase("p47x")
	u._chk("m12_old_save", GameState.from_dict(old) == "" and BankingSystem._bond_yield("SK") > 0.0)
