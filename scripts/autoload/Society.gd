extends Node
# JUAN-P47 (2026-10-27): spolocnost miest a politicka moc.
# - Moc a vplyv (0-100 %) v krajine: HDP podiel, pracovne miesta, dosah medii, statne uvery, lobing. Nad 50 % = kontrola.
# - Lobing politikov, skandaly, vyhodne zakony pri kontrole.
# - Kriminalita miest, proceduralne gangy, kriminalne udalosti, PMC nasadenie a vladne bezpecnostne zmluvy.
# - Spokojnost zamestnancov (0-100) -> vykon +-20 % a fluktuacia.
# - Sluzbove podniky bez trhu: nemocnica, nakladny pristav, sukromne skoly, firemna akademia.
# Vsetko sa pocita raz za mesiac (alebo pri otvoreni panelu), nie kazdy snimok. Stav je v GameState.ext.society
# (volitelny kluc; stary save v3 sa doplni pri prvom pouziti, nove polia firiem maju predvolene hodnoty).

const CONTROL = 50.0
const BANK_STAFF = 25  # pobocka banky (zobrazenie; banka ma vlastny model nakladov)
const UNIT_SOLDIERS = 10.0
const PORT_CITIES_PATH = "res://data/port_cities.json"
const TECH_IND = ["chip_fab", "software", "ai_firm", "data_center", "electronics_plant", "telecom", "pharma_lab",
	"nuclear_plant", "solar_plant", "gas_plant", "power_coal", "oil_refinery", "gas_works", "aircraft_plant"]
const LAWS = {
	"tax": {"name": "Daňová úľava pre tvoje firmy (daň ×0,75)"},
	"subsidy": {"name": "Dotácie (1,5 % tržieb tvojich firiem v krajine mesačne)"},
	"permits": {"name": "Rýchle povolenia (stavba v krajine −15 %)"},
	"contracts": {"name": "Vládne zákazky (mesačná platba podľa HDP)"},
}
const GANG_A = ["Čierni", "Severní", "Prístavní", "Železní", "Noční", "Červení", "Starí", "Južní", "Tichí", "Zlatí"]
const GANG_B = ["vlci", "býci", "škorpióni", "havrani", "kobry", "bratia", "jastrabi", "potkani", "tigre", "duchovia"]
# satira len ako text udalosti, nie mechanika
const SATIRE = [
	"Bulvár tvrdí, že miestny gang chcel otvoriť „orgánový e-shop“. Polícia to označila za hoax a hlúpy vtip.",
	"Kriminálnici vraj ponúkali „otroka mesiaca“ ako súťaž – ukázalo sa, že išlo o satirickú reklamu na fitko.",
]
const CRIME_EVENTS = {
	"theft": "Krádež",
	"extortion": "Vydieranie",
	"sabotage": "Sabotáž",
	"attack": "Útok na zamestnancov",
}

var _port_cities: Dictionary = {}
var _power_day: Dictionary = {}

func _ready() -> void:
	var f = FileAccess.open(PORT_CITIES_PATH, FileAccess.READ)
	if f:
		var d = JSON.parse_string(f.get_as_text())
		if typeof(d) == TYPE_DICTIONARY and typeof(d.get("cities", null)) == TYPE_DICTIONARY:
			_port_cities = d.cities

# ===================== stav =====================
func st() -> Dictionary:
	if typeof(GameState.get("ext")) != TYPE_DICTIONARY:
		GameState.ext = {}
	if not GameState.ext.has("society") or typeof(GameState.ext.society) != TYPE_DICTIONARY:
		GameState.ext["society"] = {}
	var s: Dictionary = GameState.ext.society
	for k in ["cities", "deploy", "contracts", "lobby", "laws", "power", "pmc", "infra"]:
		if not s.has(k) or typeof(s[k]) != TYPE_DICTIONARY:
			s[k] = {}
	if not s.has("log") or typeof(s.log) != TYPE_ARRAY:
		s["log"] = []
	if not s.has("n"):
		s["n"] = 0
	return s

func _log(txt: String) -> void:
	var lg: Array = st().log
	lg.push_front("%d.%d.%d: %s" % [int(GameState.date.d), int(GameState.date.m), int(GameState.date.y), txt])
	while lg.size() > 40:
		lg.pop_back()

func _rng(tag: String) -> RandomNumberGenerator:
	var s = st()
	s.n = int(s.n) + 1
	var r = RandomNumberGenerator.new()
	r.seed = absi(("%s|soc|%s|%d|%d" % [str(GameState.config.get("seed", 47)), tag, GameState.day_index, int(s.n)]).hash())
	return r

func _cname(iso: String) -> String:
	return str(GameState.world.get(iso, {}).get("name_sk", DataLoader.countries.get(iso, {}).get("name_sk", iso)))

func _gdp_eur(iso: String) -> float:
	return maxf(1.0, float(GameState.world.get(iso, {}).get("gdp_usd", DataLoader.countries.get(iso, {}).get("gdp_usd", 1e11))) / maxf(GameState.usd_per_eur, 0.1))

func _gdp_pc_eur(iso: String) -> float:
	return float(GameState.world.get(iso, {}).get("gdp_pc_usd", 20000.0)) / maxf(GameState.usd_per_eur, 0.1)

func recipe_of(firm: Dictionary) -> Dictionary:
	var facs: Array = firm.get("facilities", [])
	if facs.is_empty():
		return {}
	return DataLoader.recipes.get(str(facs[0].get("recipe", "")), {})

func service_kind(firm: Dictionary) -> String:
	return str(recipe_of(firm).get("service", ""))

static func is_service_recipe(recipe: Dictionary) -> bool:
	return str(recipe.get("service", "")) != ""

# ===================== mesta =====================
func firm_city(firm: Dictionary) -> String:
	var iso = str(firm.get("country", ""))
	var nm = str(firm.get("city", ""))
	if nm != "" and not TerrainSystem.city_named(iso, nm).is_empty():
		return nm
	var cs: Array = TerrainSystem.cities(iso)
	if cs.is_empty():
		return ""
	var p = IndustrySystem.firm_pos(firm)
	if p == null:
		for c in cs:
			if bool(c.get("capital", false)):
				return str(c.name)
		return str(cs[0].name)
	var best = ""
	var bd = 1e9
	for c in cs:
		var d = (p as Vector2).distance_to(c.pos)
		if d < bd:
			bd = d
			best = str(c.name)
	return best

func key(iso: String, city_name: String) -> String:
	return iso + "|" + city_name

func port_cities(iso: String) -> Array:
	return _port_cities.get(iso, [])

func is_port_city(iso: String, city_name: String) -> bool:
	return city_name in port_cities(iso)

func crime_base(iso: String, city_name: String) -> float:
	var w: Dictionary = GameState.world.get(iso, {})
	var u = float(w.get("unemployment", 0.06))
	var poverty = 1.0 - clampf(_gdp_pc_eur(iso) / 50000.0, 0.0, 1.0)
	var risk = float(w.get("political_risk", 0.2))  # proxy slabej policie / institucii
	var c: Dictionary = TerrainSystem.city_named(iso, city_name)
	var pop = float(c.get("pop", 200000.0))
	var size = clampf(log(maxf(pop, 10000.0) / 10000.0) / log(1000.0), 0.0, 1.0)
	return clampf(8.0 + u * 180.0 + poverty * 28.0 + risk * 30.0 + size * 10.0, 3.0, 90.0)

func edu_base(iso: String) -> float:
	return clampf(25.0 + 50.0 * clampf(_gdp_pc_eur(iso) / 55000.0, 0.0, 1.0), 20.0, 80.0)

func city(iso: String, city_name: String) -> Dictionary:
	var cs: Dictionary = st().cities
	var k = key(iso, city_name)
	if cs.has(k):
		return cs[k]
	var crime = crime_base(iso, city_name)
	var row = {"crime": crime, "edu": edu_base(iso), "gangs": _make_gangs(iso, city_name, crime), "events": []}
	cs[k] = row
	return row

