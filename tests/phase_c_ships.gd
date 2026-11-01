extends RefCounted

func run(u) -> void:
	GameState.new_game({
		"loan": 0.0, "years": 5, "country": "SK", "scenario": "sandbox", "found": "",
		"wars": false, "disasters": false, "hot": false, "seed": 47, "name": "Unit", "year": 2024,
	})
	var rng0 = GameState.rng.state
	var fr0 = MarketSystem.freight_unit("SK", "DE", "crude_oil")
	var pool0 = str(MarketSystem.freight_pool)
	ShipSystem.daily()
	u._chk("ships_empty_noop", GameState.rng.state == rng0 and absf(MarketSystem.freight_unit("SK", "DE", "crude_oil") - fr0) < 0.0001 and str(MarketSystem.freight_pool) == pool0 and not GameState.ext.has("fleet"))
	GameState.player.cash = 5.0e9
	var err = ShipSystem.buy("feeder", false)
	u._chk("ships_buy", err == "" and ShipSystem.fleet().size() == 1, err)
	var full = ShipSystem.price_of("feeder", false)
	var yard = ShipSystem.price_of("feeder", true)
	u._chk("ships_yard_72", absf(yard - full * 0.72) < 1.0)
	var t0 = float(ShipSystem.fleet()[0].t)
	ShipSystem.daily()
	u._chk("ships_move", float(ShipSystem.fleet()[0].t) > t0)
	var txt = ShipSystem.info(str(ShipSystem.fleet()[0].id))
	u._chk("ships_info", txt.find("Náklad") >= 0 and txt.find("Cieľ") >= 0 and txt.find("ETA") >= 0, txt)
	var merr = ShipSystem.buy("destroyer", false)
	var mid = ""
	for s in ShipSystem.fleet():
		if str(s.kind) == "military":
			mid = str(s.id)
	u._chk("ships_sell_mil", merr == "" and ShipSystem.sell_military(mid) == "" and ShipSystem.civil_count() == 1)
