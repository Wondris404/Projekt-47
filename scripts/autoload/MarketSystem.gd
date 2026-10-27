extends Node

var world_demand = {}
var offers = {}
var bids = {}
var freight_pool = {}
var matching_market = {}
var route_transfers: Array = []
var _distance_cache = preload("res://scripts/route_distance_cache.gd").new()
var history = {}
# etapa 1: denne cache (naplni begin_day): dopyt pri aktualnej cene, referencny dopyt pri base cene, ponuka po obchode
var d_now = {}
var d_ref = {}
var sup_day = {}
var _fc = {}
var _rivals = {}  # JUAN5: denna cache poctu firiem v krajine
var _war_set = {}
var _rivals_valid = false
# --- JUAN5: urovnova simulacia (tiered LOD) ---
# tier 1 = top TIER1_TOP ekonomik podla HDP (+ povodnych 26, krajina hraca, krajiny s jeho firmami/bankami, vo vojne): plny denny trh
# tier 2 = ostatne: agregovany prepocet raz za TIER2_PERIOD dni, rozlozeny round-robin (1/7 krajin denne), krok x7
var TIER1_TOP = 70
const TIER2_PERIOD = 7
var tier1 = {}
var _top_cache = {}
var _tier2_slot = {}
var _prod_c = {}
var _active = {}
var _dt = {}
var _full_next = true

func _rebuild_top() -> void:
	_top_cache.clear()
	_tier2_slot.clear()
	var ids: Array = DataLoader.country_ids.duplicate()
	ids.sort_custom(func(a, b): return float(DataLoader.countries[a].get("gdp_usd", 0.0)) > float(DataLoader.countries[b].get("gdp_usd", 0.0)))
	for i in ids.size():
		if i < TIER1_TOP:
			_top_cache[ids[i]] = true
	for iso in DataLoader.core_ids:
		_top_cache[iso] = true
	var n = 0
	for iso in DataLoader.country_ids:
		if not _top_cache.has(iso):
			_tier2_slot[iso] = n % TIER2_PERIOD
			n += 1

func refresh_tiers() -> void:
	if _top_cache.is_empty() or _top_cache.size() + _tier2_slot.size() != DataLoader.country_ids.size():
		_rebuild_top()
	tier1 = _top_cache.duplicate()
	tier1[str(GameState.player.get("home", ""))] = true
	tier1[GameState.selected_iso] = true
	for f in GameState.firms:
		if str(f.get("owner", "")) == "player" and not f.get("closed", false):
			tier1[str(f.get("country", ""))] = true
	for b in GameState.banks:
		if str(b.get("owner", "player")) == "player":
			tier1[str(b.get("country", ""))] = true
	for w in GameState.wars:
		for x in w.get("a", []):
			tier1[str(x)] = true
		for y in w.get("b", []):
			tier1[str(y)] = true
	_active.clear()
	_dt.clear()
	var slot = GameState.day_index % TIER2_PERIOD
	for iso in DataLoader.country_ids:
		if tier1.has(iso):
			_active[iso] = true
			_dt[iso] = 1
		elif int(_tier2_slot.get(iso, 0)) == slot:
			_active[iso] = true
			_dt[iso] = TIER2_PERIOD

func tier_of(iso: String) -> int:
	if tier1.is_empty():
		refresh_tiers()
	return 1 if tier1.has(iso) else 2

func tier1_count() -> int:
	if tier1.is_empty():
		refresh_tiers()
	return tier1.size()

const CAP_TAU = 60.0   # dni: kapacita (dref) nasleduje referencny dopyt (EMA)
const WAR_OPENNESS = 0.55

func reset_runtime() -> void:
	_cw.clear()
	_cw_day = -1
	_ram_day = -1
	_active.clear()
	_dt.clear()
	_rivals.clear()
	_rivals_valid = false
	_war_set.clear()
	d_now.clear()
	d_ref.clear()
	sup_day.clear()
	_fc.clear()
	world_demand.clear()
	offers.clear()
	bids.clear()
	matching_market.clear()
	route_transfers.clear()
	freight_pool.clear()
	history.clear()
	_dvec.clear()  # JUAN5: po nacitani/novej hre prvy den prepocita vsetky krajiny naplno
	_prod_c.clear()
	tier1.clear()
	_full_next = true

func init_books() -> void:
	GameState.markets.clear()
	reset_runtime()
	_distance_cache.start(DataLoader.country_ids, DataLoader.countries)
	_cache_demand()
	for iso in DataLoader.country_ids:
		var books = {}
		for cid in DataLoader.commodity_ids:
			var base = float(DataLoader.commodity(cid).get("base_price", 1.0))
			var dem = _one_demand(iso, cid)
			# etapa 1: trh startuje v rovnovahe (cena = base, zasoba = cielova 42 dni, kapacita = referencny dopyt)
			books[cid] = {
				"price": base,
				"stock": max(dem, 1.0) * 42.0,
				"last_dem": dem,
				"last_sup": dem,
				"sell_fill": 1.0,
				"buy_fill": 1.0,
				"dref": float(d_ref.get(iso + "|" + cid, dem)),
			}
		GameState.markets[iso] = books
	_cache_supply()

# JUAN5: rovnovazny trh pre jednu krajinu (krajina, ktora v starom save chyba)
func init_country_books(iso: String) -> void:
	var books = {}
	for cid in DataLoader.commodity_ids:
		var base = float(DataLoader.commodity(cid).get("base_price", 1.0))
		var dem = _one_demand(iso, cid, base)
		var dr = _one_demand(iso, cid, base, false, true)
		books[cid] = {"price": base, "stock": max(dem, 1.0) * 42.0, "last_dem": dem, "last_sup": dem, "sell_fill": 1.0, "buy_fill": 1.0, "dref": dr}
	GameState.markets[iso] = books