func _make_gangs(iso: String, city_name: String, crime: float) -> Array:
	var h = absi(key(iso, city_name).hash()) + int(GameState.config.get("seed", 47)) * 31
	var n = clampi(1 + int(crime / 30.0), 1, 3)
	var out: Array = []
	var left = clampf(crime / 100.0, 0.05, 0.9)
	for i in n:
		var hi = absi(hash(h + i * 977))
		var terr = left * (0.55 if i < n - 1 else 1.0)
		left -= terr
		out.append({"name": "%s %s" % [GANG_A[hi % GANG_A.size()], GANG_B[(hi / 7) % GANG_B.size()]],
			"strength": clampf(crime * (0.6 + float(hi % 60) / 100.0), 5.0, 100.0), "territory": terr})
	return out

func cities_with_player() -> Dictionary:
	var out: Dictionary = {}
	for f in GameState.player_firms():
		if bool(f.get("closed", false)):
			continue
		var c = firm_city(f)
		if c == "":
			continue
		var k = key(str(f.country), c)
		if not out.has(k):
			out[k] = {"iso": str(f.country), "city": c, "firms": []}
		out[k].firms.append(f)
	return out

# ===================== PMC =====================
func pmc_state(firm: Dictionary) -> Dictionary:
	var p: Dictionary = st().pmc
	var id = str(firm.get("id", ""))
	if not p.has(id):
		p[id] = {"training": 30.0, "equipment": 30.0}
	return p[id]

func pmc_soldiers(firm: Dictionary) -> float:
	return IndustrySystem.headcount(firm)

func pmc_units(firm: Dictionary) -> int:
	return int(floor(pmc_soldiers(firm) / UNIT_SOLDIERS))

func pmc_deployed(firm: Dictionary) -> int:
	var d: Dictionary = st().deploy.get(str(firm.get("id", "")), {})
	var n = 0
	for k in d.keys():
		n += int(d[k])
	return n

func pmc_quality(firm: Dictionary) -> float:
	var s = pmc_state(firm)
	return (0.5 + float(s.training) / 200.0) * (0.5 + float(s.equipment) / 200.0)

func pmc_upgrade_cost(firm: Dictionary, what: String) -> float:
	var per = 900.0 if what == "training" else 1600.0
	return per * maxf(pmc_soldiers(firm), 10.0) * 0.1 * Difficulty.cost_mult()

func pmc_upgrade(firm_id: String, what: String) -> String:
	var f = IndustrySystem._player_firm(firm_id)
	if f.is_empty() or str(f.get("industry", "")) != "pmc_unit":
		return "Nie je to tvoja PMC."
	if not what in ["training", "equipment"]:
		return "Neznáma úprava."
	var s = pmc_state(f)
	if float(s[what]) >= 100.0:
		return "Už je na maxime."
	var cost = pmc_upgrade_cost(f, what)
	if float(GameState.player.cash) < cost:
		return "Treba %s." % EconMath.eur(cost)
	GameState.player.cash = float(GameState.player.cash) - cost
	s[what] = minf(100.0, float(s[what]) + 10.0)
	return ""

func monthly_unit_cost(iso: String) -> float:
	return IndustrySystem._wage(iso, {}) * 30.0 * UNIT_SOLDIERS * 0.35  # nasadenie: doprava, ubytovanie, prémie (herná mierka)

func can_deploy(iso: String) -> Dictionary:
	if power_value(iso) > CONTROL:
		return {"ok": true, "why": "kontrola krajiny", "max": 1000000}
	var c: Dictionary = st().contracts.get(iso, {})
	if not c.is_empty() and int(c.get("months", 0)) > 0:
		return {"ok": true, "why": "vládna bezpečnostná zmluva", "max": int(c.get("max_units", 0)), "contract": c}
	return {"ok": false, "why": "Treba kontrolu krajiny nad 50 % alebo vládnu bezpečnostnú zmluvu (panel krajiny).", "max": 0}

func deployed_in_country(iso: String) -> int:
	var n = 0
	for fid in st().deploy.keys():
		var d: Dictionary = st().deploy[fid]
		for k in d.keys():
			if str(k).begins_with(iso + "|"):
				n += int(d[k])
	return n

func deploy(firm_id: String, iso: String, city_name: String, units: int) -> String:
	var f = IndustrySystem._player_firm(firm_id)
	if f.is_empty() or str(f.get("industry", "")) != "pmc_unit":
		return "Nie je to tvoja PMC."
	if TerrainSystem.city_named(iso, city_name).is_empty():
		return "Neznáme mesto."
	var cd = can_deploy(iso)
	if not bool(cd.ok):
		return str(cd.why)
	var d: Dictionary = st().deploy.get(firm_id, {})
	var k = key(iso, city_name)
	var cur = int(d.get(k, 0))
	units = maxi(0, units)
	var free = pmc_units(f) - pmc_deployed(f) + cur
	if units > free:
		return "PMC má voľných len %d jednotiek (1 jednotka = %d vojakov)." % [free, int(UNIT_SOLDIERS)]
	if units > cur and deployed_in_country(iso) - cur + units > int(cd.max):
		return "Zmluva dovoľuje najviac %d jednotiek v krajine." % int(cd.max)
	if units == 0:
		d.erase(k)
	else:
		d[k] = units
	st().deploy[firm_id] = d
	_log("PMC %s: %d jednotiek v meste %s (%s)." % [str(f.name), units, city_name, str(cd.why)])
	return ""

func pmc_in_city(iso: String, city_name: String) -> float:
	var k = key(iso, city_name)
	var power = 0.0
	for fid in st().deploy.keys():
		var u = int(st().deploy[fid].get(k, 0))
		if u <= 0:
			continue
		var f = GameState.firm_by_id(str(fid))
		if f.is_empty() or bool(f.get("closed", false)):
			continue
		power += float(u) * pmc_quality(f)
	return power

# ochrana 0..0.85 podla sily nasadenych jednotiek vs. velkost mesta
func protection(iso: String, city_name: String) -> float:
	var pw = pmc_in_city(iso, city_name)
	if pw <= 0.0:
		return 0.0
	var pop = float(TerrainSystem.city_named(iso, city_name).get("pop", 200000.0))
	var need = maxf(2.0, pop / 60000.0)
	return clampf(pw / need, 0.0, 1.0) * 0.85

# ===================== vladna bezpecnostna zmluva =====================
func contract_fair_price(iso: String, city_crime: float = -1.0) -> float:
	var crime = city_crime
	if crime < 0.0:
		crime = country_crime(iso)
	return monthly_unit_cost(iso) / 0.35 * 1.25 * (1.0 + crime / 100.0)

func country_crime(iso: String) -> float:
	var cs: Array = TerrainSystem.cities(iso)
	if cs.is_empty():
		return crime_base(iso, "")
	var t = 0.0
	for c in cs:
		t += float(city(iso, str(c.name)).crime)
	return t / float(cs.size())

