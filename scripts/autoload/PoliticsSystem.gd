extends Node
# JUAN4: politika krajin (vlady, strany, volby), lobing + uplatky hraca a korporatny "focus tree".
# Stav je v GameState.ext.politics / ext.focus (volitelny kluc savu; stary save sa doplni cez ensure()).
# Volby a zmeny dani bezia len ked GameState.config.politics == true (nova hra z menu). Testy si to zapinaju samy.

const GOV_NAMES = {"democracy": "Demokracia", "hybrid": "Hybridný režim", "autocracy": "Autoritársky režim", "monarchy": "Monarchia", "communist": "Komunistický režim"}
const PARTIES = [
	{"id": "left", "name": "Sociálni demokrati", "tax": 0.04, "reg": 0.15},
	{"id": "center", "name": "Liberálny stred", "tax": -0.01, "reg": -0.05},
	{"id": "right", "name": "Konzervatívci", "tax": -0.03, "reg": -0.10},
	{"id": "green", "name": "Zelení", "tax": 0.02, "reg": 0.20},
	{"id": "populist", "name": "Populisti", "tax": 0.01, "reg": 0.05},
	{"id": "nat", "name": "Národná jednota", "tax": 0.02, "reg": 0.12},  # JUAN5
	{"id": "comm", "name": "Komunistická strana", "tax": 0.08, "reg": 0.30},
	{"id": "royal", "name": "Kráľovská rada", "tax": -0.02, "reg": 0.10},
]
# JUAN5: typ vlady -> cena uplatku, riziko, regulacia, volby (vlady a strany su v data/politics_juan5.json, mena su parodie)
const GOV_BRIBE_COST = {"democracy": 1.5, "hybrid": 1.0, "autocracy": 0.8, "monarchy": 1.2, "communist": 0.9}
const GOV_REG = {"democracy": 0.5, "hybrid": 0.55, "autocracy": 0.65, "monarchy": 0.6, "communist": 0.8}
const GOV_FUND_EFF = {"democracy": 1.0, "hybrid": 0.7, "autocracy": 0.35, "monarchy": 0.3, "communist": 0.25}
const GOV_ELECTIONS = {"democracy": 48, "hybrid": 60}
# akcie hraca: base cena = 20 000 € + HDP krajiny (EUR) × 1e-7
const ACTIONS = {
	"lobby_tax":  {"name": "Lobing: nižšie dane",       "mult": 1.0, "chance": 0.40, "scandal": 0.04},
	"lobby_reg":  {"name": "Lobing: menej regulácie",   "mult": 1.0, "chance": 0.45, "scandal": 0.04},
	"lobby_party": {"name": "Podpora strany vo voľbách", "mult": 1.5, "chance": 0.55, "scandal": 0.06},
	"lobby_peace": {"name": "Lobing za mier",            "mult": 2.0, "chance": 0.30, "scandal": 0.02},
	"lobby_war":  {"name": "Lobing za konflikt (zbrojári)", "mult": 3.0, "chance": 0.15, "scandal": 0.12},
	"bribe":      {"name": "Úplatok ministrovi",        "mult": 2.5, "chance": 0.60, "scandal": 0.25},
	"fund_party": {"name": "Financovať stranu (popularita)", "mult": 1.2, "chance": 0.70, "scandal": 0.10},  # JUAN5
	"war_support": {"name": "Podporiť krajinu vo vojne", "mult": 2.0, "chance": 0.80, "scandal": 0.08},
	"lobby_sanction": {"name": "Lobing: sankcie voči cieľu", "mult": 1.8, "chance": 0.30, "scandal": 0.05},
	"lobby_trade": {"name": "Lobing: obchodná dohoda s cieľom", "mult": 1.5, "chance": 0.35, "scandal": 0.03},
	"strike": {"name": "Zorganizovať štrajk (tlak na vládu)", "mult": 1.0, "chance": 0.40, "scandal": 0.15},
	# JUAN8: neprame ovplyvnovanie statu (hrac je podnikatel, nie stat) – rozhoduje vlada podla vplyvu
	"lobby_relief": {"name": "Lobing: colná úľava s cieľom", "mult": 1.3, "chance": 0.35, "scandal": 0.03},
	"lobby_embargo": {"name": "Lobing: embargo voči cieľu", "mult": 2.2, "chance": 0.20, "scandal": 0.08},
	"media_campaign": {"name": "Mediálna kampaň (vplyv)", "mult": 0.8, "chance": 0.75, "scandal": 0.02},
}
# JUAN8: vplyv hraca v krajine 0–100 (ext.influence), zvysuje sancu lobingu
const INF_GAIN = {"media_campaign": 10, "fund_party": 6, "bribe": 12, "lobby_party": 5}
const INF_SUCCESS = 4
const INF_SCANDAL = -15
const GOV_CHANCE = {"democracy": -0.10, "hybrid": 0.05, "autocracy": 0.15, "monarchy": 0.10, "communist": 0.12}
const GOV_SCANDAL = {"democracy": 1.4, "hybrid": 1.0, "autocracy": 0.6, "monarchy": 0.7, "communist": 0.8}

