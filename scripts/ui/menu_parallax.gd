extends Control
# p47/gfx (kolo 2): parallax vrstvy hlavneho menu nad pixelovym mestom – hmla nad vodou,
# kuzele svetlometov a mestska ziara. Kazda vrstva sa posuva s mysou inou hlbkou. Iba kreslenie, ~30 FPS.

const FPS := 30.0
var bg: Control              # pixelovy obrazok mesta (najhlbsia vrstva), posuva ho main_menu
var mouse_off := Vector2.ZERO  # vyhladeny posun mysi (-0.5..0.5)
var _t := 0.0
var _acc := 0.0
var _haze: Texture2D
var _glow: Texture2D

func _ready() -> void:
	name = "MenuParallax"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var g := Gradient.new()
	g.set_color(0, Color(0.75, 0.8, 1.0, 0.0))
	g.set_color(1, Color(0.75, 0.8, 1.0, 0.0))
	g.add_point(0.5, Color(0.75, 0.82, 1.0, 0.16))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	gt.width = 8
	gt.height = 64
	_haze = gt
	var rg := Gradient.new()
	rg.set_color(0, Color(1.0, 0.72, 0.35, 0.22))
	rg.set_color(1, Color(1.0, 0.6, 0.3, 0.0))
	var rt := GradientTexture2D.new()
	rt.gradient = rg
	rt.fill = GradientTexture2D.FILL_RADIAL
	rt.fill_from = Vector2(0.5, 0.5)
	rt.fill_to = Vector2(1.0, 0.5)
	rt.width = 128
	rt.height = 128
	_glow = rt

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	var vs := get_viewport_rect().size
	var m := get_viewport().get_mouse_position()
	var target := Vector2(clampf(m.x / maxf(vs.x, 1.0), 0.0, 1.0) - 0.5, clampf(m.y / maxf(vs.y, 1.0), 0.0, 1.0) - 0.5)
	mouse_off = mouse_off.lerp(target, clampf(delta * 3.0, 0.0, 1.0))
	_acc += delta
	if _acc >= 1.0 / FPS:
		_acc = 0.0
		queue_redraw()

func layer_offset(depth: float) -> Vector2:
	return -mouse_off * 28.0 * depth

func _draw() -> void:
	var vs := size
	# 1) mestska ziara na horizonte (hlbka 1.2), jemne dycha
	var gp := Vector2(vs.x * 0.5, vs.y * 0.62) + layer_offset(1.2)
	var gs := Vector2(vs.x * 1.1, vs.y * 0.5) * (1.0 + 0.03 * sin(_t * 0.7))
	draw_texture_rect(_glow, Rect2(gp - gs * 0.5, gs), false, Color(1, 1, 1, 0.8 + 0.2 * sin(_t * 0.9)))
	# 2) dva svetlomety (hlbka 1.5) – pomaly sa kyvu, aditivne svetlo
	for i in 2:
		var base := Vector2(vs.x * (0.22 if i == 0 else 0.8), vs.y * 0.66) + layer_offset(1.5)
		var ang := -PI * 0.5 + sin(_t * (0.21 + 0.07 * i) + i * 2.1) * 0.42
		_beam(base, ang, vs.y * 0.95, 0.07)
	# 3) hmla nad vodou (hlbka 2.2) – dva pasy, kazdy ide inou rychlostou
	for j in 2:
		var y := vs.y * (0.6 + 0.09 * j)
		var drift := fmod(_t * (12.0 + 9.0 * j), vs.x)
		var off := layer_offset(2.2 + j * 0.8)
		var h := vs.y * (0.10 + 0.04 * j)
		for k in [-1, 0]:
			draw_texture_rect(_haze, Rect2(Vector2(drift + k * vs.x - 40.0, y - h * 0.5) + off, Vector2(vs.x + 80.0, h)), false, Color(1, 1, 1, 0.75 - 0.25 * j))

func _beam(base: Vector2, ang: float, length: float, spread: float) -> void:
	var left := base + Vector2.from_angle(ang - spread) * length
	var right := base + Vector2.from_angle(ang + spread) * length
	var tip_c := Color(1.0, 0.93, 0.75, 0.0)
	var base_c := Color(1.0, 0.93, 0.75, 0.13)
	draw_polygon(PackedVector2Array([base, left, right]), PackedColorArray([base_c, tip_c, tip_c]))
	draw_polygon(PackedVector2Array([base, base + Vector2.from_angle(ang - spread * 0.35) * length, base + Vector2.from_angle(ang + spread * 0.35) * length]),
		PackedColorArray([Color(base_c, 0.10), tip_c, tip_c]))
	draw_circle(base, 3.0, Color(1.0, 0.95, 0.8, 0.6))
