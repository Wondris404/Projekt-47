extends Control
# JUAN4: pixelove intro (240x160 SubViewport, nearest-neighbour). Styl: ~70 % referencia (cerveno-biele pruhy,
# ordered dithering, tvrde tienovanie, vysoky kontrast) + ~30 % farby (zapad slnka, tyrkysove more, oblecenie).
# Esc / klik = preskocit, Medzernik = dalsia scena. Vsetko kreslene kodom, ziadne cudzie assety.
signal finished

const W = 240
const H = 160
# obmedzena paleta (16 farieb)
const P = {
	"k": Color8(12, 8, 10), "d": Color8(58, 52, 58), "g": Color8(120, 114, 120), "l": Color8(190, 186, 190), "w": Color8(250, 248, 244),
	"R": Color8(150, 10, 18), "r": Color8(226, 28, 30), "p": Color8(246, 140, 130),
	"o": Color8(250, 120, 30), "y": Color8(255, 206, 80), "T": Color8(10, 90, 100), "t": Color8(40, 170, 170),
	"s": Color8(240, 190, 150), "S": Color8(180, 120, 90), "b": Color8(40, 70, 160), "n": Color8(130, 80, 40),
}
const BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

var nick = "Hráč"
var gender = "muž"
var scene_i = 0
var t = 0.0
var typed = 0.0
var vp: SubViewport
var canvas: Node2D
var view: TextureRect
var text_label: Label
var bgs: Array = []
var lines: Array = []
var done = false
var arts: Array = []
const AH = 142

func setup(p_nick: String, p_gender: String) -> void:
	nick = p_nick if p_nick.strip_edges() != "" else "Hráč"
	gender = p_gender

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 90
	call_deferred("_fit_size")
	get_viewport().size_changed.connect(_fit_size)
	var bg = ColorRect.new()
	bg.color = P.k
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	vp = SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(vp)
	canvas = Node2D.new()
	canvas.draw.connect(_paint)
	vp.add_child(canvas)
	view = TextureRect.new()
	view.texture = vp.get_texture()
	view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED  # JUAN7: obraz vyplni celu obrazovku
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)
	# JUAN7: titulky vo velkom tmavom poloprehladnom boxe, velkost podla okna, ostre pismo (LINEAR filter, nie v SubViewporte)
	text_box = PanelContainer.new()
	var sbx = StyleBoxFlat.new()
	sbx.bg_color = Color(0, 0, 0, 0.72)
	sbx.border_color = Color(1.0, 0.78, 0.25, 0.9)
	sbx.set_border_width_all(2)
	sbx.set_corner_radius_all(6)
	sbx.set_content_margin_all(14)
	text_box.add_theme_stylebox_override("panel", sbx)
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(text_box)
	text_label = Label.new()
	text_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 40)
	text_label.add_theme_color_override("font_color", Color(1, 1, 1))
	text_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	text_label.add_theme_constant_override("outline_size", 12)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	text_label.add_theme_constant_override("shadow_offset_x", 3)
	text_label.add_theme_constant_override("shadow_offset_y", 3)
	text_box.add_child(text_label)
	hint_box = PanelContainer.new()
	var sbh = StyleBoxFlat.new()
	sbh.bg_color = Color(0, 0, 0, 0.72)
	sbh.set_corner_radius_all(6)
	sbh.set_content_margin_all(8)
	hint_box.add_theme_stylebox_override("panel", sbh)
	hint_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_box.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(hint_box)
	hint_label = Label.new()
	hint_label.text = "Medzerník = ďalej    Esc / klik = preskočiť"
	hint_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	hint_label.add_theme_color_override("font_color", Color(1, 1, 1))
	hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	hint_label.add_theme_constant_override("outline_size", 6)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_box.add_child(hint_label)
	_fit_size()
	lines = story_lines(nick, gender)
	bgs = [_bg_office(), _bg_hall(), _bg_night(), _bg_sunset()]
	# JUAN4: schvalene koncepty (assets/intro/sN_m|f.png, 240x142, 32 farieb) + animovane vrstvy navrchu
	var gk = "f" if gender == "žena" else "m"
	for i in 4:
		var path = "res://assets/intro/s%d_%s.png" % [i + 1, gk]
		arts.append(preload("res://scripts/ui/tex_util.gd").load_tex(path))  # JUAN7: aj bez importu
	if arts[0] != null:
		vp.size = Vector2i(W, AH)

