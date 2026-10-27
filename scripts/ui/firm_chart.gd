extends Control
# JUAN3: ciarovy graf mesacnych trzieb / nakladov / zisku firmy (max 24 mesiacov).

var rows: Array = []
# JUAN4: volitelne vlastne krivky [[kluc, farba, popis], ...]
var spec_override: Array = []

func set_rows(r: Array) -> void:
	rows = r
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.09, 0.1, 0.9))
	var font = get_theme_default_font()
	if rows.size() < 1:
		draw_string(font, Vector2(8, size.y * 0.5), "Graf sa ukáže po prvom celom mesiaci.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiPalette.TEXT_DIM)
		return
	var lo = 0.0
	var hi = 1.0
	for r in rows:
		for k in _keys():
			lo = min(lo, float(r.get(k, 0.0)))
			hi = max(hi, float(r.get(k, 0.0)))
	var pad = Vector2(8, 18)
	var w = size.x - pad.x * 2.0
	var h = size.y - pad.y * 2.0
	var n = max(rows.size() - 1, 1)
	var y0 = pad.y + h * (hi / (hi - lo))
	draw_line(Vector2(pad.x, y0), Vector2(pad.x + w, y0), UiPalette.TEXT_DIM, 1.0)
	var spec = spec_override if spec_override.size() > 0 else [["rev", Color(0.4, 0.75, 1.0), "Tržby"], ["costs", Color(1.0, 0.55, 0.35), "Náklady"], ["profit", Color(0.45, 0.9, 0.45), "Zisk"]]
	var lx = pad.x
	for sp in spec:
		var pts = PackedVector2Array()
		for i in rows.size():
			var v = float(rows[i].get(sp[0], 0.0))
			pts.append(Vector2(pad.x + w * float(i) / float(n), pad.y + h * (hi - v) / (hi - lo)))
		if pts.size() == 1:
			draw_circle(pts[0], 3.0, sp[1])
		else:
			draw_polyline(pts, sp[1], 2.0, true)
		draw_string(font, Vector2(lx, 13), str(sp[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, sp[1])
		lx += max(70.0, str(sp[2]).length() * 7.0)
	var first: Dictionary = rows[0]
	var last: Dictionary = rows[rows.size() - 1]
	draw_string(font, Vector2(pad.x, size.y - 3), "%d/%d" % [int(first.get("m", 1)), int(first.get("y", 0))], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UiPalette.TEXT_DIM)
	draw_string(font, Vector2(size.x - 60, size.y - 3), "%d/%d" % [int(last.get("m", 1)), int(last.get("y", 0))], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UiPalette.TEXT_DIM)

func _keys() -> Array:
	if spec_override.size() == 0:
		return ["rev", "costs", "profit"]
	var out: Array = []
	for sp in spec_override:
		out.append(sp[0])
	return out
