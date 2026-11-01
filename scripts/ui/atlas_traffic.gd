extends Node2D
# Presentation only: no simulation state or save fields. Capped work per visible line.
var map: Control
var _acc := 0.0
var _active := false
const MAX_TRAINS = 4
const MAX_MARKERS = 24
const MAX_VISIBLE_LINES = 64

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
	if GameState.paused: return
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
	if has_node("/root/ZombieSystem") and ZombieSystem.active() and ZombieSystem.z().get("flights", []).size() > 0:
		live = true
	if live: map.anim_time += dt
	if live or _active: queue_redraw()
	_active = live

func _draw() -> void:
	_draw_ships()
	_draw_dlc_craft()
	if not map.atlas or map.zoom < 4.0 or map.GFX.low(): return
	var visible_lines = 0
	for line in Transport.lines():
		if visible_lines >= MAX_VISIBLE_LINES: break
		var u = maxf(0.0, Transport.utilization(line))
		if u <= 0.0: continue
		var a = map._to_screen(Transport._pt(line.a))
		var b = map._to_screen(Transport._pt(line.b))
		var visible = clipped(a, b, Rect2(Vector2.ZERO, map.size).grow(32))
		if visible.is_empty() or a.distance_to(b) < 2.0: continue
		visible_lines += 1
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

static func wagon_load(util: float, wagon: int, wagons: int) -> float:
	return clampf(util * wagons - wagon, 0.0, 1.0)

func _train(p: Vector2, direction: Vector2, normal: Vector2, load: float) -> void:
	var scale_px = clampf(map.zoom / 10.0, 0.8, 1.5)
	var cars = 4 if map.zoom >= 12.0 else 2
	for car in cars:
		var q = p - direction * car * 11.0 * scale_px
		var pts = PackedVector2Array([q - direction * 4.5 * scale_px - normal * 3 * scale_px, q + direction * 4.5 * scale_px - normal * 3 * scale_px, q + direction * 4.5 * scale_px + normal * 3 * scale_px, q - direction * 4.5 * scale_px + normal * 3 * scale_px])
		draw_colored_polygon(pts, Color("D5AB39") if car == 0 else Color("333A43"))
		if car > 0:
			var start = q - direction * 3.5 * scale_px
			# Empty wagon interior remains dark; length of cargo shows actual utilization.
			draw_line(start, start + direction * 7.0 * scale_px, Color("121920"), 3 * scale_px)
			var cargo = wagon_load(load, car - 1, cars - 1)
			if cargo > 0.0: draw_line(start, start + direction * 7.0 * scale_px * cargo, Color("C99060"), 3 * scale_px)

func _draw_ships() -> void:
	if not map.atlas or not has_node("/root/ShipSystem"):
		return
	if typeof(GameState.ext) != TYPE_DICTIONARY:
		return
	var ships = GameState.ext.get("fleet", [])
	if typeof(ships) != TYPE_ARRAY or ships.is_empty():
		return
	var n = 0
	for s in ships:
		if n >= 32:
			break
		if str(s.get("kind", "")) == "military":
			continue
		n += 1
		var sp = map._to_screen(ShipSystem.pos_of(s))
		if not Rect2(Vector2.ZERO, map.size).grow(40).has_point(sp):
			continue
		var heading = Vector2.RIGHT
		draw_colored_polygon(PackedVector2Array([sp + heading * 7, sp - heading * 5 + Vector2(0, 3), sp - heading * 5 - Vector2(0, 3)]), Color("D5AB39"))

func _draw_dlc_craft() -> void:
	# Fáza C (lode) na main nie je. Stíhačky a helikoptéry DLC sa kreslia tu samy.
	if not has_node("/root/ZombieSystem") or not ZombieSystem.active():
		return
	if map.GFX.low():
		return
	var flights: Array = ZombieSystem.z().get("flights", [])
	var icon = map.zoom < 8.0
	var n = 0
	for fl in flights:
		if n >= 24:
			break
		n += 1
		if typeof(fl) != TYPE_DICTIONARY:
			continue
		var aa = fl.get("a", [0, 0])
		var bb = fl.get("b", [0, 0])
		var a = Vector2(float(aa[0]), float(aa[1]))
		var b = Vector2(float(bb[0]), float(bb[1]))
		var base_t = clampf(float(fl.get("t", 0.0)), 0.0, 1.0)
		var wobble = fposmod(map.anim_time * 0.15, 1.0)
		var pos: Vector2
		var heading: Vector2
		if bool(fl.get("patrol", false)):
			var ang = (base_t + wobble) * TAU
			pos = a + Vector2(cos(ang), sin(ang)) * 3.2
			heading = Vector2(-sin(ang), cos(ang))
		else:
			var t = clampf(base_t + wobble * 0.08, 0.0, 1.0)
			pos = a.lerp(b, t)
			heading = (b - a).normalized() if a.distance_to(b) > 0.05 else Vector2.RIGHT
		var sp = map._to_screen(pos)
		if not Rect2(Vector2.ZERO, map.size).grow(48).has_point(sp):
			continue
		if bool(fl.get("crash", false)):
			draw_circle(sp, 7.0, Color(1.0, 0.25, 0.1, 0.85))
			continue
		var col = Color(0.95, 0.86, 0.28) if str(fl.get("kind", "")) == "heli" else Color(0.45, 0.78, 1.0)
		if icon:
			draw_circle(sp, 3.5, col)
		else:
			var side = Vector2(-heading.y, heading.x)
			var pts = PackedVector2Array([sp + heading * 8.0, sp - heading * 6.0 + side * 4.0, sp - heading * 4.0, sp - heading * 6.0 - side * 4.0])
			draw_colored_polygon(pts, col)
		if str(fl.get("kind", "")) == "fighter" and int(fl.get("flash", 0)) > 0 and int(Time.get_ticks_msec() / 180) % 2 == 0:
			draw_circle(sp, 11.0, Color(1.0, 0.35, 0.15, 0.35))
