extends Node

signal day_passed(day_i: int)
signal news_posted(text: String)

var running = false
var paused = true
var speed_index = 1
var day_index = 0
var date = {"y": 2024, "m": 1, "d": 1}
var player = {}
var firms: Array = []
var banks: Array = []
var central = {}
var world = {}
var markets = {}
var wars: Array = []
var relations = {}
var sanctions: Array = []
var embargoes: Array = []
var alliances: Array = []
var treaties: Array = []
var reliefs: Array = []
var un_sanctions: Array = []
var world_events: Array = []
var bond_orders: Array = []
var stock_orders: Array = []
var sites: Array = []
var news: Array = []
var stories: Array = []
var config = {}
var selected_iso = "SK"
var view_mode = "world"
var rng = RandomNumberGenerator.new()
var next_firm = 1
var next_loan = 1
var next_bank = 1
var usd_per_eur = 1.08
var ext: Dictionary = {}  # JUAN4: politika, focus tree, AI konkurenti (volitelny kluc savu "ext")
var state_revision := 0  # Runtime only: distinguish worlds even at the same saved day.

const SAVE_VERSION = 3  # v2: dlhopisy z knihy maju kupon = statny vynos (v1 mohol mat kupon = cena/100); v3 (etapa 1): dref, cpi_hist/cpi_acc/cpi_n, prev_rate/upd_day povinne
const BOND_MIGRATE_COUPON = 0.25
const INFL_MIN = -0.25   # clamp inflacie vstupujucej do pravidla sadzby (etapa 1)
const INFL_MAX = 0.60
const INFL_DECAY = 0.3   # mesacny podiel, ktorym vstupna inflacia dozniva k 0 pocas prvych 14 mesiacov (kym nie je yoy z CPI)
# kluc savu -> povolene typy (cisla: int alebo float)
const _NUM = [TYPE_INT, TYPE_FLOAT]
const _SAVE_TYPES = {
	"running": [TYPE_BOOL], "paused": [TYPE_BOOL], "speed_index": _NUM, "day_index": _NUM,
	"date": [TYPE_DICTIONARY], "player": [TYPE_DICTIONARY], "firms": [TYPE_ARRAY], "banks": [TYPE_ARRAY],
	"central": [TYPE_DICTIONARY], "world": [TYPE_DICTIONARY], "markets": [TYPE_DICTIONARY],
	"wars": [TYPE_ARRAY], "relations": [TYPE_DICTIONARY], "sanctions": [TYPE_ARRAY],
	"embargoes": [TYPE_ARRAY], "alliances": [TYPE_ARRAY], "treaties": [TYPE_ARRAY],
	"reliefs": [TYPE_ARRAY], "un_sanctions": [TYPE_ARRAY], "world_events": [TYPE_ARRAY],
	"bond_orders": [TYPE_ARRAY], "stock_orders": [TYPE_ARRAY], "sites": [TYPE_ARRAY],
	"news": [TYPE_ARRAY], "stories": [TYPE_ARRAY], "config": [TYPE_DICTIONARY],
	"selected_iso": [TYPE_STRING], "next_firm": _NUM, "next_loan": _NUM, "next_bank": _NUM,
	"usd_per_eur": _NUM, "ext": [TYPE_DICTIONARY], "rng_seed": [TYPE_STRING], "rng_state": [TYPE_STRING], "v": _NUM,
}
const _SAVE_ARRAYS_OF_DICTS = ["firms", "banks", "wars", "bond_orders", "stock_orders", "sites"]

func new_game(cfg: Dictionary) -> void:
	state_revision += 1
	_ph = 0  # JUAN23
	config = cfg.duplicate(true)
	rng.seed = int(cfg.get("seed", 47))
	day_index = 0
	date = {"y": int(cfg.get("year", 2024)), "m": 1, "d": 1}
	usd_per_eur = DataLoader.usd_per_eur
	firms.clear()
	banks.clear()
	news.clear()
	stories.clear()
	sanctions.clear()
	embargoes.clear()
	alliances.clear()
	treaties.clear()
	reliefs.clear()
	un_sanctions.clear()
	world_events.clear()
	bond_orders.clear()
	stock_orders.clear()
	sites = DataLoader.sites.duplicate(true)
	next_firm = 1
	next_loan = 1
	next_bank = 1
	world.clear()
	for iso in DataLoader.country_ids:
		var copy: Dictionary = DataLoader.countries[iso].duplicate(true)
		copy.weather = "clear"
		copy.weather_left = 0
		copy.basket = 1.0
		copy.budget = 0.0
		world[iso] = copy
	LawSystem.bind_world()
	var home = str(cfg.get("country", "SK"))
	if not world.has(home):
		home = DataLoader.country_ids[0]
	selected_iso = home
	player = {
		"name": str(cfg.get("name", "Hráč")),
		"cash": 0.0,
		"home": home,
		"rating": 55,
		"credit_score": 55.0,
		"events": [],
		"loans": [],
		"bonds": [],
		"stocks": {},
		"bank_id": "",
		"bankrupt": false,
		"research": {},
		"research_queue": [],
		"done": [],
		"modifiers": {
			"labor_mult": 1.0,
			"freight_mult": 1.0,
			"power_mult": 1.0,
			"yield_agro": 1.0,
			"yield_chem": 1.0,
			"yield_weapons": 1.0,
			"default_mult": 1.0,
		},
	}
	BankingSystem.setup_central()
	MarketSystem.init_books()
	_fill_e1_fields()
	GeopoliticsSystem.setup()
	AgentSystem.spawn_ai()
	ext = {}
	PoliticsSystem.setup()  # JUAN4
	RivalSystem.setup()
	_open_starter(float(cfg.get("loan", 250000.0)), int(cfg.get("years", 5)), home)
	var scenario = str(cfg.get("scenario", "sandbox"))
	var found = str(cfg.get("found", ""))
	if found == "bank":
		var err = BankingSystem.found_player_bank("Hráčska banka", home)
		if err != "":
			post_news(err)
	elif found != "":
		var err2 = found_firm(found, "", home)
		if err2 != "":
			post_news(err2)
	post_news("Štart v %s. Pôžička je na účte, splátka ide každý deň. Medzerník pustí čas." % world[home].get("name_sk", home))
	if scenario != "":
		post_news("Scenár: %s." % scenario)
	running = true
	paused = true

