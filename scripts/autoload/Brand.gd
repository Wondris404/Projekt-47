extends Node
# JUAN21: logá korporácií, premenovanie firiem/korporácií, parodické názvy na burze, sledovanie predaných vozidiel, AI bonus.
# Save: GameState.ext.brand = {logos: {corp_id: {...}}, products: {firm_id: {cid: {iso: qty}}}}

const SHAPES = {"circle": "Kruh", "square": "Štvorec", "shield": "Štít", "hex": "Šesťuholník", "diamond": "Kosoštvorec"}
const SYMBOLS = {"none": "Bez symbolu", "star": "Hviezda", "bolt": "Blesk", "leaf": "List", "crown": "Koruna", "mountain": "Hora", "drop": "Kvapka", "arrow": "Šípka", "wave": "Vlna", "gear": "Ozubené koleso", "globe": "Glóbus"}
const VEHICLES = {"automobiles": "Autá", "ships": "Lode", "aircraft": "Lietadlá"}
const AI_BOOST_EACH = 0.04
const AI_BOOST_MAX = 0.12

func st() -> Dictionary:
	if not GameState.ext.has("brand") or typeof(GameState.ext.brand) != TYPE_DICTIONARY:
		GameState.ext["brand"] = {}
	var b: Dictionary = GameState.ext.brand
	for k in ["logos", "products"]:
		if not b.has(k):
			b[k] = {}
	return b

# ---------------- logo ----------------
func default_logo(cid: String) -> Dictionary:
	var h = absi(hash(cid))
	var c: Dictionary = StockMarket.ex().get("corps", {}).get(cid, {})
	var nm = str(c.get("name", "P47"))
	var ini = ""
	for w in nm.split(" ", false):
		ini += w.substr(0, 1).to_upper()
	return {"shape": SHAPES.keys()[h % SHAPES.size()], "bg": Color.from_hsv(float(h % 360) / 360.0, 0.6, 0.55).to_html(false), "fg": "F2EAD6", "symbol": SYMBOLS.keys()[1 + h % (SYMBOLS.size() - 1)], "text": ini.substr(0, 3)}

func logo(cid: String) -> Dictionary:
	var l = st().logos.get(cid, {})
	return l if not l.is_empty() else default_logo(cid)

func has_custom_logo(cid: String) -> bool:
	return st().logos.has(cid)

func set_logo(cid: String, l: Dictionary) -> String:
	if not StockMarket.ex().get("corps", {}).has(cid):
		return "Korporácia neexistuje."
	if not SHAPES.has(str(l.get("shape", ""))) or not SYMBOLS.has(str(l.get("symbol", ""))):
		return "Neplatný tvar alebo symbol."
	st().logos[cid] = {"shape": str(l.shape), "bg": str(l.get("bg", "335577")), "fg": str(l.get("fg", "FFFFFF")), "symbol": str(l.symbol), "text": str(l.get("text", "")).strip_edges().substr(0, 4)}
	_tex.erase(cid)
	return ""

func shape_poly(shape: String, n: int = 28) -> PackedVector2Array:
	var p = PackedVector2Array()
	match shape:
		"square":
			p = PackedVector2Array([Vector2(-0.9, -0.9), Vector2(0.9, -0.9), Vector2(0.9, 0.9), Vector2(-0.9, 0.9)])
		"shield":
			p = PackedVector2Array([Vector2(-0.85, -0.9), Vector2(0.85, -0.9), Vector2(0.85, 0.1), Vector2(0.5, 0.6), Vector2(0, 0.95), Vector2(-0.5, 0.6), Vector2(-0.85, 0.1)])
		"hex":
			for i in 6:
				var a = TAU * i / 6.0 + PI / 6.0
				p.append(Vector2(cos(a), sin(a)) * 0.95)
		"diamond":
			p = PackedVector2Array([Vector2(0, -0.98), Vector2(0.98, 0), Vector2(0, 0.98), Vector2(-0.98, 0)])
		_:
			for i in n:
				var a2 = TAU * i / float(n)
				p.append(Vector2(cos(a2), sin(a2)) * 0.95)
	return p

