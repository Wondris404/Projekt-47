extends Node
# P47 DESIGNS: system alternativnych UI dizajnov (pozri docs/DESIGNS.md).
# - Auto-discovery: kazdy priecinok res://themes/<id>/ s design.json je dizajn. Pridanie dizajnu = pridat priecinok.
# - "current" = sucasny dizajn (ui/theme_p47.tres, gfx kolo 1+2) bez akejkolvek zmeny spravania.
# - Volba sa uklada do user://settings.cfg [ui] design (nastavenia hry, NIE save hry -> SAVE_VERSION sa nemeni).
# - Neplatny / chybajuci dizajn -> "current".
# - Ziadna herna logika: len Theme, pozadie menu, paleta (UiPalette), HUD (strategic_skin), mapa a farby krajin
#   (world_map, atlas_style, map_fx_overlay) a motion parametre animacii (ui_fx, pauza, menu, parallax, glow mapy).
# - Kazdy napojeny skript ma const DEFAULTS (= presne hodnoty gfx kola 2) a static var s rovnakym menom;
#   _apply_static() ich pri kazdej aktivacii najprv vrati na DEFAULTS a potom prepise klucmi z design.json.

signal design_changed(id: String)

const CURRENT := "current"
const THEMES_DIR := "res://themes/"
const SETTINGS := "user://settings.cfg"
const DEFAULT_THEME := "res://ui/theme_p47.tres"
const PaletteScript = preload("res://scripts/ui/ui_palette.gd")
const SkinScript = preload("res://scripts/ui/strategic_skin.gd")
const AtlasStyleScript = preload("res://scripts/ui/atlas_style.gd")
const WorldMapScript = preload("res://scripts/ui/world_map.gd")
const MapFxScript = preload("res://scripts/ui/map_fx_overlay.gd")
# Kam ide ktora sekcia design.json: [sekcia, skript, DEFAULTS].
# Kluc v design.json = meno static var malymi pismenami (napr. palette.accent -> UiPalette.ACCENT).
const SECTIONS := [
	["palette", PaletteScript, PaletteScript.DEFAULTS],
	["hud", SkinScript, SkinScript.DEFAULTS],
	["map", AtlasStyleScript, AtlasStyleScript.DEFAULTS],
	["map", WorldMapScript, WorldMapScript.MAP_DEFAULTS],
	["map", MapFxScript, MapFxScript.DEFAULTS],
	["countries", AtlasStyleScript, AtlasStyleScript.COUNTRY_DEFAULTS],
	["countries", WorldMapScript, WorldMapScript.COUNTRY_DEFAULTS],
]
# Kluce sekcie "map"/"menu", ktore cita priamo DesignManager (nie su static var).
const EXTRA_KEYS := {"map": ["tint"], "countries": [], "palette": [], "hud": []}
const TRANS := {"linear": Tween.TRANS_LINEAR, "sine": Tween.TRANS_SINE, "quad": Tween.TRANS_QUAD, "cubic": Tween.TRANS_CUBIC,
	"quart": Tween.TRANS_QUART, "quint": Tween.TRANS_QUINT, "expo": Tween.TRANS_EXPO, "circ": Tween.TRANS_CIRC,
	"back": Tween.TRANS_BACK, "elastic": Tween.TRANS_ELASTIC, "bounce": Tween.TRANS_BOUNCE, "spring": Tween.TRANS_SPRING}
const EASE := {"in": Tween.EASE_IN, "out": Tween.EASE_OUT, "in_out": Tween.EASE_IN_OUT, "out_in": Tween.EASE_OUT_IN}

var current_id: String = CURRENT
var spec: Dictionary = {}  # obsah design.json aktivneho dizajnu ({} pre current)
var _theme: Theme
var _host: Node  # main.gd (Main Control), ak je pripojeny cez attach()
var _menu_orig: Dictionary = {}

func _ready() -> void:
	var forced = _cmdline_design()
	if forced != "":
		_activate(forced)
	else:
		_activate(load_setting())

# --- discovery -------------------------------------------------------------

