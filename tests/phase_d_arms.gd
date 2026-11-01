extends RefCounted

func run(u) -> void:
	GameState.new_game({
		"loan": 0.0, "years": 5, "country": "SK", "scenario": "sandbox", "found": "",
		"wars": false, "disasters": false, "hot": false, "seed": 47, "name": "Unit", "year": 2024,
	})
	u._chk("arms_mult_one", absf(ArmsSystem.arms_mult() - 1.0) < 0.0001 and absf(ArmsSystem.air_mult() - 1.0) < 0.0001)
	var blocked = ArmsSystem.buy_bp("kalas")
	u._chk("arms_need_plant", blocked != "")
	GameState.firms.append({"id": "arm1", "owner": "player", "industry": "arms_plant", "country": "SK", "closed": false, "name": "Zbrojovka"})
	GameState.player.cash = 5000000.0
	u._chk("arms_buy", ArmsSystem.buy_bp("kalas") == "" and "kalas" in ArmsSystem.owned())
	u._chk("arms_design", ArmsSystem.design("kalas", "Puška 47", 120000.0, 55.0, 80.0) == "")
	u._chk("arms_mult_up", ArmsSystem.arms_mult() > 1.0 and absf(ArmsSystem.air_mult() - 1.0) < 0.0001)
	var cash = float(GameState.player.cash)
	var did = str(ArmsSystem.designs()[0].id)
	u._chk("arms_sell", ArmsSystem.sell(did) == "" and float(GameState.player.cash) > cash and ArmsSystem.designs().is_empty())
	u._chk("arms_mult_back", absf(ArmsSystem.arms_mult() - 1.0) < 0.0001)