# vlada prijme cenu do limitu: ferova cena × (1 + vplyv) ; pri vyssej cene vrati protinavrh
func propose_contract(iso: String, firm_id: String, price_per_unit: float, months: int, max_units: int) -> Dictionary:
	var f = IndustrySystem._player_firm(firm_id)
	if f.is_empty() or str(f.get("industry", "")) != "pmc_unit":
		return {"ok": false, "text": "Vyber svoju PMC."}
	if not GameState.world.has(iso):
		return {"ok": false, "text": "Neznáma krajina."}
	months = clampi(months, 1, 60)
	max_units = clampi(max_units, 1, 500)
	if GeopoliticsSystem.at_war(iso) and power_value(iso) < 20.0:
		return {"ok": false, "text": "Vláda vo vojne nepustí cudziu PMC bez väčšieho vplyvu (aspoň 20 %)."}
	var limit = contract_fair_price(iso) * (1.0 + power_value(iso) / 100.0 * 0.6 + PoliticsSystem.influence_bonus(iso))
	var units_ok = maxi(1, int(5 + power_value(iso) / 2.0 + country_crime(iso) / 4.0))
	if price_per_unit > limit or max_units > units_ok:
		return {"ok": false, "counter": {"price": snappedf(minf(price_per_unit, limit), 10.0), "max_units": mini(max_units, units_ok), "months": months},
			"text": "Vláda %s odmietla. Protinávrh: najviac %s za jednotku mesačne a %d jednotiek." % [_cname(iso), EconMath.eur(limit), units_ok]}
	st().contracts[iso] = {"firm": firm_id, "price": price_per_unit, "months": months, "max_units": max_units, "signed_day": GameState.day_index}
	PoliticsSystem.add_influence(iso, 2.0)
	_log("Bezpečnostná zmluva s vládou %s: %s/jednotku, %d mes., max %d jednotiek." % [_cname(iso), EconMath.eur(price_per_unit), months, max_units])
	GameState.post_news("Tvoja PMC podpísala bezpečnostnú zmluvu s vládou %s." % _cname(iso))
	return {"ok": true, "text": "Zmluva podpísaná."}

func cancel_contract(iso: String) -> String:
	if not st().contracts.has(iso):
		return "Zmluva neexistuje."
	st().contracts.erase(iso)
	_withdraw_without_right(iso)
	return ""

func _withdraw_without_right(iso: String) -> void:
	if bool(can_deploy(iso).ok):
		return
	for fid in st().deploy.keys():
		var d: Dictionary = st().deploy[fid]
		for k in d.keys().duplicate():
			if str(k).begins_with(iso + "|"):
				d.erase(k)

# ===================== moc a vplyv =====================
func power(iso: String, force: bool = false) -> Dictionary:
	var cache: Dictionary = st().power
	if not force and cache.has(iso) and GameState.day_index - int(cache[iso].get("day", -999)) < 30:
		return cache[iso]
	var r = _power0(iso)
	r["day"] = GameState.day_index
	cache[iso] = r
	return r

func power_value(iso: String) -> float:
	var cache: Dictionary = st().power
	if cache.has(iso):
		return float(cache[iso].get("value", 0.0))
	return 0.0

func has_control(iso: String) -> bool:
	return power_value(iso) > CONTROL

var use_power_headcount_cache := true  # porovnávateľná referenčná cesta pre testy
var use_monthly_city_groups := true  # porovnávateľná referenčná cesta pre testy

func _power0(iso: String) -> Dictionary:
	if Empire.owns_state(iso):
		return {"value": 100.0, "parts": {"Vlastníš štát": 100.0}, "control": true, "owned": true}
	var d: Dictionary = Empire.dependency(iso, use_power_headcount_cache)
	var w: Dictionary = GameState.world.get(iso, {})
	var pop = maxf(1.0, float(w.get("population", 1e6)))
	var people = float(d.get("_headcount", 0.0)) if use_power_headcount_cache else 0.0
	if not use_power_headcount_cache:
		for f in GameState.player_firms():
			if str(f.get("country", "")) == iso:
				people += IndustrySystem.headcount(f)
	var jobs = people / (pop * 0.5)
	var media = 0.0
	for r in Brand.country_media(iso):
		media = maxf(media, float(r.pct))
	var c_gdp = clampf(float(d.gdp_share) / 0.15, 0.0, 1.0) * 25.0
	var c_job = clampf(jobs / 0.08, 0.0, 1.0) * 20.0
	var c_med = clampf(media / 0.5, 0.0, 1.0) * 15.0
	var c_loan = clampf(float(d.loan_share) / 0.2, 0.0, 1.0) * 15.0
	var c_lob = clampf(PoliticsSystem.influence(iso) / 100.0, 0.0, 1.0) * 25.0
	var v = clampf(c_gdp + c_job + c_med + c_loan + c_lob, 0.0, 100.0)
	return {"value": v, "control": v > CONTROL, "owned": false, "jobs": jobs, "media": media,
		"parts": {"HDP tvojich firiem": c_gdp, "Pracovné miesta": c_job, "Dosah médií": c_med, "Štátne úvery tvojich bánk": c_loan, "Lobing a vzťahy": c_lob}}

func politicians(iso: String) -> Array:
	var lb: Dictionary = st().lobby
	if lb.has(iso) and typeof(lb[iso].get("pols", null)) == TYPE_ARRAY and not (lb[iso].pols as Array).is_empty():
		return lb[iso].pols
	var c: Dictionary = PoliticsSystem.country(iso)
	var out: Array = []
	var h = absi(iso.hash()) + int(GameState.config.get("seed", 47)) * 7919
	out.append({"name": str(c.get("leader_name", "Líder")), "party": str(c.get("party", "")), "role": "líder vlády", "weight": 3.0, "loyalty": 0.0, "spent": 0.0})
	var i = 0
	for p in c.get("parties", []):
		for j in 2:
			var gender = "f" if (h + i) % 2 == 1 else "m"
			out.append({"name": DataLoader.person_name(iso, h + i * 131, gender), "party": str(p.get("id", "")), "party_name": str(p.get("name", "")),
				"role": "poslanec" if j == 1 else "minister" if str(p.get("id", "")) == str(c.get("party", "")) else "šéf frakcie", "weight": 1.0 if j == 1 else 1.6, "loyalty": 0.0, "spent": 0.0})
			i += 1
	if not lb.has(iso):
		lb[iso] = {}
	lb[iso]["pols"] = out
	return out

func lobby_base_cost(iso: String) -> float:
	return (15000.0 + _gdp_eur(iso) * 5e-8) * PoliticsSystem.bonus_mult("act_cost")

# hrac zaplati politikovi (dary, kampane, poradenstvo) -> lojalita rastie, vplyv rastie postupne kazdy mesiac
func lobby(iso: String, idx: int, amount: float) -> String:
	var pols = politicians(iso)
	if idx < 0 or idx >= pols.size():
		return "Neznámy politik."
	amount = maxf(0.0, amount)
	if amount < 1000.0:
		return "Minimálna suma je 1 000 €."
	if float(GameState.player.cash) < amount:
		return "Nemáš dosť peňazí."
	GameState.player.cash = float(GameState.player.cash) - amount
	var p: Dictionary = pols[idx]
	p.spent = float(p.spent) + amount
	p.loyalty = clampf(float(p.loyalty) + 12.0 * sqrt(amount / lobby_base_cost(iso)), 0.0, 100.0)
	var lb: Dictionary = st().lobby[iso]
	lb["month_spent"] = float(lb.get("month_spent", 0.0)) + amount
	_log("Lobing %s (%s): %s." % [str(p.name), _cname(iso), EconMath.eur(amount)])
	return ""

func monthly_lobby() -> void:
	for iso in st().lobby.keys():
		var lb: Dictionary = st().lobby[iso]
		var gain = 0.0
		for p in lb.get("pols", []):
			gain += float(p.loyalty) / 100.0 * float(p.weight)
			p.loyalty = maxf(0.0, float(p.loyalty) * 0.94 - 0.5)
		if gain > 0.0:
			PoliticsSystem.add_influence(str(iso), minf(6.0, gain * 1.5))
		var spent = float(lb.get("month_spent", 0.0))
		lb["month_spent"] = 0.0
		if spent <= 0.0:
			continue
		var gt = str(PoliticsSystem.country(str(iso)).get("gov", "hybrid"))
		var chance = clampf(0.03 + 0.06 * sqrt(spent / lobby_base_cost(str(iso)) / 10.0), 0.0, 0.35) * float(PoliticsSystem.GOV_SCANDAL.get(gt, 1.0)) * PoliticsSystem.bonus_mult("scandal")
		var r = _rng("scandal" + str(iso))
		if r.randf() < chance:
			var fine = spent * (1.0 + r.randf())
			GameState.player.cash = float(GameState.player.cash) - fine
			PoliticsSystem.add_influence(str(iso), -10.0)
			GameState.player.rating = clampi(int(GameState.player.get("rating", 55)) - 5, 0, 100)
			var txt = "ŠKANDÁL v krajine %s: médiá odhalili tvoj lobing. Pokuta %s, vplyv −10, reputácia −5." % [_cname(str(iso)), EconMath.eur(fine)]
			GameState.post_news(txt)
			_log(txt)

