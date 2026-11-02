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
	var far_ok = true
	var home = Vector2(-500, -500)
	var t = ZombieSystem.fighter_target(home)
	if not t.is_empty():
		var rp = t.get("pos", [0, 0])
		far_ok = ZombieSystem.km_between(home, Vector2(float(rp[0]), float(rp[1]))) <= 600.0
	var near = ZombieSystem.fighter_target(Vector2(float(ZombieSystem._region("PL", "Kraków").pos[0]), float(ZombieSystem._region("PL", "Kraków").pos[1])))
	u._chk("zombie_fighter_600km", far_ok and not near.is_empty())
	_bunkers(u)

func _bunkers(u) -> void:
	GameState.new_game({
		"loan": 0.0, "years": 5, "country": "SK", "scenario": "sandbox", "found": "",
		"wars": false, "disasters": false, "hot": false, "seed": 47, "name": "Unit", "year": 2024,
		"zombie_mode": true, "zombie_start_money": 0,
	})
	GameState.player.cash = 20000000.0
	GameState.selected_iso = "SK"
	var err = ZombieSystem.build_bunker()
	var row = ZombieSystem.z()
	var bunker: Dictionary = row.bunkers[0] if row.bunkers.size() > 0 else {}
	u._chk("bunker_build", err == "" and row.bunkers.size() == 1 and int(bunker.get("build_left", -1)) == 3 and int(bunker.get("capacity", 0)) == 5000 and absf(float(GameState.player.cash) - 18000000.0) < 1.0, err)
	for _i in 3:
		ZombieSystem._tick_bunkers(row)
	var built = false
	for item in GameState.news:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("category", "")) == "nákaza" and str(item.get("text", "")).find("postavený") >= 0:
			built = true
	u._chk("bunker_built", int(bunker.get("build_left", 1)) == 0 and built)
	var took = ZombieSystem.shelter_into(bunker, 9000)
	u._chk("bunker_capacity", took == 5000 and int(bunker.people) == 5000 and bool(bunker.full_news))
	var before_up = float(GameState.player.cash)
	var up = ZombieSystem.upgrade_bunker(str(bunker.id))
	u._chk("bunker_upgrade", up == "" and int(bunker.level) == 2 and int(bunker.capacity) == 20000 and absf(before_up - float(GameState.player.cash) - 4000000.0) < 1.0, up)
	bunker["food_days"] = 0
	bunker["hp"] = 100.0
	var reg0 = ZombieSystem._region(str(bunker.iso), str(bunker.city))
	reg0["infection"] = 0.0
	reg0["zombies"] = 0
	reg0["status"] = "čistý"
	ZombieSystem._tick_bunkers(row)
	u._chk("bunker_food", int(bunker.food_days) == 0 and absf(float(bunker.hp) - 95.0) < 0.01, str(bunker.hp))
	bunker["food_days"] = 10
	bunker["hp"] = 80.0
	reg0["infection"] = 12.0
	reg0["zombies"] = 400
	ZombieSystem._tick_bunkers(row)
	u._chk("bunker_hp", absf(float(bunker.hp) - 70.0) < 0.01, str(bunker.hp))
	row.zones = [{"id": "szwall", "iso": str(bunker.iso), "alive": true, "pts": [[0, 0], [1, 0], [0, 1]]}]
	row.buildings = [{"id": "mur1", "kind": "mur", "level": 1, "zone": "szwall"}]
	bunker["hp"] = 80.0
	ZombieSystem._tick_bunkers(row)
	u._chk("bunker_wall", absf(float(bunker.hp) - 75.0) < 0.01, str(bunker.hp))
	row.buildings.clear()
	reg0["infection"] = 0.0
	reg0["zombies"] = 0
	reg0["status"] = "čistý"
	bunker["hp"] = 5.0
	bunker["food_days"] = 0
	bunker["people"] = 80
	bunker["alive"] = true
	row["saved"] = 80
	ZombieSystem._tick_bunkers(row)
	var fell = false
	for item2 in GameState.news:
		if typeof(item2) == TYPE_DICTIONARY and str(item2.get("category", "")) == "nákaza" and str(item2.get("text", "")).find("padol") >= 0:
			fell = true
	u._chk("bunker_fall", not bool(bunker.alive) and int(bunker.people) == 0 and int(row.saved) == 0 and fell and float(ZombieSystem.region_at(str(bunker.iso), str(bunker.city)).get("infection", 0.0)) > 0.0)
	err = ZombieSystem.build_bunker()
	var bunker2: Dictionary = row.bunkers[row.bunkers.size() - 1]
	bunker2["build_left"] = 0
	bunker2["alive"] = true
	var lab_cash = float(GameState.player.cash)
	var lab_err = ZombieSystem.build_bunker_lab(str(bunker2.id), "uwc")
	u._chk("bunker_lab_player_only", lab_err != "" and not bool(bunker2.lab), lab_err)
	lab_err = ZombieSystem.build_bunker_lab(str(bunker2.id), "")
	u._chk("bunker_lab", lab_err == "" and bool(bunker2.lab) and absf(lab_cash - float(GameState.player.cash) - 1000000.0) < 1.0, lab_err)
	GameState.firms.append({"id": "bunkerlab", "name": "Lab", "owner": "player", "country": "SK", "city": "", "closed": false, "industry": "pharma_lab"})
	row.vaccine = {"progress": 10.0, "firm": "bunkerlab", "done": false, "deployed": false, "name": "Lab"}
	ZombieSystem._vaccine_step(row, "vaccine", row.vaccine)
	u._chk("bunker_lab_speed", absf(float(row.vaccine.progress) - 11.1) < 0.001, str(row.vaccine.progress))
	bunker2["people"] = 0
	bunker2["capacity"] = 5000
	bunker2["full_news"] = false
	row["outbreak"] = true
	row.helicopters = [{"id": "h1", "lost": false}]
	ZombieSystem._flights(row)
	u._chk("bunker_heli", int(bunker2.people) == 120, str(bunker2.people))
	for i in range(GameState.firms.size() - 1, -1, -1):
		if str(GameState.firms[i].get("id", "")) == "bunkerlab":
			GameState.firms.remove_at(i)
	var snap = GameState.to_dict()
	snap["zombie"].erase("bunkers")
	var load_err = GameState.from_dict(snap)
	u._chk("bunker_old_save", load_err == "" and typeof(GameState.zombie.get("bunkers")) == TYPE_ARRAY and GameState.zombie.bunkers.is_empty(), load_err)
	var src = FileAccess.get_file_as_string("res://scripts/main.gd")
	u._chk("bunker_ui", src.find("Postaviť bunker") >= 0 and src.find("\"Vylepšiť\"") >= 0 and src.find("Postaviť laboratórium") >= 0)
	u._chk("bunker_model", FileAccess.file_exists(ZombieSystem.bunker_model_path()))