var text_box: PanelContainer
var hint_box: PanelContainer
var hint_label: Label

func _fit_size() -> void:
	if is_inside_tree():
		position = Vector2.ZERO
		size = get_viewport_rect().size
	if text_box == null or not is_inside_tree():
		return
	var vs = get_viewport_rect().size
	var k = clampf(vs.y / 720.0, 0.8, 2.5)
	text_label.add_theme_font_size_override("font_size", int(40 * k))
	text_label.add_theme_constant_override("outline_size", int(10 * k))
	var bh = 40.0 * k * 2.8 + 28.0
	text_box.position = Vector2(vs.x * 0.06, vs.y - bh - 20.0 * k)
	text_box.size = Vector2(vs.x * 0.88, bh)
	hint_label.add_theme_font_size_override("font_size", int(24 * k))
	hint_box.position = Vector2(14, 12)
	hint_box.reset_size()

static func story_lines(n: String, g: String) -> Array:
	var u = n.to_upper()
	if g == "žena":
		return ["%s, SI VYHODENÁ." % u, "A PARTNER ŤA OPUSTIL. OSTALA SI SAMA.", "BUDEM NAJBOHATŠÍ ČLOVEK NA SVETE!",
			"RAZ BUDEM NAJBOHATŠIA. ŠAMPANSKÉ S ALONOM MOSKOM, JAFFOM BEZOSSOM, BILLOM GAYTESOM A MORKOM ZUCKERBARGOM."]
	if g == "iné":
		return ["%s, VYHODILI ŤA Z KORPORÁTU." % u, "A TVOJA LÁSKA ŤA OPUSTILA. OSTALO SI SAMO.", "BUDEM NAJBOHATŠÍ ČLOVEK NA SVETE!",
			"RAZ BUDEM NAJBOHATŠÍ. ŠAMPANSKÉ S ALONOM MOSKOM, JAFFOM BEZOSSOM, BILLOM GAYTESOM A MORKOM ZUCKERBARGOM."]
	return ["%s, SI VYHODENÝ." % u, "A PARTNERKA ŤA OPUSTILA. OSTAL SI SÁM.", "BUDEM NAJBOHATŠÍ ČLOVEK NA SVETE!",
		"RAZ BUDEM NAJBOHATŠÍ. ŠAMPANSKÉ S ALONOM MOSKOM, JAFFOM BEZOSSOM, BILLOM GAYTESOM A MORKOM ZUCKERBARGOM."]

func _bayer(x: int, y: int) -> float:
	return (float(BAYER[y % 4][x % 4]) + 0.5) / 16.0

# JUAN4: farebne prostredia (chunky pixely, gradienty cez ordered dithering)
func _grad(img: Image, y0: int, y1: int, a: Color, b: Color) -> void:
	for y in range(y0, y1):
		var f = float(y - y0) / max(1.0, float(y1 - y0))
		for x in W:
			img.set_pixel(x, y, b if f > _bayer(x, y) else a)

func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), c)

func _bg_office() -> ImageTexture:
	var img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	_grad(img, 0, 100, P.l, P.g)
	_grad(img, 100, H, P.g, P.d)
	for x in range(0, W, 16):
		_rect(img, x, 100, 1, 60, P.d)
	for x in range(10, W, 60):
		_rect(img, x, 40, 26, 60, P.n)
		_rect(img, x + 2, 42, 22, 56, Color8(160, 100, 50))
		_rect(img, x + 20, 70, 2, 3, P.y)
		_rect(img, x + 4, 46, 18, 10, P.t)
	for x in range(30, W, 60):
		_rect(img, x, 4, 20, 3, P.w)
	return ImageTexture.create_from_image(img)