# ===================== zakony pri kontrole =====================
func laws(iso: String) -> Dictionary:
	return st().laws.get(iso, {})

func law_on(iso: String, law: String) -> bool:
	return bool(st().laws.get(iso, {}).get(law, false)) and has_control(iso)

func set_law(iso: String, law: String, on: bool) -> String:
	if not LAWS.has(law):
		return "Neznámy zákon."
	power(iso, true)
	if on and not has_control(iso):
		return "Treba kontrolu krajiny nad 50 %% (teraz %.0f %%)." % power_value(iso)
	var l: Dictionary = st().laws.get(iso, {})
	l[law] = on
	st().laws[iso] = l
	_log("%s: %s %s." % [_cname(iso), str(LAWS[law].name), "presadený" if on else "zrušený"])
	return ""

func tax_mult(firm: Dictionary) -> float:
	if str(firm.get("owner", "")) != "player":
		return 1.0
	var laws_all: Dictionary = st().laws
	if laws_all.is_empty():
		return 1.0
	var iso = str(firm.get("country", ""))
	return 0.75 if law_on(iso, "tax") else 1.0

func build_mult(iso: String) -> float:
	if st().laws.is_empty():
		return 1.0
	return 0.85 if law_on(iso, "permits") else 1.0

func infra_mult(iso: String) -> float:
	var inf: Dictionary = st().infra
	if inf.is_empty():
		return 1.0
	return 1.0 + float(inf.get(iso, 0.0))

# ===================== sluzbove podniky =====================
func op_cost_day(firm: Dictionary) -> float:
	var r = recipe_of(firm)
	var iso = str(firm.get("country", ""))
	var sc = float(firm.get("facilities", [{}])[0].get("scale", 1.0))
	var elec = 0.0
	for in_id in r.get("inputs", {}).keys():
		elec += float(r.inputs[in_id]) * MarketSystem.price(iso, str(in_id))
	return (float(r.get("labor", 0.0)) * IndustrySystem._wage(iso, firm) + float(r.get("rent", 0.0)) * IndustrySystem._zone_rent(str(firm.facilities[0].get("zone", ""))) + float(r.get("maintain", 0.0)) + elec) * sc

func capacity(firm: Dictionary) -> float:
	var sc = float(firm.get("facilities", [{}])[0].get("scale", 1.0))
	return float(recipe_of(firm).get("capacity", 0.0)) * sc

func tuition_ref(firm: Dictionary) -> float:
	var cap = maxf(capacity(firm), 1.0)
	return snappedf(1.54 * op_cost_day(firm) * 30.0 / cap, 1.0)

func tuition(firm: Dictionary) -> float:
	return float(firm.get("tuition", tuition_ref(firm)))

func set_tuition(firm_id: String, v: float) -> String:
	var f = IndustrySystem._player_firm(firm_id)
	if f.is_empty() or not service_kind(f) in ["school", "academy"]:
		return "Nie je to tvoja škola."
	f["tuition"] = clampf(v, 0.0, 1.0e6)
	f.erase("svc")
	return ""

func students(firm: Dictionary) -> float:
	var ref = maxf(tuition_ref(firm), 1.0)
	var t = tuition(firm)
	var demand = clampf(1.25 - 0.5 * t / ref, 0.02, 1.0)
	var c = city(str(firm.country), firm_city(firm))
	var pop = float(TerrainSystem.city_named(str(firm.country), firm_city(firm)).get("pop", 200000.0))
	var market = clampf(pop * 0.02 / maxf(capacity(firm), 1.0), 0.3, 1.0)  # male mesto = menej deti/studentov
	return floor(capacity(firm) * demand * market * (0.9 + float(c.edu) / 500.0))

func subsidy_rate(firm: Dictionary) -> float:
	return 0.05 + 0.05 * clampf(power_value(str(firm.get("country", ""))) / 100.0, 0.0, 1.0)

func subsidy_month(firm: Dictionary) -> float:
	var st_n = students(firm)
	var cap = maxf(capacity(firm), 1.0)
	return op_cost_day(firm) * 30.0 / cap * st_n * subsidy_rate(firm)

func hospital_patients(firm: Dictionary) -> float:
	var pop = float(TerrainSystem.city_named(str(firm.country), firm_city(firm)).get("pop", 200000.0))
	return minf(capacity(firm), pop * 0.004)

func port_stats(firm: Dictionary) -> Dictionary:
	var iso = str(firm.get("country", ""))
	var cap = capacity(firm)
	var linked = not Transport.connected(firm, "rail").is_empty() or not Transport.connected(firm, "pipe").is_empty()
	if linked:
		cap *= 1.25
	var ports = 0
	for f in GameState.firms:
		if not bool(f.get("closed", false)) and str(f.get("industry", "")) == "cargo_port" and str(f.get("country", "")) == iso:
			ports += 1
	var country_teu = _gdp_eur(iso) * 4.0e-7 + float(MarketSystem.freight_pool.get(iso, 0.0)) * 30.0 / 400.0
	var teu = minf(cap, country_teu * 0.6 / maxf(float(ports), 1.0))
	var own_share = clampf(float(Empire.dependency(iso).gdp_share) * 3.0, 0.0, 0.8)
	var fee = IndustrySystem._wage(iso, firm) * 0.18
	return {"cap": cap, "teu": teu, "tons": teu * 11.0, "fee_teu": fee, "own_share": own_share, "linked": linked, "income": teu * fee}

# denny prijem sluzby (cache na mesiac; rata sa pri prvom pouziti a v mesacnej uzavierke)
func service_income_day(firm: Dictionary) -> float:
	var c = firm.get("svc", null)
	if typeof(c) == TYPE_DICTIONARY and int(c.get("m", -1)) == int(GameState.date.m) and int(c.get("y", -1)) == int(GameState.date.y):
		return float(c.get("day", 0.0))
	var v = _service_income_month(firm) / 30.0
	firm["svc"] = {"m": int(GameState.date.m), "y": int(GameState.date.y), "day": v}
	return v

func _service_income_month(firm: Dictionary) -> float:
	match service_kind(firm):
		"school":
			return students(firm) * tuition(firm) + subsidy_month(firm)
		"academy":
			return students(firm) * tuition(firm) * 0.3 + op_cost_day(firm) * 30.0 * 0.35 + subsidy_month(firm)  # externe kurzy + ciastocne preplatenie
		"hospital":
			var pop = float(TerrainSystem.city_named(str(firm.country), firm_city(firm)).get("pop", 200000.0))
			return op_cost_day(firm) * 30.0 * (1.05 + 0.25 * clampf(pop / 1.0e6, 0.0, 1.0))
		"port":
			return float(port_stats(firm).income)
	return 0.0

