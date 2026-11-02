extends RefCounted

func run(u) -> void:
	var fin: Dictionary = DataLoader.industries.get("offshore", {})
	u._chk("offshore_finance_untouched", str(fin.get("recipe", "")) == "offshore" and str(fin.get("name", "")).to_lower().find("offshore") >= 0)
	var oil: Dictionary = DataLoader.industries.get("offshore_oil_rig", {})
	var gas: Dictionary = DataLoader.industries.get("offshore_gas_rig", {})
	var fpso: Dictionary = DataLoader.industries.get("fpso", {})
	var oil_out = float(DataLoader.recipes.get("offshore_oil_rig", {}).get("outputs", {}).get("crude_oil", 0))
	var gas_out = float(DataLoader.recipes.get("offshore_gas_rig", {}).get("outputs", {}).get("natural_gas", 0))
	u._chk("rigs_richer", float(oil.get("cost", 0)) > 1900000.0 and oil_out > 90.0 and float(gas.get("cost", 0)) > 1400000.0 and gas_out > 80.0 and float(fpso.get("cost", 0)) > float(oil.get("cost", 0)))
	GameState.new_game({
		"loan": 0.0, "years": 5, "country": "SK", "scenario": "sandbox", "found": "",
		"wars": false, "disasters": false, "hot": false, "seed": 47, "name": "Unit", "year": 2024,
	})
	var inland = TerrainSystem.cities("SK")
	var bad = TerrainSystem.can_place("offshore_oil_rig", "SK", inland[0].pos if not inland.is_empty() else Vector2.ZERO)
	u._chk("rig_not_on_land", not bool(bad.get("ok", true)))
	var found = false
	for iso in ["NO", "GB", "US", "SA", "AE", "NL", "BR"]:
		if not DataLoader.countries.has(iso):
			continue
		for spot in TerrainSystem._sea_spots("offshore_oil_rig", iso):
			var chk = TerrainSystem.can_place("offshore_oil_rig", iso, spot.pos)
			if bool(chk.get("ok", false)):
				found = true
				break
		if found:
			break
	u._chk("rig_sea_spot", found)
	var desc = preload("res://scripts/business_descriptions.gd").describe("offshore_oil_rig")
	u._chk("rig_desc", desc.find("rop") >= 0 and desc.to_lower().find("elektr") >= 0)
