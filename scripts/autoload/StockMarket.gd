extends Node
# JUAN5 #19: Burza – narodne velke firmy + AI konkurenti, IPO jednej hracovej firmy, korporacia/holding so spin-offom,
# dividendy, hostile takeover (> 50 %). Stav: GameState.ext.exch (volitelny kluc savu v3, chyba -> vytvori sa).
# Krajiny v urovni 2 (MarketSystem.tier_of == 2) nemaju vlastnu burzu.

const SHARES = 1000000.0
const SECTORS = {"bank": {"name": "Financie", "pe": 10.0}, "agri": {"name": "Poľnohospodárstvo", "pe": 11.0}, "arms": {"name": "Zbrojárstvo", "pe": 14.0},
	"energy": {"name": "Energetika", "pe": 9.0}, "tech": {"name": "Technológie", "pe": 22.0}, "industry": {"name": "Priemysel", "pe": 13.0},
	"transport": {"name": "Doprava", "pe": 11.0}, "media": {"name": "Médiá", "pe": 15.0}, "health": {"name": "Zdravotníctvo", "pe": 19.0},
	"consumer": {"name": "Spotrebný tovar", "pe": 16.0}, "telecom": {"name": "Telekom", "pe": 12.0}, "ai": {"name": "AI a dáta", "pe": 30.0}}
const NAT_SUFFIX = {"energy": "Energy", "tech": "Tech", "bank": "Bank", "telecom": "Telekom", "industry": "Industries", "consumer": "Retail",
	"agri": "Agro", "arms": "Defence", "transport": "Logistics", "media": "Media", "health": "Pharma", "ai": "AI"}
const NAT_COUNTRIES = 30  # JUAN10: 30 krajin x 4 firmy = 120 + AI konkurenti
const NAT_PER_COUNTRY = 4
const IPO_MIN_VALUE = 1000000.0
const IPO_FEE = 0.05
const HIST_MAX = 104

func ex() -> Dictionary:
	if typeof(GameState.get("ext")) != TYPE_DICTIONARY:
		GameState.ext = {}
	var e: Dictionary = GameState.ext
	if not e.has("exch") or typeof(e.exch) != TYPE_DICTIONARY:
		e["exch"] = {"list": {}, "own": {}, "index": [], "mood": 0.0, "corps": {}, "seq": 0, "base": 0.0}
	return e.exch

func has_exchange(iso: String) -> bool:
	return MarketSystem.tier_of(iso) != 2

func unlocked() -> bool:
	if bool(GameState.config.get("dev", false)) or not IndustrySystem.progression_on():
		return true
	return IndustrySystem._req_ok("r:score1") or IndustrySystem._req_ok("r:fin2") or IndustrySystem._req_ok("f:fin2")

func ipo_unlocked() -> bool:
	if bool(GameState.config.get("dev", false)) or not IndustrySystem.progression_on():
		return true
	return IndustrySystem._req_ok("r:fin2") or IndustrySystem._req_ok("f:fin2")

func _rng(tag: String) -> RandomNumberGenerator:
	var r = RandomNumberGenerator.new()
	r.seed = absi(("%s|stk|%s|%d" % [str(GameState.config.get("seed", 47)), tag, GameState.day_index]).hash())
	return r