# symbol: zoznam polygonov v jednotkovych suradniciach (-1..1)
func symbol_polys(sym: String) -> Array:
	var out: Array = []
	match sym:
		"star":
			var p = PackedVector2Array()
			for i in 10:
				var a = -PI / 2 + TAU * i / 10.0
				p.append(Vector2(cos(a), sin(a)) * (0.55 if i % 2 == 0 else 0.23))
			out.append(p)
		"bolt":
			out.append(PackedVector2Array([Vector2(0.1, -0.6), Vector2(-0.35, 0.08), Vector2(-0.02, 0.08), Vector2(-0.12, 0.6), Vector2(0.35, -0.1), Vector2(0.02, -0.1)]))
		"leaf":
			var q = PackedVector2Array()
			for i in 16:
				var t = float(i) / 15.0
				q.append(Vector2(lerpf(-0.45, 0.45, t), -sin(t * PI) * 0.3 + (t - 0.5) * -0.5))
			for i in 16:
				var t2 = 1.0 - float(i) / 15.0
				q.append(Vector2(lerpf(-0.45, 0.45, t2), sin(t2 * PI) * 0.18 + (t2 - 0.5) * -0.5))
			out.append(q)
		"crown":
			out.append(PackedVector2Array([Vector2(-0.5, 0.35), Vector2(-0.5, -0.3), Vector2(-0.25, 0.0), Vector2(0, -0.45), Vector2(0.25, 0.0), Vector2(0.5, -0.3), Vector2(0.5, 0.35)]))
		"mountain":
			out.append(PackedVector2Array([Vector2(-0.6, 0.4), Vector2(-0.15, -0.4), Vector2(0.1, 0.0), Vector2(0.25, -0.2), Vector2(0.6, 0.4)]))
		"drop":
			var d = PackedVector2Array([Vector2(0, -0.55)])
			for i in 13:
				var a3 = -PI * 0.15 + PI * 1.3 * i / 12.0
				d.append(Vector2(cos(a3) * 0.3, 0.15 + sin(a3) * 0.3))
			out.append(d)
		"arrow":
			out.append(PackedVector2Array([Vector2(-0.5, 0.12), Vector2(0.1, 0.12), Vector2(0.1, 0.35), Vector2(0.55, 0), Vector2(0.1, -0.35), Vector2(0.1, -0.12), Vector2(-0.5, -0.12)]))
		"wave":
			for k in 2:
				var w = PackedVector2Array()
				for i in 13:
					var x = lerpf(-0.6, 0.6, i / 12.0)
					w.append(Vector2(x, -0.1 + k * 0.32 + sin(x * 6.0) * 0.1))
				for i in 13:
					var x2 = lerpf(0.6, -0.6, i / 12.0)
					w.append(Vector2(x2, 0.02 + k * 0.32 + sin(x2 * 6.0) * 0.1))
				out.append(w)
		"gear":
			var g = PackedVector2Array()
			for i in 32:
				var a4 = TAU * i / 32.0
				g.append(Vector2(cos(a4), sin(a4)) * (0.55 if (i / 2) % 2 == 0 else 0.42))
			out.append(g)
		"globe":
			var c = PackedVector2Array()
			for i in 24:
				var a5 = TAU * i / 24.0
				c.append(Vector2(cos(a5), sin(a5)) * 0.5)
			out.append(c)
	return out

