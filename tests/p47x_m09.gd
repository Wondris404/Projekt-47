extends RefCounted

func run(u) -> void:
	var m = P47Mechanics
	u._new()
	var def = GameState.research_def("auto1")
	var days0 = GameState._research_days(def)
	var cost0 = GameState.research_cost(def)
	u._chk("m09_progress_visible", m.M09.text(m, "auto1").contains("0 / 3"), m.M09.text(m, "auto1"))
	for i in 3:
		GameState.firms.append({"id": "t%d" % i, "owner": "player", "industry": "cafe"})
	GameState.player.cash = 1.0e7
	GameState.start_research("logistics1")
	var slot: Dictionary = GameState.player.research
	var left0 = int(slot.left)
	GameState.firms.append({"id": "t9", "owner": "player", "industry": "warehouse"})
	m.monthly()
	u._chk("m09_unlock", m.M09.has_eureka(m, "auto1") and m.M09.has_eureka(m, "logistics1"))
	u._chk("m09_discount", GameState._research_days(def) == int(ceil(days0 * 0.6)) and absf(GameState.research_cost(def) - cost0 * 0.6) < 0.01)
	u._chk("m09_running_prorata", int(slot.left) == int(ceil(left0 * 0.6)), "%d -> %d" % [left0, int(slot.left)])
	GameState.firms = GameState.firms.filter(func(f): return not str(f.get("id", "")).begins_with("t"))
	var saved = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	var lerr = GameState.from_dict(saved)
	u._chk("m09_save_load", lerr == "" and m.M09.has_eureka(m, "auto1"), lerr)
	u._new()
	m.only([])
	for i in 3:
		GameState.firms.append({"id": "t%d" % i, "owner": "player", "industry": "cafe"})
	var before = GameState.to_dict()
	m.monthly()
	u._chk("m09_off_no_change", before == GameState.to_dict() and GameState._research_days(def) == days0 and GameState.research_cost(def) == cost0 and m.M09.text(m, "auto1") == "")
