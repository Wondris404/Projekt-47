extends Node
# JUAN19: zeleznice, ropovody/plynovody, bonus logistickej firmy, doprava vstupov (vlastne vs kupene)
const KM_PER_UNIT = 27.8  # 1 jednotka mapy ~ 0.25 stupna ~ 27.8 km
const RAIL_KM = 45000.0
const PIPE_KM = 30000.0
const RAIL_CAP = 600.0  # jednotiek tovaru za den
const PIPE_CAP = 900.0
const CONNECT = 0.6  # firma do ~17 km od trate je napojena
const RAIL_CUT = 0.6
const PIPE_CUT = 0.85
const LOGI_CUT = 0.9
const MARKET_TRANSPORT = 0.06  # doprava pri nakupe od konkurencie (podiel z ceny)
const SALES_TRANSPORT = 0.03  # doprava predanych vyrobkov k odberatelom/pristavom
const PIPE_GOODS = ["crude_oil", "natural_gas", "fuel"]
const GOODS = ["wheat", "coffee", "meat", "crude_oil", "coal", "iron_ore", "copper", "steel", "chemicals", "pharma", "textiles", "electronics", "automobiles", "weapons", "arms", "fuel", "natural_gas"]
const KIND_NAME = {"rail": "Železnica", "pipe": "Ropovod / plynovod"}
var _day := -1
var _revision := -1

func st() -> Dictionary:
	if typeof(GameState.get("ext")) != TYPE_DICTIONARY:
		GameState.ext = {}
	if not GameState.ext.has("transport") or typeof(GameState.ext.transport) != TYPE_DICTIONARY:
		GameState.ext["transport"] = {}
	var s: Dictionary = GameState.ext.transport
	if not s.has("lines"):
		s["lines"] = []
	if not s.has("seq"):
		s["seq"] = 0
	return s

func lines() -> Array:
	return st().lines

func km(a: Vector2, b: Vector2) -> float:
	return a.distance_to(b) * KM_PER_UNIT

func line_cost(kind: String, a: Vector2, b: Vector2) -> float:
	return km(a, b) * (RAIL_KM if kind == "rail" else PIPE_KM) * Difficulty.cost_mult()

func build_line(kind: String, a: Vector2, b: Vector2) -> String:
	if not kind in ["rail", "pipe"]:
		return "Neznámy typ trate."
	var k = km(a, b)
	if k < 10.0:
		return "Trasa je príliš krátka (min. 10 km)."
	if k > 2500.0:
		return "Trasa je príliš dlhá (max. 2 500 km) – rozdeľ ju na úseky."
	var cost = line_cost(kind, a, b)
	if float(GameState.player.cash) < cost:
		return "Na %s (%.0f km) treba %s." % [KIND_NAME[kind], k, EconMath.eur(cost)]
	GameState.player.cash = float(GameState.player.cash) - cost
	var s = st()
	s.seq = int(s.seq) + 1
	s.lines.append({"id": "L%d" % int(s.seq), "kind": kind, "a": [a.x, a.y], "b": [b.x, b.y], "km": k, "cap": RAIL_CAP if kind == "rail" else PIPE_CAP, "used": 0.0, "used_prev": 0.0})
	GameState.post_news("%s postavená: %.0f km za %s." % [KIND_NAME[kind], k, EconMath.eur(cost)])
	return ""

static func _pt(v) -> Vector2:
	return Vector2(float(v[0]), float(v[1]))

static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var t = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
	return p.distance_to(a + ab * t)

# JUAN23: cache (pamat za rychlost) - platna v ramci jedneho snimku/dna a rovnakeho poctu firiem/liniek
var _csig := ""
var _c_wp := {}
var _c_dpos := {}
var _c_conn := {}
var _c_disc := {}
var _c_hub := {}
var _c_cap := {}
const _WM = preload("res://scripts/ui/world_map.gd")

func _cache_ok() -> void:
	var sig = "%d|%d|%d|%d|%d" % [GameState.state_revision, Engine.get_process_frames(), GameState.day_index, GameState.firms.size(), lines().size()]
	if sig != _csig:
		_csig = sig
		_c_wp.clear(); _c_dpos.clear(); _c_conn.clear(); _c_disc.clear(); _c_hub.clear()

func invalidate() -> void:
	_csig = ""