func default_book(cid: String) -> Dictionary:
	var base = float(DataLoader.commodity(cid).get("base_price", 1.0))
	return {"price": base, "stock": 40.0, "last_dem": 0.0, "last_sup": 0.0, "sell_fill": 1.0, "buy_fill": 1.0}

func _book(iso: String, cid: String) -> Dictionary:
	if not GameState.markets.has(iso):
		GameState.markets[iso] = {}
	if not GameState.markets[iso].has(cid):
		GameState.markets[iso][cid] = default_book(cid)
	return GameState.markets[iso][cid]

func price(iso: String, cid: String) -> float:
	var books = GameState.markets.get(iso, {})
	if typeof(books) == TYPE_DICTIONARY and books.has(cid):
		return float(books[cid].get("price", 1.0))
	return float(DataLoader.commodity(cid).get("base_price", 1.0))

func begin_day() -> void:
	begin_day_start()
	while not begin_day_step():
		pass

var _begin_stage := 0
var _begin_index := 0
const _BEGIN_COMMODITY_CHUNK = 2

func begin_day_start() -> void:
	offers.clear()
	bids.clear()
	matching_market.clear()
	route_transfers.clear()
	_distance_cache.poll()
	freight_pool.clear()
	refresh_tiers()
	if _full_next:
		_full_next = false
		for iso in DataLoader.country_ids:
			_active[iso] = true
			_dt[iso] = 1
	_demand_fast_prepare()
	_begin_stage = 0
	_begin_index = 0

func begin_day_step() -> bool:
	match _begin_stage:
		0:
			_begin_index = _demand_fast_chunk(_begin_index, _BEGIN_COMMODITY_CHUNK)
			if _begin_index >= DataLoader.commodity_ids.size():
				_begin_stage = 1
				_begin_index = 0
		1:
			_begin_index = _update_capacity_chunk(_begin_index, 12, true)
			if _begin_index >= DataLoader.country_ids.size():
				_begin_stage = 2
		2:
			_supply_prepare(true)
			_begin_index = 0
			_begin_stage = 3
		3:
			_begin_index = _supply_chunk(_begin_index, _BEGIN_COMMODITY_CHUNK)
			if _begin_index >= DataLoader.commodity_ids.size():
				_begin_stage = 4
				return true
	return _begin_stage == 4

func post_offer(iso: String, cid: String, actor: String, qty: float) -> void:
	if qty <= 0.0:
		return
	var k = iso + "|" + cid
	if not offers.has(k):
		offers[k] = []
	offers[k].append({"actor": actor, "qty": qty})

func post_bid(iso: String, cid: String, actor: String, qty: float) -> void:
	if qty <= 0.0:
		return
	var k = iso + "|" + cid
	if not bids.has(k):
		bids[k] = []
	bids[k].append({"actor": actor, "qty": qty})

func actor_sell_fill(iso: String, cid: String) -> float:
	var books = GameState.markets.get(iso, {})
	if typeof(books) != TYPE_DICTIONARY or not books.has(cid):
		return 0.0
	return float(books[cid].get("sell_fill", 0.0))

func actor_buy_fill(iso: String, cid: String) -> float:
	var books = GameState.markets.get(iso, {})
	if typeof(books) != TYPE_DICTIONARY or not books.has(cid):
		return 0.0
	return float(books[cid].get("buy_fill", 0.0))

func trade_routes() -> void:
	trade_routes_chunk(0, DataLoader.commodity_ids.size())

func trade_routes_chunk(start: int, count: int) -> int:
	var end = mini(start + count, DataLoader.commodity_ids.size())
	for index in range(start, end):
		var cid = str(DataLoader.commodity_ids[index])
		var com: Dictionary = DataLoader.commodity(cid)
		if not com.get("tradable", false):
			continue
		var exporters = []
		var importers = []
		for iso in DataLoader.country_ids:
			var book: Dictionary = _book(iso, cid)
			var dem = max(float(book.get("last_dem", 1.0)), 0.001)
			var days = float(book.stock) / dem
			if days > 55.0 and float(book.stock) > 5.0:
				exporters.append({"iso": iso, "price": float(book.price), "days": days})
			elif days < 28.0:
				importers.append({"iso": iso, "price": float(book.price), "days": days})
		exporters.sort_custom(func(a, b): return float(a.price) < float(b.price))
		importers.sort_custom(func(a, b): return float(a.price) > float(b.price))
		var ei = 0
		var ii = 0
		var guard = 0
		while ei < exporters.size() and ii < importers.size() and guard < 80:
			guard += 1
			var ex: Dictionary = exporters[ei]
			var im: Dictionary = importers[ii]
			if str(ex.iso) == str(im.iso):
				ii += 1
				continue
			var freight = freight_unit(str(ex.iso), str(im.iso), cid)
			if float(im.price) < float(ex.price) + freight:
				ii += 1
				continue
			var src: Dictionary = _book(ex.iso, cid)
			var dst: Dictionary = _book(im.iso, cid)
			var qty = min(float(src.stock) * 0.04, max(float(dst.last_dem), 1.0) * 0.08)
			if GeopoliticsSystem.blocked(str(ex.iso), str(im.iso)):
				qty *= 0.04
			if qty < 0.01:
				ei += 1
				continue
			src.stock = float(src.stock) - qty
			dst.stock = float(dst.stock) + qty
			if IndustrySystem.record_goods_flow:
				route_transfers.append({"day": GameState.day_index, "seller": "@market", "buyer": "@market", "cid": cid, "src": str(ex.iso), "dst": str(im.iso), "qty": qty, "seller_price": float(ex.price), "buyer_price": float(im.price), "kind": "market_transfer"})
			var fee = freight * qty
			freight_pool[str(ex.iso)] = float(freight_pool.get(str(ex.iso), 0.0)) + fee * 0.5
			freight_pool[str(im.iso)] = float(freight_pool.get(str(im.iso), 0.0)) + fee * 0.5
			ei += 1
			ii += 1
	return end