# kreslenie loga do lubovolneho CanvasItem (_draw)
func draw_logo(ci: CanvasItem, r: Rect2, l: Dictionary, font: Font = null) -> void:
	var c = r.get_center()
	var s = minf(r.size.x, r.size.y) * 0.5
	var bg = Color(str(l.get("bg", "335577")))
	var fg = Color(str(l.get("fg", "FFFFFF")))
	var sp = shape_poly(str(l.get("shape", "circle")))
	var pts = PackedVector2Array()
	for p in sp:
		pts.append(c + p * s)
	ci.draw_colored_polygon(pts, bg)
	pts.append(pts[0])
	ci.draw_polyline(pts, bg.darkened(0.5), maxf(1.0, s * 0.08), true)
	var txt = str(l.get("text", ""))
	var sym_off = Vector2(0, -0.18 if txt != "" else 0.0)
	var sym_sc = 0.75 if txt != "" else 1.0
	for poly in symbol_polys(str(l.get("symbol", "none"))):
		var q = PackedVector2Array()
		for p2 in poly:
			q.append(c + (p2 * sym_sc + sym_off) * s)
		if str(l.symbol) == "globe":
			ci.draw_polyline(q + PackedVector2Array([q[0]]), fg, maxf(1.0, s * 0.07), true)
			ci.draw_line(c + Vector2(-0.5, 0) * s * sym_sc + sym_off * s, c + Vector2(0.5, 0) * s * sym_sc + sym_off * s, fg, maxf(1.0, s * 0.05))
			ci.draw_arc(c + sym_off * s, s * 0.22 * sym_sc, 0, TAU, 16, fg, maxf(1.0, s * 0.05))
		elif Geometry2D.triangulate_polygon(q).size() > 0:
			ci.draw_colored_polygon(q, fg)
	if txt != "" and font and s >= 9.0:
		var fs = int(clampf(s * (0.62 if txt.length() <= 2 else 0.46), 7.0, 64.0))
		var ts = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var tp = c + Vector2(-ts.x * 0.5, s * 0.62)
		ci.draw_string_outline(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(1, fs / 6), bg.darkened(0.6))
		ci.draw_string(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fg)

# rasterizovane logo (pre ItemList ikony) – bez textu, cache
var _tex: Dictionary = {}
func logo_texture(cid: String, px: int = 24) -> Texture2D:
	var l = logo(cid)
	var key = cid + str(l)
	if _tex.has(key):
		return _tex[key]
	var img = Image.create(px, px, false, Image.FORMAT_RGBA8)
	var sp = shape_poly(str(l.shape))
	var syms = symbol_polys(str(l.symbol))
	var bg = Color(str(l.bg))
	var fg = Color(str(l.fg))
	for y in px:
		for x in px:
			var u = Vector2((x + 0.5) / px * 2.0 - 1.0, (y + 0.5) / px * 2.0 - 1.0)
			if not Geometry2D.is_point_in_polygon(u, sp):
				continue
			var col = bg
			for poly in syms:
				if Geometry2D.is_point_in_polygon(u, poly):
					col = fg
			img.set_pixel(x, y, col)
	var t = ImageTexture.create_from_image(img)
	_tex[key] = t
	return t

# ---------------- premenovanie ----------------
func _clean(nm: String) -> String:
	return nm.strip_edges().replace("\n", " ").substr(0, 40)

func rename_firm(fid: String, nm: String) -> String:
	var f = GameState.firm_by_id(fid)
	if f.is_empty() or str(f.get("owner", "")) != "player":
		return "Môžeš premenovať len svoju firmu."
	var n = _clean(nm)
	if n.length() < 2:
		return "Názov musí mať aspoň 2 znaky."
	var old = str(f.get("name", ""))
	f.name = n
	for row in StockMarket.ex().get("list", {}).values():
		if str(row.get("firm", "")) == fid:
			row.name = n
	GameState.post_news("Firma %s sa premenovala na %s." % [old, n])
	return ""

func rename_corp(cid: String, nm: String) -> String:
	var c: Dictionary = StockMarket.ex().get("corps", {}).get(cid, {})
	if c.is_empty():
		return "Korporácia neexistuje."
	var n = _clean(nm)
	if n.length() < 2:
		return "Názov musí mať aspoň 2 znaky."
	var old = str(c.name)
	c.name = n
	for row in StockMarket.ex().get("list", {}).values():
		if str(row.get("corp", "")) == cid:
			row.name = n
	GameState.post_news("Korporácia %s sa premenovala na %s." % [old, n])
	return ""

