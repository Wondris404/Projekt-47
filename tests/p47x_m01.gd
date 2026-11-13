extends RefCounted

func _cfg(year: int, extra: Dictionary = {}) -> Dictionary:
	var c = {"loan": 0.0, "years": 5, "country": "SK", "scenario": "sandbox", "found": "",
		"wars": false, "disasters": false, "hot": false, "seed": 47, "name": "Unit", "year": year}
	c.merge(extra, true)
	return c

func run(u) -> void:
	var m = P47Mechanics
	u._new()
	var gdp24 = float(GameState.world.US.gdp_usd)
	var snap24 = GameState.to_dict()
	u._chk("m01_years", m.start_years().has(1950) and m.start_years().has(2024))
	GameState.new_game(_cfg(1950))
	u._chk("m01_1950_date", int(GameState.date.y) == 1950)
	u._chk("m01_1950_gdp", absf(float(GameState.world.US.gdp_usd) - gdp24 * 0.12) < 1.0)
	u._chk("m01_lock_ai", IndustrySystem.unlock_reason("ai_firm", "SK").contains("neexistuje") and m.industry_lock("cafe") == "")
	GameState.player.cash = 1.0e9
	u._chk("m01_found_refused", GameState.found_firm("ai_firm", "", "SK").contains("neexistuje"))
	for i in 3:
		GameState.paused = false
		GameState.simulate_day()
	u._chk("m01_runs", int(GameState.date.y) == 1950 and not EconMath.is_bad(float(GameState.world.US.gdp_usd)))
	var saved = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	u._chk("m01_save_load", GameState.from_dict(saved) == "" and int(GameState.date.y) == 1950)
	GameState.new_game(_cfg(1950, {"p47x_enabled": {"M01": false}}))
	u._chk("m01_off", absf(float(GameState.world.US.gdp_usd) - gdp24) < 1.0 and m.industry_lock("ai_firm") == "" and not m.active("M01"))
	u._new()
	var again = GameState.to_dict()
	u._chk("m01_2024_unchanged", JSON.stringify(again.world) == JSON.stringify(snap24.world) and not GameState.ext.has("p47x"))
