extends RefCounted
# Halloween DLC. Dve kontroly: šírenie z Krakova a starý save bez zombie dát.

func run(u) -> void:
	GameState.new_game({
		"loan": 0.0, "years": 5, "country": "SK", "scenario": "sandbox", "found": "",
		"wars": false, "disasters": false, "hot": false, "seed": 47, "name": "Unit", "year": 2024,
	})
	var old = GameState.to_dict()
	old.erase("game_settings")
	old.erase("zombie")
	var err = GameState.from_dict(old)
	u._chk("zombie_old_save", err == "" and bool(GameState.game_settings.get("zombie_mode", true)) == false and int(GameState.game_settings.get("zombie_start_money", 1)) == 0 and typeof(GameState.zombie) == TYPE_DICTIONARY, err)

	GameState.new_game({
		"loan": 0.0, "years": 5, "country": "SK", "scenario": "sandbox", "found": "",
		"wars": false, "disasters": false, "hot": false, "seed": 47, "name": "Unit", "year": 2024,
		"zombie_mode": true, "zombie_start_money": 150000,
	})
	for _i in 16:
		if GameState.paused:
			GameState.paused = false
		GameState.simulate_day()
	var infected = 0
	for reg in GameState.zombie.get("regions", {}).values():
		if str(reg.get("iso", "")) == "PL" and float(reg.get("infection", 0.0)) > 0.0:
			infected += 1
	u._chk("zombie_krakow_spread", infected >= 2, "nakazenych miest PL=%d den=%d" % [infected, GameState.day_index])
	var dlc_news = 0
	for item in GameState.news:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("category", "")) == "nákaza":
			dlc_news += 1
	u._chk("zombie_news_in_noviny", dlc_news >= 2, "nakaza spravy=%d" % dlc_news)
	u._chk("zombie_vaccine_not_dlc_lab", ZombieSystem.start_vaccine("uwc") != "")
	var row = ZombieSystem.z()
	row.ai_vaccine["firm"] = "neexistuje"
	row.ai_vaccine["progress"] = 50.0
	ZombieSystem._vaccine(row)
	u._chk("zombie_ai_lab_lost", str(row.ai_vaccine.firm) == "" and float(row.ai_vaccine.progress) == 0.0 or str(row.ai_vaccine.firm) != "neexistuje")
