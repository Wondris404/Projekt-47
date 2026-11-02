extends Node2D
# Presentation only: no simulation state or save fields. Capped work per visible line.
var map: Control
var _acc := 0.0
var _active := false
const MAX_TRAINS = 4
const MAX_MARKERS = 24
const MAX_VISIBLE_LINES = 64
const MAX_CIVIL_SHIPS = 32
const NEAR_ZOOM = 8.0
var _far_tex := {}
var _near := {}

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
	if map.atlas and has_node("/root/ShipSystem") and ShipSystem.fleet().size() > 0 and map.is_visible_in_tree():
		live = true
		if map.zoom >= NEAR_ZOOM and not map.GFX.low():
			_prepare_near_views()
	if live: map.anim_time += dt
	if live or _active: queue_redraw()
	_active = live

func _draw() -> void:
	_draw_ships()
	_draw_air()
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
	var mil = 0
	for s in ships:
		var military = str(s.get("kind", "")) == "military"
		if military:
			if mil >= MAX_CIVIL_SHIPS:
				continue
			mil += 1
		else:
			if n >= MAX_CIVIL_SHIPS:
				continue
			n += 1
		var sp = map._to_screen(ShipSystem.pos_of(s))
		if not Rect2(Vector2.ZERO, map.size).grow(40).has_point(sp):
			continue
		var heading = _ship_heading(s)
		var model_path := ShipSystem.model_path(str(s.get("kind_id", "")))
		if model_path != "":
			var near = map.zoom >= NEAR_ZOOM and not map.GFX.low() and _near.has(model_path)
			var tex: Texture2D = (_near[model_path] as SubViewport).get_texture() if near else _far_sprite(model_path)
			if tex == null:
				tex = _far_sprite(model_path)
			if tex != null:
				_draw_ship_tex(sp, heading, tex, _ship_px(model_path, near))
				continue
		# Chýbajúci model: pôvodný zlatý trojuholník.
		draw_colored_polygon(PackedVector2Array([sp + heading * 7, sp - heading * 5 + Vector2(0, 3), sp - heading * 5 - Vector2(0, 3)]), Color("D5AB39"))

func _ship_px(model_path: String, near: bool) -> Vector2:
	var stem = model_path.get_file().get_basename()
	var scale = 1.0
	if stem == "carrier" or stem == "landing":
		scale = 1.4
	elif stem == "tanker" or stem == "lng" or stem == "cargo" or stem == "bulk":
		scale = 1.15
	elif stem == "general":
		scale = 1.05
	elif stem == "submarine":
		scale = 0.9
	elif stem == "patrol" or stem == "psv":
		scale = 0.82
	var base = Vector2(36, 22) if near else Vector2(18, 10)
	return base * scale

func _ship_heading(ship: Dictionary) -> Vector2:
	var a = ShipSystem._port_pos(str(ship.get("src", "")))
	var b = ShipSystem._port_pos(str(ship.get("dst", "")))
	var d = b - a
	if d.length_squared() < 0.0001:
		return Vector2.RIGHT
	return d.normalized()

func _far_sprite(model_path: String) -> Texture2D:
	var sprite_path := "res://assets/sprites/ships/%s.png" % model_path.get_file().get_basename()
	if _far_tex.has(sprite_path):
		return _far_tex[sprite_path]
	if not ResourceLoader.exists(sprite_path):
		_far_tex[sprite_path] = null
		return null
	var tex = load(sprite_path)
	_far_tex[sprite_path] = tex
	return tex

func _prepare_near_views() -> void:
	var ships = GameState.ext.get("fleet", []) if typeof(GameState.ext) == TYPE_DICTIONARY else []
	if typeof(ships) != TYPE_ARRAY:
		return
	var n = 0
	for s in ships:
		if n >= MAX_CIVIL_SHIPS * 2:
			break
		n += 1
		var path := ShipSystem.model_path(str(s.get("kind_id", "")))
		if path != "":
			_near_texture(path)