func freight_unit(a: String, b: String, cid: String) -> float:
	var ca: Dictionary = DataLoader.countries.get(a, {})
	var cb: Dictionary = DataLoader.countries.get(b, {})
	var km = _distance_cache.distance(a, b, -1.0)
	if km < 0.0:
		km = EconMath.haversine(float(ca.get("lat", 0)), float(ca.get("lon", 0)), float(cb.get("lat", 0)), float(cb.get("lon", 0)))
	var base = float(DataLoader.commodity(cid).get("base_price", 1.0))
	var oil = price(a, "crude_oil") / max(float(DataLoader.commodity("crude_oil").get("base_price", 78.0)), 1.0)
	var embargo = 6.0 if GeopoliticsSystem.blocked(a, b) else 1.0
	var war = 1.0 + GeopoliticsSystem.war_intensity_world() * 0.12
	return base * (0.012 + km / 18000.0) * oil * embargo * war

func _exit_tree() -> void:
	_distance_cache.wait_for_completion()

func power_price(base: float, demand: float, supply: float, elasticity: float) -> float:
	var s = max(supply, 0.000001)
	var p = base * pow(max(demand, 0.0) / s, elasticity)
	if EconMath.is_bad(p) or p <= 0.0:
		return base
	return p

func demand_factors(iso: String, cid: String) -> Dictionary:
	var c: Dictionary = GameState.world.get(iso, {})
	var income = max(float(c.get("gdp_pc_usd", c.get("gdp_per_capita", 10000.0))) / 20000.0, 0.05)
	var tod = 1.08 if TimeSystem.dow() < 5 else 0.92
	var weather = EventSystem.weather_factor(str(c.get("weather", "clear")), cid)
	var holiday = EventSystem.holiday_factor(iso, cid)
	var rivals = 0
	if _rivals_valid:
		rivals = int(_rivals.get(iso, 0))
	else:
		for firm in GameState.firms:
			if str(firm.get("country", "")) == iso and not firm.get("closed", false):
				rivals += 1
	var competition = 1.0 / (1.0 + 0.08 * float(rivals))
	var geo = GeopoliticsSystem.conflict_demand(_war_set.has(iso) if _rivals_valid else GeopoliticsSystem.at_war(iso), cid)
	var population = float(c.get("population", 0.0))
	var product = population * income * tod * weather * holiday * competition * geo
	return {
		"population": population,
		"income_factor": income,
		"time_of_day_factor": tod,
		"weather_factor": weather,
		"holiday_factor": holiday,
		"competition_factor": competition,
		"geopolitics_factor": geo,
		"product": product,
	}

# etapa 1: aktivna - denny adaptivny krok ceny (gap dopyt/ponuka + zasoby), ohranicenie 0.22-6.5 x base
func adjust_price(price: float, demand: float, supply: float, stock: float, base: float) -> float:
	var gap = (demand - supply) / max(supply, 0.001)
	price = price * (1.0 + clampf(gap, -0.65, 1.1) * 0.05)
	var target = max(demand, 1.0) * 42.0
	var stock_p = (target - stock) / max(target, 0.001)
	price = price * (1.0 + clampf(stock_p, -1.0, 1.0) * 0.012)
	if is_nan(price) or is_inf(price):
		price = base
	return clampf(price, base * 0.22, base * 6.5)

var _bases = PackedFloat64Array()
# JUAN23: to iste ako clear_all, ale po castiach (pre rozlozenie dna cez snimky); vrati dalsi index alebo -1
func clear_chunk(start: int, n: int) -> int:
	if start == 0:
		if _active.is_empty():
			refresh_tiers()
		_bases.resize(DataLoader.commodity_ids.size())
		for j in _bases.size():
			_bases[j] = float(DataLoader.commodity(DataLoader.commodity_ids[j]).get("base_price", 1.0))
	var ids: Array = DataLoader.country_ids
	var done = 0
	var i = start
	while i < ids.size() and done < n:
		var iso = str(ids[i])
		i += 1
		if not _active.has(iso):
			continue
		done += 1
		var steps = int(_dt.get(iso, 1))
		var j = 0
		for cid in DataLoader.commodity_ids:
			_clear_one(iso, cid, steps, _bases[j])
			j += 1
		_remember(iso)
		_accumulate_cpi(iso, steps)
	return -1 if i >= ids.size() else i

func clear_all() -> void:
	if _active.is_empty():
		refresh_tiers()
	_bases.resize(DataLoader.commodity_ids.size())
	for j in _bases.size():
		_bases[j] = float(DataLoader.commodity(DataLoader.commodity_ids[j]).get("base_price", 1.0))
	for iso in DataLoader.country_ids:
		if not _active.has(iso):
			continue
		var steps = int(_dt.get(iso, 1))
		var j = 0
		for cid in DataLoader.commodity_ids:
			_clear_one(iso, cid, steps, _bases[j])
			j += 1
		_remember(iso)
		_accumulate_cpi(iso, steps)

# --- CPI (etapa 1, krok 3): vazeny kosik spotrebnych komodit; vahy = podiel vydavkov (weight x poor/rich mult) ---
const CPI_BASKET = ["wheat", "meat", "coffee", "food_service", "electricity", "crude_oil", "textiles", "electronics", "automobiles", "pharma"]

