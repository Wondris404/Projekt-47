extends Node

const RAMADAN = {
	2024: [3, 11], 2025: [3, 1], 2026: [2, 18], 2027: [2, 8], 2028: [1, 28],
	2029: [1, 16], 2030: [1, 5], 2031: [12, 14], 2032: [12, 3], 2033: [11, 22],
	2034: [11, 11], 2035: [10, 31], 2036: [10, 20], 2037: [10, 9], 2038: [9, 28],
}
const LUNAR = {
	2024: [2, 10], 2025: [1, 29], 2026: [2, 17], 2027: [2, 6], 2028: [1, 26],
	2029: [2, 13], 2030: [2, 3], 2031: [1, 23], 2032: [2, 11], 2033: [1, 31],
	2034: [2, 19], 2035: [2, 8], 2036: [1, 28],
}
const DIWALI = {
	2024: [11, 1], 2025: [10, 20], 2026: [11, 8], 2027: [10, 29], 2028: [10, 17],
	2029: [11, 5], 2030: [10, 24], 2031: [11, 12], 2032: [10, 31], 2033: [11, 19],
	2034: [11, 8], 2035: [10, 28], 2036: [11, 15],
}

func begin_day() -> void:
	for iso in GameState.world.keys():
		var w: Dictionary = GameState.world[iso]
		var left = int(w.get("weather_left", 0))
		if left > 0:
			w.weather_left = left - 1
			if w.weather_left <= 0:
				w.weather = "clear"
			continue
		if not GameState.config.get("disasters", true):
			w.weather = "clear"
			continue
		var roll = _hash01(iso, GameState.day_index)
		var lat = float(w.get("lat", 0.0))
		var season = TimeSystem.season_index(lat)
		if roll < 0.012 and season != 0:
			w.weather = "drought"
			w.weather_left = 22
			if roll < 0.004:
				GameState.post_news("%s: sucho škrtí úrodu." % w.get("name_sk", iso))
		elif roll > 0.992:
			w.weather = "storm"
			w.weather_left = 6
			GameState.post_news("%s: búrky brzdia stavby a logistiku." % w.get("name_sk", iso))
		elif season == 0 and abs(lat) > 40.0 and roll > 0.97:
			w.weather = "cold"
			w.weather_left = 12

# DEAD: duplikat GeopoliticsSystem.demand_mult, bez volajuceho (etapa 0: nezmazane, len oznacene)
func demand_mult(iso: String, cid: String) -> float:
	var c: Dictionary = GameState.world.get(iso, {})
	var m = 1.0
	var group = str(c.get("holiday_group", "secular"))
	var month = int(GameState.date.m)
	var day = int(GameState.date.d)
	if group == "christian_west" or group == "christian_east":
		var xmas = (month == 12 and day >= 22) or (month == 1 and day <= 2)
		if group == "christian_east":
			xmas = (month == 1 and day >= 5 and day <= 8) or (month == 12 and day >= 24)
		if xmas:
			m *= _xmas(cid)
		var eas: Dictionary = TimeSystem.easter(int(GameState.date.y)) if group == "christian_west" else TimeSystem.orthodox_easter(int(GameState.date.y))
		if TimeSystem.within_md(int(eas.m), int(eas.d) - 2 if int(eas.d) > 2 else int(eas.d), 5) and month == int(eas.m):
			if cid == "food_service" or cid == "meat":
				m *= 1.18
	if group == "muslim" and _in_table(RAMADAN, 30):
		m *= _ramadan(cid)
		if _in_table(RAMADAN, 33) and not _in_table(RAMADAN, 30):
			if cid in ["food_service", "textiles", "meat"]:
				m *= 1.25
	if group == "east_asia" and _in_table(LUNAR, 6):
		if cid in ["food_service", "meat", "textiles"]:
			m *= 1.3
		if cid == "construction":
			m *= 0.7
	if group == "india" and _in_table(DIWALI, 4):
		if cid in ["food_service", "textiles", "electronics"]:
			m *= 1.28
	var weather = str(c.get("weather", "clear"))
	if weather == "cold" and cid == "electricity":
		m *= 1.16
	if weather == "cold" and cid == "food_service":
		m *= 0.92
	if weather == "drought" and cid == "wheat":
		m *= 1.05
	var com: Dictionary = DataLoader.commodity(cid)
	var seas: Array = com.get("season_dem", [1, 1, 1, 1])
	var si = TimeSystem.season_index(float(c.get("lat", 0.0)))
	if si < seas.size():
		m *= float(seas[si])
	if TimeSystem.dow() >= 5 and cid == "food_service":
		m *= 1.12
	if TimeSystem.dow() < 5 and cid == "food_service":
		m *= 0.96
	return m