# ===== focus tree (inspiracia: strom narodnych cielov; vlastny obsah) =====
# bonusy: lobby (+sanca), scandal (nasobok rizika), cost (nasobok cien firiem), rate (p.b. k uroku), vote (vplyv na volby), rival (odolnost voci AI konkurentom)
# HOI4-like (vlastny obsah): naraz jeden ciel, 35-70 dni, prerekvizity (req), vzajomne exkluzivne (excl),
# x/y = pozicia v strome, on_done = jednorazovy efekt pri dokonceni, gender = len pre dane pohlavie.
const FOCUS = [
	{"id": "ind1", "branch": "Ekonomika", "x": 0, "y": 0, "name": "Štandardizácia", "days": 35, "req": [], "bonus": {"cost": 0.96}, "desc": "ceny firiem ×0,96"},
	{"id": "ind2", "branch": "Ekonomika", "x": 0, "y": 1, "name": "Vlastní dodávatelia", "days": 50, "req": ["ind1"], "bonus": {"cost": 0.95, "rival": 0.10}, "desc": "ceny ×0,95, AI konkurencia −10 %"},
	{"id": "ind3", "branch": "Ekonomika", "x": 0, "y": 2, "name": "Monopolná pozícia", "days": 70, "req": ["ind2"], "bonus": {"rival": 0.20}, "desc": "AI konkurencia −20 %"},
	{"id": "fin1", "branch": "Ekonomika", "x": 1, "y": 0, "name": "Dobré vzťahy s bankármi", "days": 35, "req": [], "bonus": {"rate": -0.005}, "desc": "úver −0,5 p.b."},
	{"id": "fin2", "branch": "Ekonomika", "x": 1, "y": 1, "name": "Ratingová agentúra", "days": 50, "req": ["fin1"], "bonus": {"rate": -0.007}, "desc": "úver −0,7 p.b.", "on_done": {"rating": 3}},
	{"id": "fin3", "branch": "Ekonomika", "x": 1, "y": 2, "name": "Daňová optimalizácia", "days": 70, "req": ["fin2", "ind1"], "bonus": {"rate": -0.005, "cost": 0.97}, "desc": "úver −0,5 p.b., ceny ×0,97"},
	{"id": "rnd1", "branch": "Ekonomika", "x": 1, "y": 3, "name": "Výskumné oddelenie", "days": 45, "req": ["fin1"], "bonus": {}, "desc": "+1 slot výskumu (paralelný výskum)"},  # JUAN5
	{"id": "lob1", "branch": "Politika", "x": 2, "y": 0, "name": "Kontakty v parlamente", "days": 35, "req": [], "bonus": {"lobby": 0.05}, "desc": "+5 % šanca lobingu"},
	{"id": "lob2", "branch": "Politika", "x": 2, "y": 1, "name": "Lobistická kancelária", "days": 50, "req": ["lob1"], "bonus": {"lobby": 0.08}, "desc": "+8 % šanca lobingu"},
	{"id": "lob3", "branch": "Politika", "x": 2, "y": 2, "name": "Tieňový minister", "days": 70, "req": ["lob2"], "bonus": {"lobby": 0.10, "vote": 0.10}, "desc": "+10 % lobing, +10 % vplyv na voľby"},
	{"id": "med1", "branch": "Politika", "x": 3, "y": 0, "name": "PR oddelenie", "days": 35, "req": [], "bonus": {"scandal": 0.85}, "desc": "riziko škandálu ×0,85"},
	{"id": "med2", "branch": "Politika", "x": 3, "y": 1, "name": "Vlastný denník", "days": 50, "req": ["med1"], "bonus": {"scandal": 0.75, "vote": 0.05}, "desc": "škandál ×0,75, +5 % voľby"},
	{"id": "med3", "branch": "Politika", "x": 3, "y": 2, "name": "Televízia", "days": 70, "req": ["med2"], "bonus": {"vote": 0.15}, "desc": "+15 % vplyv na voľby", "on_done": {"rating": 5}},
	{"id": "clean", "branch": "Podsvetie", "x": 4, "y": 0, "name": "Čistý podnikateľ", "days": 40, "req": [], "excl": ["dirty"], "bonus": {"scandal": 0.80, "vote": 0.05}, "desc": "škandál ×0,8, +5 % voľby, +5 reputácia (vylúči Korupciu)", "on_done": {"rating": 5}},
	{"id": "clean2", "branch": "Podsvetie", "x": 4, "y": 1, "name": "Transparentná firma", "days": 60, "req": ["clean"], "bonus": {"cost": 0.97, "rate": -0.003}, "desc": "ceny ×0,97, úver −0,3 p.b."},
	{"id": "dirty", "branch": "Podsvetie", "x": 5, "y": 0, "name": "Korupcia a podsvetie", "days": 40, "req": [], "excl": ["clean"], "bonus": {"act_cost": 0.90}, "desc": "odomkne úplatky, lobing −10 % cena (vylúči Čistého podnikateľa)"},
	{"id": "lob_gov", "branch": "Podsvetie", "x": 5, "y": 1, "name": "Kontakty v miestnej vláde", "days": 50, "req": ["dirty"], "bonus": {"lobby": 0.03}, "desc": "odomkne vymáhanie dlhov cez PMC (s podplatenou vládou)"},
	{"id": "pmc_net", "branch": "Podsvetie", "x": 5, "y": 2, "name": "Bezpečnostné kontakty", "days": 60, "req": ["lob_gov"], "bonus": {"pmc": 0.10}, "desc": "PMC vymôže o 10 % viac"},
	{"id": "g_m1", "branch": "Pohlavie", "gender": "muž", "x": 6, "y": 0, "name": "Old boys club", "days": 45, "req": [], "bonus": {"act_cost": 0.92, "scandal": 0.92}, "desc": "lobing a úplatky −8 % cena, škandál ×0,92"},
	{"id": "g_m2", "branch": "Pohlavie", "gender": "muž", "x": 6, "y": 1, "name": "Tvrdý vyjednávač", "days": 45, "req": [], "bonus": {"rate": -0.006}, "desc": "úvery −0,6 p.b."},
	{"id": "g_f1", "branch": "Pohlavie", "gender": "žena", "x": 6, "y": 0, "name": "Sieť žien v biznise", "days": 45, "req": [], "bonus": {"mgr_cost": 0.92}, "desc": "pravá ruka −8 % plat"},
	{"id": "g_f2", "branch": "Pohlavie", "gender": "žena", "x": 6, "y": 1, "name": "Mediálna ikona", "days": 45, "req": [], "bonus": {"rep": 1.0}, "desc": "reputácia +1 mesačne (max 100), kampane účinnejšie"},
]

