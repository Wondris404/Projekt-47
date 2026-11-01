extends RefCounted

func run(u) -> void:
	GameState.new_game({
		"loan": 0.0, "years": 5, "country": "SK", "scenario": "sandbox", "found": "",
		"wars": false, "disasters": false, "hot": false, "seed": 47, "name": "Unit", "year": 2024,
	})
	GameState.news.clear()
	GameState.post_news("Založená firma v Bratislave.")
	GameState.post_news("Vojna medzi SK a HU.")
	var row = GameState.news_row(GameState.news[0])
	u._chk("news_war_cat", str(row.category) == "vojna" and str(row.headline).find("Vojna") >= 0, str(row))
	var old = GameState.news_row("Krach oceliarne po šoku.")
	u._chk("news_old_string", str(old.category) == "šoky" and str(old.text).find("Krach") >= 0, str(old.category))
	var legacy = GameState.news_row({"day": 3, "date": "1. 1. 2024", "text": "Starý titulok bez kategórie."})
	u._chk("news_legacy_dict", int(legacy.day) == 3 and str(legacy.category) == "ostatné" and str(legacy.headline) == "Starý titulok bez kategórie.")
	for i in 210:
		GameState.post_news("Bežná správa %d." % i)
	u._chk("news_cap_200", GameState.news.size() == 200, str(GameState.news.size()))
	var rng0 = GameState.rng.state
	GameState._weekly_prices()
	GameState._weekly_prices()
	u._chk("news_week_no_rng", GameState.rng.state == rng0 and typeof(GameState.ext.get("px_week", {})) == TYPE_DICTIONARY)
	var priced = false
	for item in GameState.news:
		var r = GameState.news_row(item)
		if str(r.category) == "ceny" and str(r.text).find("Ropa") >= 0:
			priced = true
	u._chk("news_week_oil", priced)