# Vrati zoznam [{id, name, path}], "current" je vzdy prvy. Priecinky bez platneho design.json sa preskocia.
func designs() -> Array:
	var out: Array = [{"id": CURRENT, "name": "Súčasný (predvolený)", "path": ""}]
	var dir = DirAccess.open(THEMES_DIR)
	if dir == null:
		return out
	var ids: Array = []
	for d in dir.get_directories():
		ids.append(str(d))
	ids.sort()
	for id in ids:
		var s = read_spec(id)
		if s.is_empty():
			continue
		out.append({"id": id, "name": str(s.get("name", id)), "path": THEMES_DIR + id + "/"})
	return out

func design_ids() -> Array:
	var ids: Array = []
	for d in designs():
		ids.append(d.id)
	return ids

func is_valid(id: String) -> bool:
	return id == CURRENT or not read_spec(id).is_empty()

# Nacita design.json; {} ak dizajn neexistuje alebo je neplatny (zly JSON, chyba theme.tres).
func read_spec(id: String) -> Dictionary:
	if id == "" or id == CURRENT or not id.is_valid_filename() or id.contains("..") or id.contains("/"):
		return {}
	var path = THEMES_DIR + id + "/design.json"
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var theme_path = THEMES_DIR + id + "/" + str(parsed.get("theme", "theme.tres"))
	if not ResourceLoader.exists(theme_path):
		return {}
	parsed["_dir"] = THEMES_DIR + id + "/"
	parsed["_theme_path"] = theme_path
	return parsed

# --- nastavenie -------------------------------------------------------------

func load_setting() -> String:
	var cfg = ConfigFile.new()
	if cfg.load(SETTINGS) != OK:
		return CURRENT
	return str(cfg.get_value("ui", "design", CURRENT))

func _save_setting(id: String) -> void:
	var cfg = ConfigFile.new()
	cfg.load(SETTINGS)  # zachova ostatne kluce (ui/scale, graphics/...)
	cfg.set_value("ui", "design", id)
	cfg.save(SETTINGS)

func _cmdline_design() -> String:
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("design="):
			return str(a).substr(7)
	return ""

# Prepne dizajn. Vrati id, ktore sa naozaj pouzilo (neplatne -> "current").
func set_design(id: String, persist: bool = true) -> String:
	var old_table := _color_table()
	var used = _activate(id)
	if persist:
		_save_setting(used)
	if _host != null and is_instance_valid(_host) and _host.is_inside_tree():
		retint(_host, old_table, _color_table())
	apply_all()
	design_changed.emit(used)
	return used

func _activate(id: String) -> String:
	var s = read_spec(id)
	var th: Theme = null
	if not s.is_empty():
		th = load(str(s._theme_path)) as Theme
	if s.is_empty() or th == null:
		if id != CURRENT:
			push_warning("P47_DESIGN neplatny dizajn '%s' -> current" % id)
		current_id = CURRENT
		spec = {}
		_theme = load(DEFAULT_THEME)
		_apply_static()
		return CURRENT
	current_id = id
	spec = s
	_theme = th
	_apply_static()
	return id

# --- napojenie farieb a parametrov v kode -------------------------------------

# Vrati vsetky static var napojenych skriptov na DEFAULTS a prepise ich hodnotami aktivneho dizajnu.
# Neplatne hodnoty (zly hex, zly typ) sa ignoruju s varovanim -> ostane default.
func _apply_static() -> void:
	for sec in SECTIONS:
		var over: Dictionary = spec.get(sec[0], {}) if typeof(spec.get(sec[0], {})) == TYPE_DICTIONARY else {}
		var script: Script = sec[1]
		var defs: Dictionary = sec[2]
		for k in defs:
			var key := str(k).to_lower()
			var v = defs[k]
			if over.has(key):
				var parsed = _coerce(over[key], defs[k])
				if parsed == null:
					push_warning("P47_DESIGN %s: neplatna hodnota %s.%s -> default" % [current_id, sec[0], key])
				else:
					v = parsed
			script.set(k, v.duplicate(true) if (v is Array or v is Dictionary) else v)