func _bg_hall() -> ImageTexture:
	var img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	_grad(img, 0, 104, Color8(230, 200, 150), Color8(200, 150, 100))
	_grad(img, 104, H, P.n, Color8(90, 50, 25))
	for x in range(0, W, 12):
		_rect(img, x, 104, 1, 56, Color8(90, 50, 25))
	_rect(img, 196, 34, 34, 70, P.n)
	_rect(img, 199, 37, 28, 67, Color8(110, 60, 30))
	_rect(img, 222, 72, 2, 3, P.y)
	_rect(img, 30, 30, 30, 22, P.n)
	_rect(img, 32, 32, 26, 18, P.t)
	_rect(img, 32, 42, 26, 8, Color8(60, 140, 60))
	return ImageTexture.create_from_image(img)

func _bg_night() -> ImageTexture:
	var img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	_grad(img, 0, 110, Color8(16, 20, 50), Color8(40, 40, 90))
	_grad(img, 110, H, Color8(40, 30, 50), P.k)
	_rect(img, 150, 20, 70, 56, P.d)
	_grad_rect(img, 153, 23, 64, 50, Color8(10, 14, 40), Color8(50, 40, 100))
	for i in 12:
		_rect(img, 156 + (i * 23) % 58, 50 + (i * 7) % 20, 2, 2, P.y)
	_rect(img, 200, 28, 6, 6, P.w)
	_rect(img, 10, 116, 70, 16, P.b)
	_rect(img, 10, 112, 20, 6, P.w)
	return ImageTexture.create_from_image(img)

func _grad_rect(img: Image, x0: int, y0: int, w: int, h: int, a: Color, b: Color) -> void:
	for y in range(y0, y0 + h):
		var f = float(y - y0) / float(h)
		for x in range(x0, x0 + w):
			img.set_pixel(x, y, b if f > _bayer(x, y) else a)

func _bg_sunset() -> ImageTexture:
	var img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var c: Color
			if y < 92:
				var f = float(y) / 92.0
				var thr = _bayer(x, y)
				if f < 0.4:
					c = P.o if f / 0.4 > thr else Color8(120, 60, 140)
				elif f < 0.75:
					c = P.y if (f - 0.4) / 0.35 > thr else P.o
				else:
					c = P.p if (f - 0.75) / 0.25 > thr else P.y
			else:
				var g = float(y - 92) / 68.0
				c = P.t if g > _bayer(x, y) * 1.4 else P.T
				if (y % 6 == 0) and ((x + y * 3) % 11 < 4):
					c = P.w if y < 110 else P.t
			img.set_pixel(x, y, c)
	for y in range(66, 92):
		for x in range(40, 80):
			if Vector2(x, y).distance_to(Vector2(60, 92)) < 18:
				img.set_pixel(x, y, P.w if (x + y) % 3 else P.y)
	return ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	t += delta
	if scene_i < lines.size():
		typed = min(float(str(lines[scene_i]).length()), typed + delta * 28.0)
		text_label.text = str(lines[scene_i]).substr(0, int(typed))
		text_label.add_theme_font_size_override("font_size", 40 if str(lines[scene_i]).length() < 50 else 28)
	canvas.queue_redraw()

func next() -> void:
	if scene_i < lines.size() and typed < float(str(lines[scene_i]).length()):
		typed = float(str(lines[scene_i]).length())
		return
	scene_i += 1
	typed = 0.0
	t = 0.0
	if scene_i >= lines.size():
		finish()

func finish() -> void:
	if done:
		return
	done = true
	finished.emit()
	queue_free()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		finish()
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			finish()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			next()
		get_viewport().set_input_as_handled()

# ===== kreslenie (v pixeloch 240x160) =====
func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	canvas.draw_rect(Rect2(floor(x), floor(y), w, h), c)