func _ext() -> Dictionary:
	if typeof(GameState.get("ext")) != TYPE_DICTIONARY:
		GameState.ext = {}
	return GameState.ext

func _rng(tag: String) -> RandomNumberGenerator:
	var r = RandomNumberGenerator.new()
	r.seed = absi(("%s|%s|%d|%d" % [str(GameState.config.get("seed", 47)), tag, GameState.day_index, int(_ext().get("pol_n", 0))]).hash())
	_ext()["pol_n"] = int(_ext().get("pol_n", 0)) + 1
	return r

func gov_type(iso: String) -> String:
	var d: Dictionary = DataLoader.politics.get(iso, {})
	if d.has("gov"):
		return str(d.gov)
	var risk = float(GameState.world.get(iso, {}).get("political_risk", 0.2))
	if risk < 0.15:
		return "democracy"
	if risk < 0.35:
		return "hybrid"
	return "autocracy"

func setup() -> void:
	var pol: Dictionary = {}
	for iso in GameState.world.keys():
		pol[iso] = _new_country(str(iso))
	_ext()["politics"] = pol
	_ext()["focus"] = {"done": [], "current": "", "left": 0}

func _new_country(iso: String) -> Dictionary:
	var h = absi(iso.hash())
	var gt = gov_type(iso)
	var party = PARTIES[h % 5]
	if gt == "autocracy":
		party = PARTIES[4]
	var cycle = int(GOV_ELECTIONS.get(gt, 0))
	var reg = float(GOV_REG.get(gt, 0.5))
	var c = {"gov": gt, "party": str(party.id), "base_tax": LawSystem.corporate_tax(iso), "reg": reg, "base_reg": reg,
		"approval": 0.5, "next_election": (h % cycle) + 1 if cycle > 0 else -1, "favor": 0, "support": ""}
	_fill_juan5(iso, c)
	return c

# JUAN5: doplni strany, lidra a typ vlady z data/politics_juan5.json (aj do stareho savu)
func _fill_juan5(iso: String, c: Dictionary) -> void:
	var d: Dictionary = DataLoader.politics.get(iso, {})
	if c.has("parties") and typeof(c.parties) == TYPE_ARRAY:
		return
	var parties: Array = []
	for p in d.get("parties", []):
		parties.append({"id": str(p.id), "name": str(p.name), "ideology": str(p.get("ideology", "")), "popularity": float(p.get("popularity", 0.3)), "leader_name": str(p.get("leader_name", ""))})
	if parties.is_empty():
		for i in 3:
			var pd: Dictionary = PARTIES[(absi(iso.hash()) + i) % 5]
			parties.append({"id": str(pd.id), "name": str(pd.name), "ideology": "", "popularity": 0.34 if i == 0 else 0.33, "leader_name": ""})
	c["parties"] = parties
	c["leader_name"] = str(d.get("leader_name", "neznámy líder"))
	if d.has("gov") and str(d.gov) != str(c.get("gov", "")):
		c["gov"] = str(d.gov)
		var cycle = int(GOV_ELECTIONS.get(str(d.gov), 0))
		c["next_election"] = (absi(iso.hash()) % cycle) + 1 if cycle > 0 else -1
	if d.has("ruling"):
		c["party"] = str(d.ruling)

func party_in(iso: String, pid: String) -> Dictionary:
	for p in country(iso).get("parties", []):
		if str(p.id) == pid:
			return p
	return {}

