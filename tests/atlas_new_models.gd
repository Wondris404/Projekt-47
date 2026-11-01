extends RefCounted
# Fáza F: nové sprity existujú, ale nepridávajú odvetvia do industries.json.

const BUILDINGS = ["ai_services", "crude_oil", "fuel", "weapons", "offshore_oil_rig", "offshore_gas_rig", "fpso"]
const SHIPS = ["feeder", "vlcc", "destroyer", "psv", "ahts"]

func run(u) -> void:
	for id in BUILDINGS:
		u._chk("atlas_no_new_industry_%s" % id, not DataLoader.industries.has(id))
		for lv in range(1, 4):
			var path = "res://assets/map_models/levels/%s_%d.png" % [id, lv]
			var img = Image.new()
			var err = img.load(path)
			u._chk("atlas_level_%s_%d" % [id, lv], err == OK and img.get_width() == 64 and img.get_height() == 72, "%s %d" % [path, err])
	for sid in SHIPS:
		var sp = "res://assets/map_models/units/%s.png" % sid
		var img2 = Image.new()
		var err2 = img2.load(sp)
		u._chk("atlas_ship_%s" % sid, err2 == OK and img2.get_width() == 32 and img2.get_height() == 16, sp)
	u._chk("atlas_offshore_still_finance", str(DataLoader.industries.get("offshore", {}).get("id", "offshore")) != "offshore_oil_rig")
