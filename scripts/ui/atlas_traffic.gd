extends Node2D
# Presentation only: no simulation state or save fields. Capped work per visible line.
var map: Control
var _acc := 0.0
var _active := false
const MAX_TRAINS = 4
const MAX_MARKERS = 24

static func train_count(util: float) -> int:
	if util <= 0.0: return 0
	return clampi(ceili(util * 3.0), 1, MAX_TRAINS)

# Clip long/offscreen segments before placing details; bounded at any zoom.
static func clipped(a: Vector2, b: Vector2, rect: Rect2) -> PackedVector2Array:
	var d = b - a
	var lo = 0.0
	var hi = 1.0
	for pair in [[-d.x, a.x - rect.position.x], [d.x, rect.end.x - a.x], [-d.y, a.y - rect.position.y], [d.y, rect.end.y - a.y]]:
		var p = float(pair[0])
		var q = float(pair[1])
		if absf(p) < 0.000001:
			if q < 0.0: return PackedVector2Array()
		else:
			var r = q / p
			if p < 0.0: lo = maxf(lo, r)
			else: hi = minf(hi, r)
			if lo > hi: return PackedVector2Array()
	return PackedVector2Array([a + d * lo, a + d * hi])

func _process(delta: float) -> void:
	_acc += delta
	if _acc < 0.1: return
	var dt = _acc
	_acc = 0.0
	var live = false
	if map.atlas and map.zoom >= 4.0 and not map.GFX.low() and map.is_visible_in_tree():
		for line in Transport.lines():
			if Transport.utilization(line) > 0.0 and not clipped(map._to_screen(Transport._pt(line.a)), map._to_screen(Transport._pt(line.b)), Rect2(Vector2.ZERO, map.size).grow(32)).is_empty():
				live = true
				break
	if live: map.anim_time += dt
	if live or _active: queue_redraw()
	_active = live

func _draw() -> void:
	if not map.atlas or map.zoom < 4.0 or map.GFX.low(): return
	for line in Transport.lines():
		var u = maxf(0.0, Transport.utilization(line))
		if u <= 0.0: continue
		var a = map._to_screen(Transport._pt(line.a))
		var b = map._to_screen(Transport._pt(line.b))
		var visible = clipped(a, b, Rect2(Vector2.ZERO, map.size).grow(32))
		if visible.is_empty() or a.distance_to(b) < 2.0: continue
		var direction = (b - a).normalized()
		var normal = Vector2(-direction.y, direction.x)
		var seed_phase = float(absi(str(line.get("id", "")).hash()) % 997) / 997.0
		if str(line.kind) == "rail":
			var n = train_count(u)
			var speed = 0.025 + minf(u, 1.0) * 0.035
			for i in n:
				# Alternate both directions: network stores aggregate usage, not origin/destination.
				var t = fposmod(map.anim_time * speed + seed_phase + float(i) / n, 1.0)
				var forward = i % 2 == 0
				if not forward: t = 1.0 - t
				var p = a.lerp(b, t)
				if not Rect2(Vector2.ZERO, map.size).grow(40).has_point(p): continue
				_train(p, direction if forward else -direction, normal, clampf(u, 0.0, 1.0))
		else:
			var count = clampi(int(visible[0].distance_to(visible[1]) / 32.0), 1, MAX_MARKERS)
			var phase = fposmod(map.anim_time * (0.25 + minf(u, 1.0) * 0.65), 1.0)
			var col = Color("D95A39") if u > 1.0 else Color("59D8BD").lerp(Color("F4D164"), minf(u, 1.0))
			for i in count:
				var p = visible[0].lerp(visible[1], (i + phase) / count)
				# Symmetric pulse: explicitly no claim about physical flow direction.
				draw_circle(p, 1.5 + minf(u, 1.0) * 2.0, Color(col, 0.4 + 0.6 * sin(phase * PI)))

func _train(p: Vector2, direction: Vector2, normal: Vector2, load: float) -> void:
	var scale_px = clampf(map.zoom / 10.0, 0.8, 1.5)
	for car in (4 if map.zoom >= 12.0 else 2):
		var q = p - direction * car * 11.0 * scale_px
		var pts = PackedVector2Array([q - direction * 4.5 * scale_px - normal * 3 * scale_px, q + direction * 4.5 * scale_px - normal * 3 * scale_px, q + direction * 4.5 * scale_px + normal * 3 * scale_px, q - direction * 4.5 * scale_px + normal * 3 * scale_px])
		draw_colored_polygon(pts, Color("D5AB39") if car == 0 else Color("333A43"))
		if car > 0:
			var start = q - direction * 3.5 * scale_px
			# Empty wagon interior remains dark; length of cargo shows actual utilization.
			draw_line(start, start + direction * 7.0 * scale_px, Color("121920"), 3 * scale_px)
			if load > 0.0: draw_line(start, start + direction * 7.0 * scale_px * load, Color("C99060"), 3 * scale_px)
