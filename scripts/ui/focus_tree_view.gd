extends Control
# JUAN4: strom firemnych cielov (inspiracia HOI4, vlastny vzhlad): uzly = tlacidla s ikonou vetvy,
# ciary = prerekvizity (oranzova = splnene), cervena prerusovana = vzajomne vylucenie.
signal focus_pressed(fid: String)
const NW = 150.0
const NH = 46.0
const GX = 170.0
const GY = 80.0
const ICONS = {"Ekonomika": "⚙", "Politika": "⚖", "Podsvetie": "☠", "Pohlavie": "★"}
var nodes: Dictionary = {}

func _node_pos(f: Dictionary) -> Vector2:
	return Vector2(10.0 + float(f.x) * GX, 34.0 + float(f.y) * GY)

func rebuild() -> void:
	for c in get_children():
		c.queue_free()
	nodes.clear()
	var g = str(GameState.player.get("gender", ""))
	var cur = str(PoliticsSystem.focus_state().get("current", ""))
	var maxx = 0.0
	for br in ICONS.keys():
		var col = {"Ekonomika": 0, "Politika": 2, "Podsvetie": 4, "Pohlavie": 6}[br]
		var hl = Label.new()
		hl.text = "%s %s" % [ICONS[br], br.to_upper()]
		hl.position = Vector2(10.0 + col * GX, 6)
		hl.add_theme_color_override("font_color", UiPalette.ACCENT)
		add_child(hl)
	for f in PoliticsSystem.FOCUS:
		if f.has("gender") and str(f.gender) != g:
			continue
		var fid = str(f.id)
		var b = Button.new()
		b.name = "Focus_" + fid
		var done = PoliticsSystem.focus_done(fid)
		var mark = "✔ " if done else ("▶ " if cur == fid else "")
		b.text = "%s%s %s\n%d dní" % [mark, ICONS.get(str(f.branch), ""), str(f.name), int(f.days)]
		b.add_theme_font_size_override("font_size", 11)
		b.position = _node_pos(f)
		b.size = Vector2(NW, NH)
		b.custom_minimum_size = Vector2(NW, NH)
		b.clip_text = true
		b.tooltip_text = "%s (%d dní)\nEfekt: %s%s%s" % [str(f.name), int(f.days), str(f.desc),
			("\nVyžaduje: " + ", ".join(f.req.map(func(r): return str(PoliticsSystem.focus_def(str(r)).name)))) if f.req.size() > 0 else "",
			("\nVylučuje: " + ", ".join(f.get("excl", []).map(func(r): return str(PoliticsSystem.focus_def(str(r)).name)))) if f.get("excl", []).size() > 0 else ""]
		b.disabled = not PoliticsSystem.focus_available(fid) or cur != ""
		if done:
			b.modulate = Color(0.75, 1.0, 0.75)
		b.pressed.connect(func(): focus_pressed.emit(fid))
		add_child(b)
		nodes[fid] = f
		maxx = max(maxx, b.position.x + NW)
	custom_minimum_size = Vector2(maxx + 10.0, 34.0 + 4.0 * GY)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BG_1)
	for fid in nodes.keys():
		var f: Dictionary = nodes[fid]
		var p = _node_pos(f) + Vector2(NW * 0.5, 0)
		for r in f.req:
			if not nodes.has(str(r)):
				continue
			var q = _node_pos(nodes[str(r)]) + Vector2(NW * 0.5, NH)
			var col = UiPalette.ACCENT if PoliticsSystem.focus_done(str(r)) else UiPalette.BORDER_HI
			var mid = (p.y + q.y) * 0.5
			draw_polyline(PackedVector2Array([q, Vector2(q.x, mid), Vector2(p.x, mid), p]), col, 2.0)
		for e in f.get("excl", []):
			if nodes.has(str(e)) and str(fid) < str(e):
				var a = _node_pos(f) + Vector2(NW, NH * 0.5)
				var b = _node_pos(nodes[str(e)]) + Vector2(0, NH * 0.5)
				if a.x > b.x:
					a = _node_pos(f) + Vector2(0, NH * 0.5)
					b = _node_pos(nodes[str(e)]) + Vector2(NW, NH * 0.5)
				draw_dashed_line(a, b, UiPalette.BAD, 2.0, 5.0)
				draw_string(get_theme_default_font(), (a + b) * 0.5 + Vector2(-6, -4), "✕", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiPalette.BAD)