# Prevedie hodnotu z JSON na typ defaultu. null = neplatna.
static func _coerce(raw, def):
	match typeof(def):
		TYPE_COLOR:
			return _to_color(raw)
		TYPE_FLOAT:
			return float(raw) if (typeof(raw) == TYPE_FLOAT or typeof(raw) == TYPE_INT) else null
		TYPE_INT:
			return int(raw) if (typeof(raw) == TYPE_FLOAT or typeof(raw) == TYPE_INT) else null
		TYPE_STRING:
			return str(raw) if typeof(raw) == TYPE_STRING else null
		TYPE_ARRAY:
			if typeof(raw) != TYPE_ARRAY or (raw as Array).is_empty():
				return null
			var out: Array = []
			for c in raw:
				var col = _to_color(c)
				if col == null:
					return null
				out.append(col)
			return out
		TYPE_DICTIONARY:
			if typeof(raw) != TYPE_DICTIONARY:
				return null
			var d := {}
			for k in raw:
				if str(k).begins_with("_"):
					continue
				var col = _to_color(raw[k])
				if col == null:
					return null
				d[str(k)] = col
			return d
	return null

# "#RRGGBB", "#RRGGBBAA" alebo [r, g, b(, a)] v 0..1 (pre modulate aj > 1).
static func _to_color(raw):
	if typeof(raw) == TYPE_STRING and Color.html_is_valid(str(raw)):
		return Color.html(str(raw))
	if typeof(raw) == TYPE_ARRAY and (raw.size() == 3 or raw.size() == 4):
		return Color(float(raw[0]), float(raw[1]), float(raw[2]), float(raw[3]) if raw.size() == 4 else 1.0)
	return null

# Aktualne farby vsetkych napojenych static var (na premapovanie uz postaveneho UI pri prepnuti za behu).
func _color_table() -> Array:
	var out: Array = []
	for sec in SECTIONS:
		for k in sec[2]:
			var v = (sec[1] as Script).get(k)
			if v is Color:
				out.append(v)
	return out

# --- API pre UI -------------------------------------------------------------

func get_theme() -> Theme:
	if _theme == null:
		_theme = load(DEFAULT_THEME)
	return _theme

# Motion parametre (design.json "motion"): napr. motion("dur_fast", 0.12), motion("ease", "out_cubic").
# Pre "current" vrati vzdy default volajuceho -> ziadna zmena spravania.
func motion(key: String, default_value = null):
	return spec.get("motion", {}).get(key, default_value)

# Trvanie animacie v sekundach: motion[key], inak default * motion.dur_scale (current = presne default).
func dur(key: String, default_value: float) -> float:
	var m: Dictionary = spec.get("motion", {})
	if m.has(key) and (typeof(m[key]) == TYPE_FLOAT or typeof(m[key]) == TYPE_INT):
		return float(m[key])
	if m.has("dur_scale") and (typeof(m.dur_scale) == TYPE_FLOAT or typeof(m.dur_scale) == TYPE_INT):
		return default_value * float(m.dur_scale)
	return default_value

# Easing z motion[key] vo formate "<trans>_<ease>", napr. "cubic_out", "back_in_out". Vrati [trans, ease].
func trans(key: String, default_trans: int, default_ease: int) -> Array:
	var raw = spec.get("motion", {}).get(key, null)
	if typeof(raw) != TYPE_STRING:
		return [default_trans, default_ease]
	var parts := str(raw).split("_", false, 1)
	if parts.size() != 2 or not TRANS.has(parts[0]) or not EASE.has(parts[1]):
		return [default_trans, default_ease]
	return [TRANS[parts[0]], EASE[parts[1]]]

# Farba z palety (design.json "palette"), napr. color("accent", UiPalette.ACCENT).
func color(key: String, default_value: Color = Color.WHITE) -> Color:
	var v = spec.get("palette", {}).get(key, null)
	return Color(str(v)) if v != null else default_value

func map_value(key: String, default_value = null):
	return spec.get("map", {}).get(key, default_value)

func asset_path(rel: String) -> String:
	return str(spec.get("_dir", "")) + rel

# Pripoji main.gd: aplikuje dizajn na theme, mapu a hlavne menu a pri zmene ich obnovi.
func attach(host: Node) -> void:
	_host = host
	apply_all()