func ensure() -> void:
	var e = _ext()
	if not e.has("politics") or typeof(e.politics) != TYPE_DICTIONARY:
		e["politics"] = {}
	for iso in GameState.world.keys():
		if not e.politics.has(iso):
			e.politics[iso] = _new_country(str(iso))
		elif not e.politics[iso].has("parties"):
			_fill_juan5(str(iso), e.politics[iso])
	if not e.has("focus") or typeof(e.focus) != TYPE_DICTIONARY:
		e["focus"] = {"done": [], "current": "", "left": 0}

func country(iso: String) -> Dictionary:
	var e = _ext()
	if e.has("politics") and typeof(e.politics) == TYPE_DICTIONARY and e.politics.has(iso) and e.politics[iso].has("parties") and e.has("focus"):
		return e.politics[iso]
	ensure()
	return _ext().politics.get(iso, {})

func party_def(pid: String) -> Dictionary:
	for p in PARTIES:
		if str(p.id) == pid:
			return p
	return PARTIES[1]

# nasobok cien firiem v krajine: regulacia (0.5 = neutralne) + bonus z focus tree
func cost_mult(iso: String) -> float:
	var m = bonus_mult("cost")
	var c: Dictionary = _ext().get("politics", {}).get(iso, {})
	if not c.is_empty():
		m *= 1.0 + (float(c.get("reg", 0.5)) - float(c.get("base_reg", 0.5))) * 0.4
	return m

func rate_bonus() -> float:
	return bonus_sum("rate") + float(GameState.player.get("modifiers", {}).get("rate_bonus", 0.0))  # JUAN5: vyskum fin2

func action_cost(iso: String, action: String) -> float:
	var gdp_eur = float(GameState.world.get(iso, {}).get("gdp_usd", 1e11)) / max(GameState.usd_per_eur, 0.1)
	var m = 1.0
	if action == "bribe":
		m = float(GOV_BRIBE_COST.get(str(country(iso).get("gov", "hybrid")), 1.0))
	return (20000.0 + gdp_eur * 1e-7) * float(ACTIONS.get(action, {"mult": 1.0}).mult) * bonus_mult("act_cost") * m

func action_chance(iso: String, action: String) -> float:
	var a: Dictionary = ACTIONS.get(action, {})
	var gt = str(country(iso).get("gov", "hybrid"))
	var media = min(0.10, 0.03 * float(IndustrySystem.media_count()))  # JUAN5 #18: vlastne media
	return clamp(float(a.get("chance", 0.3)) + float(GOV_CHANCE.get(gt, 0.0)) + bonus_sum("lobby") + media + influence_bonus(iso) + Empire.dep_index(iso) * 0.003, 0.05, 0.98)  # JUAN13: zavislost krajiny

# ===== JUAN8: vplyv =====
func influence_map() -> Dictionary:
	var e = _ext()
	if not e.has("influence") or typeof(e.influence) != TYPE_DICTIONARY:
		e["influence"] = {}
	return e.influence

func influence(iso: String) -> float:
	return float(influence_map().get(iso, 0.0))

func add_influence(iso: String, d: float) -> void:
	influence_map()[iso] = clampf(influence(iso) + d, 0.0, 100.0)

# vplyv (do +0.30), podporena strana pri moci (+0.10), podplatena vlada (+0.08)
func influence_bonus(iso: String) -> float:
	var b = influence(iso) * 0.003
	var c: Dictionary = _ext().get("politics", {}).get(iso, {})
	if not c.is_empty():
		if str(c.get("support", "")) != "" and str(c.get("support", "")) == str(c.get("party", "")):
			b += 0.10
		if bool(c.get("bribed", false)):
			b += 0.08
	return b

func scandal_chance(iso: String, action: String) -> float:
	var a: Dictionary = ACTIONS.get(action, {})
	var gt = str(country(iso).get("gov", "hybrid"))
	return clamp(float(a.get("scandal", 0.05)) * float(GOV_SCANDAL.get(gt, 1.0)) * bonus_mult("scandal"), 0.0, 0.9)

