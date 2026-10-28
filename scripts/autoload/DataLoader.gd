extends Node

var countries = {}
var country_ids: Array = []
var commodities = {}
var commodity_ids: Array = []
var recipes = {}
var industries = {}
var industry_ids: Array = []
var research: Array = []
var scenarios: Array = []
var map = {"w": 1440, "h": 720, "countries": []}
var wars: Array = []
var tension_seed: Array = []
var supply_shares = {}
var laws = {"international": [], "countries": {}}
var sites: Array = []
var tech_nodes: Array = []
var tech_by_id = {}
var focus_trees = {}
var focus_by_id = {}
var forecasts: Array = []
var forecast_by_id = {}
var usd_per_eur = 1.08
var errors: Array = []
var names: Dictionary = {}  # JUAN5 #17: mena osob podla krajiny (data/names_juan5.json)
var politics: Dictionary = {}  # JUAN5: vlady, strany, lidri (parodie) pre 165 krajin
var core_ids: Array = []  # JUAN5: povodnych 26 krajin (tier 1 vzdy)
var _extra_override = null

# JUAN5: vsetkych 165 krajin; vypnut sa da argumentom "core26" (testy so starym zlatym vystupom)
func include_extra() -> bool:
	if _extra_override != null:
		return bool(_extra_override)
	return not OS.get_cmdline_user_args().has("core26")

# JUAN5 #17: typicke meno osoby v krajine; seed = deterministicky vyber (seedovane z hry), gender "m"/"f"
func name_group(iso: String) -> String:
	return str(names.get("country", {}).get(iso, "en"))

func person_name(iso: String, seed: int, gender: String = "m") -> String:
	var groups: Dictionary = names.get("groups", {})
	var g: Dictionary = groups.get(name_group(iso), groups.get("en", {}))
	if g.is_empty():
		return "Ján Kováč"
	var h = absi(seed)
	var firsts: Array = g.get("f" if gender == "f" else "m", [])
	var fams: Array = g.get("s", [])
	var famf: Array = g.get("sf", [])
	var first = str(firsts[h % firsts.size()])
	var si = (h / 13) % fams.size()
	var fam = str(famf[si]) if gender == "f" and famf.size() == fams.size() and famf.size() > 0 else str(fams[si])
	if str(g.get("order", "")) == "family_first":
		return "%s %s" % [fam, first]
	return "%s %s" % [first, fam]

func is_core(iso: String) -> bool:
	return not bool(countries.get(iso, {}).get("extra", false))

func _ready() -> void:
	load_all()

