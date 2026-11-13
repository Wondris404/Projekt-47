extends Node
# P47 DESIGNS: system alternativnych UI dizajnov (pozri docs/DESIGNS.md).
# - Auto-discovery: kazdy priecinok res://themes/<id>/ s design.json je dizajn. Pridanie dizajnu = pridat priecinok.
# - "current" = sucasny dizajn (ui/theme_p47.tres, gfx kolo 1+2) bez akejkolvek zmeny spravania.
# - Volba sa uklada do user://settings.cfg [ui] design (nastavenia hry, NIE save hry -> SAVE_VERSION sa nemeni).
# - Neplatny / chybajuci dizajn -> "current".
# - Ziadna herna logika: len Theme, pozadie menu, tint mapy a motion parametre.

signal design_changed(id: String)

const CURRENT := "current"
const THEMES_DIR := "res://themes/"
const SETTINGS := "user://settings.cfg"
const DEFAULT_THEME := "res://ui/theme_p47.tres"

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
	var used = _activate(id)
	if persist:
		_save_setting(used)
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
		return CURRENT
	current_id = id
	spec = s
	_theme = th
	return id

# --- API pre UI -------------------------------------------------------------

func get_theme() -> Theme:
	if _theme == null:
		_theme = load(DEFAULT_THEME)
	return _theme

# Motion parametre (design.json "motion"): napr. motion("dur_fast", 0.12), motion("ease", "out_cubic").
# Pre "current" vrati vzdy default volajuceho -> ziadna zmena spravania.
func motion(key: String, default_value = null):
	return spec.get("motion", {}).get(key, default_value)

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

func apply_map(m: CanvasItem) -> void:
	# Len tint vykreslovania mapy (self_modulate) – herna logika a farby krajin v kode ostavaju.
	m.self_modulate = Color(str(map_value("tint", "#ffffff")))

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