func cpi_weights(iso: String) -> Dictionary:
	var c: Dictionary = GameState.world.get(iso, {})
	var rich = EconMath.rich_index(float(c.get("gdp_pc_usd", 10000.0)))
	var out = {}
	var total = 0.0
	for cid in CPI_BASKET:
		if not DataLoader.commodities.has(cid):
			continue
		var com: Dictionary = DataLoader.commodity(cid)
		var w = float(com.get("weight", 0.01)) * lerpf(float(com.get("poor_mult", 1.0)), float(com.get("rich_mult", 1.0)), rich)
		out[cid] = w
		total += w
	for k in out.keys():
		out[k] = float(out[k]) / max(total, 1e-9)
	return out

# okamzity CPI index (1.0 = vsetky ceny na base)
var _cw = {}
var _cw_day = -1
func cpi_index(iso: String) -> float:
	if _cw_day != GameState.day_index:
		_cw.clear()
		_cw_day = GameState.day_index
	if not _cw.has(iso):
		_cw[iso] = cpi_weights(iso)
	var w: Dictionary = _cw[iso]
	var idx = 0.0
	for cid in w.keys():
		idx += float(w[cid]) * price(iso, cid) / max(float(DataLoader.commodity(cid).get("base_price", 1.0)), 0.0001)
	return idx

func _accumulate_cpi(iso: String, steps: int = 1) -> void:
	if not GameState.world.has(iso):
		return
	var c: Dictionary = GameState.world[iso]
	var idx = cpi_index(iso)
	if EconMath.is_bad(idx):
		return
	c.cpi_acc = float(c.get("cpi_acc", 0.0)) + idx * steps
	c.cpi_n = int(c.get("cpi_n", 0)) + steps

# mesacny priemer CPI (a vynulovanie akumulatora); ak nie su data, okamzity index
func cpi_month_average(iso: String) -> float:
	var c: Dictionary = GameState.world.get(iso, {})
	var n = int(c.get("cpi_n", 0))
	var idx = float(c.get("cpi_acc", 0.0)) / float(n) if n > 0 else cpi_index(iso)
	c.cpi_acc = 0.0
	c.cpi_n = 0
	return idx

func _clear_one(iso: String, cid: String, steps: int = 1, base: float = -1.0) -> void:
	var book: Dictionary = _book(iso, cid)
	if base < 0.0:
		base = float(DataLoader.commodity(cid).get("base_price", 1.0))
	var k = iso + "|" + cid
	var firm_sup = 0.0
	var firm_dem = 0.0
	if offers.has(k):
		for o in offers[k]:
			firm_sup += float(o.qty)
	if bids.has(k):
		for b in bids[k]:
			firm_dem += float(b.qty)
	var npc_dem: float = float(d_now[k]) if d_now.has(k) else _one_demand(iso, cid)
	var npc_sup: float = float(sup_day[k]) if sup_day.has(k) else npc_dem
	var sup = npc_sup + firm_sup
	var dem = npc_dem + firm_dem
	var sell_fill = 1.0 if sup <= 0.0001 else clampf(dem / sup, 0.0, 1.0)
	var buy_fill = 1.0 if dem <= 0.0001 else clampf(sup / dem, 0.0, 1.0)
	if firm_sup > 0.0 or firm_dem > 0.0:
		matching_market[k] = {"supply": npc_sup * sell_fill, "demand": npc_dem * buy_fill}
	var factors = null if (_fast_f and d_now.has(k)) else _factors_cached(iso, cid)
	# etapa 1: adaptivny tlmeny krok namiesto bezpamatoveho base*(D/S)^e (pozri adjust_price)
	for _s in steps:  # JUAN5: tier 2 dobehne zmeskane dni naraz
		book.price = adjust_price(float(book.price), max(dem, 0.0001), max(sup, 0.0001), float(book.stock), base)
		book.stock = max(0.2, float(book.stock) + npc_sup - npc_dem)
	if firm_sup > 0.0:  # JUAN15: odberatelia hraca
		Empire.record_sales(iso, cid, offers[k], bids.get(k, []), npc_dem, dem, sell_fill, float(book.price))
	book.last_dem = dem
	book.last_sup = sup
	book.sell_fill = sell_fill
	book.buy_fill = buy_fill
	if factors != null and not factors.is_empty():  # rychla cesta zapisala faktory uz v _cache_demand_fast
		book.f_pop = float(factors.population)
		book.f_income = float(factors.income_factor)
		book.f_tod = float(factors.time_of_day_factor)
		book.f_weather = float(factors.weather_factor)
		book.f_holiday = float(factors.holiday_factor)
		book.f_comp = float(factors.competition_factor)
		book.f_geo = float(factors.geopolitics_factor)
		book.demand_product = float(factors.product)
	book.capital_add = 0.0
	if cid == "finance":
		var gdp_eur = float(GameState.world.get(iso, {}).get("gdp_usd", 0.0)) / max(GameState.usd_per_eur, 0.2)
		var rate = float(GameState.central.get(iso, {}).get("base_rate", GameState.central.get(iso, {}).get("policy", 0.02)))
		book.capital_add = BankingSystem.capital_demand(rate, gdp_eur) / 365.0

func _remember(iso: String) -> void:
	if iso != str(GameState.player.get("home", "")) and iso != GameState.selected_iso:
		return
	for cid in DataLoader.commodity_ids:
		var key = iso + "|" + cid
		if not history.has(key):
			history[key] = []
		history[key].append(float(_book(iso, cid).price))
		if history[key].size() > 90:
			history[key].pop_front()

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func chart(iso: String, cid: String) -> Array:
	return history.get(iso + "|" + cid, [])

func try_arbitrage(src: String, dst: String, cid: String, qty: float) -> float:
	if not GameState.markets.has(src) or not GameState.markets.has(dst):
		return 0.0
	var a: Dictionary = _book(src, cid)
	var b: Dictionary = _book(dst, cid)
	var moved = min(qty, float(a.stock) * 0.25)
	var unmet = max(0.0, float(b.last_dem) - float(b.last_sup))
	moved = min(moved, max(unmet, float(b.last_dem) * 0.05))
	if moved <= 0.0:
		return 0.0
	a.stock = float(a.stock) - moved
	return moved