# ---------------- parodicke nazvy (satira, ziadne realne logá) ----------------
const PARODY = {
	"tech": ["Mikrosoftt", "Macrohard", "Apfel", "Gugel", "Amazoom", "Metta Platformz", "Nvidea", "Intell Inside-ish", "Orakel", "Samsang", "Sonny", "Adobbe", "IBN"],
	"energy": ["Shall", "Exxoff Mobile", "Bitter Petroleum", "Gazpromm", "Totall Energiez", "Chevrown", "Aramkoo", "Equinoor", "Enell", "Slovnaftt", "Petrobraz", "Rozneft"],
	"bank": ["J.P. Morgun", "Goldman Sax", "Bank of Amerika", "HSBS", "Deutsche Bunk", "UBZ", "Santandor", "BNP Paribaz", "Citigrup", "Morgan Stanly", "Barklays", "Tatra Bunka"],
	"agri": ["Nestlí", "Cargil", "Monsatan", "Danonne", "Unilivr", "Kraft Heinzz", "Tyson Fudz", "Archer Daniels Midlund", "Sinjenta", "Doul", "Čikita", "Bayerr Crop"],
	"arms": ["Lockhead Martini", "Raytheonn", "Boing Defense", "Northrop Grumpman", "BAY Systems", "Rheinmetal Heavy", "Thalez", "Leonardon", "General Dynamix", "Saap", "Kalašnikoff", "Dassolt"],
	"industry": ["Siemenz", "General Elektrik", "Teslo", "Folkswagon", "Toyotta", "BASS-F", "ArcelorMittel", "4M", "Boš", "Caterpiller", "Hyundaj", "Škodda"],
	"transport": ["Mearsk", "FedExx", "UPZ", "DHLL", "Cryanair", "Luftansa", "Ubber", "Boing", "Airbuss", "Deutsche Bahnn", "Emiratez", "Deltta"],
	"media": ["Dizney", "Netflux", "Warmer Bros", "Comcrust", "Paramound", "Sonny Pictures", "Fawks News", "Spotifly", "TikTak", "Bertelsman", "Vivendee", "Markízza"],
	"health": ["Pfizzer", "Jonson & Jonson", "Rošš", "Novartiz", "Murk", "AstraZeneka", "Sanofy", "Bayerr Pharma", "GlaxoSmithKlon", "Modderna", "AbbVee", "Novo Nordysk"],
	"consumer": ["Koka-Kola", "Pepsy", "McDonnald's", "Nikke", "Adidaz", "IKEJA", "L'Oreál", "Proctor & Gambel", "Wallmart", "Starbux", "H&N", "Lidll"],
	"telecom": ["Vodafón", "Verizonn", "AT&TT", "T-Mobil Plus", "Oranž", "Deutsche Telekomm", "Telefonika", "China Mobil", "Ericson", "Nokkia", "Huavej", "O3"],
	"ai": ["Open AJ", "Antrophik", "DeepMynd", "Mistrall", "Palantyr", "Hugging Faze", "CoreWeev", "Equinixx Data", "Digital Realtty", "Kohír", "Stabilitty", "Perplexitty"],
}

# premenuje narodne tituly na parodie (raz na hru; aj starsie savy) – sektory ostavaju
func apply_parody() -> void:
	var x = StockMarket.ex()
	if int(x.get("parody_v", 0)) >= 1 or not x.has("list"):
		return
	var used = {}
	var rows: Array = x.list.values().filter(func(r): return str(r.get("kind", "")) == "nat")
	rows.sort_custom(func(a, b): return str(a.ticker) < str(b.ticker))
	for row in rows:
		var sec = str(row.get("sector", "industry"))
		var pool: Array = PARODY.get(sec, PARODY.industry)
		var nm = ""
		for cand in pool:
			if not used.has(cand):
				nm = str(cand)
				break
		if nm == "":
			nm = "%s %s" % [str(pool[absi(hash(str(row.ticker))) % pool.size()]), str(row.get("iso", ""))]
		used[nm] = true
		row["orig_name"] = str(row.get("name", ""))
		row.name = nm
	x["parody_v"] = 1