func setup() -> void:
	var x = ex()
	x.list = {}
	x.own = {}
	x.index = []
	x.corps = {}
	var ids: Array = DataLoader.country_ids.duplicate()
	ids.sort_custom(func(a, b): return float(DataLoader.countries[a].get("gdp_usd", 0)) > float(DataLoader.countries[b].get("gdp_usd", 0)))
	var keys = SECTORS.keys()
	var n = 0
	for iso in ids:
		if n >= NAT_COUNTRIES:
			break
		if not has_exchange(str(iso)):
			continue
		n += 1
		var gdp = float(DataLoader.countries[iso].get("gdp_usd", 1e11))
		var r = _rng(str(iso))
		for k in NAT_PER_COUNTRY:
			var sec = str(keys[(n * 3 + k * 5) % keys.size()])
			var nm = "%s %s" % [str(DataLoader.countries[iso].get("name", iso)), NAT_SUFFIX[sec]]
			var profit = gdp * 0.00004 * (0.6 + r.randf())
			_add({"ticker": _ticker(nm), "name": nm, "kind": "nat", "iso": str(iso), "sector": sec, "eps": profit / SHARES, "growth": 0.01 + r.randf() * 0.05})
	for rv in RivalSystem.rivals():
		var nm2 = str(rv.get("name", "Rival"))
		_add({"ticker": _ticker(nm2), "name": nm2, "kind": "rival", "rival": str(rv.id), "iso": str(rv.get("home", "")), "sector": "industry",
			"eps": float(rv.get("cash", 3e6)) * 0.08 / SHARES, "growth": 0.03})
	x.parody_v = 0
	Brand.apply_parody()  # JUAN21
	x.base = index_value()

func _ticker(nm: String) -> String:
	var t = ""
	for w in nm.split(" "):
		if w.length() > 0:
			t += w.substr(0, 2).to_upper()
	t = t.substr(0, 5)
	var x = ex()
	var base = t
	var i = 2
	while x.list.has(t):
		t = "%s%d" % [base, i]
		i += 1
	return t

func _add(row: Dictionary) -> void:
	var x = ex()
	row["shares"] = SHARES
	row["price"] = _fundamental(row)
	row["hist"] = [row.price]
	row["p0"] = row.price
	x.list[row.ticker] = row

func listing(t: String) -> Dictionary:
	return ex().list.get(t, {})

func listings() -> Array:
	Brand.apply_parody()  # JUAN21: aj stare savy
	var out: Array = ex().list.values()
	out.sort_custom(func(a, b): return str(a.ticker) < str(b.ticker))
	return out

# ---- ocenenie ----
func firm_value(firm: Dictionary) -> float:
	var v = BankingSystem.asset_market_value({"kind": "firm", "id": str(firm.get("id", ""))})
	if v <= 0.0 and str(firm.get("owner", "")) != "player":
		var ind: Dictionary = DataLoader.industries.get(str(firm.get("industry", "")), {})
		v = float(ind.get("cost", 0.0)) * 0.7
	return v + maxf(0.0, _annual_profit(firm)) * 6.0

func _annual_profit(firm: Dictionary) -> float:
	var h: Array = firm.get("history", [])
	if h.is_empty():
		return 0.0
	var s = 0.0
	for row in h:
		s += float(row.get("profit", 0.0))
	return s / float(h.size()) * 365.0

func corp_value(c: Dictionary) -> float:
	var s = 0.0
	var n = 0
	for t in c.get("members", []):  # JUAN10: zaclenene burzove firmy (podiel hraca)
		var row = listing(str(t))
		if not row.is_empty():
			s += float(row.price) * owned(str(t))
			n += 1
	for fid in c.get("firms", []):
		var f = GameState.firm_by_id(str(fid))
		if not f.is_empty():
			s += firm_value(f)
			n += 1
	return s * (1.0 + corp_premium(n))

func corp_premium(n: int) -> float:
	# diverzifikacia +5 % za kazdu dalsiu firmu (max +25 %), jedna firma = bez premie
	return clampf(0.05 * float(n - 1), 0.0, 0.25)

func _fundamental(row: Dictionary) -> float:
	var kind = str(row.get("kind", ""))
	if kind == "player":
		var f = GameState.firm_by_id(str(row.get("firm", "")))
		return maxf(0.01, firm_value(f) / float(row.shares)) if not f.is_empty() else 0.01
	if kind == "corp":
		return maxf(0.01, corp_value(ex().corps.get(str(row.get("corp", "")), {})) / float(row.shares))
	if kind == "rival":
		var e = 0.0
		for f in RivalSystem.rival_firms(str(row.get("rival", ""))):
			e += _annual_profit(f)
		if e != 0.0:
			row.eps = lerpf(float(row.eps), e / float(row.shares), 0.3)
	var sec: Dictionary = SECTORS.get(str(row.get("sector", "industry")), SECTORS.industry)
	var rate = float(GameState.central.get(str(row.get("iso", "")), {}).get("base_rate", 0.03))
	var pe = float(sec.pe) * (1.0 + float(row.get("growth", 0.02)) * 8.0) / (1.0 + rate * 6.0)
	return maxf(0.05, float(row.eps) * pe)