# JUAN23: den rozdeleny na fazy, aby sa dal rozlozit cez viac snimok (plynulost) - poradie a vysledok rovnake ako simulate_day
var _ph := 0
var _ph_mb := 0
var _ph_yb := 0
var _ph_ci := 0
const _CLEAR_CHUNK = 12
const _ROUTE_CHUNK = 3

func day_in_progress() -> bool:
	return _ph > 0

func finish_pending_day() -> void:
	while _ph > 0:
		_sim_phase()

# vrati true, ked sa den dokoncil
func _sim_phase() -> bool:
	match _ph:
		0:
			if not running or player.get("bankrupt", false):
				return true
			_ph_mb = int(date.m)
			_ph_yb = int(date.y)
			EventSystem.begin_day()
			MarketSystem.begin_day_start()
			_ph = 1
		1:
			if MarketSystem.begin_day_step():
				GeopoliticsSystem.daily()
				IndustrySystem.plan_start()
				_ph_ci = 0
				_ph = 2
		2:
			_ph_ci = IndustrySystem.plan_chunk(_ph_ci, 4)
			if _ph_ci >= firms.size():
				_ph = 3
				_ph_ci = 0
		3:
			_ph_ci = MarketSystem.trade_routes_chunk(_ph_ci, _ROUTE_CHUNK)
			if _ph_ci >= DataLoader.commodity_ids.size():
				_ph = 4
				_ph_ci = 0
		4:
			_ph_ci = MarketSystem.clear_chunk(_ph_ci, _CLEAR_CHUNK)
			if _ph_ci < 0:
				_ph = 5
		5:
			IndustrySystem.settle_start()
			_ph_ci = 0
			_ph = 6
		6:
			_ph_ci = IndustrySystem.settle_chunk(_ph_ci, 4)
			if _ph_ci >= firms.size():
				_ph = 7
		7:
			_ph = 0
			_finish_day(_ph_mb, _ph_yb)
			return true
	return false

# spusti fazy, kym nevycerpa rozpocet (usec); vrati pocet dokoncenych dni
func sim_budget(budget_usec: int, max_days: int) -> int:
	var t0 = Time.get_ticks_usec()
	var done = 0
	while done < max_days:
		if _sim_phase():
			done += 1
		if Time.get_ticks_usec() - t0 >= budget_usec:
			break
	return done

func simulate_day() -> void:
	finish_pending_day()
	if not running or player.get("bankrupt", false):
		return
	var month_before = int(date.m)
	var year_before = int(date.y)
	EventSystem.begin_day()
	MarketSystem.begin_day()
	GeopoliticsSystem.daily()
	IndustrySystem.plan_and_post()
	MarketSystem.trade_routes()
	MarketSystem.clear_all()
	IndustrySystem.settle()
	_finish_day(month_before, year_before)

func _finish_day(month_before: int, year_before: int) -> void:
	BankingSystem.daily()
	_tick_research()
	PoliticsSystem.daily()  # JUAN4: focus tree
	day_index += 1
	TimeSystem.roll()
	if int(date.m) != month_before or int(date.y) != year_before:
		_macro()
		Society.monthly(year_before, month_before)  # JUAN-P47: moc, kriminalita, spokojnost, sluzby (pred uzavierkou firiem)
		IndustrySystem.close_month(year_before, month_before)  # JUAN3: mesacna historia + prava ruka
		IndustrySystem.pay_dividends()  # JUAN-FIX K0c4
		var shock = config.get("shock_war", [])
		if typeof(shock) == TYPE_ARRAY and shock.size() >= 2:
			GeopoliticsSystem._start_war(str(shock[0]), str(shock[1]))
			config.erase("shock_war")
		BankingSystem.update_rates()
		BankingSystem.process_monthly_interest()
		BankingSystem.monthly()
		GeopoliticsSystem.monthly()
		AgentSystem.monthly()
		EventSystem.monthly()
		PoliticsSystem.monthly()  # JUAN4: volby (len config.politics)
		RivalSystem.monthly()  # JUAN4: AI konkurenti (len config.rivals)
		PoliticsSystem.gender_monthly()  # JUAN4: bonus postavy
		IndustrySystem.media_monthly()  # JUAN5 #18
		BankingSystem.collateral_monthly()  # JUAN5 #18
		IndustrySystem.airport_monthly()
		StockMarket.monthly()
		Empire.monthly()  # JUAN10
	if day_index % 7 == 0:
		StockMarket.weekly()  # JUAN5 #19
		Empire.weekly()  # JUAN10 financna divizia
	day_passed.emit(day_index)

