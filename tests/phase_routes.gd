extends RefCounted

func run(u) -> void:
	u._new()
	var original_books = GameState.markets.duplicate(true)
	MarketSystem._update_capacity(false)
	var full_capacity = GameState.markets.duplicate(true)
	GameState.markets = original_books.duplicate(true)
	var capacity_index = 0
	while capacity_index < DataLoader.country_ids.size():
		capacity_index = MarketSystem._update_capacity_chunk(capacity_index, 12, false)
	u._chk("capacity_chunk_identical", JSON.stringify(GameState.markets) == JSON.stringify(full_capacity))
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 1.0e8
	GameState.found_firm("cafe", "Profil kaviarne", "SK")
	GameState.found_firm("coal_mine", "Profil bane", "CZ")
	GameState.found_firm("power_coal", "Profil elektrárne", "CZ")
	MarketSystem._distance_cache.wait_for_completion()
	var start = GameState.to_dict().duplicate(true)
	for i in 3:
		GameState.simulate_day()
	var sync = GameState.to_dict().duplicate(true)
	var err = GameState.from_dict(start.duplicate(true))
	u._chk("route_phase_restore", err == "", err)
	var completed = 0
	var route_steps = 0
	var plan_steps = 0
	while completed < 3:
		if GameState._ph == 3:
			route_steps += 1
		if GameState._ph == 2:
			plan_steps += 1
		if GameState._sim_phase():
			completed += 1
	var phased = GameState.to_dict().duplicate(true)
	u._chk("route_phase_split", route_steps > 3, str(route_steps))
	u._chk("plan_phase_split", plan_steps > 3, str(plan_steps))
	u._chk("route_phase_state_identical", JSON.stringify(sync) == JSON.stringify(phased))
	GameState.from_dict(start.duplicate(true))
	while GameState._ph != 3:
		GameState._sim_phase()
	GameState._sim_phase()
	u._chk("route_phase_pending", GameState.day_in_progress())
	GameState.finish_pending_day()
	u._chk("route_phase_finish_pending", not GameState.day_in_progress() and GameState.day_index == int(start.day_index) + 1)
	GameState.from_dict(start.duplicate(true))
	while GameState._ph != 2:
		GameState._sim_phase()
	GameState._sim_phase()
	GameState.finish_pending_day()
	u._chk("plan_phase_finish_pending", not GameState.day_in_progress() and GameState.day_index == int(start.day_index) + 1)