func weekly() -> void:
	var x = ex()
	if x.list.is_empty():
		return
	var r = _rng("wk")
	var shock = -0.04 * float(GameState.wars.size() > 0) - 0.02 * float(GameState.world_events.size() > 3)
	x.mood = clampf(float(x.mood) * 0.9 + (r.randf() - 0.5) * 0.04 + shock * 0.3, -0.35, 0.35)
	var smood: Dictionary = x.get("smood", {})  # JUAN10: nalada sektora
	for sk in SECTORS.keys():
		var sh2 = 0.0
		if sk == "arms" and GameState.wars.size() > 0:
			sh2 = 0.06
		elif sk == "transport" and GameState.wars.size() > 0:
			sh2 = -0.02
		smood[sk] = clampf(float(smood.get(sk, 0.0)) * 0.9 + (r.randf() - 0.5) * 0.03 + sh2 * 0.3, -0.3, 0.3)
	x["smood"] = smood
	for row in x.list.values():
		row.eps = float(row.eps) * (1.0 + float(row.get("growth", 0.02)) / 52.0 + (r.randf() - 0.5) * 0.01)
		var tgt = _fundamental(row) * (1.0 + float(x.mood) + float(smood.get(str(row.get("sector", "")), 0.0)))
		var noise = 1.0 + (r.randf() - 0.5) * 0.04
		row.price = maxf(0.01, lerpf(float(row.price), tgt, 0.3) * noise)
		row.hist.append(row.price)
		if row.hist.size() > HIST_MAX:
			row.hist.pop_front()
	x.index.append(index_value())
	if x.index.size() > HIST_MAX:
		x.index.pop_front()
	var sidx: Dictionary = x.get("sidx", {})
	for sk2 in SECTORS.keys():
		var hh: Array = sidx.get(sk2, [])
		hh.append(sector_index(sk2))
		if hh.size() > HIST_MAX:
			hh.pop_front()
		sidx[sk2] = hh
	x["sidx"] = sidx

# JUAN10: sektorovy index (priemer kurz/kurz pri starte * 1000)
func sector_index(sec: String) -> float:
	var s = 0.0
	var n = 0
	for row in ex().list.values():
		if str(row.get("sector", "")) != sec or not (str(row.kind) in ["nat", "rival"]):
			continue
		var h: Array = row.hist
		var p0 = float(row.get("p0", h[0] if h.size() > 0 else row.price))
		s += float(row.price) / maxf(p0, 0.0001)
		n += 1
	return 0.0 if n == 0 else 1000.0 * s / float(n)

func sector_of_row(row: Dictionary) -> String:
	return str(row.get("sector", "industry"))

# JUAN10: zaclenenie ovladanej burzovej firmy (>50 %) do korporacie hraca
func can_absorb(t: String) -> bool:
	var row = listing(t)
	return not row.is_empty() and str(row.kind) in ["nat", "rival"] and stake(t) > 0.5 and str(row.get("in_corp", "")) == ""

func absorb_into_corp(cid: String, t: String) -> String:
	var x = ex()
	if not x.corps.has(cid):
		return "Vyber korporáciu (najprv ju vytvor v časti Korporácia / Holding)."
	if not can_absorb(t):
		var row0 = listing(t)
		if not row0.is_empty() and str(row0.get("in_corp", "")) != "":
			return "Táto firma už je v korporácii."
		return "Musíš vlastniť viac ako 50 % akcií (máš %.1f %%)." % (stake(t) * 100.0)
	var row = listing(t)
	if not bool(row.get("controlled", false)):
		takeover(t)
	row.in_corp = cid
	var c: Dictionary = x.corps[cid]
	var m: Array = c.get("members", [])
	m.append(t)
	c["members"] = m
	GameState.post_news("%s je teraz súčasťou korporácie %s." % [str(row.name), str(c.name)])
	return ""

