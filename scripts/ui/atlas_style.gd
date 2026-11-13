extends RefCounted
## Atlas-only cartographic presentation. Uses no simulation state or RNG.
# P47 DESIGNS: static var namiesto const – DesignManager prepise farby atlasu zo sekcie design.json "map"
# (border, border_light, selected, hover, label, label_shadow) a farby krajin zo sekcie "countries"
# (palette = pole farieb, fixed = {ISO: farba}, alpha_far/alpha_near). DEFAULTS = presne povodne hodnoty.
const DEFAULTS := {
	"BORDER": Color("303437"),
	"BORDER_LIGHT": Color("d6cbb4", 0.30),
	"SELECTED": Color("e4cf91"),
	"HOVER": Color("eee2bf"),
	"LABEL": Color("ede5d1"),
	"LABEL_SHADOW": Color("20282c", 0.85),
}
const COUNTRY_DEFAULTS := {
	"PALETTE": [Color("a2a894"),Color("9aabb1"),Color("b9a697"),Color("a29aa8"),Color("c3b18d"),Color("8f9f90"),Color("b5a1a8"),Color("a7aea3"),Color("939fab"),Color("baa18e")],
	"FIXED": {"FR":Color("bdac8c"),"DE":Color("8e909a"),"IT":Color("b8baa6"),"GB":Color("a48e9c"),"RU":Color("7e927a"),"US":Color("8c9faf"),"CN":Color("bfaa7f"),"BR":Color("7f9c80"),"IN":Color("ac9fa7"),"AU":Color("c1ad8c"),"SK":Color("b5a484")},
	"ALPHA_FAR": 0.55,
	"ALPHA_NEAR": 0.10,
}
static var BORDER: Color = Color("303437")
static var BORDER_LIGHT: Color = Color("d6cbb4", 0.30)
static var SELECTED: Color = Color("e4cf91")
static var HOVER: Color = Color("eee2bf")
static var LABEL: Color = Color("ede5d1")
static var LABEL_SHADOW: Color = Color("20282c", 0.85)
static var PALETTE: Array = [Color("a2a894"),Color("9aabb1"),Color("b9a697"),Color("a29aa8"),Color("c3b18d"),Color("8f9f90"),Color("b5a1a8"),Color("a7aea3"),Color("939fab"),Color("baa18e")]
static var FIXED: Dictionary = {"FR":Color("bdac8c"),"DE":Color("8e909a"),"IT":Color("b8baa6"),"GB":Color("a48e9c"),"RU":Color("7e927a"),"US":Color("8c9faf"),"CN":Color("bfaa7f"),"BR":Color("7f9c80"),"IN":Color("ac9fa7"),"AU":Color("c1ad8c"),"SK":Color("b5a484")}
static var ALPHA_FAR: float = 0.55
static var ALPHA_NEAR: float = 0.10
static var _font: FontVariation

static func political_color(iso: String, pixels_per_world_unit: float) -> Color:
	var c: Color = FIXED.get(iso, PALETTE[absi(iso.hash()) % PALETTE.size()])
	# Screen scale, not the UI zoom number: layout changes must not change style.
	c.a = lerpf(ALPHA_FAR,ALPHA_NEAR,smoothstep(2.0,22.0,pixels_per_world_unit))
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