func _macro() -> void:
	for iso in world.keys():
		var c: Dictionary = world[iso]
		# etapa 1, krok 3: vazeny CPI (mesacny priemer), medzirocna inflacia z priemerov, clamp vstupu do pravidla
		var index = MarketSystem.cpi_month_average(iso)
		var hist: Array = c.get("cpi_hist", [])
		hist.append(index)
		while hist.size() > 25:
			hist.pop_front()
		c.cpi_hist = hist
		var n = hist.size()
		var yoy = null
		if n >= 15:
			yoy = (float(hist[n - 1]) + float(hist[n - 2]) + float(hist[n - 3])) / (float(hist[n - 13]) + float(hist[n - 14]) + float(hist[n - 15])) - 1.0
		# do 15 mesiacov historie ostava vstupna (datova) inflacia: kratke okno by zosilnilo startovaci prechod (~+-2 % cien)
		if yoy != null and not EconMath.is_bad(float(yoy)):
			var realized = clampf(float(yoy), INFL_MIN, INFL_MAX)
			c.inflation = lerpf(float(c.inflation), realized, 0.3)
		else:
			# kym nie je rocna historia, vstupna (datova) inflacia a sokova (+0.03 z vojny) hladko doznieva k 0 (model nema cenovy drift);
			# bez toho by drzala az do 15. mesiaca a potom by sadzba spadla zo ~0.25 na podlahu naraz (Miguel v1: 0.156 -> 0.006)
			c.inflation = lerpf(float(c.inflation), 0.0, INFL_DECAY)
		c.basket = index
		var shock = -0.012 if GeopoliticsSystem.at_war(iso) else 0.0
		var g = float(c.gdp_growth) + shock
		c.gdp_usd = float(c.gdp_usd) * (1.0 + g / 12.0)
		c.gdp_pc_usd = float(c.gdp_usd) / max(float(c.population), 1.0)
		var u_target = 0.045 + max(0.0, -g) * 1.4
		if GeopoliticsSystem.at_war(iso):
			u_target += 0.03
		c.unemployment = lerpf(float(c.unemployment), u_target, 0.2)
		var gdp_eur = float(c.gdp_usd) / max(usd_per_eur, 0.2)
		var tax = gdp_eur * float(c.tax_rate) / 12.0 * 0.22
		var mil = gdp_eur * float(c.get("military_share", 0.015)) / 12.0
		if GeopoliticsSystem.at_war(iso):
			mil *= 1.8
		c.budget = tax - mil
		c.debt_gdp = EconMath.cl(float(c.debt_gdp) + (mil - tax) / max(gdp_eur, 1.0), 0.0, 3.5)
		c.political_risk = EconMath.cl(float(c.political_risk) + shock * 0.4, 0.02, 0.92)

func set_view(mode: String) -> void:
	if mode == "world" or mode == "region":
		view_mode = mode

func _open_starter(amount: float, years: int, _iso: String) -> void:
	if amount <= 0.0:
		return
	var res: Dictionary = BankingSystem.request_loan(amount, years)
	if not bool(res.get("ok", false)):
		post_news("Úver zamietnutý: %s." % str(res.get("reason", "")))
	else:
		post_news("Úver %s, sadzba %s, mesačná splátka %s." % [EconMath.eur(amount), EconMath.pct(float(res.rate)), EconMath.eur(float(res.payment))])

func found_firm(ind_id: String, fname: String, iso: String) -> String:
	if not industries_ok(ind_id) or not world.has(iso):
		return "Neznáme odvetvie alebo krajina."
	if player.get("bankrupt", false):
		return "Si v bankrote."
	var lock = IndustrySystem.unlock_reason(ind_id, iso)  # JUAN5 #18: progresia
	if lock != "":
		return lock
	var ind: Dictionary = DataLoader.industries[ind_id]
	var port_city = ""
	if bool(ind.get("needs_port_city", false)):  # JUAN-P47: pristav len v primorskom/riecnom meste
		var pcs: Array = Society.port_cities(iso)
		if pcs.is_empty():
			return "Nákladný prístav sa dá postaviť len v prímorskom alebo riečnom meste – %s také mesto v hre nemá." % str(world[iso].get("name_sk", iso))
		port_city = str(pcs[0])
	var cost = float(ind.get("cost", 0.0)) * Difficulty.cost_mult() * PoliticsSystem.cost_mult(iso) * PoliticsSystem.take_discount() * Society.build_mult(iso)  # JUAN-P47: rychle povolenia  # JUAN4: obtiaznost + regulacia/focus + zlava z vyjednavania
	var wc = max(4000.0, cost * 0.22)
	if float(player.cash) < cost + wc:
		return "Treba %s vrátane prevádzkového kapitálu. Máš %s." % [EconMath.eur(cost + wc), EconMath.eur(float(player.cash))]
	player.cash = float(player.cash) - cost - wc
	var nm = fname if fname != "" else "%s %s" % [ind.get("name", "Firma"), world[iso].get("name_sk", iso)]
	var id = "f%d" % next_firm
	next_firm += 1
	firms.append({
		"id": id,
		"name": nm,
		"owner": "player",
		"country": iso,
		"industry": ind_id,
		"cash": wc,
		"closed": false,
		"shares": 1000,
		"public": 0.0,
		"share_price": cost / 1000.0,
		"history": [],
		"distress": 0,
		"facilities": [{
			"recipe": ind.get("recipe", ind_id),
			"country": iso,
			"scale": 1.0,
			"auto": true,
			"util": 1.0,
			"zone": ind.get("zone", "industrial"),
			"inventory": {},
			"cargo": "",
			"src": iso,
			"dst": "",
		}],
	})
	if ind_id == "airport":
		firms[firms.size() - 1]["city"] = IndustrySystem.airport_city(iso)  # JUAN5 #18
	if port_city != "":
		firms[firms.size() - 1]["city"] = port_city
	post_news("Založené: %s v %s. Kapitál firmy %s." % [nm, world[iso].get("name_sk", iso), EconMath.eur(wc)])
	return ""

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func add_facility(firm_id: String, iso: String) -> String:
	var firm = firm_by_id(firm_id)
	if firm.is_empty() or str(firm.owner) != "player":
		return "Firma nie je tvoja."
	var ind: Dictionary = DataLoader.industries.get(firm.industry, {})
	var cost = float(ind.get("cost", 0.0)) * 0.72
	if float(player.cash) < cost:
		return "Rozšírenie stojí %s." % EconMath.eur(cost)
	player.cash = float(player.cash) - cost
	firm.facilities.append({
		"recipe": ind.get("recipe", ""),
		"country": iso,
		"scale": 1.0,
		"auto": true,
		"util": 1.0,
		"zone": ind.get("zone", "industrial"),
		"inventory": {},
		"cargo": "",
		"src": iso,
		"dst": "",
	})
	post_news("Nová prevádzka %s v %s." % [firm.name, world[iso].get("name_sk", iso)])
	return ""

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func dividend(firm_id: String) -> String:
	var firm = firm_by_id(firm_id)
	if firm.is_empty():
		return "Nič."
	var take = max(0.0, float(firm.cash) - 8000.0) * 0.5
	if take < 10.0:
		return "Firma si drží rezervu."
	var share = 1.0 - float(firm.get("public", 0.0))
	firm.cash = float(firm.cash) - take
	player.cash = float(player.cash) + take * share
	post_news("Dividenda %s." % EconMath.eur(take * share))
	return ""

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func inject_firm(firm_id: String, amount: float) -> String:
	var firm = firm_by_id(firm_id)
	if firm.is_empty():
		return "Nič."
	if amount <= 0.0 or float(player.cash) < amount:
		return "Nie dosť hotovosti."
	player.cash = float(player.cash) - amount
	firm.cash = float(firm.cash) + amount
	return ""