func index_value() -> float:
	var x = ex()
	var cap = 0.0
	for row in x.list.values():
		if str(row.kind) == "nat" or str(row.kind) == "rival":
			cap += float(row.price) * float(row.shares)
	var b = float(x.get("base", 0.0))
	return 1000.0 if b <= 0.0 else 1000.0 * cap / b

func monthly() -> float:
	# dividendy: 40 % zisku (ovladane narodne firmy 70 %)
	var x = ex()
	var paid = 0.0
	for t in x.own.keys():
		var row = listing(str(t))
		if row.is_empty() or str(row.kind) == "player" or str(row.kind) == "corp":
			continue
		var payout = 0.7 if bool(row.get("controlled", false)) else 0.4
		paid += maxf(0.0, float(row.eps)) / 12.0 * payout * float(x.own[t])
	if paid > 0.0:
		GameState.player.cash = float(GameState.player.cash) + paid
	return paid

func owned(t: String) -> float:
	return float(ex().own.get(t, 0.0))

func stake(t: String) -> float:
	var row = listing(t)
	return 0.0 if row.is_empty() else owned(t) / float(row.shares)

func portfolio_value() -> float:
	var v = 0.0
	for t in ex().own.keys():
		var row = listing(str(t))
		if not row.is_empty() and (str(row.kind) == "nat" or str(row.kind) == "rival"):
			v += owned(str(t)) * float(row.price)
	return v

# ---- obchodovanie ----
const FEE = 0.0025  # JUAN10: poplatok brokera 0,25 %

# JUAN10: nahlad obchodu (bez zmeny stavu) - cena/akcia, spolu, poplatok, novy podiel, hotovost po
func quote(t: String, qty: float, side: String) -> Dictionary:
	var row = listing(t)
	if row.is_empty() or qty <= 0.0:
		return {"ok": false, "reason": "Vyber titul a počet kusov."}
	var sh = float(row.shares)
	var cash = float(GameState.player.cash)
	if side == "buy":
		var px = float(row.price) * (1.0 + 0.5 * qty / sh)
		var gross = px * qty
		var fee = gross * FEE
		var total = gross + fee
		var reason = ""
		if owned(t) + qty > sh + 0.1:
			reason = "Toľko akcií nie je v obehu (voľných %.0f ks)." % maxf(0.0, sh - owned(t))
		elif cash < total:
			reason = "Nemáš dosť peňazí: treba %s, máš %s." % [EconMath.eur(total), EconMath.eur(cash)]
		return {"ok": reason == "", "reason": reason, "px": px, "gross": gross, "fee": fee, "total": total, "stake_after": (owned(t) + qty) / sh, "cash_after": cash - total}
	var px2 = float(row.price) * (1.0 - 0.5 * qty / sh)
	var gross2 = px2 * qty
	var fee2 = gross2 * FEE
	var r2 = "" if qty <= owned(t) + 0.01 else "Máš len %.0f ks." % owned(t)
	return {"ok": r2 == "", "reason": r2, "px": px2, "gross": gross2, "fee": fee2, "total": gross2 - fee2, "stake_after": maxf(0.0, owned(t) - qty) / sh, "cash_after": cash + gross2 - fee2}

func buy(t: String, qty: float) -> String:
	var row = listing(t)
	if row.is_empty():
		return "Neznámy titul."
	if not unlocked():
		return "Burza je zamknutá (výskum Úverový scoring/Algoritmické hodnotenie alebo cieľ Financie)."
	if qty <= 0.0:
		return "Zlé množstvo."
	if owned(t) + qty > float(row.shares) + 0.1:
		return "Toľko akcií nie je v obehu."
	var px = float(row.price) * (1.0 + 0.5 * qty / float(row.shares))  # dopad velkeho nakupu na cenu
	var cost = px * qty * (1.0 + FEE)
	if float(GameState.player.cash) < cost:
		return "Nemáš dosť peňazí (%s)." % EconMath.eur(cost)
	GameState.player.cash = float(GameState.player.cash) - cost
	ex().own[t] = owned(t) + qty
	row.price = px
	return ""