# Vrati {ok, success, scandal, text}. roll_a/roll_b mozu testy zadat (0..1), inak nahodne.
func act(iso: String, action: String, party_id: String = "", roll_a: float = -1.0, roll_b: float = -1.0) -> Dictionary:
	ensure()
	if not ACTIONS.has(action) or not GameState.world.has(iso):
		return {"ok": false, "success": false, "scandal": false, "text": "Neznáma akcia alebo krajina."}
	if action == "bribe" and not focus_done("dirty"):
		return {"ok": false, "success": false, "scandal": false, "text": "Úplatky odomkne cieľ „Korupcia a podsvetie“ (Ciele → Podsvetie)."}
	var pre = _juan5_precheck(iso, action, party_id)
	if pre != "":
		return {"ok": false, "success": false, "scandal": false, "text": pre}
	var cost = action_cost(iso, action)
	if float(GameState.player.get("cash", 0.0)) < cost:
		return {"ok": false, "success": false, "scandal": false, "text": "Treba %s, máš %s." % [EconMath.eur(cost), EconMath.eur(float(GameState.player.cash))]}
	GameState.player.cash = float(GameState.player.cash) - cost
	var r = _rng("act" + iso + action)
	var a = roll_a if roll_a >= 0.0 else r.randf()
	var b = roll_b if roll_b >= 0.0 else r.randf()
	var success = a < action_chance(iso, action)
	var scandal = b < scandal_chance(iso, action)
	var c: Dictionary = _ext().politics[iso]
	var nm = str(GameState.world[iso].get("name_sk", iso))
	var text = ""
	if success:
		match action:
			"lobby_tax":
				LawSystem.set_tax(iso, LawSystem.corporate_tax(iso) - 0.01)
				text = "%s: daň z príjmu firiem klesla na %s." % [nm, EconMath.pct(LawSystem.corporate_tax(iso))]
			"lobby_reg":
				c.reg = clamp(float(c.reg) - 0.08, 0.0, 1.0)
				text = "%s: menej byrokracie, stavby lacnejšie." % nm
			"lobby_party":
				c.support = party_id if party_id != "" else "center"
				text = "%s: podporuješ stranu %s pred voľbami." % [nm, str(party_def(str(c.support)).name)]
			"lobby_peace":
				var ended = false
				for w in GameState.wars.duplicate():
					if iso in w.get("a", []) or iso in w.get("b", []):
						GeopoliticsSystem._end_war(w)
						ended = true
						break
				text = "%s: vláda podpísala prímerie." % nm if ended else "%s: vláda sľúbila mier (nie je vo vojne)." % nm
			"lobby_war":
				for k in GameState.relations.keys():
					if str(k).find(iso) >= 0:
						GameState.relations[k] = int(GameState.relations[k]) - 15
				text = "%s: vzťahy so susedmi sa zhoršili, zbrojári sa tešia." % nm
			"bribe":
				LawSystem.set_tax(iso, LawSystem.corporate_tax(iso) - 0.02)
				c.reg = clamp(float(c.reg) - 0.12, 0.0, 1.0)
				c.favor = 12
				c.bribed = true  # JUAN4: vlada v tejto krajine je podplatena (pre PMC vymahanie)
				text = "%s: minister prijal obálku. Dane −2 p.b., regulácia nižšia." % nm
			_:
				text = _juan5_effect(iso, action, party_id, c, nm, cost)
	else:
		text = "%s: %s nevyšiel, peniaze sú preč." % [nm, str(ACTIONS[action].name)]
	# JUAN8: vplyv
	add_influence(iso, float(INF_GAIN.get(action, 0)) + (float(INF_SUCCESS) if success else 0.0) + (float(INF_SCANDAL) if scandal else 0.0))
	if scandal:
		var fine = cost * 2.0
		GameState.player.cash = float(GameState.player.cash) - fine
		GameState.player.rating = maxi(0, int(GameState.player.get("rating", 55)) - 10)
		GameState.player.credit_score = max(0.0, float(GameState.player.get("credit_score", 55.0)) - 10.0)
		text += " ŠKANDÁL! Médiá to prevalili: pokuta %s, rating −10." % EconMath.eur(fine)
	GameState.post_news(text)
	return {"ok": true, "success": success, "scandal": scandal, "text": text, "cost": cost}

# ===== JUAN5: nove akcie (financovanie strany, podpora vo vojne, sankcie/dohody, strajk) =====
func _juan5_precheck(iso: String, action: String, arg: String) -> String:
	match action:
		"fund_party":
			if party_in(iso, arg).is_empty():
				return "Vyber stranu, ktorá v tejto krajine existuje."
		"war_support":
			if not GeopoliticsSystem.at_war(iso):
				return "%s nie je vo vojne." % str(GameState.world[iso].get("name_sk", iso))
		"lobby_sanction", "lobby_trade", "lobby_relief", "lobby_embargo":
			if arg == "" or arg == iso or not GameState.world.has(arg):
				return "Vyber cieľovú krajinu (iná ako lobovaná)."
	return ""

func fund_eff(iso: String) -> float:
	return float(GOV_FUND_EFF.get(str(country(iso).get("gov", "hybrid")), 0.5))

func player_industry_count(ids: Array) -> int:
	var n = 0
	for f in GameState.player_firms():
		if str(f.get("industry", "")) in ids:
			n += 1
	return n