func firm_wp(f: Dictionary) -> Vector2:
	var p = IndustrySystem.firm_pos(f)
	if p != null:
		return p
	_cache_ok()
	var fid = str(f.get("id", ""))
	if _c_wp.has(fid):
		return _c_wp[fid]
	var iso = str(f.get("country", ""))
	if not _c_cap.has(iso):
		var c: Dictionary = DataLoader.countries.get(iso, {})
		_c_cap[iso] = _WM.project(float(c.get("capital_lat", c.get("lat", 0.0))), float(c.get("capital_lon", c.get("lon", 0.0))))
	var r = default_pos(f, _c_cap[iso])
	_c_wp[fid] = r
	return r

# neumiestnena firma: spirala blizko hlavneho mesta (namiesto radu stovky km na vychod)
func default_pos(firm: Dictionary, cap: Vector2) -> Vector2:
	_cache_ok()
	if _c_dpos.is_empty():  # JUAN23: poradie neumiestnenych firiem v krajine raz za snimok/den (predtym O(n) na volanie)
		var cnt := {}
		for f2 in GameState.firms:
			var i2 = str(f2.get("country", ""))
			_c_dpos[str(f2.get("id", ""))] = int(cnt.get(i2, 0))
			if not bool(f2.get("closed", false)) and IndustrySystem.firm_pos(f2) == null:
				cnt[i2] = int(cnt.get(i2, 0)) + 1
	var idx = int(_c_dpos.get(str(firm.get("id", "")), 0))
	var a = float(idx) * 2.39996
	return cap + Vector2(cos(a), sin(a)) * (0.9 + 0.22 * sqrt(float(idx)))

func connected(f: Dictionary, kind: String) -> Array:
	_cache_ok()
	var ck = str(f.get("id", "")) + kind + str(f.get("pos", ""))
	if _c_conn.has(ck):
		return _c_conn[ck]
	var out: Array = []
	var p = firm_wp(f)
	for l in lines():
		if str(l.kind) == kind and seg_dist(p, _pt(l.a), _pt(l.b)) <= CONNECT:
			out.append(l)
	_c_conn[ck] = out
	return out

func _capf(ls: Array) -> float:
	var best = 0.0
	for l in ls:
		var up = float(l.get("used_prev", 0.0))
		best = maxf(best, 1.0 if up <= float(l.cap) else float(l.cap) / up)
	return best

# logisticka firma: dosah X km a Y % objemu takmer zadarmo; X/Y rastu s urovnou a velkostou
func logi_params(h: Dictionary) -> Dictionary:
	var lvl = IndustrySystem.firm_level(h)
	var sc = 1.0
	for fac in h.get("facilities", []):
		sc = maxf(sc, float(fac.get("scale", 1.0)))
	return {"km": 150.0 * lvl * sqrt(sc), "share": minf(0.9, 0.3 * lvl * sqrt(sc))}

func logi_hub_for(f: Dictionary) -> Dictionary:
	_cache_ok()
	var hk = str(f.get("id", "")) + str(f.get("pos", ""))
	if _c_hub.has(hk):
		return _c_hub[hk]
	var r = _logi_hub_for0(f)
	_c_hub[hk] = r
	return r

func _logi_hub_for0(f: Dictionary) -> Dictionary:
	var p = firm_wp(f)
	var best: Dictionary = {}
	var best_s = 0.0
	for h in GameState.player_firms():
		if str(h.get("industry", "")) != "logistics_hub":
			continue
		var lp = logi_params(h)
		if km(p, firm_wp(h)) <= float(lp.km) and float(lp.share) > best_s:
			best_s = float(lp.share)
			best = h
	return best

func discount(f: Dictionary, cid: String) -> Dictionary:
	_cache_ok()
	var dk = str(f.get("id", "")) + "|" + cid + str(f.get("pos", ""))
	if _c_disc.has(dk):
		return _c_disc[dk]
	var r = _discount0(f, cid)
	_c_disc[dk] = r
	return r

func _discount0(f: Dictionary, cid: String) -> Dictionary:
	var rail = 0.0
	var pipe = 0.0
	var logi = 0.0
	if cid in GOODS:
		var rl = connected(f, "rail")
		if not rl.is_empty():
			rail = RAIL_CUT * _capf(rl)
		if cid in PIPE_GOODS:
			var pl = connected(f, "pipe")
			if not pl.is_empty():
				pipe = PIPE_CUT * _capf(pl)
	var hub = logi_hub_for(f)
	if not hub.is_empty():
		logi = float(logi_params(hub).share) * LOGI_CUT
	var port = Society.port_discount(f) if cid in GOODS else 0.0  # JUAN-P47: vlastny nakladny pristav v krajine
	var d = 1.0 - (1.0 - rail) * (1.0 - pipe) * (1.0 - logi) * (1.0 - port)
	return {"d": d, "rail": rail, "pipe": pipe, "logi": logi, "port": port, "hub": str(hub.get("id", ""))}

