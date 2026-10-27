extends Node
# JUAN4: rozsirene produkty hracovej banky (volitelne kluce banky, stary save dostane defaulty):
#  sav_rate/savings   – sporiace ucty (vyssi urok, stabilnejsie ako bezne vklady)
#  mort_rate/mort_loans – hypoteky 240 mesiacov, nizsi default, rizikova vaha 50 %
#  corp_rate/corp_loans – firemne uvery 60 mesiacov, vyssi default, rizikova vaha 100 %
#  reserve_target – cielovy podiel rezerv k vkladom (min. zakonna rezerva krajiny)
#  CAR = vlastny kapital / rizikovo vazene aktiva; pod 8 % banka nesmie poskytovat nove uvery
const MIN_CAR = 0.08
const MORT_TERM = 240
const CORP_TERM = 60
const W_CONS = 1.0
const W_MORT = 0.5
const W_CORP = 1.0

func ensure(b: Dictionary) -> void:
	var pol = float(GameState.central.get(str(b.get("country", "")), {}).get("policy", 0.03))
	if not b.has("sav_rate"):
		b["sav_rate"] = clamp(pol * 0.8 + 0.005, 0.0, 0.2)
	if not b.has("savings"):
		b["savings"] = 0.0
	if not b.has("mort_rate"):
		b["mort_rate"] = clamp(pol + 0.02, 0.01, 0.3)
	if not b.has("corp_rate"):
		b["corp_rate"] = clamp(pol + 0.035, 0.01, 0.4)
	if not b.has("mort_loans"):
		b["mort_loans"] = []
	if not b.has("corp_loans"):
		b["corp_loans"] = []
	if not b.has("reserve_target"):
		b["reserve_target"] = max(float(b.get("reserve_ratio", 0.1)), LawSystem.min_reserve(str(b.get("country", ""))))

func _pay(p: float, r: float, n: int) -> float:
	return BankingSystem.annuity_payment(p, r, n)

func sum_p(arr: Array) -> float:
	var s = 0.0
	for l in arr:
		s += float(l.get("p", 0.0))
	return s

func cons_outstanding(b: Dictionary) -> float:
	return sum_p(b.get("cons_loans", []))

func rwa(b: Dictionary) -> float:
	return cons_outstanding(b) * W_CONS + sum_p(b.get("mort_loans", [])) * W_MORT + sum_p(b.get("corp_loans", [])) * W_CORP + maxf(0.0, float(b.get("npc_loans", 0.0))) + maxf(0.0, float(b.get("explicit", 0.0))) + SovereignLoans.outstanding(b)

func car(b: Dictionary) -> float:
	var r = rwa(b)
	return 9.99 if r < 1.0 else float(b.get("equity", 0.0)) / r

func can_lend(b: Dictionary) -> bool:
	return car(b) >= MIN_CAR

func _env(iso: String) -> Dictionary:
	var c: Dictionary = GameState.world.get(iso, {})
	var unemp = float(c.get("unemployment", 0.06))
	var war = 1.6 if GeopoliticsSystem.at_war(iso) else 1.0
	return {"unemp": unemp, "war": war, "pop": float(c.get("population", 5e6)), "gpc": float(c.get("gdp_pc_usd", 20000)) / max(GameState.usd_per_eur, 0.1)}

func mort_default(b: Dictionary, rate_override: float = -1.0) -> float:
	var e = _env(str(b.country))
	var strict = float(b.get("strictness", 0.5))
	var rate = rate_override if rate_override >= 0.0 else float(b.mort_rate)
	return clamp(0.0008 * (1.0 + (e.unemp - 0.05) * 8.0) * e.war * (1.5 - strict) * (1.0 + max(0.0, rate - 0.04) * 6.0), 0.0001, 0.05)

func corp_default(b: Dictionary, rate_override: float = -1.0) -> float:
	var e = _env(str(b.country))
	var strict = float(b.get("strictness", 0.5))
	var rate = rate_override if rate_override >= 0.0 else float(b.corp_rate)
	return clamp(0.003 * (1.0 + (e.unemp - 0.05) * 6.0) * e.war * (1.5 - strict) * (1.0 + max(0.0, rate - 0.06) * 5.0), 0.0005, 0.08)

