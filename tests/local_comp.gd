extends RefCounted

func run(u) -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 1.0e9
	for i in 16:
		GameState.found_firm("cafe", "Kaviareň %d" % i, "SK" if i < 12 else "CZ")
	for i in 8:
		GameState.found_firm("restaurant", "Reštaurácia %d" % i, "SK")
	var firms = GameState.player_firms()
	u._chk("local_comp_setup", firms.size() == 24)
	if firms.size() != 24:
		return
	firms[1].closed = true
	IndustrySystem._prepare_local_competition()
	var equal = true
	for firm in firms:
		var fac: Dictionary = firm.facilities[0]
		IndustrySystem.use_local_competition_cache = false
		var old = IndustrySystem._local_mult(firm, fac, "food_service")
		IndustrySystem.use_local_competition_cache = true
		var cached = IndustrySystem._local_mult(firm, fac, "food_service")
		if old != cached:
			equal = false
	u._chk("local_comp_matches_scan", equal)
	var cross: Dictionary = firms[0].facilities[0].duplicate(true)
	cross.country = "CZ"
	IndustrySystem.use_local_competition_cache = false
	var cross_original = IndustrySystem._local_mult(firms[0], cross, "food_service")
	IndustrySystem.use_local_competition_cache = true
	u._chk("local_comp_foreign_facility", cross_original == IndustrySystem._local_mult(firms[0], cross, "food_service"))
	var fac: Dictionary = firms[0].facilities[0]
	IndustrySystem.use_local_competition_cache = false
	var t0 = Time.get_ticks_usec()
	for i in 2000:
		IndustrySystem._local_mult(firms[0], fac, "food_service")
	var old_us = Time.get_ticks_usec() - t0
	IndustrySystem.use_local_competition_cache = true
	t0 = Time.get_ticks_usec()
	for i in 2000:
		IndustrySystem._local_mult(firms[0], fac, "food_service")
	print("P47_LOCAL_COMP original_ms=%.2f cached_ms=%.2f" % [old_us / 1000.0, (Time.get_ticks_usec() - t0) / 1000.0])
	MarketSystem._distance_cache.wait_for_completion()
	var start = GameState.to_dict().duplicate(true)
	GameState.from_dict(start.duplicate(true))
	IndustrySystem.use_local_competition_cache = false
	t0 = Time.get_ticks_usec()
	for i in 3:
		GameState.simulate_day()
	var sim_original = (Time.get_ticks_usec() - t0) / 3000.0
	var original = GameState.to_dict().duplicate(true)
	GameState.from_dict(start.duplicate(true))
	IndustrySystem.use_local_competition_cache = true
	t0 = Time.get_ticks_usec()
	for i in 3:
		GameState.simulate_day()
	var sim_cached = (Time.get_ticks_usec() - t0) / 3000.0
	print("P47_LOCAL_SIM original_ms_per_day=%.2f cached_ms_per_day=%.2f" % [sim_original, sim_cached])
	var cached = GameState.to_dict().duplicate(true)
	u._chk("local_comp_full_state_identical", JSON.stringify(original) == JSON.stringify(cached))
