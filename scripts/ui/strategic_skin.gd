extends RefCounted
const DIR := "res://assets/ui/strategic/"
# P47 DESIGNS: farby a parametre HUD su static var – DesignManager ich prepise zo sekcie design.json "hud"
# (kluc = nazov malymi pismenami, napr. "text", "card_bg"). DEFAULTS = presne hodnoty gfx kola 2 (dizajn "current").
const DEFAULTS := {
	"TEXT": Color("e6dcc5"),
	"MUTED": Color("a8aa9e"),
	"GOLD": Color("d6b876"),
	"UP": Color("92c79b"),
	"DOWN": Color("e08d7b"),
	"AMBER": Color("ddb56a"),
	"HOVER_TEXT": Color("fff0cc"),
	"BADGE_BG": Color("343c3c"),
	"BADGE_BORDER": Color("76674e"),
	"FRAME_MODULATE": Color(1, 1, 1),
	"BUTTON_HOVER_MODULATE": Color(1.20, 1.14, 1.02),
	"BUTTON_PRESSED_MODULATE": Color(1.35, 1.16, .80),
	"CARD_BG": Color("1d2229"),
	"CARD_BG_2": Color("181c22"),
	"CARD_BORDER": Color("3a424e"),
	"CARD_ACCENT_CASH": Color("e8a33d"),
	"CARD_ACCENT_DEBT": Color("e08d7b"),
	"CARD_ACCENT_WORTH": Color("92c79b"),
	"CARD_ACCENT_OTHER": Color("5b6676"),
	"CARD_SHADOW": Color(0, 0, 0, 0.4),
	"CARD_RADIUS": 8,
	"METRIC_BADGE_BG": Color("2b3233"),
	"CLOCK_BADGE_BG": Color("283435"),
	"BG_TOP": Color(0.090, 0.106, 0.129, 1.0),
	"BG_BOTTOM": Color(0.047, 0.055, 0.071, 1.0),
	"BG_GLOW": Color(0.910, 0.639, 0.239, 1.0),
	"BG_GLOW_STRENGTH": 0.05,
	"BG_VIGNETTE": 0.35,
}
static var TEXT: Color = Color("e6dcc5")
static var MUTED: Color = Color("a8aa9e")
static var GOLD: Color = Color("d6b876")
static var UP: Color = Color("92c79b")
static var DOWN: Color = Color("e08d7b")
static var AMBER: Color = Color("ddb56a")
static var HOVER_TEXT: Color = Color("fff0cc")
static var BADGE_BG: Color = Color("343c3c")
static var BADGE_BORDER: Color = Color("76674e")
static var FRAME_MODULATE: Color = Color(1, 1, 1)
static var BUTTON_HOVER_MODULATE: Color = Color(1.20, 1.14, 1.02)
static var BUTTON_PRESSED_MODULATE: Color = Color(1.35, 1.16, .80)
static var CARD_BG: Color = Color("1d2229")
static var CARD_BG_2: Color = Color("181c22")
static var CARD_BORDER: Color = Color("3a424e")
static var CARD_ACCENT_CASH: Color = Color("e8a33d")
static var CARD_ACCENT_DEBT: Color = Color("e08d7b")
static var CARD_ACCENT_WORTH: Color = Color("92c79b")
static var CARD_ACCENT_OTHER: Color = Color("5b6676")
static var CARD_SHADOW: Color = Color(0, 0, 0, 0.4)
static var CARD_RADIUS: int = 8
static var METRIC_BADGE_BG: Color = Color("2b3233")
static var CLOCK_BADGE_BG: Color = Color("283435")
static var BG_TOP: Color = Color(0.090, 0.106, 0.129, 1.0)
static var BG_BOTTOM: Color = Color(0.047, 0.055, 0.071, 1.0)
static var BG_GLOW: Color = Color(0.910, 0.639, 0.239, 1.0)
static var BG_GLOW_STRENGTH: float = 0.05
static var BG_VIGNETTE: float = 0.35
static var textures: Dictionary = {}

static func icon(id: String) -> Texture2D:
	if not textures.has(id): textures[id] = preload("res://scripts/ui/tex_util.gd").load_tex(DIR+id+".png")
	return textures[id]

static func frame(panel: bool = false) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = icon("panel_frame" if panel else "metric_frame")
	box.modulate_color = FRAME_MODULATE  # P47 DESIGNS (current = biela, bez zmeny)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		box.set_texture_margin(side,8)
		box.set_content_margin(side,10 if panel else 6)
	return box

static func button(button: Button) -> void:
	button.add_theme_stylebox_override("normal",frame())
	var hover := frame()
	hover.modulate_color = BUTTON_HOVER_MODULATE * FRAME_MODULATE
	button.add_theme_stylebox_override("hover",hover)
	var pressed := frame()
	pressed.modulate_color = BUTTON_PRESSED_MODULATE * FRAME_MODULATE
	button.add_theme_stylebox_override("pressed",pressed)
	button.add_theme_color_override("font_color",TEXT)
	button.add_theme_color_override("font_pressed_color",TEXT)
	button.add_theme_color_override("font_hover_color",HOVER_TEXT)
	button.add_theme_color_override("font_hover_pressed_color",HOVER_TEXT)
	button.add_theme_font_size_override("font_size",13)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func badge(texture: Texture2D, background = null, extent: int = 28) -> PanelContainer:
	if not (background is Color): background = BADGE_BG
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = BADGE_BORDER
	box.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel",box)
	panel.custom_minimum_size = Vector2(extent,extent)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var img := TextureRect.new()
	img.texture = texture
	img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(img)
	return panel