func mort_demand(b: Dictionary) -> float:
	var e = _env(str(b.country))
	return e.pop * e.gpc * 2.0e-6 * clamp(1.6 - float(b.mort_rate) * 12.0, 0.05, 1.6) * (1.2 - float(b.get("strictness", 0.5)) * 0.6)

func corp_demand(b: Dictionary) -> float:
	var n = 0
	for f in GameState.firms:
		if str(f.get("country", "")) == str(b.country) and str(f.get("owner", "")) == "ai" and not bool(f.get("closed", false)):
			n += 1
	return float(maxi(n, 2)) * 40000.0 * clamp(1.5 - float(b.corp_rate) * 8.0, 0.05, 1.5) * (1.2 - float(b.get("strictness", 0.5)) * 0.6)

func savings_flow(b: Dictionary) -> float:
	var e = _env(str(b.country))
	var market = float(GameState.central.get(str(b.country), {}).get("policy", 0.03)) * 0.6
	var pull = clamp((float(b.sav_rate) - market) * 25.0, -1.0, 1.5)
	var inflow = e.pop * e.gpc * 3.0e-7 * max(0.0, pull + 0.3)
	var outflow = float(b.savings) * (0.008 + max(0.0, -pull) * 0.05)
	return inflow - outflow

func _book(arr: Array, rate: float, dr: float, bank: Dictionary, risk_kind: String = "") -> Dictionary:
	var keep: Array = []
	var collected = 0.0
	var interest = 0.0
	var loss = 0.0
	for l in arr:
		var p = float(l.p)
		var n = int(l.n)
		var loan_rate = float(l.get("rate", rate))
		var actual_risk = dr
		if risk_kind == "mortgage":
			actual_risk = mort_default(bank, loan_rate)
		elif risk_kind == "corporate":
			actual_risk = corp_default(bank, loan_rate)
		var lost = p * actual_risk
		loss += lost
		p -= lost
		var pay = _pay(p, loan_rate, n)
		var i = p * loan_rate / 12.0
		var princ = max(0.0, pay - i)
		p = max(0.0, p - princ)
		n -= 1
		collected += pay
		interest += i
		if n > 0 and p > 1.0:
			keep.append({"p": p, "n": n, "rate": loan_rate})
	return {"keep": keep, "collected": collected, "interest": interest, "loss": loss}