func _juan5_effect(iso: String, action: String, arg: String, c: Dictionary, nm: String, cost: float) -> String:
	var home = str(GameState.player.get("home", ""))
	match action:
		"fund_party":
			var p: Dictionary = party_in(iso, arg)
			var gain = 0.06 * fund_eff(iso)
			p.popularity = float(p.popularity) + gain
			var tot = 0.0
			for q in c.parties:
				tot += float(q.popularity)
			for q in c.parties:
				q.popularity = float(q.popularity) / max(tot, 0.001)
			c.support = str(p.id)
			return "%s: strana %s (líder %s) má +%d %% popularity." % [nm, str(p.name), str(p.get("leader_name", "")), int(round(gain * 100))]
		"war_support":
			var enemies: Array = []
			for w in GameState.wars:
				if iso in w.get("a", []):
					enemies += w.get("b", [])
				elif iso in w.get("b", []):
					enemies += w.get("a", [])
			if home != "":
				GeopoliticsSystem._add(home, iso, 20)
				for e in enemies:
					GeopoliticsSystem._add(home, str(e), -15)
			var supply = player_industry_count(["arms_plant", "chem_plant", "logistics_hub", "pharma_lab"])
			var pmc = player_industry_count(["pmc_unit"])
			var income = cost * 0.25 * min(supply, 4) + (cost * 0.9 if pmc > 0 else 0.0)
			GameState.player.cash = float(GameState.player.cash) + income
			var t = "%s: tvoja podpora dorazila. Vzťahy +20, s nepriateľmi −15." % nm
			if supply > 0:
				t += " Dodávky z %d tvojich firiem." % supply
			if pmc > 0:
				t += " PMC kontrakt podpísaný."
			if income > 0.0:
				t += " Príjem z kontraktov %s." % EconMath.eur(income)
			GameState.player.rating = maxi(0, int(GameState.player.get("rating", 55)) - 2)  # verejnost nema rada vojnovych dodavatelov
			return t
		"lobby_sanction":
			var k = GeopoliticsSystem.sanction_key(iso, arg)
			if not GameState.sanctions.has(k):
				GameState.sanctions.append(k)
			GeopoliticsSystem._add(iso, arg, -12)
			return "%s uvalila sankcie na %s." % [nm, str(GameState.world[arg].get("name_sk", arg))]
		"lobby_trade":
			var k2 = GeopoliticsSystem.sanction_key(iso, arg)
			GameState.sanctions.erase(k2)
			if not GameState.treaties.has(k2):
				GameState.treaties.append(k2)
			GeopoliticsSystem._add(iso, arg, 15)
			return "%s podpísala obchodnú dohodu s %s." % [nm, str(GameState.world[arg].get("name_sk", arg))]
		"lobby_relief":
			var k3 = GeopoliticsSystem.sanction_key(iso, arg)
			if not GameState.reliefs.has(k3):
				GameState.reliefs.append(k3)
			GeopoliticsSystem._add(iso, arg, 8)
			return "%s znížila clá voči %s." % [nm, str(GameState.world[arg].get("name_sk", arg))]
		"lobby_embargo":
			var k4 = GeopoliticsSystem.sanction_key(iso, arg)
			if not GameState.embargoes.has(k4):
				GameState.embargoes.append(k4)
			GameState.treaties.erase(k4)
			GeopoliticsSystem._add(iso, arg, -20)
			return "%s vyhlásila embargo voči %s." % [nm, str(GameState.world[arg].get("name_sk", arg))]
		"media_campaign":
			c.approval = clamp(float(c.get("approval", 0.5)) + 0.02, 0.05, 0.95)
			return "%s: tvoja mediálna kampaň zabrala, máš tu väčší vplyv." % nm
		"strike":
			c.approval = clamp(float(c.approval) - 0.10, 0.05, 0.95)
			c.reg = clamp(float(c.reg) - 0.05, 0.0, 1.0)
			return "%s: štrajk ochromil krajinu, vláda ustúpila (regulácia nižšia, podpora vlády −10 %%)." % nm
	return nm

func bribed(iso: String) -> bool:
	return bool(country(iso).get("bribed", false))

func monthly() -> void:
	for k in influence_map().keys():  # JUAN8: vplyv pomaly vyprcha
		influence_map()[k] = maxf(0.0, float(influence_map()[k]) - 1.0)
	if not bool(GameState.config.get("politics", false)):
		return
	ensure()
	if bonus_sum("rep") > 0.0:
		GameState.player.rating = mini(100, int(GameState.player.get("rating", 55)) + 1)
	var month_no = int(GameState.date.y) * 12 + int(GameState.date.m)
	for iso in _ext().politics.keys():
		var c: Dictionary = _ext().politics[iso]
		# JUAN5: tier 2 krajiny = zjednodusene (prepocet raz za 3 mesiace, odpocet volieb po 3)
		var step = 1
		if MarketSystem.tier_of(str(iso)) == 2:
			if month_no % 3 != 0:
				continue
			step = 3
		if int(c.get("favor", 0)) > 0:
			c.favor = int(c.favor) - 1
		var w: Dictionary = GameState.world.get(iso, {})
		var appr = float(c.get("approval", 0.5)) + float(w.get("gdp_growth", 0.0)) * 0.5 - (float(w.get("unemployment", 0.05)) - 0.06) * 0.2 - (0.02 if GeopoliticsSystem.at_war(str(iso)) else 0.0)
		c.approval = clamp(appr * 0.97 + 0.5 * 0.03, 0.05, 0.95)
		if int(c.get("next_election", -1)) > 0:
			c.next_election = max(0, int(c.next_election) - step)
			if int(c.next_election) == 0:
				election(str(iso))

