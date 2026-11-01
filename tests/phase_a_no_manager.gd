extends RefCounted
# Fáza A: pravá ruka je preč. Starý save s manažérom sa načíta, firma beží, bonus sa nečíta.

func run(u) -> void:
	u._new()
	GameState.player.cash = 5.0e6
	GameState.found_firm("cafe", "", "SK")
	var src: Dictionary = GameState.player_firms()[0]
	src["manager"] = {"name": "Stará Ruka", "gender": "f", "skill": 0.95, "salary": 9000000.0}
	var snap = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	var kept = false
	for row in snap.firms:
		if str(row.get("owner", "")) == "player" and str(row.get("manager", {}).get("name", "")) == "Stará Ruka":
			kept = true
	u._chk("a_manager_kept_in_save", kept)
	var err = GameState.from_dict(snap)
	var g: Dictionary = GameState.player_firms()[0] if GameState.player_firms().size() > 0 else {}
	u._chk("a_old_manager_loads", err == "" and str(g.get("manager", {}).get("name", "")) == "Stará Ruka", err)
	var staff = 1.0
	var tgt = IndustrySystem.target_workers(g)
	if tgt > 0.0:
		staff = clampf(IndustrySystem.workers(g) / tgt, 0.0, 1.0)
	var soc = float(g.get("soc_mult", 1.0))
	u._chk("a_eff_ignores_manager", is_equal_approx(IndustrySystem.firm_efficiency(g), IndustrySystem.NO_MANAGER_EFF * staff * soc))
	g.manager.skill = 0.0
	u._chk("a_eff_skill_irrelevant", is_equal_approx(IndustrySystem.firm_efficiency(g), IndustrySystem.NO_MANAGER_EFF * staff * soc))
	u._chk("a_buy_share_full", IndustrySystem.buy_share(g) == 1.0)
	GameState.running = true
	GameState.paused = false
	g.history = []
	GameState.simulate_day()
	var hist: Array = g.get("history", [])
	var wages = float(hist.back().get("wages", 1.0e9)) if not hist.is_empty() else 1.0e9
	u._chk("a_salary_not_paid", wages < 5000.0 and is_finite(float(g.cash)), "wages %.2f cash %.2f" % [wages, float(g.cash)])
	var svc = {"hospital": 0, "insurance": 0, "pmc": 0, "school": 0, "academy": 0}
	var crow = {"crime": 12.0}
	var with_m = Society.compute_happiness(g, svc, crow, 0.0)
	var bare = g.duplicate(true)
	bare["manager"] = {}
	var no_m = Society.compute_happiness(bare, svc, crow, 0.0)
	var label = false
	for w in with_m.why:
		if str(w[0]).find("pravá ruka") >= 0:
			label = true
	u._chk("a_happy_fair", is_equal_approx(float(with_m.h), float(no_m.h)) and not label, "h=%.2f" % float(with_m.h))
	var focus: Dictionary = PoliticsSystem.focus_def("g_f1")
	u._chk("a_focus_wage", str(focus.desc).find("pravá") < 0 and is_equal_approx(float(focus.bonus.wage), 0.97), str(focus.desc))
	var host = Engine.get_main_loop().current_scene
	if host != null and host.has_method("firm_detail_text"):
		var txt = str(host.firm_detail_text(g))
		u._chk("a_detail_no_right_hand", txt.find("pravá ruka") < 0 and txt.find("PRAVÁ RUKA") < 0 and txt.find("Základný manažment") >= 0)
	else:
		u._chk("a_detail_no_right_hand", false, "chýba scéna")
