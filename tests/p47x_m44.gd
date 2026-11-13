extends RefCounted

func run(u) -> void:
	u._new()
	var before = GameState.to_dict()
	for debt in [0.0, 0.6, 2.5, 20.0]:
		GameState.world.SK.debt_gdp = debt
		u._chk("m44_bond_parts_%s" % debt, absf(P47Mechanics.sum_parts(BankingSystem._bond_yield_parts("SK")) - BankingSystem._bond_yield("SK")) < 0.000001)
		u._chk("m44_loan_parts_%s" % debt, absf(P47Mechanics.sum_parts(SovereignLoans.suggested_rate_parts("SK")) - SovereignLoans.suggested_rate("SK")) < 0.000001)
	GameState.ext["p47x"] = {"enabled": {"M44": false}}
	var disabled = GameState.to_dict()
	u._chk("m44_disabled_empty", BankingSystem._bond_yield_parts("SK").is_empty() and SovereignLoans.suggested_rate_parts("SK").is_empty() and P47Mechanics.breakdown_text([{"label":"x", "value":1.0}]) == "")
	u._chk("m44_disabled_state_rng", disabled == GameState.to_dict())
	GameState.from_dict(before)
	var metric = load("res://scripts/ui/hud_metric.gd").new()
	metric.set_breakdown(BankingSystem._bond_yield_parts("SK"))
	u._chk("m44_metric_tooltip", metric.tooltip_text.contains("Centrálna sadzba"))
	metric.free()
	u._chk("m44_no_state_created", not GameState.ext.has("p47x"))