func service_text(firm: Dictionary) -> String:
	var k = service_kind(firm)
	if k == "":
		return ""
	var out = "\nSLUŽBA (mesačne): príjem ~%s, prevádzka ~%s\n" % [EconMath.eur(service_income_day(firm) * 30.0), EconMath.eur(op_cost_day(firm) * 30.0)]
	match k:
		"school", "academy":
			out += "Kapacita %d, žiaci/študenti %d, školné %s/mes. (odporúčané %s). Vyššie školné = menej žiakov.\nŠtátna dotácia %.1f %% nákladov na žiaka = %s/mes. (rastie s tvojím vplyvom).\n" % [int(capacity(firm)), int(students(firm)), EconMath.eur(tuition(firm)), EconMath.eur(tuition_ref(firm)), subsidy_rate(firm) * 100.0, EconMath.eur(subsidy_month(firm))]
			if k == "academy":
				out += "Akadémia: tvoji zamestnanci v meste +produktivita a +spokojnosť.\n"
		"hospital":
			out += "Pacienti ~%d mesačne. Tvoji zamestnanci v meste majú zdravotnú starostlivosť zadarmo.\n" % int(hospital_patients(firm))
		"port":
			var ps = port_stats(firm)
			out += "Kapacita %s TEU/mes., prekládka %s TEU (~%s t), poplatok %s/TEU. Tvoj tovar ~%.0f %%, konkurencia ~%.0f %%.%s\nTvoje firmy v krajine majú lacnejšiu dopravu tovaru; infraštruktúra krajiny +%.1f %%.\n" % [_fmt(float(ps.cap)), _fmt(float(ps.teu)), _fmt(float(ps.tons)), EconMath.eur(float(ps.fee_teu)), float(ps.own_share) * 100.0, (1.0 - float(ps.own_share)) * 100.0, " Napojený na železnicu/potrubie (+25 % kapacity)." if bool(ps.linked) else " Napoj ho železnicou alebo potrubím (+25 % kapacity).", float(st().infra.get(str(firm.country), 0.0)) * 100.0]
	return out

func _fmt(v: float) -> String:
	if v >= 1.0e6:
		return "%.2f mil." % (v / 1.0e6)
	if v >= 1000.0:
		return "%.1f tis." % (v / 1000.0)
	return "%.0f" % v

# zlava na dopravu tovaru pre hracove firmy v krajine s vlastnym pristavom
func port_discount(f: Dictionary) -> float:
	if str(f.get("owner", "")) != "player":
		return 0.0
	var iso = str(f.get("country", ""))
	for p in GameState.player_firms():
		if str(p.get("industry", "")) == "cargo_port" and str(p.get("country", "")) == iso and not bool(p.get("closed", false)):
			return 0.2
	return 0.0

func city_services(iso: String, city_name: String, player_city_firms = null) -> Dictionary:
	var out = {"hospital": 0, "insurance": 0, "pmc": 0, "school": 0, "academy": 0, "university": 0, "students": 0.0}
	for nf in _npc_service_firms():  # skoly konkurencie tiez vzdelavaju mesto (vyhody pre ludi len z vlastnych firiem)
		if str(nf.get("country", "")) == iso and str(nf.get("city", "")) == city_name and str(nf.get("industry", "")) in ["school_primary", "school_high", "university"]:
			out.students = float(out.students) + students(nf) * float(recipe_of(nf).get("edu", 1.0))
	var candidates: Array = GameState.player_firms() if player_city_firms == null else player_city_firms
	for f in candidates:
		if bool(f.get("closed", false)) or str(f.get("country", "")) != iso or firm_city(f) != city_name:
			continue
		var ind = str(f.get("industry", ""))
		if ind in ["hospital", "clinic"]:
			out.hospital += 1
		elif ind == "insurance":
			out.insurance += 1
		elif ind == "pmc_unit":
			out.pmc += 1
		elif ind == "corp_academy":
			out.academy += 1
		if ind in ["school_primary", "school_high", "university"]:
			out.school += 1
			out.students = float(out.students) + students(f) * float(recipe_of(f).get("edu", 1.0))  # vazene urovnou skoly
		if ind == "university":
			out.university += 1
	if pmc_in_city(iso, city_name) > 0.0:
		out.pmc += 1
	return out

func universities_in(iso: String) -> int:
	var n = 0
	for f in GameState.player_firms():
		if str(f.get("industry", "")) == "university" and str(f.get("country", "")) == iso and not bool(f.get("closed", false)):
			n += 1
	return n

# ===================== spokojnost =====================
func happiness(firm: Dictionary) -> float:
	return float(firm.get("happy", 50.0))

func compute_happiness(firm: Dictionary, svc: Dictionary, crow: Dictionary, prot: float) -> Dictionary:
	var why: Array = []
	var h = 52.0
	why.append(["základ", 52.0])
	if IndustrySystem.has_manager(firm):
		h += 5.0
		why.append(["pravá ruka", 5.0])
	var crime_pen = -float(crow.crime) * 0.15 * (1.0 - prot)
	h += crime_pen
	why.append(["kriminalita mesta", crime_pen])
	var hos = int(svc.hospital) > 0
	var ins = int(svc.insurance) > 0
	var sec = int(svc.pmc) > 0
	if hos:
		h += 8.0
		why.append(["zdravotná starostlivosť zadarmo (nemocnica/klinika)", 8.0])
	if ins:
		h += 6.0
		why.append(["poistenie zadarmo (poisťovňa)", 6.0])
	if sec:
		h += 5.0
		why.append(["bezpečnosť (PMC)", 5.0])
	if hos and ins and sec:
		h += 6.0
		why.append(["balík všetkých troch výhod", 6.0])
	if int(svc.school) > 0:
		h += 4.0
		why.append(["škola v meste (deti zamestnancov)", 4.0])
	if int(svc.academy) > 0:
		h += 5.0
		why.append(["firemná akadémia", 5.0])
	var ev = int(firm.get("crime_hit", 0))
	if ev > 0:
		h -= 10.0
		why.append(["nedávny útok/kriminalita", -10.0])
	return {"h": clampf(h, 0.0, 100.0), "why": why, "hos": hos, "ins": ins, "sec": sec}

func benefit_cost_month(firm: Dictionary, hv: Dictionary) -> float:
	var w = IndustrySystem._wage(str(firm.get("country", "")), firm) * 30.0 * IndustrySystem.workers(firm)
	var c = 0.0
	if bool(hv.hos):
		c += w * 0.03
	if bool(hv.ins):
		c += w * 0.02
	if bool(hv.sec):
		c += w * 0.015
	return c  # skutocne, ale zlavnene naklady (vlastne sluzby)

func happiness_text(firm: Dictionary) -> String:
	var h = happiness(firm)
	var out = "Spokojnosť zamestnancov %.0f/100 → výkon ×%.2f" % [h, output_mult_h(h)]
	var why: Array = firm.get("happy_why", [])
	if not why.is_empty():
		var parts: Array = []
		for w in why:
			parts.append("%s %+.0f" % [str(w[0]), float(w[1])])
		out += "\nPríčiny: " + ", ".join(parts)
	var bc = float(firm.get("benefit_cost", 0.0))
	if bc > 0.0:
		out += "\nNáklady na benefity (zľavnené vlastné služby): %s/mes." % EconMath.eur(bc)
	if h < 45.0:
		out += "\nNízka spokojnosť zvyšuje fluktuáciu ľudí."
	return out

static func output_mult_h(h: float) -> float:
	return 0.8 + 0.4 * clampf(h, 0.0, 100.0) / 100.0

