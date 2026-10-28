extends Node
# JUAN-P47 (2026-10-27): jeden spolocny pomocnik pre vsetky vyskakovacie okna (PanelContainer nad mapou).
# Presun: tahanim za titulny pruh (horny pas okna). Zmena velkosti: tahanim za okraje alebo roh (uchyt vpravo dole).
# Min. velkost, orezanie na obrazovku, obsah sa posuva (ScrollContainer v okne). Poloha/velkost sa pamata podla typu
# okna pocas relacie a v nastaveniach user://ui_windows.cfg (nie v save v3). Ziadna praca za snimku – len udalosti mysi.

const CFG_PATH = "user://ui_windows.cfg"
const EDGE = 8.0
const MIN_SIZE = Vector2(300, 180)
const TOP_Z = 48

var rects: Dictionary = {}      # kluc typu okna -> Rect2 (relacia + nastavenia)
var wins: Dictionary = {}       # kluc -> {panel, default: Callable, title_h, base_z, min}
var _mode := 0                  # 0 nic, 1 presun, 2 zmena velkosti
var _edges := Vector4.ZERO      # lavy, horny, pravy, dolny okraj pri zmene velkosti
var _key := ""
var _start_mouse := Vector2.ZERO
var _start_rect := Rect2()
var persist := true

func _ready() -> void:
	_load_cfg()
	get_viewport().size_changed.connect(clamp_all)
	var window = get_window()
	if window != null:
		window.focus_exited.connect(_cancel_active_drag)

func _cancel_active_drag() -> void:
	if _mode == 0:
		return
	_mode = 0
	if wins.has(_key):
		var panel: Control = wins[_key].panel
		if is_instance_valid(panel):
			rects[_key] = Rect2(panel.position, panel.size)
			_save_cfg()

func _load_cfg(path: String = CFG_PATH) -> void:
	var cf = ConfigFile.new()
	if cf.load(path) != OK:
		return
	for k in cf.get_section_keys("windows") if cf.has_section("windows") else []:
		var v = cf.get_value("windows", k, null)
		if typeof(v) == TYPE_RECT2:
			rects[k] = v

func _save_cfg(path: String = CFG_PATH, force: bool = false) -> void:
	if not persist and not force:
		return
	var cf = ConfigFile.new()
	for k in rects.keys():
		cf.set_value("windows", str(k), rects[k])
	cf.save(path)

func register(panel: Control, key: String, default_rect: Callable, title_h: float = 40.0, min_size: Vector2 = MIN_SIZE) -> void:
	if panel == null:
		return
	if wins.has(key) and wins[key].panel == panel:
		return
	wins[key] = {"panel": panel, "default": default_rect, "title_h": title_h, "base_z": panel.z_index, "min": min_size}
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
	panel.set_meta("win_key", key)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb = panel.get_theme_stylebox("panel")
	if sb:  # sirsi okraj, aby sa dalo chytit za hranu
		var sb2: StyleBox = sb.duplicate()
		sb2.content_margin_left = maxf(sb.content_margin_left, EDGE + 2.0)
		sb2.content_margin_right = maxf(sb.content_margin_right, EDGE + 2.0)
		sb2.content_margin_bottom = maxf(sb.content_margin_bottom, EDGE + 4.0)
		sb2.content_margin_top = maxf(sb.content_margin_top, 6.0)
		panel.add_theme_stylebox_override("panel", sb2)
	panel.gui_input.connect(_on_input.bind(key))
	panel.draw.connect(_draw_grip.bind(panel))
	panel.visibility_changed.connect(_on_vis.bind(key))

func _on_vis(key: String) -> void:
	var p: Control = wins[key].panel
	if p.visible:
		raise(key)
	else:
		if _key == key:
			_mode = 0
		if rects.has(key):
			_save_cfg()

# zavolat pri otvoreni okna: pouzije zapamatanu polohu alebo predvolenu
func place(key: String) -> void:
	if not wins.has(key):
		return
	var w = wins[key]
	var r: Rect2 = rects.get(key, w.default.call())
	_apply(key, r)