func _factors_cached(iso: String, cid: String) -> Dictionary:
	var k = iso + "|" + cid
	if not _fc.has(k):
		_fc[k] = demand_factors(iso, cid)
	return _fc[k]

var _fast_f = false
func _cache_demand_fast() -> void:
	_demand_fast_prepare()
	_demand_fast_chunk(0, DataLoader.commodity_ids.size())

var _dm_contexts: Dictionary = {}
var _dm_inactive := PackedFloat64Array()
var _dm_tod := 1.0
var _dm_month := 1
var _dm_day := 1

func _demand_fast_prepare() -> void:
	_build_day_cache()
	_fc.clear()
	world_demand.clear()
	_fast_f = true
	var tod = 1.08 if TimeSystem.dow() < 5 else 0.92
	var month = int(GameState.date.m)
	var day = int(GameState.date.d)
	var ctxs = {}
	for iso in DataLoader.country_ids:
		if (_active.has(iso) or not _dvec.has(iso)) and GameState.world.has(iso):
			ctxs[iso] = _ctx(iso)
	var nc = DataLoader.commodity_ids.size()
	var inact = PackedFloat64Array()
	inact.resize(nc)
	for iso in DataLoader.country_ids:
		if not ctxs.has(iso):
			var v: PackedFloat64Array = _dvec.get(iso, PackedFloat64Array())
			for j in min(nc, v.size()):
				inact[j] += v[j]
	_dm_contexts = ctxs
	_dm_inactive = inact
	_dm_tod = tod
	_dm_month = month
	_dm_day = day

func _demand_fast_chunk(start: int, count: int) -> int:
	var ctxs = _dm_contexts
	var inact = _dm_inactive
	var tod = _dm_tod
	var month = _dm_month
	var day = _dm_day
	var nc = DataLoader.commodity_ids.size()
	var end = mini(start + count, nc)
	for ci in range(start, end):
		var cid = DataLoader.commodity_ids[ci]
		var total = inact[ci]
		var com: Dictionary = DataLoader.commodity(cid)
		var base = float(com.get("base_price", 1.0))
		var w0 = float(com.get("weight", 0.01))
		var pm = float(com.get("poor_mult", 1.0))
		var rm = float(com.get("rich_mult", 1.0))
		var elas = float(com.get("elasticity", 0.4))
		var bp = com.get("base_price", null)
		var is_fin = cid == "finance"
		var is_arms = cid == "weapons" or cid == "arms"
		var geo_hot = GeopoliticsSystem.conflict_demand(true, cid)
		var xmas = month == 12 and day >= 24 and cid == "food_service"
		var ram = month == 3 and day < 20 and cid == "food_service"
		for iso in ctxs.keys():
			var x: Dictionary = ctxs[iso]
			var k = iso + "|" + cid
			var weather = 1.0 if x.weather == "clear" else EventSystem.weather_factor(x.weather, cid)
			var holiday = 1.0
			if xmas and str(x.grp).begins_with("christian"):
				holiday = 1.42
			elif ram and x.grp == "muslim":
				holiday = 1.15
			var geo = geo_hot if x.hot else 1.0
			var population: float = x.pop
			var income: float = x.income
			var comp: float = x.comp
			var product = population * income * tod * weather * holiday * comp * geo
			var books: Dictionary = x.books
			if not books.has(cid):
				books[cid] = default_book(cid)
			var book: Dictionary = books[cid]
			book.f_pop = population
			book.f_income = income
			book.f_tod = tod
			book.f_weather = weather
			book.f_holiday = holiday
			book.f_comp = comp
			book.f_geo = geo
			book.demand_product = product
			var px = float(book.get("price", 1.0))
			var gdp_eur: float = x.gdp_eur
			var spend = gdp_eur * w0 * lerpf(pm, rm, float(x.rich)) / 365.0
			var pf = product / max(population, 1.0) * float(x.unemp)
			var dn = spend / max(px, 0.05) * pow(max(float(bp if bp != null else px), 0.05) / max(px, 0.05), elas) * pf
			var dr = spend / max(base, 0.05) * pow(max(float(bp if bp != null else base), 0.05) / max(base, 0.05), elas) * pf / max(tod, 0.01)
			if is_fin:
				var cap = BankingSystem.capital_demand(float(x.rate), gdp_eur) / 365.0
				dn += cap / max(px, 0.05)
				dr += cap / max(base, 0.05)
			elif is_arms:
				var mil = gdp_eur * float(x.mil) * 0.22 / 365.0
				dn += mil / max(px, 0.05)
				dr += mil / max(base, 0.05)
			dn = max(0.0, dn)
			d_now[k] = dn
			d_ref[k] = max(0.0, dr)
			total += dn
			if not _dvec.has(iso) or _dvec[iso].size() != nc:
				var nv = PackedFloat64Array()
				nv.resize(nc)
				_dvec[iso] = nv
			_dvec[iso][ci] = dn
		world_demand[cid] = total
	return end