func _dither_rect(x: int, y: int, w: int, h: int, a: Color, b: Color) -> void:
	_px(x, y, w, h, a)
	for yy in h:
		for xx in w:
			if (xx + yy) % 2 == 0:
				_px(x + xx, y + yy, 1, 1, b)

# postavicka: s = mierka, shirt = farba, hair = farba, long = dlhe vlasy, frame = animacia
func _person(x: float, y: float, s: int, shirt: Color, hair: Color, long_hair: bool, frame: int, arm_up: bool = false, glass: bool = false) -> void:
	var bob = float(frame % 2) * s
	y += bob
	# nohy
	_px(x + 2 * s, y + 22 * s, 2 * s, 8 * s, P.d)
	_px(x + 6 * s, y + 22 * s, 2 * s, 8 * s, P.d)
	_px(x + 1 * s, y + 29 * s, 3 * s, 1 * s, P.k)
	_px(x + 6 * s, y + 29 * s, 3 * s, 1 * s, P.k)
	# telo + tvrdy tien (dither vpravo)
	_px(x, y + 10 * s, 10 * s, 12 * s, shirt)
	for yy in range(10 * s, 22 * s):
		for xx in range(7 * s, 10 * s):
			if (xx + yy) % 2 == 0:
				_px(x + xx, y + yy, 1, 1, shirt.darkened(0.45))
	_px(x, y + 10 * s, 10 * s, s, P.k)
	# ruky
	if arm_up:
		_px(x + 10 * s, y + 2 * s, 2 * s, 9 * s, shirt)
		_px(x + 10 * s, y, 3 * s, 3 * s, P.s)
	else:
		_px(x + 10 * s, y + 11 * s, 2 * s, 8 * s, shirt.darkened(0.3))
		_px(x + 10 * s, y + 19 * s, 2 * s, 2 * s, P.s)
	_px(x - 2 * s, y + 11 * s, 2 * s, 8 * s, shirt)
	_px(x - 2 * s, y + 19 * s, 2 * s, 2 * s, P.s)
	if glass:
		_px(x + 11 * s, y + 15 * s, s, 4 * s, P.y)
		_px(x + 10 * s, y + 14 * s, 3 * s, s, P.w)
	# hlava
	_px(x + 1 * s, y + 2 * s, 8 * s, 8 * s, P.s)
	_px(x + 6 * s, y + 3 * s, 3 * s, 7 * s, P.S)
	_px(x + 3 * s, y + 5 * s, s, s, P.k)
	_px(x + 6 * s, y + 5 * s, s, s, P.k)
	_px(x + 4 * s, y + 8 * s, 2 * s, s, P.R)
	# vlasy
	_px(x, y, 10 * s, 3 * s, hair)
	_px(x, y + 2 * s, 2 * s, 3 * s, hair)
	if long_hair:
		_px(x - s, y + 2 * s, 2 * s, 10 * s, hair)
		_px(x + 8 * s, y + 2 * s, 2 * s, 9 * s, hair)

func _player_long() -> bool:
	return gender == "žena"

func _bubble(x: int, y: int, w: int, txt: String) -> void:
	_px(x, y, w, 11, P.k)
	_px(x + 1, y + 1, w - 2, 9, P.w)
	_px(x + 4, y + 11, 2, 2, P.w)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(x + 2, y + 8), txt, HORIZONTAL_ALIGNMENT_LEFT, w - 3, 7, P.k)

func _logo() -> void:
	_px(4, H - 13, 62, 10, P.k)
	_px(5, H - 12, 60, 8, P.w)
	_px(7, H - 11, 4, 6, P.r)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(13, H - 5), "WONDRIS404", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, P.k)