# ---------------- vozidla: kam sa predali ----------------
func _dest_pool() -> Array:
	var ids: Array = DataLoader.country_ids.duplicate()
	ids.sort_custom(func(a, b): return float(DataLoader.countries[a].get("gdp_usd", 0)) > float(DataLoader.countries[b].get("gdp_usd", 0)))
	return ids.slice(0, 40)

var _pool: Array = []
func track(fid: String, cid: String, qty: float, market_iso: String) -> void:
	if not VEHICLES.has(cid) or qty <= 0.0:
		return
	var pr: Dictionary = st().products
	if not pr.has(fid):
		pr[fid] = {}
	if not pr[fid].has(cid):
		pr[fid][cid] = {}
	var d: Dictionary = pr[fid][cid]
	# 60 % ostane na domacom trhu, 40 % ide na export (dovozcovia podla HDP)
	d[market_iso] = float(d.get(market_iso, 0.0)) + qty * 0.6
	if _pool.is_empty():
		_pool = _dest_pool()
	var r = RandomNumberGenerator.new()
	r.seed = hash(fid + cid + str(GameState.day_index))
	for k in 2:
		var dest = str(_pool[mini(int(pow(r.randf(), 2.0) * _pool.size()), _pool.size() - 1)])
		if dest == market_iso:
			dest = str(_pool[(k + 1) % _pool.size()])
		d[dest] = float(d.get(dest, 0.0)) + qty * 0.2

func destinations(fid: String) -> Array:
	var out: Array = []
	var pr: Dictionary = st().products.get(fid, {})
	for cid in pr.keys():
		for iso in pr[cid].keys():
			out.append({"cid": str(cid), "iso": str(iso), "qty": float(pr[cid][iso])})
	out.sort_custom(func(a, b): return float(a.qty) > float(b.qty))
	return out

func makes_vehicles(firm: Dictionary) -> bool:
	var r: Dictionary = DataLoader.recipes.get(str(firm.get("recipe", firm.get("industry", ""))), {})
	for o in r.get("outputs", {}).keys():
		if VEHICLES.has(str(o)):
			return true
	return false

func products_text(firm: Dictionary) -> String:
	var rows = destinations(str(firm.get("id", "")))
	if rows.is_empty():
		return "KAM SKONČILI TVOJE VÝROBKY: zatiaľ nič nepredané."
	var tot = 0.0
	for r in rows:
		tot += float(r.qty)
	var t = "KAM SKONČILI TVOJE VÝROBKY (spolu %.1f ks):\n" % tot
	for r in rows.slice(0, 12):
		t += "• %s – %s: %.1f ks (%.0f %%)\n" % [str(GameState.world.get(r.iso, {}).get("name_sk", r.iso)), str(VEHICLES.get(r.cid, r.cid)), float(r.qty), float(r.qty) / maxf(tot, 0.0001) * 100.0]
	return t

# ---------------- AI bonus ----------------
func ai_boost(firm: Dictionary) -> float:
	if str(firm.get("owner", "")) != "player" or str(firm.get("industry", "")) in ["ai_firm", "data_center"]:
		return 1.0
	var iso = str(firm.get("country", ""))
	var n = 0
	for f in GameState.player_firms():
		if str(f.get("industry", "")) == "ai_firm" and str(f.get("country", "")) == iso and not bool(f.get("closed", false)):
			n += 1
	return 1.0 + minf(AI_BOOST_MAX, AI_BOOST_EACH * n)

# ---------------- JUAN22: penetracia medii a telekomu (% obyvatelov krajiny) ----------------
# Pocita sa zivo (nic sa neuklada): strop dosahu typu x prijmovy faktor krajiny, kapacita firmy vs konkurencia (AI firmy + domaci hraci).
const MEDIA = {
	"telecom": {"name": "Telekom", "noun": "zákazníkov", "reach": 0.95, "users": 2500000.0},
	"social_network": {"name": "Sociálna sieť", "noun": "používateľov", "reach": 0.80, "users": 3000000.0},
	"tv_station": {"name": "Televízia", "noun": "divákov", "reach": 0.85, "users": 1500000.0},
	"newspaper": {"name": "Noviny", "noun": "čitateľov", "reach": 0.35, "users": 400000.0},
}
const INCUMBENT_SHARE = 0.6  # domaci hraci drzia kapacitu ~60 % trhu, hrac ich musi vytlacit