func supply_mult(iso: String, cid: String) -> float:
	var c: Dictionary = GameState.world.get(iso, {})
	var m = 1.0
	var com: Dictionary = DataLoader.commodity(cid)
	var seas: Array = com.get("season_prod", [1, 1, 1, 1])
	var si = TimeSystem.season_index(float(c.get("lat", 0.0)))
	if si < seas.size():
		m *= float(seas[si])
	var weather = str(c.get("weather", "clear"))
	if weather == "drought" and cid in ["wheat", "coffee", "meat"]:
		m *= 0.62
	if weather == "storm" and cid in ["construction", "logistics", "wheat"]:
		m *= 0.78
	if weather == "cold" and cid == "construction":
		m *= 0.7
	if str(c.get("holiday_group", "")) == "muslim" and _in_table(RAMADAN, 30):
		m *= 0.93
	if (str(c.get("holiday_group", "")).begins_with("christian")) and int(GameState.date.m) == 12 and int(GameState.date.d) >= 24 and cid in ["steel", "automobiles", "electronics"]:
		m *= 0.82
	return m

func _xmas(cid: String) -> float:
	if cid == "food_service":
		return 1.42
	if cid == "electronics":
		return 1.28
	if cid == "textiles":
		return 1.22
	if cid in ["meat", "coffee", "wheat"]:
		return 1.12
	if cid in ["construction", "automobiles"]:
		return 0.82
	return 1.0

func _ramadan(cid: String) -> float:
	if cid == "food_service":
		return 1.08
	if cid == "coffee":
		return 1.12
	if cid == "textiles":
		return 0.95
	return 1.0

func _in_table(table: Dictionary, length: int) -> bool:
	var y = int(GameState.date.y)
	if table.has(y) and TimeSystem.within_md(int(table[y][0]), int(table[y][1]), length):
		return true
	if table.has(y - 1):
		var md: Array = table[y - 1]
		var start_y = y - 1
		var now_abs = TimeSystem.yday(y, int(GameState.date.m), int(GameState.date.d)) + 365
		var start_abs = TimeSystem.yday(start_y, int(md[0]), int(md[1]))
		return now_abs >= start_abs and now_abs < start_abs + length
	return false

func _hash01(iso: String, day: int) -> float:
	var h = int(iso.hash()) ^ (day * 9741) ^ int(GameState.config.get("seed", 1))
	h = (h << 13) ^ h
	return float(absi(h) % 10000) / 10000.0

func weather_factor(weather: String, cid: String) -> float:
	if weather == "clear":
		return 1.0
	if weather == "drought" and cid == "wheat":
		return 1.2
	if weather == "storm" and (cid == "construction" or cid == "logistics"):
		return 0.72
	if weather == "cold" and cid == "electricity":
		return 1.16
	return 1.0

func holiday_factor(iso: String, cid: String) -> float:
	var group = str(GameState.world.get(iso, {}).get("holiday_group", "secular"))
	var month = int(GameState.date.m)
	var day = int(GameState.date.d)
	if group.begins_with("christian") and month == 12 and day >= 24 and cid == "food_service":
		return 1.42
	if group == "muslim" and month == 3 and day < 20 and cid == "food_service":
		return 1.15
	return 1.0

func climate_board() -> String:
	var text = ""
	for iso in DataLoader.country_ids:
		var c: Dictionary = GameState.world.get(str(iso), DataLoader.countries.get(str(iso), {}))
		var group = str(c.get("holiday_group", "secular"))
		var holiday = "žiadny"
		if holiday_factor(str(iso), "food_service") > 1.01:
			holiday = "sviatok"
		text += "%s %s %s %s\n" % [str(iso), str(c.get("weather", "clear")), group, holiday]
	return text

func announce_weather(iso: String) -> void:
	var c: Dictionary = GameState.world.get(iso, {})
	if str(c.get("weather", "")) == "storm":
		GameState.post_story("storm", "%s: búrka." % c.get("name_sk", iso))

func announce_holiday(iso: String) -> void:
	if holiday_factor(iso, "food_service") > 1.01:
		GameState.post_story("holiday", "%s: sviatok, skupina %s." % [GameState.world.get(iso, {}).get("name_sk", iso), GameState.world.get(iso, {}).get("holiday_group", "")])

func apply_recession(c: Dictionary) -> float:
	c.gdp_growth = float(c.get("gdp_growth", 0.02)) - 0.02
	c.recession = true
	GameState.post_story("recession", "%s: recesia." % c.get("name_sk", ""))
	return float(c.gdp_growth)

func monthly() -> void:
	if not GameState.config.get("disasters", true):
		return
	var sev = Difficulty.severity()  # JUAN4: obtiaznost
	if GameState.rng.randf() < 0.08 * Difficulty.event_mult():
		var ids: Array = GameState.world.keys()
		if ids.is_empty():
			return
		var iso: String = ids[GameState.rng.randi() % ids.size()]
		var c: Dictionary = GameState.world[iso]
		var kind = GameState.rng.randi() % 3
		if kind == 0:
			c.gdp_growth = float(c.gdp_growth) - 0.01 * sev
			GameState.post_news("%s: lokálna recesia. Dopyt slabne." % c.get("name_sk", iso))
		elif kind == 1:
			c.gdp_growth = float(c.gdp_growth) + 0.008 / sev
			GameState.post_news("%s: konjunktúra. Firmy expandujú." % c.get("name_sk", iso))
		else:
			c.inflation = float(c.inflation) + 0.01 * sev
			GameState.post_news("%s: cenový šok. Centrálna banka bude reagovať." % c.get("name_sk", iso))