func _paint() -> void:
	var si = mini(scene_i, 3)
	if arts.size() > si and arts[si] != null:
		_paint_art(si)
		return
	canvas.draw_texture(bgs[si], Vector2.ZERO)
	var fr = int(t * 4.0)
	match si:
		0:
			# kancelaria: stol, sef ukazuje von, hrac s krabicou
			_dither_rect(20, 100, 90, 8, P.n, P.k)
			_px(24, 108, 4, 30, P.k)
			_px(102, 108, 4, 30, P.k)
			_px(30, 84, 22, 16, P.d)
			_px(32, 86, 18, 11, P.t)
			_person(60, 60, 2, P.d, P.g, false, fr, true)
			_px(64, 80, 2, 10, P.r)
			_person(150 + min(t * 6.0, 30.0), 62, 2, P.b, P.n if gender != "žena" else P.k, _player_long(), fr)
			_dither_rect(144 + int(min(t * 6.0, 30.0)), 96, 30, 16, P.o, P.n)
			_px(150 + min(t * 6.0, 30.0), 92, 6, 4, P.l)
			_px(160 + min(t * 6.0, 30.0), 90, 3, 6, P.t)
		1:
			var walk = t * 14.0
			_dither_rect(40, 124, 26, 14, P.o, P.n)
			_px(44, 120, 6, 4, P.l)
			_px(54, 118, 3, 6, P.t)
			_person(70, 64, 2, P.b, P.n if gender != "žena" else P.k, _player_long(), 0)
			# slzy
			for k in 3:
				var ty = 76 + int(fmod(t * 20.0 + k * 4.0, 12.0))
				_px(75, ty, 2, 3, P.t)
				_px(83, ty + 2, 2, 3, P.t)
			var px = 140 + walk
			_person(px, 64, 2, P.r if gender != "žena" else P.T, P.y if gender != "žena" else P.d, gender != "žena", fr)
			# kufor
			_px(px + 24, 100, 14, 18, P.R)
			_px(px + 26, 102, 10, 2, P.k)
			_px(px + 28, 96, 6, 4, P.k)
		2:
			# velky detail: hrac zdviha past
			_person(84, 6, 5, P.b, P.n if gender != "žena" else P.k, _player_long(), fr, true)
			for i in 6:
				var a = t * 2.0 + float(i)
				_px(120 + cos(a) * 90.0, 70 + sin(a) * 50.0, 3, 3, P.y)
		3:
			_yacht(fr)
	_logo()