# ===================== mesacna uzavierka =====================
func monthly(_y: int = 0, _m: int = 0) -> void:
	var s = st()
	# 1) moc v krajinach, kde hrac nieco ma
	var isos: Dictionary = {}
	for f in GameState.player_firms():
		isos[str(f.get("country", ""))] = true
	for b in BankingSystem.player_banks():
		isos[str(b.get("country", ""))] = true
		for loan in b.get("sovereign_loans", []):
			isos[str(loan.get("country", ""))] = true
	for iso in s.lobby.keys():
		isos[str(iso)] = true
	for iso in PoliticsSystem.influence_map().keys():
		if float(PoliticsSystem.influence(str(iso))) > 0.0:
			isos[str(iso)] = true
	monthly_lobby()
	for iso in isos.keys():
		if GameState.world.has(str(iso)):
			power(str(iso), true)
	_npc_cache_day = -1
	ai_monthly()  # AI konkurenti a statne firmy stavaju sluzbove podniky samy
	# 2) zakony a zmluvy
	_monthly_laws()
	_monthly_contracts()
	# 3) mesta s hracovymi firmami
	var cw = cities_with_player()
	var inf: Dictionary = {}
	for k in cw.keys():
		var iso = str(cw[k].iso)
		var cname = str(cw[k].city)
		var crow = city(iso, cname)
		var svc = city_services(iso, cname, cw[k].firms if use_monthly_city_groups else null)
		var prot = protection(iso, cname)
		_update_city(iso, cname, crow, svc, prot)
		for f in cw[k].firms:
			_firm_month(f, iso, cname, crow, svc, prot)
			if str(f.get("industry", "")) == "cargo_port":
				inf[iso] = minf(0.03, float(inf.get(iso, 0.0)) + 0.01 * float(IndustrySystem.firm_level(f)))
	s.infra = inf
	# 4) PMC naklady nasadenia
	for fid in s.deploy.keys():
		var pf = GameState.firm_by_id(str(fid))
		if pf.is_empty() or bool(pf.get("closed", false)) or str(pf.get("owner", "")) != "player":
			s.deploy[fid] = {}
			continue
		var cost = 0.0
		for k2 in s.deploy[fid].keys():
			cost += float(s.deploy[fid][k2]) * monthly_unit_cost(str(k2).split("|")[0])
		pf.cash = float(pf.cash) - cost
		pf["pmc_cost"] = cost
	for pid in s.pmc.keys():
		var ps: Dictionary = s.pmc[pid]
		ps.training = maxf(0.0, float(ps.training) - 1.0)
		ps.equipment = maxf(0.0, float(ps.equipment) - 1.5)

func _update_city(iso: String, cname: String, crow: Dictionary, svc: Dictionary, prot: float) -> void:
	var base = crime_base(iso, cname)
	var pop = float(TerrainSystem.city_named(iso, cname).get("pop", 200000.0))
	# vzdelanie: skoly pridavaju podla poctu studentov voci populacii, pomaly sa vracia k zakladu
	var eb = edu_base(iso)
	var gain = clampf(float(svc.students) / maxf(pop * 0.01, 1.0) * 1.2, 0.0, 2.5)
	crow.edu = clampf(float(crow.edu) + gain - (float(crow.edu) - eb) * 0.02, 0.0, 100.0)
	var edu_cut = maxf(0.0, float(crow.edu) - eb) * 0.25
	var gang_s = 0.0
	for g in crow.gangs:
		var pmc_hit = prot * 12.0
		g.strength = clampf(float(g.strength) + (base - float(g.strength)) * 0.05 - pmc_hit - edu_cut * 0.1, 0.0, 100.0)
		if prot > 0.0:
			g.territory = maxf(0.0, float(g.territory) * (1.0 - prot * 0.1))
		gang_s = maxf(gang_s, float(g.strength))
	var target = clampf(base - edu_cut + gang_s * 0.1 - prot * 15.0, 1.0, 100.0)
	crow.crime = clampf(lerpf(float(crow.crime), target, 0.25), 0.0, 100.0)
	if crow.gangs.size() < 3 and float(crow.crime) > 60.0 and _rng("gang" + cname).randf() < 0.1:
		var ng: Array = _make_gangs(iso, cname + str(GameState.day_index), float(crow.crime))
		crow.gangs.append(ng[0])
		GameState.post_news("V meste %s sa objavil nový gang: %s." % [cname, str(ng[0].name)])

func _firm_month(f: Dictionary, iso: String, cname: String, crow: Dictionary, svc: Dictionary, prot: float) -> void:
	f["crime_hit"] = maxi(0, int(f.get("crime_hit", 0)) - 1)
	# kriminalne udalosti
	var r = _rng("crime" + str(f.get("id", "")))
	var p = float(crow.crime) / 100.0 * 0.22 * (1.0 - prot)
	if r.randf() < p:
		_crime_event(f, cname, crow, r)
	elif r.randf() < 0.004:
		_log(SATIRE[r.randi() % SATIRE.size()])
	var hv = compute_happiness(f, svc, crow, prot)
	f["happy"] = float(hv.h)
	f["happy_why"] = hv.why
	var bc = benefit_cost_month(f, hv)
	f["benefit_cost"] = bc
	if bc > 0.0:
		f.cash = float(f.cash) - bc
	# fluktuacia
	var h = float(hv.h)
	if h < 50.0:
		var q = (50.0 - h) / 50.0 * 0.04
		if IndustrySystem.has_manager(f):
			f.cash = float(f.cash) - q * IndustrySystem.workers(f) * IndustrySystem._wage(iso, f) * 20.0  # nabor nahrady
		else:
			f["workers"] = maxf(0.0, IndustrySystem.workers(f) * (1.0 - q))
	# multiplikator vykonu: spokojnost, vzdelanie mesta, akademia, univerzita
	var m = output_mult_h(h)
	var ind = str(f.get("industry", ""))
	var edu = float(crow.edu)
	m *= 1.0 + clampf((edu - edu_base(iso)) / 100.0, -0.05, 0.08)
	if edu >= 55.0 and ind in TECH_IND:
		m *= 1.05  # kvalifikovane pracovne miesta odomknute
	if int(svc.academy) > 0:
		m *= 1.04
	if ind in TECH_IND:
		m *= 1.0 + 0.03 * mini(3, universities_in(iso))
	f["soc_mult"] = m
	f.erase("svc")
	if service_kind(f) != "":
		service_income_day(f)

func _crime_event(f: Dictionary, cname: String, crow: Dictionary, r: RandomNumberGenerator) -> void:
	var kinds = CRIME_EVENTS.keys()
	var kind = str(kinds[r.randi() % kinds.size()])
	var gang = "neznámi páchatelia"
	if not (crow.gangs as Array).is_empty():
		gang = str(crow.gangs[r.randi() % crow.gangs.size()].name)
	var rev = maxf(0.0, float(f.get("month_acc", {}).get("rev", 0.0)))
	var loss = 0.0
	var txt = ""
	match kind:
		"theft":
			loss = rev * (0.005 + 0.015 * r.randf()) + 2000.0
			txt = "ukradli tovar a techniku"
		"extortion":
			loss = rev * 0.02 + 5000.0
			txt = "vymáhali „ochranné“"
		"sabotage":
			loss = rev * 0.03 + 3000.0
			f["crime_hit"] = 2
			txt = "poškodili prevádzku"
		"attack":
			loss = 1500.0
			f["crime_hit"] = 2
			if not IndustrySystem.has_manager(f):
				f["workers"] = maxf(0.0, IndustrySystem.workers(f) * 0.98)
			txt = "napadli zamestnancov (nižšia spokojnosť)"
	f.cash = float(f.cash) - loss
	var msg = "%s v meste %s: %s (%s) – %s, škoda %s." % [str(CRIME_EVENTS[kind]), cname, str(f.get("name", "")), gang, txt, EconMath.eur(loss)]
	var ev: Array = crow.get("events", [])
	ev.push_front(msg)
	while ev.size() > 5:
		ev.pop_back()
	crow["events"] = ev
	GameState.post_news(msg)

func _monthly_laws() -> void:
	for iso in st().laws.keys():
		if not has_control(str(iso)):
			continue
		var rev = 0.0
		for f in GameState.player_firms():
			if str(f.get("country", "")) == str(iso):
				rev += maxf(0.0, float(f.get("month_acc", {}).get("rev", 0.0)))
		var pay = 0.0
		if law_on(str(iso), "subsidy"):
			pay += rev * 0.015
		if law_on(str(iso), "contracts"):
			pay += minf(_gdp_eur(str(iso)) * 2.0e-6, 5.0e6)
		if pay > 0.0:
			GameState.player.cash = float(GameState.player.cash) + pay
			_log("%s: dotácie a vládne zákazky %s." % [_cname(str(iso)), EconMath.eur(pay)])