func research_def(rid: String) -> Dictionary:
	for r in DataLoader.research:
		if str(r.get("id", "")) == rid:
			return r
	return {}

func research_edges() -> Array:
	var edges: Array = []
	for r in DataLoader.research:
		for req in r.get("requires", []):
			edges.append({"from": str(req), "to": str(r.get("id", ""))})
	return edges

# ===== JUAN5: research tree (vetvy, sloty, paralelny vyskum). player.research = slot 1 (stary format), player.research_extra = dalsie sloty =====
const RND_CENTER_COST = 250000.0

func research_slots() -> int:
	var n = 1
	if PoliticsSystem.focus_done("rnd1"):
		n += 1
	if bool(player.get("rnd_center", false)):
		n += 1
	return n

func research_running() -> Array:
	var out: Array = []
	if typeof(player.get("research", {})) == TYPE_DICTIONARY and not player.research.is_empty():
		out.append(player.research)
	if typeof(player.get("research_extra", [])) == TYPE_ARRAY:
		for r in player.get("research_extra", []):
			out.append(r)
	return out

func research_is_running(rid: String) -> bool:
	for r in research_running():
		if str(r.get("id", "")) == rid:
			return true
	return false

func research_available(rid: String) -> bool:
	var def = research_def(rid)
	if def.is_empty() or rid in player.get("done", []) or research_is_running(rid):
		return false
	for req in def.get("requires", []):
		if str(req) not in player.get("done", []):
			return false
	return true

func build_rnd_center() -> String:
	if bool(player.get("rnd_center", false)):
		return "R&D centrum už máš."
	if float(player.cash) < RND_CENTER_COST:
		return "R&D centrum stojí %s." % EconMath.eur(RND_CENTER_COST)
	player.cash = float(player.cash) - RND_CENTER_COST
	player.rnd_center = true
	post_news("Otvorené R&D centrum: +1 slot výskumu.")
	return ""

func _research_days(def: Dictionary) -> int:
	return maxi(1, int(ceil(float(def.get("days", 30)) / max(float(player.modifiers.get("research_speed", 1.0)), 0.1))))

func _start_slot(rid: String, def: Dictionary) -> void:
	var slot = {"id": rid, "left": _research_days(def), "total": _research_days(def), "name": def.get("name", rid)}
	if player.research.is_empty():
		player.research = slot
	else:
		if not player.has("research_extra") or typeof(player.research_extra) != TYPE_ARRAY:
			player.research_extra = []
		player.research_extra.append(slot)
	post_news("Výskum: %s." % def.get("name", rid))

func start_research(rid: String) -> String:
	if rid in player.done:
		return "Už hotové."
	if not player.has("research_queue"):
		player.research_queue = []
	for queued in player.research_queue:
		if str(queued) == rid:
			return "Už vo fronte."
	if research_is_running(rid):
		return "Už beží."
	var def = research_def(rid)
	if def.is_empty():
		return "Neznámy výskum."
	for req in def.get("requires", []):
		if str(req) not in player.done:
			return "Chýba predpoklad."
	var cost = float(def.get("cost", 0.0))
	if float(player.cash) < cost:
		return "Výskum stojí %s." % EconMath.eur(cost)
	player.cash = float(player.cash) - cost
	if research_running().size() < research_slots():
		_start_slot(rid, def)
	else:
		player.research_queue.append(rid)
		post_news("Vo fronte: %s." % def.get("name", rid))
	return ""

# lepsia hodnota vyhrava (nasobky nakladov = mensia, vynosy/rychlost = vacsia); stare efekty sa tak spravaju rovnako
func _apply_effect(k: String, v) -> void:
	var cur = player.modifiers.get(k, null)
	if cur == null:
		player.modifiers[k] = v
		return
	var lower_better = k.ends_with("_mult") and k != "reach_mult" or k == "rate_bonus"
	player.modifiers[k] = min(float(cur), float(v)) if lower_better else max(float(cur), float(v))

func _finish_research(rid: String) -> void:
	for r in DataLoader.research:
		if str(r.get("id", "")) != rid:
			continue
		for k in r.get("effects", {}).keys():
			_apply_effect(str(k), r.effects[k])
		player.done.append(rid)
		post_story("research", "Hotovo: %s. %s" % [r.get("name", rid), r.get("text", "")])
		player.events.append({"type": "research", "text": str(r.get("name", rid))})