func _near_texture(model_path: String) -> Texture2D:
	if _near.has(model_path):
		return (_near[model_path] as SubViewport).get_texture()
	if not ResourceLoader.exists(model_path):
		return null
	var packed = load(model_path)
	if packed == null or not (packed is PackedScene):
		return null
	var vp := SubViewport.new()
	vp.name = "Ship3D"
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.size = Vector2i(128, 96)
	vp.gui_disable_input = true
	# Loď sa nehýbe v 3D, stačí jeden snímok. Každý snímok by stiahol FPS pod 30.
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.9, 0.94)
	env.ambient_light_energy = 1.15
	var lighting := WorldEnvironment.new()
	lighting.environment = env
	world.add_child(lighting)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -30, 0)
	sun.light_energy = 1.5
	world.add_child(sun)
	var inst = (packed as PackedScene).instantiate()
	world.add_child(inst)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 4.8
	cam.position = Vector3(2.1, 2.3, 2.6)
	cam.look_at(Vector3(0, 0.55, 0))
	cam.current = true
	world.add_child(cam)
	_near[model_path] = vp
	return vp.get_texture()

func _draw_ship_tex(sp: Vector2, heading: Vector2, tex: Texture2D, sz: Vector2) -> void:
	# Sprite má predok hore (-Y). Otočenie zarovná predok na smer plavby.
	draw_set_transform(sp, heading.angle() + PI * 0.5, Vector2.ONE)
	draw_texture_rect(tex, Rect2(-sz * 0.5, sz), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

const AIR_TEX = {
	"heli": preload("res://assets/models/aircraft/heli_sprite.png"),
	"fighter": preload("res://assets/models/aircraft/fighter_sprite.png"),
}

# Lietadlá DLC idú cez dopravu lodí (ShipSystem.air_traffic), nie vlastný systém.
func _draw_air() -> void:
	if not has_node("/root/ShipSystem") or map.GFX.low():
		return
	var icon = map.zoom < 8.0
	var now = Time.get_ticks_msec()
	for e in ShipSystem.air_traffic(map.anim_time):
		var sp = map._to_screen(e.pos)
		if not Rect2(Vector2.ZERO, map.size).grow(48).has_point(sp):
			continue
		var kind = str(e.kind)
		var col = Color(0.95, 0.86, 0.28) if kind == "heli" else Color(0.45, 0.78, 1.0)
		if e.state == "crash":
			var k = fposmod(now / 900.0, 1.0)
			draw_circle(sp, 4.0 + 8.0 * k, Color(1.0, 0.35, 0.1, 0.9 - 0.8 * k))
			draw_circle(sp + Vector2(2, -6.0 - 8.0 * k), 3.0 + 4.0 * k, Color(0.25, 0.25, 0.25, 0.6 - 0.5 * k))
			continue
		if e.state == "hover":
			sp.y += sin(now / 160.0) * 2.0
			draw_arc(sp, 9.0, 0.0, TAU, 16, Color(col, 0.5), 1.0)
		if icon:
			# Oddialená mapa: len malá ikona.
			draw_circle(sp, 3.5, col)
			draw_circle(sp, 1.5, Color.BLACK)
		else:
			var tex: Texture2D = AIR_TEX.get(kind)
			var sz = Vector2(28, 28) if kind == "heli" else Vector2(32, 32)
			draw_set_transform(sp, e.heading.angle(), Vector2.ONE)
			draw_texture_rect(tex, Rect2(-sz / 2.0, sz), false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if kind == "fighter" and int(e.flash) > 0 and int(now / 180) % 2 == 0:
			# Útok: záblesk a stopa striel.
			draw_circle(sp, 11.0, Color(1.0, 0.35, 0.15, 0.35))
			draw_line(sp, sp + e.heading * 18.0, Color(1.0, 0.8, 0.3, 0.9), 1.5)