func _apply(key: String, r: Rect2) -> void:
	var w = wins[key]
	var p: Control = w.panel
	var vp = p.get_viewport_rect().size if p.is_inside_tree() else Vector2(1280, 720)
	var mn: Vector2 = w.min
	var sz = Vector2(clampf(r.size.x, mn.x, maxf(mn.x, vp.x)), clampf(r.size.y, mn.y, maxf(mn.y, vp.y - 8.0)))
	var pos = Vector2(clampf(r.position.x, 0.0, maxf(0.0, vp.x - sz.x)), clampf(r.position.y, 0.0, maxf(0.0, vp.y - sz.y)))
	p.custom_minimum_size = Vector2.ZERO
	p.position = pos
	p.size = sz

func clamp_all() -> void:
	for k in wins.keys():
		var p: Control = wins[k].panel
		if is_instance_valid(p) and p.visible:
			_apply(k, Rect2(p.position, p.size))

func raise(key: String) -> void:
	for k in wins.keys():
		var p: Control = wins[k].panel
		if is_instance_valid(p):
			p.z_index = TOP_Z if k == key else int(wins[k].base_z)

func _edge_at(p: Control, lp: Vector2) -> Vector4:
	var s = p.size
	return Vector4(1.0 if lp.x <= EDGE else 0.0, 1.0 if lp.y <= 4.0 else 0.0, 1.0 if lp.x >= s.x - EDGE else 0.0, 1.0 if lp.y >= s.y - EDGE else 0.0)

func _cursor(e: Vector4) -> int:
	if (e.x > 0 and e.y > 0) or (e.z > 0 and e.w > 0):
		return Control.CURSOR_FDIAGSIZE
	if (e.z > 0 and e.y > 0) or (e.x > 0 and e.w > 0):
		return Control.CURSOR_BDIAGSIZE
	if e.x > 0 or e.z > 0:
		return Control.CURSOR_HSIZE
	if e.y > 0 or e.w > 0:
		return Control.CURSOR_VSIZE
	return Control.CURSOR_ARROW

func _on_input(ev: InputEvent, key: String) -> void:
	var w = wins.get(key, {})
	if w.is_empty():
		return
	var p: Control = w.panel
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			raise(key)
			var e = _edge_at(p, ev.position)
			if e != Vector4.ZERO:
				_mode = 2
				_edges = e
			elif ev.position.y <= float(w.title_h):
				_mode = 1
			else:
				return
			_key = key
			_start_mouse = ev.global_position
			_start_rect = Rect2(p.position, p.size)
			p.accept_event()
		elif _mode != 0 and _key == key:
			_mode = 0
			rects[key] = Rect2(p.position, p.size)
			_save_cfg()
			p.accept_event()
	elif ev is InputEventMouseMotion:
		if _mode == 0 or _key != key:
			p.mouse_default_cursor_shape = _cursor(_edge_at(p, ev.position)) if ev.position.y > float(w.title_h) or _edge_at(p, ev.position) != Vector4.ZERO else Control.CURSOR_MOVE
			return
		var d = ev.global_position - _start_mouse
		var r = _start_rect
		if _mode == 1:
			r.position += d
		else:
			var mn: Vector2 = w.min
			if _edges.x > 0:
				var nx = minf(r.position.x + d.x, r.end.x - mn.x)
				r = Rect2(Vector2(nx, r.position.y), Vector2(r.end.x - nx, r.size.y))
			if _edges.z > 0:
				r.size.x = maxf(mn.x, _start_rect.size.x + d.x)
			if _edges.y > 0:
				var ny = minf(r.position.y + d.y, r.end.y - mn.y)
				r = Rect2(Vector2(r.position.x, ny), Vector2(r.size.x, r.end.y - ny))
			if _edges.w > 0:
				r.size.y = maxf(mn.y, _start_rect.size.y + d.y)
		_apply(key, r)
		rects[key] = Rect2(p.position, p.size)  # pamat aj ked sa uvolnenie tlacidla strati mimo okna
		p.accept_event()

func _draw_grip(p: Control) -> void:
	var s = p.size
	var c = Color(1, 1, 1, 0.35)
	for i in 3:
		var o = 4.0 + i * 4.0
		p.draw_line(Vector2(s.x - o, s.y - 2.0), Vector2(s.x - 2.0, s.y - o), c, 1.0)
	p.draw_line(Vector2(10, 3), Vector2(s.x - 10, 3), Color(1, 1, 1, 0.08), 1.0)
