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
	u._chk("ships_civil_cap", preload("res://scripts/ui/atlas_traffic.gd").MAX_CIVIL_SHIPS == 32)
	u._chk("ship_model_cargo", ShipSystem.model_path("feeder").ends_with("cargo.glb") and ShipSystem.model_path("ulcv").ends_with("cargo.glb") and ShipSystem.model_path("handy_bulk") == "" and ShipSystem.model_path("general") == "" and ShipSystem.model_path("ssn") == "")
	var model_rows = 0
	for id in ShipSystem.catalog.keys():
		var raw = str(ShipSystem.spec(str(id)).get("model", ""))
		if raw == "":
			continue
		model_rows += 1
		u._chk("ship_model_file_%s" % str(id), raw.ends_with(".glb") and FileAccess.file_exists(raw) and ShipSystem.model_path(str(id)) == raw, raw)
	u._chk("ship_model_psv_ahts", model_rows == 31 and ShipSystem.model_path("psv").ends_with("psv.glb") and ShipSystem.model_path("ahts") == ShipSystem.model_path("psv") and ShipSystem.model_path("carrier").ends_with("carrier.glb") and ShipSystem.model_path("lhd").ends_with("landing.glb") and ShipSystem.model_path("hospital").ends_with("landing.glb") and ShipSystem.model_path("destroyer").ends_with("destroyer.glb") and ShipSystem.model_path("cruiser").ends_with("destroyer.glb") and ShipSystem.model_path("frigate").ends_with("frigate.glb") and ShipSystem.model_path("corvette").ends_with("frigate.glb") and ShipSystem.model_path("patrol").ends_with("patrol.glb") and ShipSystem.model_path("minelayer").ends_with("patrol.glb") and ShipSystem.model_path("oiler").ends_with("tanker.glb") and ShipSystem.model_path("vlcc").ends_with("tanker.glb") and ShipSystem.model_path("chem_tanker").ends_with("tanker.glb") and ShipSystem.model_path("lng").ends_with("lng.glb") and ShipSystem.model_path("lpg").ends_with("lng.glb"))