func _tick_research() -> void:
	var finished: Array = []
	if not player.research.is_empty():
		player.research.left = int(player.research.left) - 1
		if int(player.research.left) <= 0:
			finished.append(str(player.research.id))
			player.research = {}
	if typeof(player.get("research_extra", null)) == TYPE_ARRAY:
		for r in player.research_extra.duplicate():
			r.left = int(r.left) - 1
			if int(r.left) <= 0:
				finished.append(str(r.id))
				player.research_extra.erase(r)
	for rid in finished:
		_finish_research(rid)
	if not finished.is_empty() or research_running().size() < research_slots():
		_start_queued_research()

func _start_queued_research() -> void:
	if not player.has("research_queue"):
		return
	while not player.research_queue.is_empty() and research_running().size() < research_slots():
		var rid = str(player.research_queue.pop_front())
		var def = research_def(rid)
		if def.is_empty():
			continue
		_start_slot(rid, def)

func firm_by_id(id: String) -> Dictionary:
	for f in firms:
		if str(f.get("id", "")) == id:
			return f
	return {}

func player_firms() -> Array:
	var out: Array = []
	for f in firms:
		if str(f.get("owner", "")) == "player" and not f.get("closed", false):
			out.append(f)
	return out

func debt() -> float:
	var s = 0.0
	for loan in player.get("loans", []):
		s += float(loan.get("remaining", 0.0))
	return s

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func net_worth() -> float:
	var s = float(player.get("cash", 0.0)) - debt()
	for f in player_firms():
		s += float(f.cash)
		var ind: Dictionary = DataLoader.industries.get(f.industry, {})
		if f.facilities.size() > 0:
			s += float(ind.get("cost", 0.0)) * 0.45 * float(f.facilities[0].get("scale", 1.0))
	for bank in BankingSystem.player_banks():  # JUAN9: vsetky banky hraca
		s += max(0.0, float(bank.equity))
	for b in player.get("bonds", []):
		if str(b.get("issuer", "")) == "player":
			s -= float(b.get("face", 0.0))  # JUAN13: vlastny vydany dlhopis je dlh, nie majetok
		else:
			s += BankingSystem._bond_value(b)
	s += StockMarket.portfolio_value()  # JUAN5 #19
	s += Empire.extra_worth()  # JUAN10 budovy + rozpocet financnych divizii
	for l in player.get("loans", []):
		s += float(l.get("escrow", 0.0))  # JUAN5 #18: hotovost v zalohe
	return s

func days_per_second() -> float:
	if speed_index <= 1:
		return 1.2
	if speed_index == 2:
		return 6.0
	if speed_index == 3:
		return 24.0
	return 72.0

func post_story(kind: String, text: String) -> void:
	stories.push_front({
		"kind": kind,
		"day": day_index,
		"date": EconMath.date_sk(int(date.y), int(date.m), int(date.d)),
		"text": text,
	})
	if stories.size() > 120:
		stories.pop_back()
	post_news(text)

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func newspaper(kind: String) -> Array:
	var out: Array = []
	for row in stories:
		if kind == "" or str(row.get("kind", "")) == kind:
			out.append(row)
	return out

func post_news(text: String) -> void:
	news.push_front({
		"day": day_index,
		"date": EconMath.date_sk(int(date.y), int(date.m), int(date.d)),
		"text": text,
	})
	if news.size() > 80:
		news.pop_back()
	news_posted.emit(text)

func industries_ok(ind_id: String) -> bool:
	return DataLoader.industries.has(ind_id)

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func _bank_in(iso: String) -> Dictionary:
	for b in banks:
		if str(b.get("country", "")) == iso and not b.get("failed", false):
			return b
	return {}

func to_dict() -> Dictionary:
	return {
		"v": SAVE_VERSION,
		"rng_seed": str(rng.seed),
		"rng_state": str(rng.state),
		"running": running,
		"paused": paused,
		"speed_index": speed_index,
		"day_index": day_index,
		"date": date.duplicate(true),
		"player": player.duplicate(true),
		"firms": firms.duplicate(true),
		"banks": banks.duplicate(true),
		"central": central.duplicate(true),
		"world": world.duplicate(true),
		"markets": markets.duplicate(true),
		"wars": wars.duplicate(true),
		"relations": relations.duplicate(true),
		"sanctions": sanctions.duplicate(true),
		"embargoes": embargoes.duplicate(true),
		"alliances": alliances.duplicate(true),
		"treaties": treaties.duplicate(true),
		"reliefs": reliefs.duplicate(true),
		"un_sanctions": un_sanctions.duplicate(true),
		"world_events": world_events.duplicate(true),
		"bond_orders": bond_orders.duplicate(true),
		"stock_orders": stock_orders.duplicate(true),
		"sites": sites.duplicate(true),
		"news": news.duplicate(true),
		"stories": stories.duplicate(true),
		"config": config.duplicate(true),
		"selected_iso": selected_iso,
		"next_firm": next_firm,
		"next_loan": next_loan,
		"next_bank": next_bank,
		"usd_per_eur": usd_per_eur,
		"ext": ext.duplicate(true),
	}

