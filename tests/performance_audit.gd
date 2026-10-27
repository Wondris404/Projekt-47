extends RefCounted

func run() -> void:
	GameState.new_game({"loan": 0.0, "country": "SK", "scenario": "sandbox", "wars": false, "rivals": true, "seed": 47, "year": 2024})
	GameState.config.progression = false
	GameState.player.cash = 5.0e10
	var kinds = ["coal_mine", "iron_mine", "steel_mill", "power_coal", "oil_well", "oil_refinery", "auto_plant", "telecom", "newspaper", "tv_station", "data_center", "ai_firm", "logistics_hub", "wheat_farm", "gas_well", "shipyard"]
	var count = 0
	for iso in ["SK", "CZ", "DE", "PL", "AT", "HU", "FR", "IT", "US", "CN", "GB", "ES"]:
		for i in 6:
			if GameState.found_firm(kinds[(count + i) % kinds.size()], "Profil %d" % count, iso) == "": count += 1
	MarketSystem._distance_cache.wait_for_completion()
	for i in 5: GameState.simulate_day()
	var times: Array = []
	var total = 0.0
	for i in 100:
		var start = Time.get_ticks_usec()
		GameState.simulate_day()
		var ms = (Time.get_ticks_usec() - start) / 1000.0
		times.append(ms)
		total += ms
	times.sort()
	print("P47_BENCHMARK ", JSON.stringify({"countries": DataLoader.country_ids.size(), "player_firms": count, "total_firms": GameState.firms.size(), "days": 100, "warmup": 5, "mean_ms": total/100.0, "p50_ms": times[50], "p95_ms": times[95], "max_ms": times[99]}))
