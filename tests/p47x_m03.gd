extends RefCounted

func run(u) -> void:
	var m = P47Mechanics
	u._new()
	var t_now = GeopoliticsSystem.tariff("US", "RU")
	u._chk("m03_after_1991_nam", m.M03.bloc(m, "US") == "nam" and m.bloc_tariff("US", "RU") == 0.0)
	GameState.date.y = 1970
	u._chk("m03_blocs_1970", m.M03.bloc(m, "US") == "west" and m.M03.bloc(m, "RU") == "east" and m.M03.bloc(m, "IN") == "nam")
	u._chk("m03_tariff", absf(GeopoliticsSystem.tariff("US", "RU") - (t_now + 0.06)) < 0.000001 or GeopoliticsSystem.tariff("US", "RU") == 0.85)
	u._chk("m03_restricted", m.bloc_restricted("US", "RU") and not m.bloc_restricted("US", "GB") and not m.bloc_restricted("US", "IN"))
	PoliticsSystem.add_influence("IN", 100.0)
	GameState.player.home = "US"
	for i in 12:
		m.M03.monthly(m)
	u._chk("m03_influence_drift", m.M03.align(m, "IN") > 70.0 and m.M03.bloc(m, "IN") == "west", "IN %.1f" % m.M03.align(m, "IN"))
	var saved = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	u._chk("m03_save_load", GameState.from_dict(saved) == "" and m.M03.bloc(m, "IN") == "west")
	u._new()
	GameState.date.y = 1970
	m.only([])
	var base = GeopoliticsSystem._tariff_base("US", "RU")
	u._chk("m03_off_same", GeopoliticsSystem.tariff("US", "RU") == base or GeopoliticsSystem.tariff("US", "RU") == 0.85)
	var before = GameState.to_dict()
	m.monthly()
	u._chk("m03_off_no_change", before == GameState.to_dict() and not m.bloc_restricted("US", "RU"))