# Overi savedata BEZ zmeny zivého stavu. Vrati "" ak je v poriadku, inak text chyby.
func validate_save(d) -> String:
	if typeof(d) != TYPE_DICTIONARY:
		return "Save nie je slovník."
	var ver = d.get("v", 1)
	if typeof(ver) not in _NUM or int(ver) != float(ver):
		return "Neplatná verzia savu."
	if int(ver) > SAVE_VERSION:
		return "Save je z novšej verzie hry (v%d)." % int(ver)
	if int(ver) < 1:
		return "Neznáma verzia savu (v%d)." % int(ver)
	for key in _SAVE_TYPES.keys():
		if d.has(key) and typeof(d[key]) not in _SAVE_TYPES[key]:
			return "Chybný typ poľa '%s'." % key
	for key2 in _SAVE_ARRAYS_OF_DICTS:
		for row in d.get(key2, []):
			if typeof(row) != TYPE_DICTIONARY:
				return "Chybný prvok v '%s'." % key2
	var bad: Array = []
	_find_bad_numbers(d, "", bad, 0)
	if not bad.is_empty():
		return "Nekonečné alebo NaN číslo v savu (%s)." % str(bad[0])
	var dt: Dictionary = d.get("date", {"y": 2024, "m": 1, "d": 1})
	for k in ["y", "m", "d"]:
		if typeof(dt.get(k, null)) not in _NUM:
			return "Chybný dátum."
	var yy = int(dt.y)
	var mm = int(dt.m)
	var dd = int(dt.d)
	if yy < 1900 or yy > 3000 or mm < 1 or mm > 12 or dd < 1:
		return "Dátum mimo rozsahu."
	var dim = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][mm - 1]
	if mm == 2 and ((yy % 4 == 0 and yy % 100 != 0) or yy % 400 == 0):
		dim = 29
	if dd > dim:
		return "Neplatný dátum (deň mimo mesiaca)."
	if int(d.get("day_index", 0)) < 0:
		return "Záporný day_index."
	var sp = int(d.get("speed_index", 1))
	if sp < 0 or sp > 4:
		return "speed_index mimo rozsahu."
	var pl: Dictionary = d.get("player", {})
	if pl.is_empty():
		return "Save nemá hráča."
	if not pl.is_empty():
		if not _num_ok(pl, "cash", -1.0e15, 1.0e15):
			return "Chybná hotovosť hráča."
		for k2 in ["loans", "bonds", "events", "done", "research_queue"]:
			if pl.has(k2) and typeof(pl[k2]) != TYPE_ARRAY:
				return "Chybné pole hráča '%s'." % k2
		for k3 in ["stocks", "research", "modifiers"]:
			if pl.has(k3) and typeof(pl[k3]) != TYPE_DICTIONARY:
				return "Chybné pole hráča '%s'." % k3
		for lk in ["loans", "bonds"]:
			for row2 in pl.get(lk, []):
				if typeof(row2) != TYPE_DICTIONARY:
					return "Chybný prvok v player.%s." % lk
		var coupon_max = 1.0 if int(ver) >= 2 else 1e9  # v1: vysoky kupon sa opravi migraciou
		for bd in pl.get("bonds", []):
			if typeof(bd.get("country", null)) != TYPE_STRING or str(bd.country) == "":
				return "Dlhopis bez krajiny."
			if not DataLoader.countries.has(str(bd.country)) and not d.get("world", {}).has(str(bd.country)):
				return "Dlhopis s neznámou krajinou."
			if typeof(bd.get("face", null)) not in _NUM or float(bd.face) <= 0.0:
				return "Dlhopis s neplatným nominálom."
			if typeof(bd.get("coupon", null)) not in _NUM or float(bd.coupon) < 0.0 or float(bd.coupon) > coupon_max:
				return "Dlhopis s neplatným kupónom."
			if typeof(bd.get("years_left", null)) not in _NUM or float(bd.years_left) < 0.0:
				return "Dlhopis s neplatnou splatnosťou."
	var w: Dictionary = d.get("world", {})
	for iso in w.keys():
		if typeof(w[iso]) != TYPE_DICTIONARY:
			return "Chybná krajina '%s'." % str(iso)
		var crow: Dictionary = w[iso]
		# kazde cislo, ktore ma referencna krajina z DataLoadera, musi byt v savu tiez cislo (nie retazec)
		var ref: Dictionary = DataLoader.countries.get(str(iso), {})
		for k in ref.keys():
			if typeof(ref[k]) in _NUM and crow.has(k) and not _num_ok(crow, k, -1.0e18, 1.0e18):
				return "Krajina '%s': neplatné číslo '%s'." % [str(iso), str(k)]
		for k2 in ["population", "gdp_usd", "gdp_pc_usd"]:
			if crow.has(k2) and not _num_ok(crow, k2, 0.0, 1.0e18):
				return "Krajina '%s': neplatné '%s'." % [str(iso), k2]
		for k3 in ["inflation", "gdp_growth", "unemployment", "stability", "political_risk", "debt_gdp", "basket", "budget"]:
			if crow.has(k3) and not _num_ok(crow, k3, -1.0e18, 1.0e18):
				return "Krajina '%s': neplatné '%s'." % [str(iso), k3]
		# etapa 1: nove polia (v1/v2 volitelne - chybajuce doplni _fill_e1_fields; v3 ich vyzaduje)
		if int(ver) >= 3:
			for kreq in ["cpi_hist", "cpi_acc", "cpi_n"]:
				if not crow.has(kreq):
					return "Krajina '%s': v savu v3 chýba '%s'." % [str(iso), kreq]
		for k3b in ["cpi_acc", "war_gdp_pen"]:
			if crow.has(k3b) and not _num_ok(crow, k3b, -1.0e9, 1.0e9):
				return "Krajina '%s': neplatné '%s'." % [str(iso), k3b]
		if crow.has("cpi_n") and (not _num_ok(crow, "cpi_n", 0.0, 1.0e6) or int(crow.cpi_n) != float(crow.cpi_n)):
			return "Krajina '%s': neplatné 'cpi_n'." % str(iso)
		if crow.has("cpi_hist"):
			if typeof(crow.cpi_hist) != TYPE_ARRAY or crow.cpi_hist.size() > 60:
				return "Krajina '%s': neplatná 'cpi_hist'." % str(iso)
			for hv in crow.cpi_hist:
				if typeof(hv) not in _NUM or is_nan(float(hv)) or is_inf(float(hv)) or float(hv) <= 0.0 or float(hv) > 1.0e6:
					return "Krajina '%s': neplatná hodnota v 'cpi_hist'." % str(iso)
	var m: Dictionary = d.get("markets", {})
	for iso2 in m.keys():
		if typeof(m[iso2]) != TYPE_DICTIONARY:
			return "Chybný trh '%s'." % str(iso2)
		for cid in m[iso2].keys():
			if typeof(m[iso2][cid]) != TYPE_DICTIONARY:
				return "Chybná kniha '%s/%s'." % [str(iso2), str(cid)]
			var bk: Dictionary = m[iso2][cid]
			if int(ver) >= 3 and not bk.has("dref"):
				return "Kniha '%s/%s': v savu v3 chýba 'dref'." % [str(iso2), str(cid)]
			if bk.has("price") and (not _num_ok(bk, "price", 0.0, 1.0e18) or float(bk.price) <= 0.0):
				return "Kniha '%s/%s': neplatná cena." % [str(iso2), str(cid)]
			for k4 in ["stock", "last_dem", "last_sup", "sell_fill", "buy_fill", "capital_add", "demand_product", "dref"]:
				if bk.has(k4) and not _num_ok(bk, k4, -1.0e30, 1.0e30):
					return "Kniha '%s/%s': neplatné '%s'." % [str(iso2), str(cid), k4]
	var c: Dictionary = d.get("central", {})
	for iso3 in c.keys():
		if typeof(c[iso3]) != TYPE_DICTIONARY:
			return "Chybná centrálna banka '%s'." % str(iso3)
		if not c[iso3].has("policy") or not _num_ok(c[iso3], "policy", -0.5, 10.0):
			return "Centrálna banka '%s': chýba alebo neplatná sadzba." % str(iso3)
		if c[iso3].has("base_rate") and not _num_ok(c[iso3], "base_rate", -0.5, 10.0):
			return "Centrálna banka '%s': neplatná base_rate." % str(iso3)
		if int(ver) >= 3 and (not c[iso3].has("prev_rate") or not c[iso3].has("upd_day")):
			return "Centrálna banka '%s': v savu v3 chýba prev_rate/upd_day." % str(iso3)
		if c[iso3].has("prev_rate") and not _num_ok(c[iso3], "prev_rate", -0.5, 10.0):
			return "Centrálna banka '%s': neplatná prev_rate." % str(iso3)
		if c[iso3].has("upd_day") and (not _num_ok(c[iso3], "upd_day", -1.0, 1.0e9) or int(c[iso3].upd_day) != float(c[iso3].upd_day)):
			return "Centrálna banka '%s': neplatný upd_day." % str(iso3)
	for fr in d.get("firms", []):
		if not _num_ok(fr, "cash", -1.0e15, 1.0e15):
			return "Firma: neplatná hotovosť."
		for k5 in ["id", "country", "industry"]:
			if fr.has(k5) and typeof(fr[k5]) != TYPE_STRING:
				return "Firma: neplatné pole '%s'." % k5
	for bk2 in d.get("banks", []):
		for k6 in ["reserves", "deposits", "equity", "explicit"]:
			if bk2.has(k6) and not _num_ok(bk2, k6, -1.0e15, 1.0e15):
				return "Banka: neplatné '%s'." % k6
	for ln in pl.get("loans", []):
		for k7 in ["remaining", "annual_rate", "monthly_payment", "daily_payment"]:
			if ln.has(k7) and not _num_ok(ln, k7, -1.0e15, 1.0e15):
				return "Úver: neplatné '%s'." % k7
	for sk in pl.get("stocks", {}).keys():
		if typeof(pl.stocks[sk]) not in _NUM:
			return "Akcie hráča: neplatný počet."
	if d.has("rng_seed") and not str(d.rng_seed).is_valid_int():
		return "Chybný rng_seed."
	if d.has("rng_state") and not str(d.rng_state).is_valid_int():
		return "Chybný rng_state."
	return ""