func begin_day() -> void:
	if _day == GameState.day_index and _revision == GameState.state_revision:
		return
	_day = GameState.day_index
	_revision = GameState.state_revision
	invalidate()
	for l in lines():
		l.used_prev = float(l.get("used", 0.0))
		l.used = 0.0

func use(f: Dictionary, cid: String, qty: float) -> void:
	if qty <= 0.0 or not cid in GOODS:
		return
	for l in connected(f, "rail"):
		l.used = float(l.used) + qty
	if cid in PIPE_GOODS:
		for l2 in connected(f, "pipe"):
			l2.used = float(l2.used) + qty

func utilization(l: Dictionary) -> float:
	return float(l.get("used_prev", 0.0)) / maxf(float(l.get("cap", 1.0)), 1.0)

# zaznam zdrojov vstupov (vlastne vs kupene) a uspor - klzavych 30 dni
func log_input(f: Dictionary, cid: String, own: float, bought: float, transport_eur: float, saved: float, hub_id: String, logi_part: float) -> void:
	if not f.has("supply") or typeof(f.supply) != TYPE_DICTIONARY:
		f["supply"] = {}
	var day = int(GameState.day_index)
	if int(f.get("supply_day0", -1)) < 0 or day - int(f.get("supply_day0", 0)) >= 30:
		f["supply_prev"] = f.supply
		f["supply"] = {}
		f["supply_day0"] = day
	var row: Dictionary = f.supply.get(cid, {"own": 0.0, "bought": 0.0, "transport": 0.0, "saved": 0.0})
	row.own = float(row.own) + own
	row.bought = float(row.bought) + bought
	row.transport = float(row.transport) + transport_eur
	row.saved = float(row.saved) + saved
	f.supply[cid] = row
	if hub_id != "" and logi_part > 0.0:
		var h = GameState.firm_by_id(hub_id)
		if not h.is_empty():
			h["logi_saved"] = float(h.get("logi_saved", 0.0)) + logi_part

func supply_text(f: Dictionary) -> String:
	var sup: Dictionary = f.get("supply", {})
	if sup.is_empty():
		sup = f.get("supply_prev", {})
	var out = "ZDROJE VSTUPOV A DOPRAVA (posledných ~30 dní):\n"
	if sup.is_empty():
		out += "• zatiaľ žiadne nákupy\n"
	for cid in sup.keys():
		var r: Dictionary = sup[cid]
		var tot = float(r.own) + float(r.bought)
		var nm = str(DataLoader.commodity(cid).get("name", cid))
		out += "• %s: vlastné %.1f (%.0f %%) · kúpené od konkurencie %.1f · doprava %s · ušetrené %s\n" % [nm, float(r.own), float(r.own) / maxf(tot, 0.001) * 100.0, float(r.bought), EconMath.eur(float(r.transport)), EconMath.eur(float(r.saved))]
	var d = discount(f, "steel")
	var parts: Array = []
	if float(d.rail) > 0.0:
		parts.append("železnica −%.0f %%" % (float(d.rail) * 100.0))
	var dp = discount(f, "crude_oil")
	if float(dp.pipe) > 0.0:
		parts.append("ropovod/plynovod −%.0f %% (ropa, plyn, palivá)" % (float(dp.pipe) * 100.0))
	if float(d.logi) > 0.0:
		parts.append("logistika −%.0f %%" % (float(d.logi) * 100.0))
	out += "Zľavy na dopravu: %s\n" % (", ".join(parts) if not parts.is_empty() else "žiadne (postav železnicu, ropovod alebo logistickú firmu)")
	out += "Vlastný dodávateľ v tej istej korporácii a krajine = platíš len dopravu (%.0f %% ceny). Inak kupuješ od konkurencie: cena + doprava (%.0f %% ceny).\n" % [IndustrySystem.TRANSPORT_SHARE * 100.0, MARKET_TRANSPORT * 100.0]
	if str(f.get("industry", "")) == "logistics_hub":
		var lp = logi_params(f)
		out += "LOGISTIKA: dosah %.0f km, %.0f %% prepravy tvojich firiem v dosahu takmer zadarmo (−%.0f %%). Ušetrené spolu: %s\n" % [float(lp.km), float(lp.share) * 100.0, LOGI_CUT * 100.0, EconMath.eur(float(f.get("logi_saved", 0.0)))]
	return out
