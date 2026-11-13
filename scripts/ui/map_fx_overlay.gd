extends Control
# p47/gfx (kolo 2): vizualna vrstva nad 2D mapou – glow pri hover na krajine, pulzujuci vyber
# a vnutorny tien okraja mapy. Iba kreslenie: data mapy, hover aj vyber cita z world_map.gd, nic nemeni.

const HOVER_GLOW := Color(1.0, 0.93, 0.72)
const SELECT_GLOW := Color(0.98, 0.74, 0.30)
const FPS := 30.0

var map: Control
var _t := 0.0
var _acc := 0.0
var _by_iso: Dictionary = {}
var _last_key := ""

func setup(world_map: Control) -> void:
	map = world_map
	name = "MapFxOverlay"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# vnutorny tien okraja (lacny shader, kresli sa raz za snimku GPU)
	var vign := ColorRect.new()
	vign.name = "MapInnerShadow"
	vign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vign.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/ui/edge_pulse.gdshader")
	m.set_shader_parameter("tint", Color(0.0, 0.0, 0.0, 0.85))
	m.set_shader_parameter("width", 0.07)
	vign.material = m
	add_child(vign)

func _shape(iso: String):
	if _by_iso.size() != map.shapes.size():
		_by_iso.clear()
		for sh in map.shapes:
			_by_iso[str(sh.iso)] = sh
	return _by_iso.get(iso, null)

func _process(delta: float) -> void:
	if map == null or not is_visible_in_tree():
		return
	_t += delta
	_acc += delta
	var key := "%s|%s|%s|%s" % [str(map.hover), str(GameState.selected_iso), str(map.zoom), str(map.pan)]
	var animating := str(GameState.selected_iso) != ""
	if key != _last_key or (animating and _acc >= 1.0 / FPS):
		_last_key = key
		_acc = 0.0
		queue_redraw()

func _draw() -> void:
	if map == null or not ("shapes" in map):
		return
	var sc: float = map._fit() * map.zoom
	if sc <= 0.0001:
		return
	var inv := 1.0 / sc
	draw_set_transform(map._origin(), 0.0, Vector2(sc, sc))
	var hv := str(map.hover)
	var sel := str(GameState.selected_iso)
	if hv != "" and hv != sel:
		var sh = _shape(hv)
		if sh != null:
			_fill(sh, Color(HOVER_GLOW, 0.07))
			_outline(sh, Color(HOVER_GLOW, 0.10), 11.0 * inv)
			_outline(sh, Color(HOVER_GLOW, 0.22), 6.0 * inv)
			_outline(sh, Color(HOVER_GLOW, 0.9), 1.6 * inv)
	if sel != "":
		var ss = _shape(sel)
		if ss != null:
			var p := 0.5 + 0.5 * sin(_t * 3.2)
			_fill(ss, Color(SELECT_GLOW, 0.05 + 0.07 * p))
			_outline(ss, Color(SELECT_GLOW, 0.10 + 0.12 * (1.0 - p)), (8.0 + 10.0 * p) * inv)
			_outline(ss, Color(SELECT_GLOW, 0.35), 4.0 * inv)
			_outline(ss, Color(1.0, 0.95, 0.8, 0.95), 1.8 * inv)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _fill(sh: Dictionary, c: Color) -> void:
	var m = sh.get("mesh")
	if m is ArrayMesh and m.get_surface_count() > 0:
		draw_mesh(m, null, Transform2D.IDENTITY, c)

func _outline(sh: Dictionary, c: Color, w: float) -> void:
	for poly in sh.polys:
		if poly.size() >= 2:
			draw_polyline(poly, c, w, false)