func load_all() -> void:
	errors.clear()
	countries.clear()
	country_ids.clear()
	var arr = _read("res://data/countries.json")
	if typeof(arr) != TYPE_ARRAY:
		errors.append("countries.json")
	else:
		for c in arr:
			if typeof(c) != TYPE_DICTIONARY:
				continue
			var iso = str(c.get("iso2", ""))
			if iso == "":
				continue
			_normalize_country(c)
			countries[iso] = c
			country_ids.append(iso)
	core_ids = country_ids.duplicate()
	if include_extra():  # JUAN5: 139 dalsich krajin (tier 2 LOD)
		var ex = _read("res://data/countries_extra_juan4.json")
		if typeof(ex) == TYPE_ARRAY:
			for c in ex:
				if typeof(c) != TYPE_DICTIONARY:
					continue
				var iso2 = str(c.get("iso2", ""))
				if iso2 == "" or countries.has(iso2):
					continue
				_normalize_country(c)
				c["extra"] = true
				countries[iso2] = c
				country_ids.append(iso2)
	var nd = _read("res://data/names_juan5.json")
	names = nd if typeof(nd) == TYPE_DICTIONARY else {}
	var pd = _read("res://data/politics_juan5.json")
	politics = pd if typeof(pd) == TYPE_DICTIONARY else {}
	var coms = _read("res://data/commodities.json")
	commodities.clear()
	commodity_ids.clear()
	if typeof(coms) == TYPE_ARRAY:
		for c in coms:
			commodities[str(c.get("id", ""))] = c
			commodity_ids.append(str(c.get("id", "")))
	else:
		errors.append("commodities.json")
	recipes.clear()
	var recs = _read("res://data/recipes.json")
	if typeof(recs) == TYPE_ARRAY:
		for r in recs:
			recipes[str(r.get("id", ""))] = r
	else:
		errors.append("recipes.json")
	industries.clear()
	industry_ids.clear()
	var inds = _read("res://data/industries.json")
	if typeof(inds) == TYPE_ARRAY:
		for ind in inds:
			var id = str(ind.get("id", ""))
			industries[id] = ind
			industry_ids.append(id)
	else:
		errors.append("industries.json")
	var rs = _read("res://data/research.json")
	research = rs if typeof(rs) == TYPE_ARRAY else []
	var sc = _read("res://data/scenarios.json")
	scenarios = sc if typeof(sc) == TYPE_ARRAY else []
	var mp = _read("res://data/map.json")
	if typeof(mp) == TYPE_DICTIONARY:
		map = mp
		if include_extra():  # JUAN5
			var mx = _read("res://data/map_extra_juan4.json")
			if typeof(mx) == TYPE_ARRAY and typeof(map.get("countries", null)) == TYPE_ARRAY:
				var have = {}
				for e in map.countries:
					have[str(e.get("iso2", ""))] = true
				for e in mx:
					if typeof(e) == TYPE_DICTIONARY and not have.has(str(e.get("iso2", ""))) and countries.has(str(e.get("iso2", ""))):
						map.countries.append(e)
	else:
		errors.append("map.json")
	var w = _read("res://data/wars.json")
	wars = w if typeof(w) == TYPE_ARRAY else []
	var ts = _read("res://data/tension_seed.json")
	tension_seed = ts if typeof(ts) == TYPE_ARRAY else []
	var sh = _read("res://data/supply_shares.json")
	if typeof(sh) == TYPE_DICTIONARY:
		supply_shares = sh
		usd_per_eur = float(sh.get("usd_per_eur", 1.08))
		if usd_per_eur <= 0.1:
			usd_per_eur = 1.08
	else:
		errors.append("supply_shares.json")
	var place_doc = _read("res://data/places.json")
	sites = place_doc if typeof(place_doc) == TYPE_ARRAY else []
	if typeof(place_doc) != TYPE_ARRAY:
		errors.append("places.json")
	var law_doc = _read("res://data/laws.json")
	if typeof(law_doc) == TYPE_DICTIONARY and typeof(law_doc.get("international", null)) == TYPE_ARRAY:
		laws = law_doc
	else:
		errors.append("laws.json")
		laws = {
			"international": [{"id": "basel", "name": "Bazilej III", "area": "bank", "min_reserve": 0.08}],
			"countries": {"SK": [{"id": "sk_tax", "name": "Zákon o dani z príjmov", "area": "tax", "corporate_tax": 0.21}]}
		}
	_load_history_catalogs()

func _load_history_catalogs() -> void:
	tech_nodes = []
	tech_by_id = {}
	focus_trees = {}
	focus_by_id = {}
	forecasts = []
	forecast_by_id = {}
	var tech_doc = _read("res://data/tech_catalog.json")
	if typeof(tech_doc) == TYPE_DICTIONARY and typeof(tech_doc.get("nodes", null)) == TYPE_ARRAY:
		tech_nodes = tech_doc["nodes"]
		for n in tech_nodes:
			tech_by_id[str(n.get("id", ""))] = n
	else:
		errors.append("tech_catalog.json")
	var focus_doc = _read("res://data/focus_trees.json")
	if typeof(focus_doc) == TYPE_DICTIONARY and typeof(focus_doc.get("trees", null)) == TYPE_DICTIONARY:
		focus_trees = focus_doc["trees"]
		for tree_name in focus_trees.keys():
			for row in focus_trees[tree_name]:
				focus_by_id[str(row.get("id", ""))] = row
	else:
		errors.append("focus_trees.json")
	var forecast_doc = _read("res://data/forecasts.json")
	if typeof(forecast_doc) == TYPE_DICTIONARY and typeof(forecast_doc.get("forecasts", null)) == TYPE_ARRAY:
		forecasts = forecast_doc["forecasts"]
		for row in forecasts:
			forecast_by_id[str(row.get("id", ""))] = row
	else:
		errors.append("forecasts.json")