var _dvec = {}  # JUAN5: iso -> posledny dopyt po komoditach (tier 2 mimo svojho dna)
var _ram_day = -1
var _ram = false
# JUAN5: = EventSystem.supply_mult, ale ramadan tabulka sa pocita raz za den
func _supply_ev(iso: String, cid: String) -> float:
	if _ram_day != GameState.day_index:
		_ram_day = GameState.day_index
		_ram = EventSystem._in_table(EventSystem.RAMADAN, 30)
	var c: Dictionary = GameState.world.get(iso, {})
	var m = 1.0
	var seas: Array = DataLoader.commodity(cid).get("season_prod", [1, 1, 1, 1])
	var si = TimeSystem.season_index(float(c.get("lat", 0.0)))
	if si < seas.size():
		m *= float(seas[si])
	var weather = str(c.get("weather", "clear"))
	if weather != "clear":
		if weather == "drought" and cid in ["wheat", "coffee", "meat"]:
			m *= 0.62
		if weather == "storm" and cid in ["construction", "logistics", "wheat"]:
			m *= 0.78
		if weather == "cold" and cid == "construction":
			m *= 0.7
	var grp = str(c.get("holiday_group", ""))
	if _ram and grp == "muslim":
		m *= 0.93
	if grp.begins_with("christian") and int(GameState.date.m) == 12 and int(GameState.date.d) >= 24 and cid in ["steel", "automobiles", "electronics"]:
		m *= 0.82
	return m

func _build_day_cache() -> void:
	_rivals.clear()
	for firm in GameState.firms:
		if not firm.get("closed", false):
			var c = str(firm.get("country", ""))
			_rivals[c] = int(_rivals.get(c, 0)) + 1
	_war_set.clear()
	for w in GameState.wars:
		for x in w.get("a", []):
			_war_set[str(x)] = true
		for y in w.get("b", []):
			_war_set[str(y)] = true

# JUAN5: denny kontext krajiny (rovnake vzorce ako demand_factors/_one_demand, len bez opakovanych lookupov)
func _books_of(iso: String) -> Dictionary:
	if not GameState.markets.has(iso):
		GameState.markets[iso] = {}
	return GameState.markets[iso]

func _ctx(iso: String) -> Dictionary:
	var c: Dictionary = GameState.world[iso]
	var cen: Dictionary = GameState.central.get(iso, {})
	var gpc = float(c.get("gdp_pc_usd", c.get("gdp_per_capita", 10000.0)))
	return {
		"income": max(gpc / 20000.0, 0.05),
		"rich": EconMath.rich_index(float(c.get("gdp_pc_usd", 10000.0))),
		"weather": str(c.get("weather", "clear")),
		"comp": 1.0 / (1.0 + 0.08 * float(int(_rivals.get(iso, 0)))),
		"hot": _war_set.has(iso),
		"pop": float(c.get("population", 0.0)),
		"gdp_eur": float(c.get("gdp_usd", 0.0)) / max(GameState.usd_per_eur, 0.2),
		"unemp": EconMath.cl(1.0 - max(0.0, float(c.get("unemployment", 0.05)) - 0.04) * 0.8, 0.45, 1.15),
		"rate": float(cen.get("base_rate", cen.get("policy", 0.02))),
		"mil": float(c.get("military_share", 0.015)),
		"books": _books_of(iso),
		"grp": str(c.get("holiday_group", "secular")),
	}

func _factors_fast(iso: String, x: Dictionary, cid: String, tod: float) -> Dictionary:
	var weather = EventSystem.weather_factor(x.weather, cid)
	var holiday = EventSystem.holiday_factor(iso, cid)
	var geo = GeopoliticsSystem.conflict_demand(x.hot, cid)
	var population: float = x.pop
	var product = population * float(x.income) * tod * weather * holiday * float(x.comp) * geo
	return {"population": population, "income_factor": x.income, "time_of_day_factor": tod, "weather_factor": weather,
		"holiday_factor": holiday, "competition_factor": x.comp, "geopolitics_factor": geo, "product": product}

func _demand_fast(x: Dictionary, cid: String, com: Dictionary, px: float, f: Dictionary, neutral: bool) -> float:
	var gdp_eur: float = x.gdp_eur
	var w = float(com.get("weight", 0.01))
	w *= lerpf(float(com.get("poor_mult", 1.0)), float(com.get("rich_mult", 1.0)), float(x.rich))
	var spend = gdp_eur * w / 365.0
	var qty = spend / max(px, 0.05)
	var elas = float(com.get("elasticity", 0.4))
	qty *= pow(max(float(com.get("base_price", px)), 0.05) / max(px, 0.05), elas)
	qty *= float(f.product) / max(float(f.population), 1.0)
	if neutral:
		qty /= max(float(f.time_of_day_factor), 0.01)
	qty *= float(x.unemp)
	if cid == "finance":
		qty += BankingSystem.capital_demand(float(x.rate), gdp_eur) / 365.0 / max(px, 0.05)
	if cid == "weapons" or cid == "arms":
		qty += (gdp_eur * float(x.mil) * 0.22 / 365.0) / max(px, 0.05)
	return max(0.0, qty)

func _cache_demand(lod: bool = false) -> void:
	if lod:
		_cache_demand_fast()
		return
	_build_day_cache()
	_rivals_valid = true
	_fast_f = false
	_fc.clear()
	world_demand.clear()
	if not lod:
		d_now.clear()
		d_ref.clear()
	for cid in DataLoader.commodity_ids:
		var total = 0.0
		var base = float(DataLoader.commodity(cid).get("base_price", 1.0))
		for iso in DataLoader.country_ids:
			var k = iso + "|" + cid
			if lod and not _active.has(iso) and d_now.has(k):
				total += float(d_now[k])  # JUAN5: tier 2 mimo svojho dna drzi posledny dopyt
				continue
			var dn = _one_demand(iso, cid, -1.0, true)
			d_now[k] = dn
			d_ref[k] = _one_demand(iso, cid, base, true, true)
			total += dn
		world_demand[cid] = total
	_rivals_valid = false

func _update_capacity(lod: bool = false) -> void:
	_update_capacity_chunk(0, DataLoader.country_ids.size(), lod)