func _monthly_contracts() -> void:
	for iso in st().contracts.keys().duplicate():
		var c: Dictionary = st().contracts[iso]
		var f = GameState.firm_by_id(str(c.get("firm", "")))
		var units = mini(deployed_in_country(str(iso)), int(c.get("max_units", 0)))
		if not f.is_empty() and not bool(f.get("closed", false)) and units > 0:
			var pay = float(c.price) * float(units)
			f.cash = float(f.cash) + pay
			var acc: Dictionary = f.get("month_acc", {})
			acc["rev"] = float(acc.get("rev", 0.0)) + pay
			acc["profit"] = float(acc.get("profit", 0.0)) + pay
			f["month_acc"] = acc
		c.months = int(c.months) - 1
		if int(c.months) <= 0:
			st().contracts.erase(iso)
			GameState.post_news("Bezpečnostná zmluva s vládou %s skončila." % _cname(str(iso)))
			_withdraw_without_right(str(iso))

# ===================== texty pre UI =====================
func power_text(iso: String) -> String:
	var p = power(iso, true)
	var out = "MOC A VPLYV: %.0f %%%s\n" % [float(p.value), "  → KONTROLUJEŠ KRAJINU" if bool(p.control) else "  (kontrola od 50 %)"]
	for k in (p.parts as Dictionary).keys():
		out += "• %s: %.1f b.\n" % [str(k), float(p.parts[k])]
	var lp: Array = []
	for pol in politicians(iso):
		if float(pol.loyalty) > 0.5:
			lp.append("%s (%s) lojalita %.0f" % [str(pol.name), str(pol.role), float(pol.loyalty)])
	out += "Lobovaní politici: %s\n" % (", ".join(lp) if not lp.is_empty() else "žiadni")
	var acts: Array = []
	if bool(p.control):
		acts.append("výhodné zákony")
		acts.append("voľné nasadenie PMC")
	if not st().contracts.get(iso, {}).is_empty():
		var c: Dictionary = st().contracts[iso]
		acts.append("bezpečnostná zmluva (%s/jedn., %d mes., max %d)" % [EconMath.eur(float(c.price)), int(c.months), int(c.max_units)])
	out += "Odomknuté: %s\n" % (", ".join(acts) if not acts.is_empty() else "nič – zvyšuj vplyv nad 50 % alebo vyjednaj zmluvu")
	var on: Array = []
	for l in LAWS.keys():
		if law_on(iso, str(l)):
			on.append(str(LAWS[l].name))
	if not on.is_empty():
		out += "Platné výhodné zákony: %s\n" % ", ".join(on)
	return out

func city_text(iso: String, city_name: String) -> String:
	var c = city(iso, city_name)
	var out = "\nSPOLOČNOSŤ: kriminalita %.0f/100 | vzdelanie %.0f/100%s\n" % [float(c.crime), float(c.edu), " (kvalifikované pracovné miesta odomknuté)" if float(c.edu) >= 55.0 else ""]
	var gs: Array = []
	for g in c.gangs:
		gs.append("%s (sila %.0f, územie %.0f %%)" % [str(g.name), float(g.strength), float(g.territory) * 100.0])
	out += "Gangy: %s\n" % (", ".join(gs) if not gs.is_empty() else "žiadne")
	var prot = protection(iso, city_name)
	if prot > 0.0:
		out += "PMC ochrana: %.0f %% (znižuje škody a silu gangov)\n" % (prot * 100.0)
	var svc = city_services(iso, city_name)
	var hs: Array = []
	var n = 0
	var tot = 0.0
	for f in GameState.player_firms():
		if str(f.get("country", "")) == iso and firm_city(f) == city_name and not bool(f.get("closed", false)):
			n += 1
			tot += happiness(f)
	if n > 0:
		out += "Spokojnosť tvojich zamestnancov: priemer %.0f/100 (%d firiem)\n" % [tot / float(n), n]
	if int(svc.hospital) > 0:
		hs.append("zdravotná starostlivosť")
	if int(svc.insurance) > 0:
		hs.append("poistenie")
	if int(svc.pmc) > 0:
		hs.append("bezpečnosť")
	if int(svc.school) > 0:
		hs.append("škola")
	if int(svc.academy) > 0:
		hs.append("akadémia")
	out += "Výhody pre tvojich ľudí: %s\n" % (", ".join(hs) if not hs.is_empty() else "žiadne (postav nemocnicu, poisťovňu, PMC alebo školu)")
	if is_port_city(iso, city_name):
		out += "Prímorské/riečne mesto: dá sa tu postaviť nákladný prístav.\n"
	for e in c.get("events", []).slice(0, 2):
		out += "• %s\n" % str(e)
	return out

func portfolio_text() -> String:
	var ports: Array = []
	var schools: Array = []
	var other: Array = []
	for f in GameState.player_firms():
		if bool(f.get("closed", false)):
			continue
		var k = service_kind(f)
		var line = "%s (%s)" % [str(f.get("name", "")), firm_city(f)]
		if k == "port":
			ports.append(line + " %s TEU/mes." % _fmt(float(port_stats(f).teu)))
		elif k in ["school", "academy"]:
			schools.append(line + " %d žiakov" % int(students(f)))
		elif k == "hospital" or str(f.get("industry", "")) == "pmc_unit":
			other.append(line)
	var out = "PRÍSTAVY: %s\nŠKOLY: %s" % [", ".join(ports) if not ports.is_empty() else "žiadne", ", ".join(schools) if not schools.is_empty() else "žiadne"]
	if not other.is_empty():
		out += "\nNEMOCNICE / PMC: " + ", ".join(other)
	return out


# ===================== AI: sluzbove podniky konkurentov a statnych firiem =====================
# Raz mesacne, nezavisle od hraca. Pravidla: pristav len v meste z port_cities (pocet podla HDP, max 3 na krajinu),
# univerzita len v meste >= 500 tis., nemocnica podla populacie (>= 200 tis., 1 + pop/1 mil. na mesto), skoly >= 100 tis.
# obyvatelov (1 + pop/300 tis. na typ a mesto), akademia len pri >= 3 vlastnych firmach v krajine, poistovna 1 a PMC 1
# (len pri kriminalite >= 40) na konkurenta a krajinu. Konkurent stavia z hotovosti (rezerva 30 %), najviac 1 podnik
# mesacne a 5 sluzbovych podnikov spolu (max 2 rovnakeho typu; po 2 lacnych uz setri len na nemocnicu/univerzitu/pristav). Stat stavia len nemocnice a pristavy (skoly su len sukromne), max 2 na krajinu.
const AI_SVC_TYPES = ["cargo_port", "hospital", "university", "school_high", "school_primary", "corp_academy", "insurance", "pmc_unit"]
const AI_SVC_IND = ["cargo_port", "hospital", "university", "school_high", "school_primary", "corp_academy"]
const RIVAL_SVC_MAX = 5
const STATE_SVC_MAX = 2
const STATE_COUNTRIES = 18  # rovnake krajiny ako statne AI firmy (AgentSystem)
var _npc_cache: Array = []
var _npc_cache_day := -1
var _npc_cache_revision := -1

func _npc_service_firms() -> Array:
	if _npc_cache_day == GameState.day_index and _npc_cache_day >= 0 and _npc_cache_revision == GameState.state_revision:
		return _npc_cache
	_npc_cache = []
	for f in GameState.firms:
		if str(f.get("owner", "")) != "player" and not bool(f.get("closed", false)) and str(f.get("industry", "")) in AI_SVC_IND:
			_npc_cache.append(f)
	_npc_cache_day = GameState.day_index
	_npc_cache_revision = GameState.state_revision
	return _npc_cache