func sell(t: String, qty: float) -> String:
	var row = listing(t)
	if row.is_empty():
		return "Neznámy titul."
	if qty <= 0.0 or qty > owned(t) + 0.01:
		return "Nemáš toľko akcií."
	if (str(row.kind) == "player" or str(row.kind) == "corp") and not bool(row.get("public", false)):
		return "Firma nie je na burze – najprv IPO."
	if str(row.kind) == "player":
		var f = GameState.firm_by_id(str(row.get("firm", "")))
		if not f.is_empty() and str(f.get("pledged", "")) != "":
			return "Firma je založená v banke – akcie nemôžeš predať."
	var px = float(row.price) * (1.0 - 0.5 * qty / float(row.shares))
	GameState.player.cash = float(GameState.player.cash) + px * qty * (1.0 - FEE)
	ex().own[t] = owned(t) - qty
	row.price = maxf(0.01, px)
	_check_control(t)
	return ""

func _check_control(t: String) -> void:
	var row = listing(t)
	var k = str(row.get("kind", ""))
	if stake(t) >= 0.5:
		return
	if k == "player" or k == "corp":
		var ids: Array = [str(row.get("firm", ""))] if k == "player" else ex().corps.get(str(row.get("corp", "")), {}).get("firms", [])
		for fid in ids:
			var f = GameState.firm_by_id(str(fid))
			if not f.is_empty() and str(f.get("owner", "")) == "player":
				f.owner = "ai"
				f["lost_control"] = t
		row.controlled = false
		GameState.post_news("Pod 50 %%: stratil si kontrolu nad %s." % str(row.name))
	elif bool(row.get("controlled", false)):
		row.controlled = false

func takeover(t: String) -> String:
	var row = listing(t)
	if row.is_empty() or str(row.kind) == "player" or str(row.kind) == "corp":
		return "Na tento titul sa takeover nerobí."
	if stake(t) <= 0.5:
		return "Potrebuješ viac ako 50 %% akcií (máš %.1f %%)." % (stake(t) * 100.0)
	if bool(row.get("controlled", false)):
		return "Už ju ovládaš."
	row.controlled = true
	if str(row.kind) == "rival":
		var n = 0
		for f in RivalSystem.rival_firms(str(row.get("rival", ""))):
			f.owner = "player"
			f.rival = ""
			n += 1
		GameState.post_news("Nepriateľské prevzatie: %s je tvoja (%d firiem)." % [str(row.name), n])
	else:
		GameState.post_news("Ovládaš %s – vyššie dividendy (70 %% zisku)." % str(row.name))
	return ""

# ---- IPO a holding ----
func ipo_firm(firm_id: String, pct: float = 0.3) -> String:
	if not ipo_unlocked():
		return "IPO je zamknuté (výskum Algoritmické hodnotenie úverov alebo cieľ Financie)."
	var f = GameState.firm_by_id(firm_id)
	if f.is_empty() or str(f.get("owner", "")) != "player":
		return "Firma nie je tvoja."
	if str(f.get("pledged", "")) != "":
		return "Založenú firmu nemôžeš dať na burzu."
	if str(f.get("listed", "")) != "" or str(f.get("corp", "")) != "":
		return "Firma už je na burze alebo v holdingu."
	if not has_exchange(str(f.get("country", ""))):
		return "Krajina nemá vlastnú burzu."
	var val = firm_value(f)
	if val < IPO_MIN_VALUE:
		return "Firma je malá: hodnota %s, treba aspoň %s." % [EconMath.eur(val), EconMath.eur(IPO_MIN_VALUE)]
	var t = _ticker(str(f.get("name", "FIRM")))
	_add({"ticker": t, "name": str(f.get("name", "")), "kind": "player", "firm": firm_id, "iso": str(f.get("country", "")), "sector": "industry", "eps": maxf(0.0, _annual_profit(f)) / SHARES, "growth": 0.03})
	f.listed = t
	ex().own[t] = SHARES
	return _float(t, pct)