func _yacht(fr: int) -> void:
	var bob = float(fr % 2)
	var y0 = 92.0 + bob
	# trup (biely, ostra prida vlavo), tien dither
	var hull = PackedVector2Array([Vector2(8, y0 - 6), Vector2(232, y0 - 6), Vector2(222, y0 + 14), Vector2(40, y0 + 14)])
	canvas.draw_colored_polygon(hull, P.w)
	for x in range(40, 222):
		if x % 2 == 0:
			_px(x, y0 + 10, 1, 4, P.l)
	_px(30, y0 + 2, 194, 2, P.r)
	for x in range(48, 214, 10):
		_px(x, y0 - 2, 6, 3, P.k)
	# 3 paluby
	_px(36, y0 - 20, 178, 14, P.w)
	for x in range(42, 208, 9):
		_px(x, y0 - 16, 6, 5, P.T)
	_px(70, y0 - 32, 130, 12, P.w)
	for x in range(76, 194, 8):
		_px(x, y0 - 29, 5, 4, P.T)
	_px(100, y0 - 42, 80, 10, P.l)
	_px(104, y0 - 40, 72, 5, P.k)
	# heliport na zadnej palube
	_px(186, y0 - 34, 40, 3, P.l)
	canvas.draw_circle(Vector2(206, y0 - 37), 9.0, P.d)
	canvas.draw_arc(Vector2(206, y0 - 37), 8.0, 0.0, TAU, 16, P.y, 1.0)
	_px(203, y0 - 41, 1, 7, P.w)
	_px(208, y0 - 41, 1, 7, P.w)
	_px(203, y0 - 38, 6, 1, P.w)
	# radar / stoziar
	_px(138, y0 - 56, 2, 14, P.d)
	_px(132, y0 - 56, 14, 2, P.r)
	# gauc s vankusmi, hrac sedi uprostred so sampanskym
	_px(84, y0 - 30, 46, 4, P.n)
	_px(84, y0 - 40, 46, 10, P.R)
	for cx in range(86, 128, 10):
		_px(cx, y0 - 38, 8, 6, P.r)
		_px(cx + 1, y0 - 37, 3, 2, P.p)
	_sitting(100, y0 - 52, P.b, P.n if gender != "žena" else P.k, _player_long(), fr)
	# spolocnost v plavkach (dospeli, PG-13): opacne pohlavie k hracovi (iné = mix), opieraju sa o hraca
	var fem_l = gender != "žena"
	var fem_r = gender != "žena" if gender != "iné" else false
	_swimmer(90, y0 - 50, P.y, P.r, fem_l, fr + 1)
	_px(98, y0 - 40, 5, 2, P.s)
	_swimmer(112, y0 - 50, P.k if fem_r else P.n, P.t, fem_r, fr + 2)
	_px(108, y0 - 41, 5, 2, P.s)
	_px(104, y0 - 47, 2, 2, P.r)
	_px(108, y0 - 46, 2, 2, P.r)
	# parodicki miliardari okolo
	var cast = [[40, P.d, P.d], [58, P.o, P.l], [160, P.b, P.y], [180, P.T, P.n]]
	for i in cast.size():
		var c = cast[i]
		_person(float(c[0]), y0 - 50, 1, c[1], c[2], false, fr + i, i % 2 == 0, true)
	var bubbles = [[34, "Na zdravie!"], [52, "Vitaj v klube."], [150, "Na zdravie!"], [166, "Vitaj v klube."]]
	var bi = int(t * 0.8) % 4
	_bubble(clampi(int(bubbles[bi][0]) - 10, 2, W - 70), int(y0) - 70, 66, str(bubbles[bi][1]))

func _sitting(x: float, y: float, shirt: Color, hair: Color, long_hair: bool, frame: int) -> void:
	var bob = float(frame % 2)
	# nohy dopredu (sedi)
	_px(x + 2, y + 22, 10, 2, P.d)
	_px(x + 11, y + 22, 2, 6, P.d)
	_person_upper(x, y + bob, shirt, hair, long_hair)
	# ruka s pohárom hore (prípitok)
	_px(x + 10, y + 6 + bob, 2, 6, shirt)
	_px(x + 10, y + 4 + bob, 2, 2, P.s)
	_px(x + 11, y + 1 + bob, 1, 3, P.y)
	_px(x + 10, y + bob, 3, 1, P.w)

func _person_upper(x: float, y: float, shirt: Color, hair: Color, long_hair: bool) -> void:
	_px(x, y + 10, 10, 12, shirt)
	for yy in range(10, 22):
		for xx in range(7, 10):
			if (xx + yy) % 2 == 0:
				_px(x + xx, y + yy, 1, 1, shirt.darkened(0.45))
	_px(x + 1, y + 2, 8, 8, P.s)
	_px(x + 6, y + 3, 3, 7, P.S)
	_px(x + 3, y + 5, 1, 1, P.k)
	_px(x + 6, y + 5, 1, 1, P.k)
	_px(x + 4, y + 8, 2, 1, P.R)
	_px(x, y, 10, 3, hair)
	_px(x, y + 2, 2, 3, hair)
	if long_hair:
		_px(x - 1, y + 2, 2, 10, hair)
		_px(x + 8, y + 2, 2, 9, hair)