func _count(iso: String, city_name: String, ind: String) -> int:
	var n = 0
	for f in GameState.firms:
		if bool(f.get("closed", false)) or str(f.get("industry", "")) != ind or str(f.get("country", "")) != iso:
			continue
		if city_name == "" or str(f.get("city", "")) == city_name or (str(f.get("city", "")) == "" and firm_city(f) == city_name):
			n += 1
	return n

# najlepsie mesto pre typ v krajine, alebo "" ak nie je dopyt/vhodne miesto
func ai_site(iso: String, ind: String) -> String:
	var cs: Array = TerrainSystem.cities(iso).duplicate()
	cs.sort_custom(func(a, b): return float(a.pop) > float(b.pop))
	if ind == "cargo_port":
		var maxp = clampi(int(_gdp_eur(iso) / 4.0e11) + 1, 1, 3)
		if _count(iso, "", "cargo_port") >= maxp:
			return ""
		for c in cs:
			if is_port_city(iso, str(c.name)) and _count(iso, str(c.name), "cargo_port") == 0:
				return str(c.name)
		return ""
	for c in cs:
		var pop = float(c.pop)
		var nm = str(c.name)
		match ind:
			"university":
				if pop >= 500000.0 and _count(iso, nm, ind) == 0:
					return nm
			"hospital":
				if pop >= 200000.0 and _count(iso, nm, ind) + _count(iso, nm, "clinic") < 1 + int(pop / 1.0e6):
					return nm
			"school_primary", "school_high":
				if pop >= 100000.0 and _count(iso, nm, ind) < 1 + int(pop / 300000.0):
					return nm
			"corp_academy", "insurance", "pmc_unit":
				return nm
	return ""

func _rival_svc_owned(rid: String) -> Array:
	var out: Array = []
	for f in GameState.firms:
		if str(f.get("rival", "")) == rid and not bool(f.get("closed", false)) and str(f.get("industry", "")) in AI_SVC_TYPES and bool(f.get("ai_svc", false)):
			out.append(f)
	return out

var ai_enabled := true  # len pre meranie vykonu v testoch
var ai_usec := 0

func ai_monthly() -> void:
	if not ai_enabled:
		return
	var t0 = Time.get_ticks_usec()
	_ai_monthly0()
	ai_usec += Time.get_ticks_usec() - t0

func _ai_monthly0() -> void:
	if bool(GameState.config.get("rivals", false)):
		for rv in RivalSystem.rivals():
			_rival_build(rv)
	_state_build()

func _rival_build(rv: Dictionary) -> void:
	var rid = str(rv.get("id", ""))
	var owned = _rival_svc_owned(rid)
	if owned.size() >= RIVAL_SVC_MAX:
		return
	var r = _rng("aisvc" + rid)
	if r.randf() > 0.35 * clampf(float(rv.get("aggr", 0.5)), 0.2, 1.2):
		return
	var isos: Array = [str(rv.get("home", "SK"))]
	for f in RivalSystem.rival_firms(rid):
		if not str(f.country) in isos:
			isos.append(str(f.country))
	var best = {}
	var best_s = -1.0
	for iso in isos:
		if not GameState.world.has(iso):
			continue
		var own_here = 0
		for f in RivalSystem.rival_firms(rid):
			if str(f.country) == iso:
				own_here += 1
		for ind in AI_SVC_TYPES:
			var cost = float(DataLoader.industries.get(ind, {}).get("cost", 1e12))
			if float(rv.cash) < cost * 1.3:
				continue
			var same = 0
			for f in owned:
				if str(f.industry) == ind:
					same += 1
			if same >= 2:
				continue
			if owned.size() >= 2 and not ind in ["hospital", "university", "cargo_port"]:
				continue  # po 2 lacnych sluzbach konkurent setri na nemocnicu/univerzitu/pristav
			if ind in ["corp_academy", "insurance", "pmc_unit"]:
				var dup = false
				for f in owned:
					if str(f.industry) == ind and str(f.country) == iso:
						dup = true
				if dup:
					continue
				if ind == "corp_academy" and own_here < 3:
					continue
			var site = ai_site(iso, ind)
			if site == "":
				continue
			if ind == "pmc_unit" and float(city(iso, site).crime) < 40.0:
				continue
			var pop = float(TerrainSystem.city_named(iso, site).get("pop", 1e5))
			var score = r.randf() + log(pop) * 0.1 + (0.4 if ind in ["hospital", "school_primary", "school_high"] else 0.0)
			if score > best_s:
				best_s = score
				best = {"iso": iso, "ind": ind, "city": site, "cost": cost}
	if best.is_empty():
		return
	rv.cash = float(rv.cash) - float(best.cost)
	var ind_d: Dictionary = DataLoader.industries[str(best.ind)]
	var f = _npc_firm("rv_%s_%d" % [rid, GameState.firms.size()], "%s %s" % [str(rv.name), str(ind_d.get("name", ""))], str(best.iso), str(best.ind), str(best.city), float(best.cost), r)
	f["rival"] = rid
	GameState.post_news("Konkurencia: %s otvára %s v meste %s." % [str(rv.name), str(ind_d.get("name", "")), str(best.city)])

func _state_build() -> void:
	var n = mini(STATE_COUNTRIES, DataLoader.country_ids.size())
	for i in n:
		var iso = str(DataLoader.country_ids[i])
		if not GameState.world.has(iso):
			continue
		var have = 0
		for f in GameState.firms:
			if bool(f.get("state_svc", false)) and str(f.get("country", "")) == iso and not bool(f.get("closed", false)):
				have += 1
		if have >= STATE_SVC_MAX:
			continue
		var r = _rng("state" + iso)
		if r.randf() > 0.12:
			continue
		var order = ["cargo_port", "hospital"] if r.randf() < 0.5 else ["hospital", "cargo_port"]
		for ind in order:  # stat nestavia skoly
			var cost = float(DataLoader.industries.get(ind, {}).get("cost", 1e12))
			if cost > _gdp_eur(iso) * 0.0005 or float(GameState.world[iso].get("budget", 0.0)) < -_gdp_eur(iso) * 0.01:
				continue
			var site = ai_site(iso, ind)
			if site == "":
				continue
			var nm = "Štátna nemocnica %s" % site if ind == "hospital" else "Štátny prístav %s" % site
			var f = _npc_firm("ai_svc_%s_%d" % [iso, GameState.firms.size()], nm, iso, ind, site, cost, r)
			f["state_svc"] = true
			f["public"] = 0.4
			GameState.post_news("%s: štát otvára %s." % [_cname(iso), nm])
			break

func _npc_firm(id: String, nm: String, iso: String, ind: String, site: String, cost: float, r: RandomNumberGenerator) -> Dictionary:
	var ind_d: Dictionary = DataLoader.industries[ind]
	var firm = {"id": id, "name": nm, "owner": "ai", "country": iso, "industry": ind, "cash": cost * 0.3, "closed": false, "shares": 1000,
		"public": 0.0, "share_price": cost / 1000.0, "history": [], "distress": 0, "facilities": [AgentSystem._facility(ind_d, iso)],
		"city": site, "ai_svc": true}
	var c: Dictionary = TerrainSystem.city_named(iso, site)
	if not c.is_empty():
		firm["pos"] = [float(c.pos.x) + r.randf_range(-0.6, 0.6), float(c.pos.y) + r.randf_range(-0.6, 0.6)]
	GameState.firms.append(firm)
	_npc_cache_day = -1
	return firm

func ai_service_counts() -> Dictionary:
	var out = {}
	for f in GameState.firms:
		if bool(f.get("ai_svc", false)) and not bool(f.get("closed", false)):
			var k = ("stat " if bool(f.get("state_svc", false)) else "konkurent ") + str(f.industry)
			out[k] = int(out.get(k, 0)) + 1
	return out
