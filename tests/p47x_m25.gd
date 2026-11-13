extends RefCounted

func run(u) -> void:
	var m = P47Mechanics
	u._new()
	GameState.config.wars = false
	GeopoliticsSystem._start_war("HU", "RO")
	var wid = str(GameState.wars[-1].id)
	u._chk("m25_needs_plant", m.proxy_supply(wid, "HU", "arms", 50000.0) != "")
	GameState.firms.append({"id": "tp", "owner": "player", "industry": "arms_plant", "closed": false})
	var err = m.proxy_supply(wid, "HU", "arms", 50000.0)
	u._chk("m25_contract", err == "" and m.M25.contracts(m).size() == 1, err)
	GameState.player.cash = 0.0
	var rel = GeopoliticsSystem.relation("SK", "HU")
	var t0 = m.M02.value(m)
	m.M25.monthly(m)
	var detected = m.M25.contracts(m).is_empty()
	u._chk("m25_income", float(GameState.player.cash) > 0.0)
	u._chk("m25_tension_or_detect", detected or (m.M02.value(m) > t0 and GeopoliticsSystem.relation("SK", "HU") > rel))
	if not detected:
		GeopoliticsSystem._end_war(GameState.wars[-1])
		m.M25.monthly(m)
		u._chk("m25_concession", m.concession_mult("HU") < 1.0 and PoliticsSystem.cost_mult("HU") < PoliticsSystem.cost_mult("RO") + 0.000001 and m.M25.contracts(m).is_empty())
	GameState.firms = GameState.firms.filter(func(f): return str(f.get("id", "")) != "tp")
	var saved = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	u._chk("m25_save_load", GameState.from_dict(saved) == "")
	u._new()
	m.only([])
	GeopoliticsSystem._start_war("HU", "RO")
	u._chk("m25_off_refuse", m.proxy_supply(str(GameState.wars[-1].id), "HU", "arms", 50000.0) != "" and m.concession_mult("HU") == 1.0)
	var before = GameState.to_dict()
	m.monthly()
	u._chk("m25_off_no_change", before == GameState.to_dict())