# dospela postava v plavkach (decentne: jednodielne / sortky)
func _swimmer(x: float, y: float, hair: Color, suit: Color, female: bool, frame: int) -> void:
	var bob = float(frame % 2)
	y += bob
	_px(x + 2, y + 22, 2, 8, P.s)
	_px(x + 6, y + 22, 2, 8, P.s)
	_px(x, y + 10, 10, 12, P.s)
	for yy in range(10, 22):
		if yy % 2 == 0:
			_px(x + 8, y + yy, 2, 1, P.S)
	if female:
		_px(x + 1, y + 12, 8, 10, suit)
	else:
		_px(x, y + 18, 10, 5, suit)
	_px(x - 2, y + 11, 2, 9, P.s)
	_px(x + 10, y + 11, 2, 9, P.s)
	_px(x + 1, y + 2, 8, 8, P.s)
	_px(x + 6, y + 3, 3, 7, P.S)
	_px(x + 3, y + 5, 1, 1, P.k)
	_px(x + 6, y + 5, 1, 1, P.k)
	_px(x + 3, y + 4, 5, 1, P.k)
	_px(x, y, 10, 3, hair)
	if female:
		_px(x - 1, y + 2, 2, 11, hair)
		_px(x + 8, y + 2, 2, 10, hair)

# ===== JUAN4: animacia nad konceptmi =====
# casti obrazu (postavy) sa prekresluju posunute o 1 px (dychanie/bob), plus efekty: slzy, sviecka, hviezdy, bublinky, more
const BOB = [
	[[Rect2(48, 20, 92, 122), 0], [Rect2(126, 14, 76, 128), 1]],
	[[Rect2(62, 40, 80, 102), 0], [Rect2(158, 18, 40, 104), 1]],
	[[Rect2(48, 4, 116, 130), 0]],
	[[Rect2(0, 22, 92, 70), 1], [Rect2(144, 22, 96, 70), 0], [Rect2(20, 56, 200, 90), 0]],
]

func _paint_art(si: int) -> void:
	var tex: Texture2D = arts[si]
	var full = Rect2(0, 0, W, AH)
	canvas.draw_texture_rect(tex, full, false)
	var ts = tex.get_size()
	var kx = ts.x / float(W)
	var ky = ts.y / float(AH)
	var fr = int(t * 4.0)
	for part in BOB[si]:
		var r: Rect2 = part[0]
		var dy = -1.0 if (fr + int(part[1])) % 2 == 0 else 0.0
		if si == 2:
			dy = -1.0 if fr % 2 == 0 else 0.0
		if dy != 0.0:
			canvas.draw_texture_rect_region(tex, Rect2(r.position + Vector2(0, dy), r.size), Rect2(r.position.x * kx, r.position.y * ky, r.size.x * kx, r.size.y * ky))
	match si:
		0:
			# kvapka potu + blikajuce svetla
			var sy = 52 + int(fmod(t * 10.0, 10.0))
			_px(96, sy, 1, 2, P.t)
			if fr % 4 == 0:
				_px(150, 6, 20, 1, P.w)
		1:
			for k in 3:
				var ty = 76 + int(fmod(t * 16.0 + k * 4.0, 14.0))
				_px(84, ty, 1, 2, Color8(120, 200, 255))
				_px(98, ty + 2, 1, 2, Color8(120, 200, 255))
			if fr % 6 < 3:
				_px(195, 37, 2, 2, P.y)
		2:
			var fl = 0.6 + 0.4 * sin(t * 13.0)
			canvas.draw_circle(Vector2(172, 92), 3.0 * fl + 1.0, Color(1.0, 0.7, 0.2, 0.55))
			for i in 8:
				if (fr + i) % 3 == 0:
					_px(4 + (i * 13) % 60, 4 + (i * 7) % 30, 1, 1, P.w)
			_px(195 + (fr % 8) * 3, 100 - (fr % 8), 2, 1, Color8(60, 230, 90))
		3:
			for i in 10:
				var bx = [25, 84, 152, 220, 112][i % 5] + (i / 5) * 2
				var by = 10 + int(fmod(t * 12.0 + i * 3.0, 10.0))
				_px(bx, by, 1, 1, P.w)
			# JUAN8: odstranene trblietky mora na y=62 – na obrazku jachty padali na zabradlie (biele ciarky)
			if fr % 8 < 4:
				_px(100, 30, 40, 1, Color(1, 1, 1, 0.0))