func _update_capacity_chunk(start: int, count: int, lod: bool = false) -> int:
	var end = mini(start + count, DataLoader.country_ids.size())
	for index in range(start, end):
		var iso = str(DataLoader.country_ids[index])
		if lod and not _active.has(iso):
			continue
		var steps = int(_dt.get(iso, 1)) if lod else 1
		var tau = CAP_TAU if steps <= 1 else 1.0 / (1.0 - pow(1.0 - 1.0 / CAP_TAU, steps))
		for cid in DataLoader.commodity_ids:
			var book: Dictionary = _book(iso, cid)
			var dr = float(d_ref.get(iso + "|" + cid, 0.0))
			var cur = float(book.get("dref", 0.0))
			if cur <= 0.0 or EconMath.is_bad(cur):
				book.dref = dr
			else:
				book.dref = cur + (dr - cur) / tau
	return end

func _season_prod(iso: String, cid: String) -> float:
	var c: Dictionary = GameState.world.get(iso, {})
	var seas: Array = DataLoader.commodity(cid).get("season_prod", [1, 1, 1, 1])
	var si = TimeSystem.season_index(float(c.get("lat", 0.0)))
	if si < seas.size():
		return max(float(seas[si]), 0.05)
	return 1.0

# otvorenost obchodu krajiny: 1 = bez blokad; klesa podla podielu HDP partnerov pod sankciou/embargom/vojnou
func _openness() -> Dictionary:
	# JUAN5: rovnaky vysledok ako povodna O(n^2) slucka cez blocked(), ale len cez realne blokovane dvojice
	var out = {}
	var total = 0.0
	var gdp = {}
	for iso in DataLoader.country_ids:
		var g = float(GameState.world.get(iso, {}).get("gdp_usd", 0.0))
		gdp[iso] = g
		total += g
	var partners = {}  # iso -> {partner: true}
	var _pair = func(a: String, b: String) -> void:
		if a == b or not gdp.has(a) or not gdp.has(b):
			return
		if not partners.has(a):
			partners[a] = {}
		if not partners.has(b):
			partners[b] = {}
		partners[a][b] = true
		partners[b][a] = true
	for bucket in [GameState.sanctions, GameState.embargoes]:
		for k in bucket:
			var p = str(k).split("|")
			if p.size() == 2:
				_pair.call(p[0], p[1])
	for k in GameState.relations.keys():
		if int(GameState.relations[k]) <= -60:
			var p2 = str(k).split("|")
			if p2.size() == 2:
				_pair.call(p2[0], p2[1])
	for w in GameState.wars:
		for x in w.get("a", []):
			for y in w.get("b", []):
				_pair.call(str(x), str(y))
	var un = {}
	for k in GameState.un_sanctions:
		var s = str(k)
		if s.begins_with("UN|"):
			un[s.substr(3)] = true
	for a in DataLoader.country_ids:
		var ga = float(gdp[a])
		var others = max(total - ga, 1.0)
		var blocked_gdp = 0.0
		if un.has(a):
			blocked_gdp = total - ga
		else:
			var seen: Dictionary = partners.get(a, {})
			for b in seen.keys():
				blocked_gdp += float(gdp[b])
			for b2 in un.keys():
				if b2 != a and gdp.has(b2) and not seen.has(b2):
					blocked_gdp += float(gdp[b2])
		var open = 1.0 - blocked_gdp / others
		if _war_set.has(str(a)):
			open *= WAR_OPENNESS
		out[str(a)] = clampf(open, 0.0, 1.0)
	return out

# Ponuka krajiny po obchode (etapa 1): produkcia P = svetova kapacita x normalizovany podiel x supply sok;
# obchod rozdeli svetovu ponuku podla dopytu s otvorenostou phi: S = (1-phi)*P + phi*f*dref, f = sum(P)/sum(dref).
# Sluzby (netradovatelne) = lokalna kapacita x sok. Bez soku a pri phi=1 je S = dref (trh v rovnovahe).
func _cache_supply(lod: bool = false) -> void:
	_supply_prepare(lod)
	_supply_chunk(0, DataLoader.commodity_ids.size())

var _sp_ids: Array = []
var _sp_books: Array = []
var _sp_phis := PackedFloat64Array()
var _sp_act: Array = []
var _sp_sis: Array = []
var _sp_wths: Array = []
var _sp_grps: Array = []
var _sp_gmul := PackedFloat64Array()

func _supply_prepare(lod: bool) -> void:
	if not lod:
		sup_day.clear()
		_prod_c.clear()
	var open = _openness()
	var ids: Array = DataLoader.country_ids
	var n = ids.size()
	var books: Array = []
	var phis = PackedFloat64Array()
	var act: Array = []
	var sis: Array = []
	var wths: Array = []
	var grps: Array = []
	var gmul = PackedFloat64Array()
	if _ram_day != GameState.day_index:
		_ram_day = GameState.day_index
		_ram = EventSystem._in_table(EventSystem.RAMADAN, 30)
	for iso in ids:
		if not GameState.markets.has(iso):
			GameState.markets[iso] = {}
		books.append(GameState.markets[iso])
		phis.append(float(open.get(iso, 1.0)))
		act.append((not lod) or _active.has(iso))
		var cw: Dictionary = GameState.world.get(iso, {})
		sis.append(TimeSystem.season_index(float(cw.get("lat", 0.0))))
		wths.append(str(cw.get("weather", "clear")))
		grps.append(str(cw.get("holiday_group", "")))
		gmul.append((0.82 if _war_set.has(iso) else 1.0) * (0.75 if bool(cw.get("infra_damage", false)) else 1.0))
	_sp_ids = ids
	_sp_books = books
	_sp_phis = phis
	_sp_act = act
	_sp_sis = sis
	_sp_wths = wths
	_sp_grps = grps
	_sp_gmul = gmul

