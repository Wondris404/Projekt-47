extends RefCounted
## Atlas-only cartographic presentation. Uses no simulation state or RNG.
const BORDER := Color("303437")
const BORDER_LIGHT := Color("d6cbb4", 0.30)
const SELECTED := Color("e4cf91")
const HOVER := Color("eee2bf")
const LABEL := Color("ede5d1")
const LABEL_SHADOW := Color("20282c", 0.85)
const PALETTE := [Color("a2a894"),Color("9aabb1"),Color("b9a697"),Color("a29aa8"),Color("c3b18d"),Color("8f9f90"),Color("b5a1a8"),Color("a7aea3"),Color("939fab"),Color("baa18e")]
const FIXED := {"FR":Color("bdac8c"),"DE":Color("8e909a"),"IT":Color("b8baa6"),"GB":Color("a48e9c"),"RU":Color("7e927a"),"US":Color("8c9faf"),"CN":Color("bfaa7f"),"BR":Color("7f9c80"),"IN":Color("ac9fa7"),"AU":Color("c1ad8c"),"SK":Color("b5a484")}
static var _font: FontVariation

static func political_color(iso: String, pixels_per_world_unit: float) -> Color:
	var c: Color = FIXED.get(iso, PALETTE[absi(iso.hash()) % PALETTE.size()])
	# Screen scale, not the UI zoom number: layout changes must not change style.
	c.a = lerpf(0.55,0.10,smoothstep(2.0,22.0,pixels_per_world_unit))
	return c

static func country_font() -> Font:
	if _font == null:
		_font = FontVariation.new()
		_font.base_font = load("res://assets/fonts/NotoSerif-Variable.ttf")
		_font.variation_opentype = {"wght":600.0,"wdth":90.0}
		_font.spacing_glyph = 1
	return _font

static func label_lines(title: String) -> PackedStringArray:
	var words := title.to_upper().split(" ",false)
	if title.length() < 17 or words.size()<2:
		return PackedStringArray([title.to_upper()])
	var cut := 1
	var balance := 10000
	for i in range(1,words.size()):
		var difference := absi(" ".join(words.slice(0,i)).length()-" ".join(words.slice(i)).length())
		if difference < balance:
			balance = difference
			cut = i
	return PackedStringArray([" ".join(words.slice(0,cut))," ".join(words.slice(cut))])

static func label_size(lines: PackedStringArray, available: Vector2) -> int:
	var font := country_font()
	var longest := 1.0
	for line in lines: longest = maxf(longest,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,24).x)
	return floori(minf(clampf(available.x*0.72/longest*24.0,0,40),available.y*0.30/lines.size()))

static func reserve_label(rect: Rect2, occupied: Array, view: Rect2) -> bool:
	if not view.encloses(rect): return false
	for old in occupied:
		if rect.grow(3).intersects(old): return false
	occupied.append(rect)
	return true