func history_catalog_errors() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var cats = {"EKO": true, "ENE": true, "DOP": true, "FIN": true, "IT": true, "VOJ": true, "VES": true, "MED": true}
	if tech_nodes.size() != 70:
		out.append("tech count %d" % tech_nodes.size())
	for i in range(1, 71):
		var tid = "T%02d" % i
		if not tech_by_id.has(tid):
			out.append("missing " + tid)
			continue
		var node: Dictionary = tech_by_id[tid]
		var cat = str(node.get("category", ""))
		if not cats.has(cat):
			out.append("bad cat " + tid)
		for req in node.get("prerequisites", []):
			if not tech_by_id.has(str(req)):
				out.append("bad prereq %s %s" % [tid, str(req)])
	if _catalog_cycle(tech_by_id, "prerequisites"):
		out.append("tech cycle")
	if _catalog_cycle(focus_by_id, "prerequisites"):
		out.append("focus cycle")
	var t63 = str(tech_by_id.get("T63", {}).get("status", ""))
	var t68 = str(tech_by_id.get("T68", {}).get("status", ""))
	if not t63.begins_with("NEOVERENE") or t63.find("2019 nepotvrdený") < 0:
		out.append("T63 status")
	if not t68.begins_with("NEOVERENE") or t68.find("FPV") < 0:
		out.append("T68 status")
	var expect = {"USA": 12, "SU": 12, "CN": 11, "UK": 10, "FR": 10, "DE": 10, "JP": 9, "IN": 10, "generic": 14}
	for key in expect.keys():
		var n = 0
		for row in focus_trees.get(key, []):
			var fid = str(row.get("id", ""))
			if _is_primary_focus(key, fid):
				n += 1
		if n != int(expect[key]):
			out.append("count %s %d" % [key, n])
	if not _exclusive_pair("US2", "US2A") or not _exclusive_pair("G2", "G3") or not _exclusive_pair("G2", "G4") or not _exclusive_pair("G3", "G4"):
		out.append("exclusive")
	if not _exclusive_pair("G1A", "G1B"):
		out.append("G1 exclusive")
	var g6: Dictionary = focus_by_id.get("G6", {})
	var g7: Dictionary = focus_by_id.get("G7", {})
	if g6.get("options", []) != ["plávajúci kurz", "fixácia"]:
		out.append("G6 options")
	if g7.get("options", []) != ["šetrenie", "jadro", "nové náleziská"]:
		out.append("G7 options")
	var reforma = _focus_named("Trhová reforma")
	if reforma.is_empty() or not ("G10" in reforma.get("prerequisites", [])):
		out.append("trhova")
	if forecasts.size() != 13:
		out.append("forecast count")
	for i in range(1, 14):
		var fid = "F%d" % i
		var row: Dictionary = forecast_by_id.get(fid, {})
		if row.is_empty() or str(row.get("class", "")) != "ODHAD":
			out.append("F class " + fid)
		if tech_by_id.has(fid):
			out.append("F in tech " + fid)
		var st = str(row.get("status", ""))
		if str(row.get("name", "")) == "":
			out.append("F name " + fid)
		if fid == "F6" or fid == "F9":
			if not st.begins_with("NEOVERENE"):
				out.append("F status " + fid)
		elif st != "OVERENE":
			out.append("F status " + fid)
	return out

func _is_primary_focus(tree: String, fid: String) -> bool:
	if fid == "TRHOVA" or fid.ends_with("A") or fid.ends_with("B"):
		return false
	if tree == "generic":
		return fid.begins_with("G")
	if tree == "SU":
		return fid.begins_with("SU")
	if tree == "USA":
		return fid.begins_with("US")
	return fid.begins_with(tree)

func _exclusive_pair(a: String, b: String) -> bool:
	var ra: Dictionary = focus_by_id.get(a, {})
	var rb: Dictionary = focus_by_id.get(b, {})
	return b in ra.get("exclusive", []) and a in rb.get("exclusive", [])

func _focus_named(name: String) -> Dictionary:
	for fid in focus_by_id.keys():
		var row: Dictionary = focus_by_id[fid]
		if str(row.get("name", "")) == name:
			return row
	return {}

func _catalog_cycle(table, key: String) -> bool:
	var color = {}
	for id in table.keys():
		if _catalog_visit(table, key, str(id), color):
			return true
	return false

func _catalog_visit(table, key: String, id: String, color) -> bool:
	var state = int(color.get(id, 0))
	if state == 1:
		return true
	if state == 2:
		return false
	color[id] = 1
	var row: Dictionary = table.get(id, {})
	for req in row.get(key, []):
		var pid = str(req)
		if table.has(pid) and _catalog_visit(table, key, pid, color):
			return true
	color[id] = 2
	return false