# volane mesacne po consumer_month (hracova banka)
func monthly(b: Dictionary) -> Dictionary:
	ensure(b)
	var md = mort_default(b)
	var cd = corp_default(b)
	var m = _book(b.mort_loans, float(b.mort_rate), md, b, "mortgage")
	var c = _book(b.corp_loans, float(b.corp_rate), cd, b, "corporate")
	# sporiace ucty
	var flow = maxf(savings_flow(b), -float(b.savings))
	var sav_int = float(b.savings) * float(b.sav_rate) / 12.0
	b.savings = max(0.0, float(b.savings) + flow + sav_int)
	b.reserves = float(b.get("reserves", 0.0)) + flow + float(m.collected) + float(c.collected)
	b.equity = float(b.get("equity", 0.0)) + float(m.interest) + float(c.interest) - float(m.loss) - float(c.loss) - sav_int
	b.defaults_total = float(b.get("defaults_total", 0.0)) + float(m.loss) + float(c.loss)
	var new_m = 0.0
	var new_c = 0.0
	var liab = float(b.get("deposits", 0.0)) + float(b.savings)
	var room = max(0.0, float(b.reserves) - liab * float(b.reserve_target))
	room = minf(room, maxf(0.0, float(b.get("equity", 0.0)) / MIN_CAR - rwa(b)))
	if can_lend(b) and room > 0.0:
		new_m = min(mort_demand(b), room * 0.3)
		new_c = min(corp_demand(b), (room - new_m) * 0.3)
		if new_m >= 100.0:
			m.keep.append({"p": new_m, "n": MORT_TERM, "rate": float(b.mort_rate)})
		else:
			new_m = 0.0
		if new_c >= 100.0:
			c.keep.append({"p": new_c, "n": CORP_TERM, "rate": float(b.corp_rate)})
		else:
			new_c = 0.0
		b.reserves = float(b.reserves) - new_m - new_c
	b.mort_loans = m.keep
	b.corp_loans = c.keep
	var st = {"mort_out": sum_p(m.keep), "corp_out": sum_p(c.keep), "mort_new": new_m, "corp_new": new_c,
		"mort_int": m.interest, "corp_int": c.interest, "mort_loss": m.loss, "corp_loss": c.loss, "mort_dr": md, "corp_dr": cd,
		"sav_flow": flow, "sav_int": sav_int, "car": car(b), "lend_ok": can_lend(b)}
	b["prod_stats"] = st
	# doplnenie mesacnej historie (zaznam vytvoril consumer_month)
	var mh: Array = b.get("month_hist", [])
	if mh.size() > 0:
		var row: Dictionary = mh[mh.size() - 1]
		var cs: Dictionary = b.get("cons_stats", {})
		row.rev = float(row.get("rev", 0.0)) + float(m.interest) + float(c.interest)
		row.costs = float(row.get("costs", 0.0)) + float(m.loss) + float(c.loss) + sav_int
		row.profit = float(row.rev) - float(row.costs)
		row["loans"] = cons_outstanding(b) + float(st.mort_out) + float(st.corp_out)
		row["deposits"] = float(b.get("deposits", 0.0)) + float(b.savings)
		row["reserves"] = float(b.reserves)
		row["dr_cons"] = float(cs.get("default_rate", 0.0)) * 100.0
		row["dr_mort"] = md * 100.0
		row["dr_corp"] = cd * 100.0
		row["car"] = min(car(b), 1.0) * 100.0
	legal_monthly(b)  # JUAN13: pravne oddelenie
	return st

func set_rates(b: Dictionary, sav: float, mort: float, corp: float, reserve_target: float) -> void:
	ensure(b)
	b.sav_rate = clamp(sav, 0.0, 0.25)
	b.deposit_rate = b.sav_rate  # JUAN9: jeden urok na vklady/sporenie (predtym dve rozne cisla)
	b.mort_rate = clamp(mort, 0.005, 0.3)
	b.corp_rate = clamp(corp, 0.005, 0.4)
	b.reserve_target = clamp(reserve_target, LawSystem.min_reserve(str(b.get("country", ""))), 0.9)

func text(b: Dictionary) -> String:
	ensure(b)
	var st: Dictionary = b.get("prod_stats", {})
	var cons = cons_outstanding(b)
	var mort = sum_p(b.mort_loans)
	var corp = sum_p(b.corp_loans)
	var dep = float(b.get("deposits", 0.0))
	var out = "BILANCIA\nAktíva: rezervy %s, úvery ľuďom %s, hypotéky %s, firemné úvery %s, štátne úvery %s\n" % [EconMath.eur(float(b.get("reserves", 0))), EconMath.eur(cons), EconMath.eur(mort), EconMath.eur(corp), EconMath.eur(SovereignLoans.outstanding(b))]
	out += "Pasíva: bežné vklady %s, sporiace účty %s, vlastný kapitál %s\n" % [EconMath.eur(dep), EconMath.eur(float(b.savings)), EconMath.eur(float(b.get("equity", 0)))]
	var liq = float(b.get("reserves", 0)) / max(dep + float(b.savings), 1.0)
	out += "Kapitálová primeranosť %s (min %s) %s | rezervy %s z vkladov (cieľ %s)\n" % [EconMath.pct(min(car(b), 9.99)), EconMath.pct(MIN_CAR), "OK" if can_lend(b) else "– NOVÉ ÚVERY ZASTAVENÉ", EconMath.pct(liq), EconMath.pct(float(b.reserve_target))]
	out += "\nPRODUKTY (úrok nových úverov | riziko nesplácania mesačne)\nSpotrebiteľské, hypotekárne a firemné úvery si držia sadzbu pri poskytnutí.\n"
	out += "• Spotrebiteľské: %s | %s\n" % [EconMath.pct(BankingSystem.consumer_rate(b)), EconMath.pct(float(b.get("cons_stats", {}).get("default_rate", BankingSystem.consumer_default_rate(b))))]
	out += "• Hypotéky (20 r.): %s | %s, nové minulý mesiac %s\n" % [EconMath.pct(float(b.mort_rate)), EconMath.pct(mort_default(b)), EconMath.eur(float(st.get("mort_new", 0)))]
	out += "• Firemné (5 r.): %s | %s, nové %s\n" % [EconMath.pct(float(b.corp_rate)), EconMath.pct(corp_default(b)), EconMath.eur(float(st.get("corp_new", 0)))]
	out += "• Sporiace účty: %s, prítok %s/mes., úroky klientom %s\n" % [EconMath.pct(float(b.sav_rate)), EconMath.eur(float(st.get("sav_flow", 0))), EconMath.eur(float(st.get("sav_int", 0)))]
	out += "• Bežné vklady: %s" % EconMath.pct(float(b.get("deposit_rate", 0)))
	return out

