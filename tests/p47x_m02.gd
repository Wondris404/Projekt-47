extends RefCounted

func run(u) -> void:
	var m = P47Mechanics
	u._new()
	u._chk("m02_start", m.M02.defcon(m) == 5 and absf(m.M02.value(m) - 15.0) < 0.001 and not GameState.ext.has("p47x"))
	var y0 = BankingSystem._bond_yield("SK")
	var arms0 = GeopoliticsSystem.conflict_demand(false, "weapons")
	GeopoliticsSystem._start_war("SK", "HU")
	u._chk("m02_war_raises", absf(m.M02.value(m) - 27.0) < 0.001 and m.M02.defcon(m) == 4 and m.M02.by_iso(m, "SK") > 0.0)
	u._chk("m02_effects", GeopoliticsSystem.conflict_demand(false, "weapons") > arms0 and BankingSystem._bond_yield("SK") > y0 and GeopoliticsSystem.conflict_demand(false, "wheat") == 1.0)
	u._chk("m02_breakdown_sum", absf(m.sum_parts(m.M02.breakdown(m)) - m.M02.value(m)) < 0.001)
	m.monthly()
	u._chk("m02_decay", m.M02.value(m) < 27.0 and m.M02.by_iso(m, "SK") < 12.0)
	var row = m.state("tension")
	row.value = 38.0
	var msg = m.confirm_needed("war", "CZ")
	u._chk("m02_confirm_first", msg.contains("DEFCON"), msg)
	u._chk("m02_confirm_second", m.confirm_needed("war", "CZ") == "")
	u._chk("m02_no_confirm_small", m.confirm_needed("alliance", "CZ") == "")
	row.value = 85.0
	m.add_tension(5.0, "", "Test")
	var crisis = false
	for item in GameState.news:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("text", "")).contains("Jadrová kríza"):
			crisis = true
	u._chk("m02_defcon1_crisis", m.M02.defcon(m) == 1 and crisis)
	var saved = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	u._chk("m02_save_load", GameState.from_dict(saved) == "" and m.M02.defcon(m) == 1)
	u._new()
	m.only([])
	var before_arms = GeopoliticsSystem.conflict_demand(true, "weapons")
	GeopoliticsSystem._start_war("SK", "HU")
	var root: Dictionary = GameState.ext.p47x
	u._chk("m02_off_no_state", not root.has("tension") and GeopoliticsSystem.conflict_demand(true, "weapons") == before_arms and m.confirm_needed("war", "CZ") == "" and m.status_text() == "")
	var before = GameState.to_dict()
	m.monthly()
	u._chk("m02_off_no_change", before == GameState.to_dict())