func is_media(firm: Dictionary) -> bool:
	return MEDIA.has(str(firm.get("industry", "")))

func _pop(iso: String) -> float:
	return float(GameState.world.get(iso, {}).get("population", DataLoader.countries.get(iso, {}).get("population", 1000000.0)))

func media_cap(iso: String, ind: String) -> float:
	var gdp_pc = float(GameState.world.get(iso, {}).get("gdp_pc_usd", DataLoader.countries.get(iso, {}).get("gdp_pc_usd", 10000.0)))
	var inc = clampf(0.35 + gdp_pc / 40000.0, 0.35, 1.0)
	return float(MEDIA[ind].reach) * inc

func _firm_capacity(f: Dictionary) -> float:
	var ind = str(f.get("industry", ""))
	var lvl = float(IndustrySystem.firm_level(f)) if f.get("owner", "") == "player" else 1.0
	var eff = 1.0
	if f.get("owner", "") == "player":
		var tw = IndustrySystem.target_workers(f)
		eff = clampf(IndustrySystem.workers(f) / tw, 0.2, 1.0) if tw > 0.0 else 1.0
	return float(MEDIA[ind].users) * (1.0 + (lvl - 1.0) * 0.8) * eff

# vysledok: users, pct (z celej populacie), share (podiel na pouzivateloch typu v krajine), cap_pct (strop dosahu)
func media_reach(firm: Dictionary) -> Dictionary:
	var ind = str(firm.get("industry", ""))
	if not MEDIA.has(ind):
		return {}
	var iso = str(firm.get("country", ""))
	var pop = _pop(iso)
	var cap = media_cap(iso, ind)
	var demand = pop * cap
	var caps = 0.0
	for f in GameState.firms:
		if str(f.get("industry", "")) == ind and str(f.get("country", "")) == iso and not bool(f.get("closed", false)):
			caps += _firm_capacity(f)
	var inc = demand * INCUMBENT_SHARE
	var mine = _firm_capacity(firm)
	var users = minf(mine, demand * mine / maxf(caps + inc, 1.0))
	return {"users": users, "pct": users / maxf(pop, 1.0), "share": users / maxf(demand, 1.0), "cap_pct": cap, "pop": pop, "competitors": maxi(0, GameState.firms.filter(func(x): return str(x.get("industry", "")) == ind and str(x.get("country", "")) == iso and not bool(x.get("closed", false))).size() - 1)}

func media_text(firm: Dictionary) -> String:
	var r = media_reach(firm)
	if r.is_empty():
		return ""
	var m: Dictionary = MEDIA[str(firm.industry)]
	return "DOSAH: %.1f %% obyvateľov krajiny (%s %s z %s). Podiel na trhu %.0f %%, strop typu v krajine %.0f %%, konkurenti %d." % [float(r.pct) * 100.0, _fmt_n(float(r.users)), str(m.noun), _fmt_n(float(r.pop)), float(r.share) * 100.0, float(r.cap_pct) * 100.0, int(r.competitors)]

# suhrn za krajinu: % obyvatelov pre kazdy typ, ktory hrac v krajine ma
func country_media(iso: String) -> Array:
	var by = {}
	for f in GameState.player_firms():
		if is_media(f) and str(f.get("country", "")) == iso and not bool(f.get("closed", false)):
			var ind = str(f.industry)
			by[ind] = float(by.get(ind, 0.0)) + float(media_reach(f).users)
	var out: Array = []
	for ind in by.keys():
		out.append({"ind": ind, "name": str(MEDIA[ind].name), "pct": minf(float(by[ind]) / maxf(_pop(iso), 1.0), media_cap(iso, ind))})
	return out

func _fmt_n(v: float) -> String:
	if v >= 1.0e6:
		return "%.2f mil." % (v / 1.0e6)
	if v >= 1000.0:
		return "%.0f tis." % (v / 1000.0)
	return "%.0f" % v
