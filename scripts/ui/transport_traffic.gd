class_name TransportTraffic
extends Node2D

# Lightweight animated traffic drawn separately from the static Atlas. This
# keeps trains from forcing the countries, cities and buildings to redraw.
const MIN_ZOOM := 3.0
const DETAIL_ZOOM := 8.0
const MAX_VISIBLE_LINES := 64
const MAX_TRAINS_PER_LINE := 4
const GFX = preload("res://scripts/gfx.gd")

var map: WorldMap
var preview_time := -1.0
var _clock := 0.0
var _redraw_acc := 0.0

static func rail_plan(utilization: float, zoom: float) -> Dictionary:
	var u = maxf(utilization, 0.0)
	if zoom < MIN_ZOOM or u <= 0.001:
		return {"enabled": false, "trains": 0, "wagons": 0, "fill": 0.0}
	return {
		"enabled": true,
		"trains": clampi(ceili(u * 3.0), 1, MAX_TRAINS_PER_LINE),
		"wagons": 3 if zoom >= DETAIL_ZOOM else 1,
		"fill": clampf(u, 0.0, 1.0),
	}

func set_preview_time(value: float) -> void:
	preview_time = value
	queue_redraw()

func clear_preview_time() -> void:
	preview_time = -1.0

func _process(delta: float) -> void:
	if map == null or not is_instance_valid(map) or map.zoom < MIN_ZOOM or GFX.low():
		return
	if GameState.paused and preview_time < 0.0:
		return
	_clock += delta
	_redraw_acc += delta
	var interval = 1.0 / (12.0 if map.zoom >= DETAIL_ZOOM else 6.0)
	if _redraw_acc >= interval:
		_redraw_acc = 0.0
		queue_redraw()

func _draw() -> void:
	if map == null or map.zoom < MIN_ZOOM or GFX.low():
		return
	var drawn := 0
	for line in Transport.lines():
		if drawn >= MAX_VISIBLE_LINES:
			break
		if str(line.get("kind", "")) != "rail":
			continue
		var a = map._to_screen(Transport._pt(line.get("a", [0, 0])))
		var b = map._to_screen(Transport._pt(line.get("b", [0, 0])))
		if not map._seg_vis(a, b):
			continue
		var plan = rail_plan(Transport.utilization(line), map.zoom)
		if not bool(plan.enabled):
			continue
		_draw_rail_traffic(a, b, line, plan)
		drawn += 1

func _draw_rail_traffic(a: Vector2, b: Vector2, line: Dictionary, plan: Dictionary) -> void:
	var delta = b - a
	var length = delta.length()
	if length < 12.0:
		return
	var dir = delta / length
	var normal = Vector2(-dir.y, dir.x)
	var u = maxf(Transport.utilization(line), 0.0)
	var speed = (22.0 + minf(u, 1.5) * 25.0) / length
	var now = preview_time if preview_time >= 0.0 else _clock
	var seed_phase = fposmod(float(hash(str(line.get("id", ""))) & 0xffff) / 65535.0, 1.0)
	for index in int(plan.trains):
		var t = fposmod(now * speed + seed_phase + float(index) / float(plan.trains), 1.0)
		var p = a.lerp(b, t)
		if not map._vis(p, 45.0):
			continue
		_draw_train(p, dir, normal, int(plan.wagons), float(plan.fill), u > 1.0)

func _draw_train(p: Vector2, dir: Vector2, normal: Vector2, wagons: int, fill: float, overloaded: bool) -> void:
	var scale = clampf(0.75 + map.zoom * 0.035, 0.9, 1.7)
	var loco_len = 9.0 * scale
	var wagon_len = 8.0 * scale
	var gap = 2.0 * scale
	var half_w = 3.0 * scale
	var nose = p + dir * (loco_len * 0.5)
	var rear = p - dir * (loco_len * 0.5)
	var loco_col = Color("C8D0D8") if not overloaded else Color("E05A45")
	draw_colored_polygon(PackedVector2Array([
		nose, rear + normal * half_w, rear - normal * half_w,
	]), loco_col)
	draw_circle(rear + normal * half_w, 1.3 * scale, Color("151719"))
	draw_circle(rear - normal * half_w, 1.3 * scale, Color("151719"))
	for i in wagons:
		var center = p - dir * (loco_len * 0.5 + gap + wagon_len * 0.5 + i * (wagon_len + gap))
		var start = center - dir * wagon_len * 0.5
		var end = center + dir * wagon_len * 0.5
		var body = PackedVector2Array([start + normal * half_w, end + normal * half_w, end - normal * half_w, start - normal * half_w])
		draw_colored_polygon(body, Color("34383C"))
		var cargo_len = maxf(0.0, wagon_len - 2.0) * fill
		if cargo_len > 0.2:
			var cargo_start = start + dir
			var cargo_end = cargo_start + dir * cargo_len
			draw_colored_polygon(PackedVector2Array([cargo_start + normal * half_w * 0.62, cargo_end + normal * half_w * 0.62, cargo_end - normal * half_w * 0.62, cargo_start - normal * half_w * 0.62]), Color("D69A38") if not overloaded else Color("E05A45"))
		draw_polyline(body + PackedVector2Array([body[0]]), Color("E3E7EA"), 1.0)