func _supply_chunk(start: int, count: int) -> int:
	var ids = _sp_ids
	var books = _sp_books
	var phis = _sp_phis
	var act = _sp_act
	var sis = _sp_sis
	var wths = _sp_wths
	var grps = _sp_grps
	var gmul = _sp_gmul
	var n = ids.size()
	var drs = PackedFloat64Array()
	drs.resize(n)
	var prod = PackedFloat64Array()
	prod.resize(n)
	var ncid = DataLoader.commodity_ids.size()
	var end = mini(start + count, ncid)
	for ci in range(start, end):
		var cid = DataLoader.commodity_ids[ci]
		var tradable = bool(DataLoader.commodity(cid).get("tradable", false))
		var seas: Array = DataLoader.commodity(cid).get("season_prod", [1, 1, 1, 1])
		var xmas_sup = int(GameState.date.m) == 12 and int(GameState.date.d) >= 24 and cid in ["steel", "automobiles", "electronics"]
		var dw = 0.0
		var tp = 0.0
		for i in n:
			var bk: Dictionary = books[i]
			if not bk.has(cid):
				bk[cid] = default_book(cid)
			var d = float(bk[cid].get("dref", 0.0))
			drs[i] = d
			dw += d
		var shares: Dictionary = DataLoader._share_cache[cid] if DataLoader._share_cache.has(cid) else {}
		if shares.is_empty():
			DataLoader.share(cid, str(ids[0]))
			shares = DataLoader._share_cache.get(cid, {})
		for i in n:
			# sezonna produkcia sa vyhladzuje zasobami (priemer za rok = dopyt), preto sa z soku vyberie; tazba (susko, burka, vojna) ostava
			var iso2: String = ids[i]
			var m: float
			var pv: PackedFloat64Array = _prod_c.get(iso2, PackedFloat64Array())
			if not act[i] and pv.size() == ncid:
				m = pv[ci]  # JUAN5: tier 2 - sok z posledneho prepoctu
			else:
				var si: int = sis[i]
				var sv = float(seas[si]) if si < seas.size() else 1.0
				var m_ev = sv if si < seas.size() else 1.0
				var wt: String = wths[i]
				if wt != "clear":
					if wt == "drought" and cid in ["wheat", "coffee", "meat"]:
						m_ev *= 0.62
					if wt == "storm" and cid in ["construction", "logistics", "wheat"]:
						m_ev *= 0.78
					if wt == "cold" and cid == "construction":
						m_ev *= 0.7
				if _ram and grps[i] == "muslim":
					m_ev *= 0.93
				if xmas_sup and str(grps[i]).begins_with("christian"):
					m_ev *= 0.82
				var sp = max(sv, 0.05) if si < seas.size() else 1.0
				m = m_ev / sp * gmul[i]
				if pv.size() != ncid:
					pv.resize(ncid)
				pv[ci] = m
				_prod_c[iso2] = pv
			var p = dw * float(shares.get(iso2, 0.0)) * m if tradable else drs[i] * m
			prod[i] = p
			tp += p
		var f = clampf(tp / dw, 0.3, 2.0) if (tp > 0.0 and dw > 0.0) else 1.0
		for i in n:
			if not act[i] and sup_day.has(str(ids[i]) + "|" + cid):
				continue
			var dr3 = drs[i]
			var s2 = prod[i]
			if tradable:
				var phi = phis[i]
				s2 = (1.0 - phi) * s2 + phi * f * dr3
			sup_day[str(ids[i]) + "|" + cid] = max(s2, 0.05 * dr3)
	return end

# neutral = referencny dopyt bez tyzdnoveho cyklu (tod): kapacita sa nema ladit na pracovny den
func _one_demand(iso: String, cid: String, px_override: float = -1.0, cached: bool = false, neutral: bool = false) -> float:
	if not GameState.world.has(iso):
		return 0.0
	var c: Dictionary = GameState.world[iso]
	var com: Dictionary = DataLoader.commodity(cid)
	var gdp_eur = float(c.get("gdp_usd", 0.0)) / max(GameState.usd_per_eur, 0.2)
	var rich = EconMath.rich_index(float(c.get("gdp_pc_usd", 10000.0)))
	var w = float(com.get("weight", 0.01))
	w *= lerpf(float(com.get("poor_mult", 1.0)), float(com.get("rich_mult", 1.0)), rich)
	var spend = gdp_eur * w / 365.0
	var px = px_override if px_override > 0.0 else price(iso, cid)
	var qty = spend / max(px, 0.05)
	var elas = float(com.get("elasticity", 0.4))
	qty *= pow(max(float(com.get("base_price", px)), 0.05) / max(px, 0.05), elas)
	var factors = _factors_cached(iso, cid) if cached else demand_factors(iso, cid)
	# etapa 1: populacia je uz v spend (HDP), preto sa z product odstrani (predtym /1e6 = dvojite zapocitanie)
	qty *= float(factors.product) / max(float(factors.population), 1.0)
	if neutral:
		qty /= max(float(factors.time_of_day_factor), 0.01)
	var unemp = float(c.get("unemployment", 0.05))
	qty *= EconMath.cl(1.0 - max(0.0, unemp - 0.04) * 0.8, 0.45, 1.15)
	var rate = float(GameState.central.get(iso, {}).get("base_rate", GameState.central.get(iso, {}).get("policy", 0.02)))
	if cid == "finance":
		# etapa 1: capital_demand je v EUR, nie v jednotkach; delenie cenou robi dopyt cenovo citlivy (predtym cenovo nepruzny)
		qty += BankingSystem.capital_demand(rate, gdp_eur) / 365.0 / max(px, 0.05)
	if cid == "weapons" or cid == "arms":
		var mil = float(c.get("military_share", 0.015))
		qty += (gdp_eur * mil * 0.22 / 365.0) / max(px, 0.05)
	return max(0.0, qty)
