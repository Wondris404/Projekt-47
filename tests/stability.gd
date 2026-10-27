extends RefCounted
# Meranie stability cien/sadzieb/inflacie. Spustenie: godot --headless --path . -- stability [dni...]
# Vypisuje riadky P47_STAB_*. Exit code 1 ak sa nasiel NaN/inf.

func _scan(v, path: String, bad: Array) -> void:
	match typeof(v):
		TYPE_FLOAT:
			if EconMath.is_bad(v):
				bad.append(path)
		TYPE_DICTIONARY:
			for k in v.keys():
				_scan(v[k], path + "/" + str(k), bad)
		TYPE_ARRAY:
			var i = 0
			for x in v:
				_scan(x, path + "[" + str(i) + "]", bad)
				i += 1

func _median(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var s = a.duplicate()
	s.sort()
	var n = s.size()
	if n % 2 == 1:
		return float(s[n / 2])
	return (float(s[n / 2 - 1]) + float(s[n / 2])) * 0.5

func _report(day: int) -> int:
	var bad: Array = []
	for name in ["world", "markets", "central", "player", "firms", "banks"]:
		_scan(GameState.get(name), name, bad)
	print("P47_STAB_DAY %d date %04d-%02d-%02d" % [day, int(GameState.date.y), int(GameState.date.m), int(GameState.date.d)])
	var worst_lo = 1e30
	var worst_hi = 0.0
	var out_30 = 0
	var total = 0
	for cid in DataLoader.commodity_ids:
		var base = float(DataLoader.commodity(cid).get("base_price", 1.0))
		var ratios: Array = []
		for iso in DataLoader.country_ids:
			ratios.append(MarketSystem.price(iso, cid) / max(base, 0.0001))
		var mn = ratios.min()
		var mx = ratios.max()
		worst_lo = min(worst_lo, mn)
		worst_hi = max(worst_hi, mx)
		for r in ratios:
			total += 1
			if r < 0.7 or r > 1.3:
				out_30 += 1
		print("P47_STAB_PRICE %s med %.3f min %.3f max %.3f" % [cid, _median(ratios), mn, mx])
	print("P47_STAB_PRICE_ALL min %.3f max %.3f outside30 %d/%d" % [worst_lo, worst_hi, out_30, total])
	# kriterium etapy 1: podiel parov krajina x komodita v pasme +-30 % base, median vsetkych pomerov, podmnozina SK/DE/US/BR
	var all_r: Array = []
	var sub_in = 0
	var sub_n = 0
	for iso in DataLoader.country_ids:
		for cid in DataLoader.commodity_ids:
			var r = MarketSystem.price(iso, cid) / max(float(DataLoader.commodity(cid).get("base_price", 1.0)), 0.0001)
			all_r.append(r)
			if iso in ["SK", "DE", "US", "BR"]:
				sub_n += 1
				if r >= 0.7 and r <= 1.3:
					sub_in += 1
	var in_all = 0
	for r2 in all_r:
		if r2 >= 0.7 and r2 <= 1.3:
			in_all += 1
	print("P47_STAB_CRIT day %d inband_all %.3f inband_SKDEUSBR %.3f median_all %.3f" % [day, float(in_all) / max(float(all_r.size()), 1.0), float(sub_in) / max(float(sub_n), 1.0), _median(all_r)])
	var rates: Array = []
	var infl: Array = []
	for iso in DataLoader.country_ids:
		var crow: Dictionary = GameState.central[iso]
		rates.append(float(crow.get("base_rate", crow.get("policy", 0.0))))
		infl.append(float(GameState.world[iso].get("inflation", 0.0)))
	print("P47_STAB_RATE min %.4f med %.4f max %.4f" % [rates.min(), _median(rates), rates.max()])
	print("P47_STAB_INFL min %.4f med %.4f max %.4f" % [infl.min(), _median(infl), infl.max()])
	var sk_rate = float(GameState.central["SK"].get("base_rate", GameState.central["SK"].get("policy", 0.0)))
	print("P47_STAB_SK wheat_x %.2f oil_x %.2f infl %.4f policy %.4f base_rate %.4f" % [
		MarketSystem.price("SK", "wheat") / float(DataLoader.commodity("wheat").get("base_price", 1.0)),
		MarketSystem.price("SK", "crude_oil") / float(DataLoader.commodity("crude_oil").get("base_price", 1.0)),
		float(GameState.world["SK"].inflation), float(GameState.central["SK"].get("policy", 0.0)), sk_rate])
	print("P47_STAB_CASH %.2f" % float(GameState.player.cash))
	print("P47_STAB_NAN %d %s" % [bad.size(), ",".join(bad.slice(0, 5))])
	return bad.size()

func run(days: Array = [1, 30, 365], home: String = "SK") -> int:
	GameState.new_game({
		"loan": 0.0, "years": 5, "country": home, "scenario": "sandbox", "found": "",
		"wars": false, "disasters": false, "hot": false, "seed": 47, "name": "Stab", "year": 2024,
	})
	# stejne ako request_loan() v realnej hre: sadzby sa prvykrat vypocitaju hned na zaciatku
	# (bez tohto ma central[iso] len "policy" z setup_central, nie "base_rate")
	BankingSystem.update_rates()
	print("P47_STAB_CONFIG clean (bez vojen, bez katastrof), seed 47, home=%s, bez poziky a bez firiem hraca (AI firmy su); s vojnami/katastrofami su ceny a inflacia ine" % home)
	var done = 0
	var bad_total = 0
	for target in days:
		while done < int(target):
			GameState.simulate_day()
			done += 1
		bad_total += _report(done)
	if bad_total > 0:
		print("P47_STAB_FAIL")
		return 1
	print("P47_STAB_OK")
	return 0