# ===== JUAN4: vymahanie dlhov cez hracovu PMC (abstraktne: % vymozenej sumy, naklady, riziko skandalu) =====
const PMC_RANGE_KM = 300.0
const PMC_BASE_COST = 15000.0

func km_between(a: Vector2, b: Vector2) -> float:
	var la1 = deg_to_rad(TerrainSystem.lat_of(a))
	var la2 = deg_to_rad(TerrainSystem.lat_of(b))
	var w = float(DataLoader.map.get("w", 1440))
	var dlon = deg_to_rad((b.x - a.x) / (w - 1.0) * 360.0)
	var x = dlon * cos((la1 + la2) * 0.5)
	return sqrt(x * x + (la2 - la1) * (la2 - la1)) * 6371.0

func bank_pos(b: Dictionary) -> Vector2:
	var bp = b.get("pos", null)
	if typeof(bp) == TYPE_ARRAY and bp.size() >= 2:
		return Vector2(float(bp[0]), float(bp[1]))
	var cs = TerrainSystem.cities(str(b.get("country", "")))
	return cs[0].pos if cs.size() > 0 else Vector2.ZERO

func nearest_pmc(b: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_d = 1e9
	var bp = bank_pos(b)
	for f in GameState.player_firms():
		if str(f.get("industry", "")) != "pmc_unit":
			continue
		var fp = IndustrySystem.firm_pos(f)
		if fp == null:
			continue
		var d = km_between(fp, bp)
		if d < best_d:
			best_d = d
			best = f
	if best.is_empty():
		return {}
	return {"firm": best, "km": best_d}

func recoverable(b: Dictionary) -> float:
	return max(0.0, float(b.get("defaults_total", 0.0)) - float(b.get("recovered_total", 0.0)) - float(b.get("written_off", 0.0)))

func collect_cost(b: Dictionary) -> float:
	return PMC_BASE_COST + recoverable(b) * 0.05

# Vrati {ok, reason}. Podmienky: PMC do 300 km, focus "lob_gov" hotovy, vlada krajiny dlznikov podplatena.
func collect_check(b: Dictionary) -> Dictionary:
	var iso = str(b.get("country", ""))
	var near = nearest_pmc(b)
	if near.is_empty():
		return {"ok": false, "reason": "Nemáš PMC. Postav ju v záložke Založiť (PMC)."}
	if float(near.km) > PMC_RANGE_KM:
		return {"ok": false, "reason": "Tvoja najbližšia PMC je %d km ďaleko (max %d km)." % [int(near.km), int(PMC_RANGE_KM)]}
	if not PoliticsSystem.focus_done("lob_gov"):
		return {"ok": false, "reason": "Najprv splň cieľ „Kontakty v miestnej vláde“ (záložka Ciele)."}
	if not PoliticsSystem.bribed(iso):
		return {"ok": false, "reason": "Vláda v krajine %s nie je podplatená (Politika → Úplatok ministrovi)." % str(GameState.world.get(iso, {}).get("name_sk", iso))}
	if recoverable(b) < 1000.0:
		return {"ok": false, "reason": "Nie je čo vymáhať (nesplatené dlhy pod 1 000 €)."}
	if float(GameState.player.get("cash", 0.0)) < collect_cost(b):
		return {"ok": false, "reason": "Zásah stojí %s, máš %s." % [EconMath.eur(collect_cost(b)), EconMath.eur(float(GameState.player.cash))]}
	return {"ok": true, "reason": "", "km": near.km}

func collect_debts(b: Dictionary, roll_a: float = -1.0, roll_b: float = -1.0) -> Dictionary:
	var chk = collect_check(b)
	if not bool(chk.ok):
		return {"ok": false, "text": str(chk.reason), "recovered": 0.0, "scandal": false}
	var r = RandomNumberGenerator.new()
	r.seed = absi(("pmc|%d|%s" % [GameState.day_index, str(b.get("id", ""))]).hash())
	var a = roll_a if roll_a >= 0.0 else r.randf()
	var s = roll_b if roll_b >= 0.0 else r.randf()
	var cost = collect_cost(b)
	var owed = recoverable(b)
	var share = minf(1.0, (0.30 + 0.30 * a) * (1.0 + PoliticsSystem.bonus_sum("pmc")) * (1.0 + Empire.dep_index(str(b.get("country", ""))) * 0.006))  # vymoze sa 30-60 % (+focus, +zavislost)
	var got = owed * share
	GameState.player.cash = float(GameState.player.cash) - cost
	b.reserves = float(b.get("reserves", 0.0)) + got
	b.equity = float(b.get("equity", 0.0)) + got
	b.recovered_total = float(b.get("recovered_total", 0.0)) + got
	b.written_off = float(b.get("written_off", 0.0)) + (owed - got)  # zvysok sa odpise, nevymaha sa dvakrat
	var scandal_p = clamp(0.20 * PoliticsSystem.bonus_mult("scandal"), 0.02, 0.9)
	var scandal = s < scandal_p
	var text = "PMC vymohla %s z %s nesplatených dlhov (náklady %s)." % [EconMath.eur(got), EconMath.eur(owed), EconMath.eur(cost)]
	if scandal:
		GameState.player.rating = maxi(0, int(GameState.player.get("rating", 55)) - 15)
		b.confidence = max(0.0, float(b.get("confidence", 0.7)) - 0.15)
		text += " ŠKANDÁL: médiá píšu o tvrdom vymáhaní, reputácia −15, dôvera v banku klesla."
	GameState.post_news(text)
	return {"ok": true, "text": text, "recovered": got, "scandal": scandal, "cost": cost}

# ===== JUAN13 (t805u): pravne oddelenie banky – vymahanie dlhov cez sud =====
const LAWYER_MONTHLY = 6000.0
const LAWYER_CAP = 250000.0      # kolko dlhov zvladne jeden pravnik mesacne
const TRAIN_COST = 100000.0
const LEGAL_FEE = 0.10           # sudne trovy z vymozenej sumy
const FLAVOR = [
	"Dlžníci v krajine %s zistili, že súd, noviny aj pekáreň na rohu patria tej istej korporácii. Odvolanie neprichádza do úvahy.",
	"Právnici banky v krajine %s vyhrali spor ešte pred pojednávaním – sudca bol u nich na stáži.",
	"V krajine %s sa splácanie dlhov stalo národným športom. Iné športy sponzoruje tiež tvoja korporácia.",
]

func legal(b: Dictionary) -> Dictionary:
	if not b.has("legal") or typeof(b.legal) != TYPE_DICTIONARY:
		b["legal"] = {"lawyers": 0, "level": 1, "log": [], "won": 0.0, "costs": 0.0}
	return b.legal

func hire_lawyer(b: Dictionary, n: int = 1) -> String:
	var l = legal(b)
	l.lawyers = clampi(int(l.lawyers) + n, 0, 20)
	return ""

func train_lawyers(b: Dictionary) -> String:
	var l = legal(b)
	if int(l.level) >= 3:
		return "Právnici majú najvyššiu úroveň."
	if int(l.lawyers) <= 0:
		return "Najprv najmi právnika."
	if float(GameState.player.cash) < TRAIN_COST:
		return "Školenie stojí %s." % EconMath.eur(TRAIN_COST)
	GameState.player.cash = float(GameState.player.cash) - TRAIN_COST
	l.level = int(l.level) + 1
	return ""

func corp_bonus(b: Dictionary) -> float:
	var cid = str(b.get("corp", ""))
	var c: Dictionary = StockMarket.ex().corps.get(cid, {})
	if c.is_empty():
		return 0.0
	return clampf(0.04 * log(1.0 + StockMarket.corp_value(c) / 1.0e6), 0.05, 0.25)

func set_bank_corp(b: Dictionary, cid: String) -> String:
	if cid != "" and not StockMarket.ex().corps.has(cid):
		return "Neznáma korporácia."
	b["corp"] = cid
	return ""

func legal_chance(b: Dictionary) -> float:
	var iso = str(b.get("country", ""))
	var dep = Empire.dep_index(iso)
	if dep >= 85.0:
		return 0.99  # Uplna zavislost: dlznici sa nemaju ako branit
	var l = legal(b)
	return clampf(0.45 + corp_bonus(b) + 0.07 * float(int(l.level) - 1) + 0.01 * float(int(l.lawyers)) + dep * 0.004, 0.05, 0.97)

func legal_monthly(b: Dictionary, roll: float = -1.0) -> Dictionary:
	var l = legal(b)
	var n = int(l.lawyers)
	if n <= 0:
		return {}
	var cost = LAWYER_MONTHLY * n
	b.equity = float(b.get("equity", 0.0)) - cost
	b.reserves = float(b.get("reserves", 0.0)) - cost
	l.costs = float(l.costs) + cost
	var owed = recoverable(b)
	var pursued = minf(owed, LAWYER_CAP * n * (1.0 + 0.25 * float(int(l.level) - 1)))
	if pursued < 1000.0:
		return {"cost": cost, "got": 0.0}
	var r = RandomNumberGenerator.new()
	r.seed = absi(("legal|%d|%s" % [GameState.day_index, str(b.get("id", ""))]).hash())
	var a = roll if roll >= 0.0 else r.randf()
	var p = legal_chance(b)
	var iso = str(b.get("country", ""))
	var txt = ""
	var got = 0.0
	if a < p:
		var share = 0.5 + 0.3 * r.randf() if p < 0.99 else 0.95
		got = pursued * share
		var fee = got * LEGAL_FEE
		b.reserves = float(b.reserves) + got - fee
		b.equity = float(b.equity) + got - fee
		b.recovered_total = float(b.get("recovered_total", 0.0)) + got
		b.written_off = float(b.get("written_off", 0.0)) + (pursued - got)
		l.won = float(l.won) + got
		txt = "Právnici vymohli %s z %s (trovy %s)." % [EconMath.eur(got), EconMath.eur(pursued), EconMath.eur(fee)]
		if p >= 0.99 and r.randf() < 0.5:
			GameState.post_news(FLAVOR[r.randi() % FLAVOR.size()] % str(GameState.world.get(iso, {}).get("name_sk", iso)))
	else:
		b.written_off = float(b.get("written_off", 0.0)) + pursued * 0.2
		txt = "Súd prehratý: dlžníci sa ubránili, %s odpísané." % EconMath.eur(pursued * 0.2)
		if r.randf() < 0.25:
			GameState.player.rating = maxi(0, int(GameState.player.get("rating", 55)) - 2)
			txt += " Médiá kritizujú agresívne žaloby (reputácia −2)."
	l.log.push_front("%d.%d.%d: %s" % [int(GameState.date.d), int(GameState.date.m), int(GameState.date.y), txt])
	while (l.log as Array).size() > 20:
		l.log.pop_back()
	return {"cost": cost, "got": got, "text": txt, "chance": p}