# Pole chyba (ok) alebo je to konecne cislo v rozsahu [lo, hi]; retazec/bool/NaN/inf/mimo rozsahu = false.
func _num_ok(row: Dictionary, key: String, lo: float, hi: float) -> bool:
	if not row.has(key):
		return true
	var v = row[key]
	if typeof(v) not in _NUM:
		return false
	if typeof(v) == TYPE_FLOAT and EconMath.is_bad(v):
		return false
	return float(v) >= lo and float(v) <= hi

func _find_bad_numbers(v, path: String, bad: Array, depth: int) -> void:
	if depth > 12 or bad.size() > 0:
		return
	match typeof(v):
		TYPE_FLOAT:
			if EconMath.is_bad(v):
				bad.append(path)
		TYPE_DICTIONARY:
			for k in v.keys():
				_find_bad_numbers(v[k], path + "/" + str(k), bad, depth + 1)
		TYPE_ARRAY:
			var i = 0
			for x in v:
				_find_bad_numbers(x, path + "[" + str(i) + "]", bad, depth + 1)
				i += 1

# Dopln chybajuce krajiny/komodity/centralne banky po nacitani (stary save, pridane data).
func _repair_after_load() -> void:
	for iso in DataLoader.country_ids:
		if not world.has(iso):
			var copy: Dictionary = DataLoader.countries[iso].duplicate(true)
			copy.weather = "clear"
			copy.weather_left = 0
			copy.basket = 1.0
			copy.budget = 0.0
			world[iso] = copy
		else:
			var row: Dictionary = world[iso]
			for k in DataLoader.countries[iso].keys():
				if not row.has(k):
					row[k] = DataLoader.countries[iso][k]
			for k2 in ["weather", "weather_left", "basket", "budget"]:
				if not row.has(k2):
					row[k2] = {"weather": "clear", "weather_left": 0, "basket": 1.0, "budget": 0.0}[k2]
		if not markets.has(iso):
			markets[iso] = {}
			if not central.has(iso):
				var infl0 = float(world[iso].get("inflation", 0.03))
				central[iso] = {"policy": EconMath.cl(float(world[iso].get("lending_rate", infl0 + 0.02)) * 0.75, 0.002, 0.28), "target": 0.02}
			MarketSystem.init_country_books(iso)  # JUAN5: krajina pridana po starom save -> trh v rovnovahe
		for cid in DataLoader.commodity_ids:
			if not markets[iso].has(cid):
				markets[iso][cid] = MarketSystem.default_book(cid)
		if not central.has(iso):
			var infl = float(world[iso].get("inflation", 0.03))
			central[iso] = {"policy": EconMath.cl(float(world[iso].get("lending_rate", infl + 0.02)) * 0.75, 0.002, 0.28), "target": 0.02}
	_fill_e1_fields()