func apply_all() -> void:
	if _host == null or not is_instance_valid(_host):
		return
	if _host is Control:
		(_host as Control).theme = get_theme()
	var m = _host.get("map")
	if m is CanvasItem:
		apply_map(m)
	var mm = _host.get("main_menu")
	if mm is Control:
		apply_menu(mm)
	var bg = _host.get_node_or_null("P47Background")
	if bg is ColorRect:
		apply_background(bg)
	var tb = _host.get("speed_bar")
	if tb is Node and tb.has_method("design_refresh") and tb.is_inside_tree():
		tb.design_refresh()

func apply_map(m: CanvasItem) -> void:
	# tint vykreslovania mapy (self_modulate); farby krajin, vody a okrajov su static var (sekcie map/countries)
	var t = _to_color(map_value("tint", "#ffffff"))
	m.self_modulate = t if t != null else Color.WHITE
	if m.has_method("design_refresh"):
		m.design_refresh()
	var fx = m.get_node_or_null("MapFxOverlay")
	if fx and fx.has_method("design_refresh"):
		fx.design_refresh()

# Pozadie hernej obrazovky (bg_p47.gdshader): farby z hud.bg_* (current = defaulty shaderu).
func apply_background(bg: ColorRect) -> void:
	bg.color = UiPalette.BG_0
	var mat = bg.material
	if mat is ShaderMaterial:
		mat.set_shader_parameter("top_color", SkinScript.BG_TOP)
		mat.set_shader_parameter("bottom_color", SkinScript.BG_BOTTOM)
		mat.set_shader_parameter("glow_color", SkinScript.BG_GLOW)
		mat.set_shader_parameter("glow_strength", SkinScript.BG_GLOW_STRENGTH)
		mat.set_shader_parameter("vignette", SkinScript.BG_VIGNETTE)

# Prepnutie za behu: uz postavene UI ma farby ulozene v add_theme_color_override / StyleBoxFlat.
# Prejde strom a farby, ktore sa rovnaju starej hodnote palety/HUD (RGB, alfa ostava), nahradi novou;
# vlastne kreslenie (_draw) prekresli. Pri zhode dvoch starych farieb vyhra prva v SECTIONS.
func retint(root: Node, old_table: Array, new_table: Array) -> int:
	var remap := {}
	for i in mini(old_table.size(), new_table.size()):
		var o: Color = old_table[i]
		var n: Color = new_table[i]
		var key := Color(o, 1.0).to_html(false)
		if not remap.has(key) and Color(o, 1.0) != Color(n, 1.0):
			remap[key] = n
	var seen := {}
	return _retint_node(root, remap, seen)

func _remap_color(c: Color, remap: Dictionary):
	var key := Color(c, 1.0).to_html(false)
	if remap.has(key):
		return Color(remap[key], c.a)
	return null

func _retint_node(n: Node, remap: Dictionary, seen: Dictionary) -> int:
	var changed := 0
	if n is Control and not remap.is_empty():
		var c := n as Control
		for p in c.get_property_list():
			var pname := str(p.name)
			if pname.begins_with("theme_override_colors/"):
				var k := pname.substr(22)
				if c.has_theme_color_override(k):
					var nc = _remap_color(c.get_theme_color(k), remap)
					if nc != null:
						c.add_theme_color_override(k, nc)
						changed += 1
			elif pname.begins_with("theme_override_styles/"):
				var k2 := pname.substr(22)
				if c.has_theme_stylebox_override(k2):
					var sb = c.get_theme_stylebox(k2)
					if sb is StyleBoxFlat and not seen.has(sb.get_instance_id()):
						seen[sb.get_instance_id()] = true
						for prop in ["bg_color", "border_color", "shadow_color"]:
							var nc2 = _remap_color(sb.get(prop), remap)
							if nc2 != null:
								sb.set(prop, nc2)
								changed += 1
	if n is CanvasItem:
		(n as CanvasItem).queue_redraw()
	for ch in n.get_children():
		changed += _retint_node(ch, remap, seen)
	return changed