func election(iso: String, roll: float = -1.0) -> String:
	ensure()
	var c: Dictionary = _ext().politics[iso]
	var r = _rng("elect" + iso)
	var weights: Array = []
	var total = 0.0
	var plist: Array = c.get("parties", []) if not c.get("parties", []).is_empty() else PARTIES  # JUAN5: strany krajiny
	for p in plist:
		var wgt = 0.4 + float(p.get("popularity", 0.3)) * 2.0
		if str(p.id) == str(c.party):
			wgt += float(c.approval) * 2.0
			if str(c.gov) == "hybrid":
				wgt *= 4.0
		if str(p.id) == str(c.get("support", "")):
			wgt *= 2.0 + bonus_sum("vote") * 5.0
		weights.append(wgt)
		total += wgt
	var pick = (roll if roll >= 0.0 else r.randf()) * total
	var winner: Dictionary = party_def(str(plist[0].id))
	for i in plist.size():
		pick -= float(weights[i])
		if pick <= 0.0:
			winner = party_def(str(plist[i].id))
			break
	var old = str(c.party)
	c.party = str(winner.id)
	c.approval = 0.55
	c.support = ""
	c.next_election = int(GOV_ELECTIONS.get(str(c.gov), 60))
	LawSystem.set_tax(iso, clamp(float(c.base_tax) + float(winner.tax), 0.05, 0.45))
	c.reg = clamp(float(c.base_reg) + float(winner.reg), 0.0, 1.0)
	var nm = str(GameState.world.get(iso, {}).get("name_sk", iso))
	GameState.post_news("Voľby %s: vyhrali %s%s. Daň firiem %s." % [nm, str(winner.name), "" if old != str(winner.id) else " (obhájili)", EconMath.pct(LawSystem.corporate_tax(iso))])
	return str(winner.id)

func text(iso: String) -> String:
	var c = country(iso)
	if c.is_empty():
		return "Bez dát."
	var p = party_def(str(c.party))
	var out = "%s — %s\nVláde vládne: %s (podpora %d %%)\n" % [str(GameState.world.get(iso, {}).get("name_sk", iso)), GOV_NAMES.get(str(c.gov), "?"), str(p.name), int(float(c.approval) * 100)]
	out += "Líder: %s\n" % str(c.get("leader_name", "?"))
	var ps: Array = []
	for q in c.get("parties", []):
		ps.append("%s (%s, %d %%, %s)" % [str(q.name), str(q.get("ideology", "")), int(round(float(q.popularity) * 100)), str(q.get("leader_name", ""))])
	if not ps.is_empty():
		out += "Strany: " + "; ".join(ps) + "\n"
	out += "Úplatky tu: cena ×%.1f, riziko ×%.1f | tier %d\n" % [float(GOV_BRIBE_COST.get(str(c.gov), 1.0)), float(GOV_SCANDAL.get(str(c.gov), 1.0)), MarketSystem.tier_of(iso)]
	out += "Daň firiem %s | regulácia %d/100 | ceny stavieb ×%.2f\n" % [EconMath.pct(LawSystem.corporate_tax(iso)), int(float(c.reg) * 100), cost_mult(iso)]
	if int(c.get("next_election", -1)) > 0:
		out += "Voľby o %d mes.%s\n" % [int(c.next_election), (", podporuješ: " + str(party_def(str(c.support)).name)) if str(c.get("support", "")) != "" else ""]
	else:
		out += "Voľby sa nekonajú.\n"
	return out

# ===== focus tree =====
func focus_def(fid: String) -> Dictionary:
	for f in FOCUS:
		if str(f.id) == fid:
			return f
	return {}

func focus_state() -> Dictionary:
	ensure()
	return _ext().focus

func focus_done(fid: String) -> bool:
	return fid in focus_state().get("done", [])

func focus_available(fid: String) -> bool:
	var f = focus_def(fid)
	if f.has("gender") and str(f.gender) != str(GameState.player.get("gender", "")):
		return false
	if f.is_empty() or focus_done(fid) or str(focus_state().get("current", "")) == fid:
		return false
	for r in f.req:
		if not focus_done(str(r)):
			return false
	for e in f.get("excl", []):
		if focus_done(str(e)) or str(focus_state().get("current", "")) == str(e):
			return false
	return true

func focus_progress() -> float:
	var st = focus_state()
	var cur = str(st.get("current", ""))
	if cur == "":
		return 0.0
	var d = float(focus_def(cur).get("days", 1))
	return clamp(1.0 - float(st.get("left", 0)) / max(d, 1.0), 0.0, 1.0)

func start_focus(fid: String) -> String:
	var st = focus_state()
	if str(st.get("current", "")) != "":
		return "Už beží cieľ %s." % str(focus_def(str(st.current)).get("name", ""))
	if not focus_available(fid):
		return "Tento cieľ ešte nejde (chýbajú predošlé)."
	st.current = fid
	st.left = int(focus_def(fid).days)
	GameState.post_news("Firemný cieľ: %s (%d dní)." % [str(focus_def(fid).name), int(st.left)])
	return ""