# etapa 1: idempotentne doplnenie poli, ktore vznikli v etape 1 (save v1/v2 ich nema).
# dref = 0.0 znamena "nenastavene": MarketSystem._update_capacity ho pri prvom begin_day inicializuje z dopytu.
func _fill_e1_fields() -> void:
	for iso in world.keys():
		var wrow: Dictionary = world[iso]
		if not wrow.has("cpi_hist"):
			wrow.cpi_hist = []
		if not wrow.has("cpi_acc"):
			wrow.cpi_acc = 0.0
		if not wrow.has("cpi_n"):
			wrow.cpi_n = 0
	for iso2 in central.keys():
		var crow: Dictionary = central[iso2]
		if not crow.has("prev_rate"):
			crow.prev_rate = float(crow.get("base_rate", crow.get("policy", 0.02)))
		if not crow.has("upd_day"):
			crow.upd_day = -1
	for iso3 in markets.keys():
		for cid in markets[iso3].keys():
			if not markets[iso3][cid].has("dref"):
				markets[iso3][cid].dref = 0.0

# v2 -> v3 (etapa 1): doplni nove polia defaultmi; opakovane volanie nic nemeni
func _migrate_v2_to_v3() -> void:
	_fill_e1_fields()

# Nacita save. Najprv validuje; pri chybe vrati text a zivy stav ostane nedotknuty.
func from_dict(d: Dictionary) -> String:
	var err = validate_save(d)
	if err != "":
		return err
	state_revision += 1
	_ph = 0  # platny save nahradi aj pripadny rozpracovany den
	running = bool(d.get("running", true))
	paused = true
	speed_index = int(d.get("speed_index", 1))
	day_index = int(d.get("day_index", 0))
	date = {"y": int(d.get("date", {}).get("y", 2024)), "m": int(d.get("date", {}).get("m", 1)), "d": int(d.get("date", {}).get("d", 1))}
	player = d.get("player", {})
	firms = d.get("firms", [])
	banks = d.get("banks", [])
	central = d.get("central", {})
	world = d.get("world", {})
	markets = d.get("markets", {})
	wars = d.get("wars", [])
	relations = d.get("relations", {})
	sanctions = d.get("sanctions", [])
	embargoes = d.get("embargoes", [])
	alliances = d.get("alliances", [])
	treaties = d.get("treaties", [])
	reliefs = d.get("reliefs", [])
	un_sanctions = d.get("un_sanctions", [])
	world_events = d.get("world_events", [])
	bond_orders = d.get("bond_orders", [])
	stock_orders = d.get("stock_orders", [])
	sites = d.get("sites", DataLoader.sites.duplicate(true))
	news = d.get("news", [])
	stories = d.get("stories", [])
	config = d.get("config", {})
	selected_iso = str(d.get("selected_iso", player.get("home", "SK")))
	next_firm = int(d.get("next_firm", 1))
	next_loan = int(d.get("next_loan", 1))
	next_bank = int(d.get("next_bank", 1))
	usd_per_eur = float(d.get("usd_per_eur", DataLoader.usd_per_eur))
	ext = d.get("ext", {})  # JUAN4: stary save nema -> prazdne, PoliticsSystem.ensure() doplni
	if typeof(ext) != TYPE_DICTIONARY:
		ext = {}
	if usd_per_eur <= 0.1:
		usd_per_eur = DataLoader.usd_per_eur
	if d.has("rng_seed") and d.has("rng_state"):
		rng.seed = int(str(d.rng_seed))
		rng.state = int(str(d.rng_state))
	MarketSystem.reset_runtime()
	_repair_after_load()
	if int(d.get("v", 1)) < 2:
		_migrate_v1_bonds()
	if int(d.get("v", 1)) < 3:
		_migrate_v2_to_v3()
	return ""

# v1 -> v2: dlhopisy z knihy mali kupon = cena/100 (napr. 1.0 = 100 %/rok); prepocitaj na statny vynos krajiny.
func _migrate_v1_bonds() -> void:
	for b in player.get("bonds", []):
		if float(b.get("coupon", 0.0)) > BOND_MIGRATE_COUPON:
			var iso = str(b.get("country", ""))
			if str(b.get("issuer", "state")) != "player" and central.has(iso) and world.has(iso):
				b.coupon = BankingSystem._bond_yield(iso)
			elif str(b.get("issuer", "state")) != "player":
				b.coupon = BankingSystem.BOND_FALLBACK_COUPON