# Hlavne menu ma natvrdo nastavene styly (JUAN16). Pri prvom volani si ich zapamata, aby sa dalo vratit na "current".
func apply_menu(menu: Control) -> void:
	var bg: TextureRect = menu.get("bg_tex")
	var shade: ColorRect = menu.get("shade")
	var logo: Label = menu.get("logo")
	var panel: PanelContainer = menu.get("center_panel")
	if bg == null or shade == null or logo == null or panel == null:
		return
	var buttons: Array = []
	_collect_buttons(menu, buttons)
	if _menu_orig.is_empty() or _menu_orig.get("menu") != menu.get_instance_id():
		var bstyles = {}
		for b in buttons:
			var st = {}
			for k in ["normal", "hover", "pressed"]:
				if b.has_theme_stylebox_override(k):
					st[k] = b.get_theme_stylebox(k)
			bstyles[b.get_instance_id()] = st
		_menu_orig = {
			"menu": menu.get_instance_id(), "tex": bg.texture, "mod": bg.modulate, "filter": bg.texture_filter,
			"shade": shade.color, "logo_c": logo.get_theme_color("font_color"),
			"logo_o": logo.get_theme_color("font_outline_color"),
			"panel": panel.get_theme_stylebox("panel"), "buttons": bstyles,
		}
	var o = _menu_orig
	bg.texture = o.tex
	bg.modulate = o.mod
	bg.texture_filter = o.filter
	shade.color = o.shade
	logo.add_theme_color_override("font_color", o.logo_c)
	logo.add_theme_color_override("font_outline_color", o.logo_o)
	panel.add_theme_stylebox_override("panel", o.panel)
	for b in buttons:
		var st: Dictionary = o.buttons.get(b.get_instance_id(), {})
		for k in st:
			b.add_theme_stylebox_override(k, st[k])
	var fxp = menu.get("particles")
	var fxl = menu.get("parallax")
	var mspec0: Dictionary = spec.get("menu", {})
	if fxp is CanvasItem:
		var pt = _to_color(mspec0.get("particles_tint", "#ffffff"))
		fxp.modulate = pt if pt != null else Color.WHITE
	if fxl is CanvasItem:
		var lt = _to_color(mspec0.get("parallax_tint", "#ffffff"))
		fxl.modulate = lt if lt != null else Color.WHITE
	if current_id == CURRENT:
		return
	var mspec: Dictionary = spec.get("menu", {})
	if mspec.has("background"):
		var tex = load(asset_path(str(mspec.background)))
		if tex is Texture2D:
			bg.texture = tex
			bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if mspec.has("background_modulate"):
		bg.modulate = Color(str(mspec.background_modulate))
	if mspec.has("shade"):
		shade.color = Color(str(mspec.shade))
	if mspec.has("logo_color"):
		logo.add_theme_color_override("font_color", Color(str(mspec.logo_color)))
	if mspec.has("logo_outline"):
		logo.add_theme_color_override("font_outline_color", Color(str(mspec.logo_outline)))
	if bool(mspec.get("use_theme_panel", true)):
		var th = get_theme()
		if th.has_stylebox("panel", "PanelContainer"):
			panel.add_theme_stylebox_override("panel", th.get_stylebox("panel", "PanelContainer"))
		elif th.has_stylebox("panel", "Panel"):
			panel.add_theme_stylebox_override("panel", th.get_stylebox("panel", "Panel"))
	if bool(mspec.get("use_theme_buttons", true)):
		for b in buttons:
			for k in ["normal", "hover", "pressed"]:
				b.remove_theme_stylebox_override(k)

func _collect_buttons(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Button and not (c is OptionButton) and not (c is CheckBox):
			out.append(c)
		_collect_buttons(c, out)

# Prepinac dizajnu pre Nastavenia (hlavne menu aj pauza).
func make_picker() -> OptionButton:
	var ob = OptionButton.new()
	ob.name = "DesignPicker"
	ob.tooltip_text = "Vzhľad hry. Herné nastavenia ani uložené hry sa nemenia."
	var list = designs()
	for i in list.size():
		ob.add_item("Dizajn: " + str(list[i].name))
		ob.set_item_metadata(i, str(list[i].id))
		if str(list[i].id) == current_id:
			ob.select(i)
	ob.item_selected.connect(func(i): set_design(str(ob.get_item_metadata(i))))
	return ob
