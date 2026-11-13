extends Control
# JUAN5: strom vyskumu v style focus tree (rovnaky vzhlad ako focus_tree_view): stlpce = vetvy, ciary = prerekvizity
# (oranzova = splnena), tooltip s cenou, trvanim a efektom, ▶ = bezi, ⏳ = vo fronte, ✔ = hotove.
signal research_pressed(rid: String)
const NW = 150.0
const NH = 46.0
const GX = 170.0
const GY = 70.0
const BRANCHES = ["Stroje a automatizácia", "Ťažba a suroviny", "Energetika", "Logistika", "Financie/IT", "Spotrebné produkty", "Podnikanie"]
const ICONS = {"Stroje a automatizácia": "⚙", "Ťažba a suroviny": "⛏", "Energetika": "⚡", "Logistika": "🚚", "Financie/IT": "💾", "Spotrebné produkty": "🛍", "Podnikanie": "🏢"}
var nodes: Dictionary = {}

func _node_pos(r: Dictionary) -> Vector2:
	return Vector2(10.0 + float(r.get("x", 0)) * GX, 34.0 + float(r.get("y", 0)) * GY)

func rebuild() -> void:
	for c in get_children():
		c.queue_free()
	nodes.clear()
	var maxx = 0.0
	var maxy = 0.0
	for i in BRANCHES.size():
		var hl = Label.new()
		hl.text = "%s %s" % [ICONS[BRANCHES[i]], BRANCHES[i].to_upper()]
		hl.position = Vector2(10.0 + i * GX, 6)
		hl.add_theme_font_size_override("font_size", 11)
		hl.add_theme_color_override("font_color", UiPalette.ACCENT)
		add_child(hl)
	var done: Array = GameState.player.get("done", []) if typeof(GameState.player.get("done", [])) == TYPE_ARRAY else []
	var queue: Array = GameState.player.get("research_queue", []) if typeof(GameState.player.get("research_queue", [])) == TYPE_ARRAY else []
	for r in DataLoader.research:
		var rid = str(r.get("id", ""))
		var b = Button.new()
		b.name = "Research_" + rid
		var running = GameState.research_is_running(rid) if not GameState.player.is_empty() else false
		var mark = "✔ " if rid in done else ("▶ " if running else ("⏳ " if rid in queue else ""))
		b.text = "%s%s %s\n%s · %d dní" % [mark, ICONS.get(str(r.get("branch", "")), ""), str(r.get("name", rid)), EconMath.eur(float(r.get("cost", 0))), int(r.get("days", 0))]
		b.add_theme_font_size_override("font_size", 11)
		b.position = _node_pos(r)
		b.size = Vector2(NW, NH)
		b.custom_minimum_size = Vector2(NW, NH)
		b.clip_text = true
		var reqs: Array = r.get("requires", [])
		b.tooltip_text = "%s\nCena %s, %d dní\nEfekt: %s%s" % [str(r.get("name", rid)), EconMath.eur(float(r.get("cost", 0))), int(r.get("days", 0)), str(r.get("text", "")),
			("\nVyžaduje: " + ", ".join(reqs.map(func(q): return str(GameState.research_def(str(q)).get("name", q))))) if reqs.size() > 0 else ""]
		b.disabled = GameState.player.is_empty() or not GameState.research_available(rid) or rid in queue
		if rid in done:
			_state_style(b, UiPalette.OK)  # p47/gfx: hotovy vyskum = zeleny ramik namiesto modulate
		elif running:
			_state_style(b, UiPalette.ACCENT)
		b.pressed.connect(func(): research_pressed.emit(rid))
		add_child(b)
		nodes[rid] = r
		maxx = max(maxx, b.position.x + NW)
		maxy = max(maxy, b.position.y + NH)
	custom_minimum_size = Vector2(maxx + 10.0, maxy + 10.0)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BG_1)
	var done: Array = GameState.player.get("done", []) if typeof(GameState.player.get("done", [])) == TYPE_ARRAY else []
	for rid in nodes.keys():
		var r: Dictionary = nodes[rid]
		var p = _node_pos(r) + Vector2(NW * 0.5, 0)
		for q in r.get("requires", []):
			if not nodes.has(str(q)):
				continue
			var a = _node_pos(nodes[str(q)]) + Vector2(NW * 0.5, NH)
			var col = UiPalette.ACCENT if str(q) in done else UiPalette.BORDER_HI
			var mid = (p.y + a.y) * 0.5
			draw_polyline(PackedVector2Array([a, Vector2(a.x, mid), Vector2(p.x, mid), p]), col, 2.0)

# p47/gfx: stavovy ramik uzla (hotovy/bezi) – citatelny aj ked je tlacidlo disabled
func _state_style(b: Button, c: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(c.r * 0.18, c.g * 0.18, c.b * 0.18, 0.95)
	sb.border_color = c
	sb.set_border_width_all(1)
	sb.border_width_left = 3
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(4)
	sb.anti_aliasing = true
	for st in ["normal", "disabled", "hover"]:
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_color_override("font_disabled_color", c.lightened(0.25))
	b.add_theme_color_override("font_color", c.lightened(0.35))