func _normalize_country(c: Dictionary) -> void:
	c.id = str(c.get("iso2", c.get("id", "")))
	c.gdp = float(c.get("gdp", c.get("gdp_usd", 0.0)))
	c.gdp_per_capita = float(c.get("gdp_per_capita", c.get("gdp_pc_usd", 0.0)))
	c.infrastructure = float(c.get("infrastructure", c.get("infra", 1.0)))
	c.risk = float(c.get("risk", c.get("political_risk", 0.2)))
	c.trade_balance = float(c.get("trade_balance", float(c.get("exports_usd", 0.0)) - float(c.get("imports_usd", 0.0))))
	if not c.has("stability"):
		c.stability = clampf((1.0 - c.risk) * 100.0, 0.0, 100.0)
	if not c.has("resources"):
		var res: Array = []
		var endow: Dictionary = c.get("endow", {})
		for key in endow.keys():
			if float(endow[key]) >= 0.5:
				res.append(str(key))
		c.resources = res

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func ingest_raw(kind: String, text: String):
	var data = JSON.parse_string(text)
	var bad = data == null
	if kind == "countries" and typeof(data) != TYPE_ARRAY:
		bad = true
	if bad:
		_log_data("invalid %s -> proxy" % kind)
		return _proxy(kind)
	return data

func _proxy(kind: String):
	if kind == "countries":
		return [{"id": "SK", "iso2": "SK", "name": "Slovakia", "population": 1000, "gdp": 1.0, "inflation": 0.02, "resources": [], "risk": 0.2}]
	if kind == "commodities":
		return [{"id": "wheat", "name": "Wheat", "base_price": 1.0, "category": "agro"}]
	if kind == "recipes":
		return [{"id": "proxy", "industry": "services", "inputs": [], "outputs": []}]
	return []

func _log_data(line: String) -> void:
	var path = "user://data_warnings.log"
	var mode = FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE
	var wf = FileAccess.open(path, mode)
	if wf:
		wf.seek_end()
		wf.store_string(line + "\n")
	else:
		push_warning("Nepodarilo sa zapísať diagnostiku dát: %s" % line)

func _read(path: String):
	if not FileAccess.file_exists(path):
		errors.append("missing " + path)
		return null
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		errors.append("open " + path)
		return null
	var data = JSON.parse_string(f.get_as_text())
	if data == null:
		errors.append("json " + path)
	return data

var _share_cache = {}

# Normalizovany podiel ponuky: sucet cez vsetky krajiny = 1 (etapa 1, krok 1).
func share(cid: String, iso: String) -> float:
	if not _share_cache.has(cid):
		_share_cache[cid] = _normalized_shares(cid)
	return float(_share_cache[cid].get(iso, 0.0))

func _normalized_shares(cid: String) -> Dictionary:
	var out = {}
	var total = 0.0
	for id in country_ids:
		var v = max(_raw_share(cid, str(id)), 0.0)
		out[str(id)] = v
		total += v
	if total <= 0.0:
		for id2 in country_ids:
			out[str(id2)] = 1.0 / max(float(country_ids.size()), 1.0)
		return out
	for k in out.keys():
		out[k] = float(out[k]) / total
	return out

# surovy (nenormalizovany) podiel; vstup do normalizacie v share()
func _raw_share(cid: String, iso: String) -> float:
	var block = supply_shares.get("shares", {})
	if typeof(block) != TYPE_DICTIONARY:
		return _gdp_share(iso)
	var row = block.get(cid, {})
	if typeof(row) != TYPE_DICTIONARY or row.is_empty():
		return _gdp_share(iso)
	if not row.has(iso):
		# poistka etapy 0: krajina mimo riadku nema nulovu ponuku, ale podiel podla HDP (plna oprava = etapa 1)
		return _gdp_share(iso)
	return float(row.get(iso, 0.0))

func _gdp_share(iso: String) -> float:
	var total = 0.0
	var mine = 0.0
	for id in country_ids:
		var g = float(countries[id].get("gdp_usd", 0.0))
		total += g
		if id == iso:
			mine = g
	if total <= 0.0:
		return 0.0
	return mine / total

func commodity(cid: String) -> Dictionary:
	return commodities.get(cid, {})

func country(iso: String) -> Dictionary:
	return countries.get(iso, {})