func _float(t: String, pct: float) -> String:
	var row = listing(t)
	pct = clampf(pct, 0.05, 0.95)
	var qty = SHARES * pct
	var cash = qty * float(row.price) * (1.0 - IPO_FEE)
	GameState.player.cash = float(GameState.player.cash) + cash
	ex().own[t] = owned(t) - qty
	row.public = true
	GameState.post_news("IPO %s: predaných %.0f %% akcií za %s." % [str(row.name), pct * 100.0, EconMath.eur(cash)])
	_check_control(t)
	return ""

func create_corp(name: String, firm_ids: Array) -> String:
	if name.strip_edges() == "":
		return "Zadaj názov korporácie."
	if firm_ids.size() < 2:
		return "Holding potrebuje aspoň 2 firmy."
	for fid in firm_ids:
		var e = _corp_ok(str(fid))
		if e != "":
			return e
	var x = ex()
	x.seq = int(x.get("seq", 0)) + 1
	var cid = "C%d" % int(x.seq)
	x.corps[cid] = {"id": cid, "name": name.strip_edges(), "firms": firm_ids.duplicate()}
	for fid in firm_ids:
		GameState.firm_by_id(str(fid)).corp = cid
	var t = _ticker(name)
	_add({"ticker": t, "name": name.strip_edges(), "kind": "corp", "corp": cid, "iso": str(GameState.player.get("home", "SK")), "sector": "industry", "eps": 0.0, "growth": 0.03})
	x.corps[cid]["ticker"] = t
	x.own[t] = SHARES
	return ""

func _corp_ok(fid: String) -> String:
	var f = GameState.firm_by_id(fid)
	if f.is_empty() or str(f.get("owner", "")) != "player":
		return "Firma nie je tvoja."
	if str(f.get("pledged", "")) != "":
		return "%s je založená v banke." % str(f.get("name", ""))
	if str(f.get("listed", "")) != "" or str(f.get("corp", "")) != "":
		return "%s už je na burze alebo v holdingu." % str(f.get("name", ""))
	return ""

func corp_add(cid: String, fid: String) -> String:
	var c: Dictionary = ex().corps.get(cid, {})
	if c.is_empty():
		return "Neznáma korporácia."
	var e = _corp_ok(fid)
	if e != "":
		return e
	c.firms.append(fid)
	GameState.firm_by_id(fid).corp = cid
	_reprice(str(c.ticker))
	return ""

func spin_off(cid: String, fid: String) -> String:
	var c: Dictionary = ex().corps.get(cid, {})
	if c.is_empty() or not fid in c.firms:
		return "Firma nie je v tejto korporácii."
	var f = GameState.firm_by_id(fid)
	var ct = str(c.ticker)
	var share = stake(ct)
	c.firms.erase(fid)
	f.corp = ""
	if bool(listing(ct).get("public", false)):
		# akcionari korporacie dostanu akcie novej firmy v rovnakom pomere
		var t = _ticker(str(f.get("name", "")))
		_add({"ticker": t, "name": str(f.get("name", "")), "kind": "player", "firm": fid, "iso": str(f.get("country", "")), "sector": "industry", "eps": maxf(0.0, _annual_profit(f)) / SHARES, "growth": 0.03})
		listing(t).public = true
		f.listed = t
		ex().own[t] = SHARES * share
		_check_control(t)
	_reprice(ct)
	GameState.post_news("Spin-off: %s vyčlenená z %s." % [str(f.get("name", "")), str(c.name)])
	return ""

func ipo_corp(cid: String, pct: float = 0.3) -> String:
	if not ipo_unlocked():
		return "IPO je zamknuté."
	var c: Dictionary = ex().corps.get(cid, {})
	if c.is_empty():
		return "Neznáma korporácia."
	if bool(listing(str(c.ticker)).get("public", false)):
		return "Už je na burze."
	if corp_value(c) < IPO_MIN_VALUE:
		return "Korporácia je malá na IPO."
	_reprice(str(c.ticker))
	return _float(str(c.ticker), pct)

func _reprice(t: String) -> void:
	var row = listing(t)
	if not row.is_empty():
		row.price = _fundamental(row)