func daily() -> void:
	var e = _ext()
	if not e.has("focus"):
		return
	var st: Dictionary = e.focus
	if str(st.get("current", "")) == "":
		return
	st.left = int(st.get("left", 0)) - 1
	if int(st.left) <= 0:
		var fid = str(st.current)
		var done: Array = st.get("done", [])
		done.append(fid)
		st.done = done
		st.current = ""
		st.left = 0
		var od: Dictionary = focus_def(fid).get("on_done", {})
		if od.has("rating"):
			GameState.player.rating = mini(100, int(GameState.player.get("rating", 55)) + int(od.rating))
		GameState.post_news("Cieľ splnený: %s — %s." % [str(focus_def(fid).name), str(focus_def(fid).desc)])

func bonus_sum(key: String) -> float:
	var s = 0.0
	var e = _ext()
	if not e.has("focus"):
		return 0.0
	for fid in e.focus.get("done", []):
		s += float(focus_def(str(fid)).get("bonus", {}).get(key, 0.0))
	return s

func bonus_mult(key: String) -> float:
	var m = 1.0
	var e = _ext()
	if not e.has("focus"):
		return 1.0
	for fid in e.focus.get("done", []):
		var b: Dictionary = focus_def(str(fid)).get("bonus", {})
		if b.has(key):
			m *= float(b[key])
	return m

# ===== JUAN4: male bonusy podla pohlavia postavy (5-10 %, vyvazene) =====
# muž:  autorita vo firme -> mzdove naklady ×0,95 (lepsia moral); akcia "Kampaň pre ženy" (+5 rating, 70 %)
# žena: akcia "Očariť pri vyjednávaní" -> dalsia stavba/firma −8 % (60 %); "Žena podnikateľka" -> +5 % trzieb
#       spotrebitelskych firiem mesacne ako bonus (zakaznici-muzi kupuju radsej)
# iné:  bez bonusu
const GENDER_TIPS = {
	"muž": "Muž: autorita vo firme (mzdy −5 %), akcia Kampaň pre ženy (+5 reputácia).",
	"žena": "Žena: Očariť pri vyjednávaní (ďalšia stavba −8 %), Žena podnikateľka (+5 % tržieb spotrebiteľských firiem).",
	"iné": "Iné: bez bonusov, čistá hra.",
}
const GENDER_COOLDOWN = 90
const CONSUMER_IND = ["cafe", "textile_mill", "auto_plant", "electronics_plant", "pharma_lab"]

func gender() -> String:
	return str(GameState.player.get("gender", "iné"))

func apply_gender_start() -> void:
	if gender() == "muž":
		var mods: Dictionary = GameState.player.get("modifiers", {})
		mods["labor_mult"] = float(mods.get("labor_mult", 1.0)) * 0.95
		GameState.player.modifiers = mods

func gender_action(kind: String, roll: float = -1.0) -> Dictionary:
	var g = gender()
	if (kind == "campaign" and g != "muž") or (kind == "charm" and g != "žena"):
		return {"ok": false, "text": "Táto akcia nie je pre tvoju postavu."}
	var last = int(GameState.player.get("gender_action_day", -9999))
	if GameState.day_index - last < GENDER_COOLDOWN:
		return {"ok": false, "text": "Znova o %d dní." % (GENDER_COOLDOWN - (GameState.day_index - last))}
	var cost = 15000.0 if kind == "campaign" else 5000.0
	if float(GameState.player.get("cash", 0.0)) < cost:
		return {"ok": false, "text": "Treba %s." % EconMath.eur(cost)}
	GameState.player.cash = float(GameState.player.cash) - cost
	GameState.player.gender_action_day = GameState.day_index
	var r = roll if roll >= 0.0 else _rng("gender" + kind).randf()
	var text = ""
	var ok = false
	if kind == "campaign":
		ok = r < 0.7
		if ok:
			GameState.player.rating = mini(100, int(GameState.player.get("rating", 55)) + 5 + int(bonus_sum("rep")))
		text = "Kampaň pre ženy: " + ("reputácia +5." if ok else "nezabrala.")
	else:
		ok = r < 0.6
		if ok:
			GameState.player.charm_discount = 0.08
		text = "Vyjednávanie: " + ("partneri ti dali zľavu 8 % na ďalšiu stavbu." if ok else "tentoraz neočarilo.")
	GameState.post_news(text)
	return {"ok": true, "success": ok, "text": text}

# zlava z ocarenia sa spotrebuje pri dalsej firme/stavbe
func take_discount() -> float:
	var d = float(GameState.player.get("charm_discount", 0.0))
	if d > 0.0:
		GameState.player.charm_discount = 0.0
	return 1.0 - d

func gender_monthly() -> float:
	if gender() != "žena":
		return 0.0
	var bonus = 0.0
	for f in GameState.player_firms():
		if not (str(f.get("industry", "")) in CONSUMER_IND):
			continue
		var mh: Array = f.get("month_hist", [])
		if mh.size() > 0:
			bonus += max(0.0, float(mh[mh.size() - 1].get("rev", 0.0))) * 0.05
	if bonus > 0.0:
		GameState.player.cash = float(GameState.player.cash) + bonus
		GameState.post_news("Žena podnikateľka: zákazníci-muži kupujú radšej, bonus %s." % EconMath.eur(bonus))
	return bonus
