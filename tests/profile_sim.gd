extends RefCounted

func run() -> void:
	GameState.new_game({"loan": 0.0, "country": "SK", "scenario": "sandbox", "wars": false, "seed": 47, "year": 2024})
	GameState.config.progression = false
	GameState.player.cash = 5.0e10
	var kinds = ["coal_mine", "iron_mine", "steel_mill", "power_coal", "oil_well", "oil_refinery", "auto_plant", "telecom", "newspaper", "tv_station", "data_center", "ai_firm", "logistics_hub", "wheat_farm", "gas_well", "shipyard"]
	var countries = ["SK", "CZ", "DE", "PL", "AT", "HU", "FR", "IT", "US", "CN", "GB", "ES"]
	var count = 0
	for iso in countries:
		for i in 6:
			if GameState.found_firm(kinds[(count + i) % kinds.size()], "Profil %d" % count, iso) == "":
				count += 1
	var samples := {}
	var max_times := {}
	var totals := {}
	var sub_samples := {}
	var sub_totals := {}
	var sub_max := {}
	var days = 0
	while days < 10:
		var stage = int(GameState._ph)
		var sub = int(MarketSystem._begin_stage) if stage == 1 else -1
		var start = Time.get_ticks_usec()
		var done = GameState._sim_phase()
		var elapsed = float(Time.get_ticks_usec() - start) / 1000.0
		samples[stage] = int(samples.get(stage, 0)) + 1
		totals[stage] = float(totals.get(stage, 0.0)) + elapsed
		max_times[stage] = maxf(float(max_times.get(stage, 0.0)), elapsed)
		if sub >= 0:
			sub_samples[sub] = int(sub_samples.get(sub, 0)) + 1
			sub_totals[sub] = float(sub_totals.get(sub, 0.0)) + elapsed
			sub_max[sub] = maxf(float(sub_max.get(sub, 0.0)), elapsed)
		if done:
			days += 1
	for stage in samples:
		print("P47_PHASE phase=%d count=%d mean_ms=%.3f max_ms=%.3f" % [stage, int(samples[stage]), float(totals[stage]) / float(samples[stage]), float(max_times[stage])])
	for sub in sub_samples:
		print("P47_MARKET_STAGE stage=%d count=%d mean_ms=%.3f max_ms=%.3f" % [sub, int(sub_samples[sub]), float(sub_totals[sub]) / float(sub_samples[sub]), float(sub_max[sub])])
	print("P47_PHASE_DONE firms=%d days=%d" % [count, days])
