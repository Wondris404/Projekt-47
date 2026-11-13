class_name UiPalette
extends Object
# p47/gfx: jednotna paleta, zhodna s ui/theme_p47.tres (scripts/generate_theme_p47.py)
# P47 DESIGNS: hodnoty su static var (nie const), aby ich DesignManager mohol prepisat zo sekcie
# design.json "palette" (kluc = nazov malymi pismenami, napr. "accent"). DEFAULTS = presne hodnoty gfx kola 2
# a dizajn "current" ich nemeni. Citanie v kode ostava rovnake: UiPalette.ACCENT.

const DEFAULTS := {
	"BG_0": Color("0F1216"),
	"BG_1": Color("171B21"),
	"BG_2": Color("1F242C"),
	"BG_3": Color("2A313B"),
	"BORDER": Color("3A424E"),
	"BORDER_HI": Color("5B6676"),
	"ACCENT": Color("E8A33D"),
	"ACCENT_HI": Color("F6C66B"),
	"ACCENT_DIM": Color("9C6A22"),
	"TEXT": Color("ECE8DF"),
	"TEXT_DIM": Color("A7ADB6"),
	"TEXT_ON_ACCENT": Color("14171C"),
	"OK": Color("6FBF5A"),
	"WARN": Color("E3B33C"),
	"BAD": Color("E0524A"),
	"WATER": Color("1B2836"),
	"LAND_BORDER": Color("0D0F11"),
	"GRATICULE": Color("223244"),
	"OUTLINE": Color("000000"),
	"FIELD": Color("0D1014"),
	"TOOLTIP_BG": Color("0B0D10"),
}

static var BG_0: Color = Color("0F1216")
static var BG_1: Color = Color("171B21")
static var BG_2: Color = Color("1F242C")
static var BG_3: Color = Color("2A313B")
static var BORDER: Color = Color("3A424E")
static var BORDER_HI: Color = Color("5B6676")
static var ACCENT: Color = Color("E8A33D")
static var ACCENT_HI: Color = Color("F6C66B")
static var ACCENT_DIM: Color = Color("9C6A22")
static var TEXT: Color = Color("ECE8DF")
static var TEXT_DIM: Color = Color("A7ADB6")
static var TEXT_ON_ACCENT: Color = Color("14171C")
static var OK: Color = Color("6FBF5A")
static var WARN: Color = Color("E3B33C")
static var BAD: Color = Color("E0524A")
static var WATER: Color = Color("1B2836")
static var LAND_BORDER: Color = Color("0D0F11")
static var GRATICULE: Color = Color("223244")
static var OUTLINE: Color = Color("000000")
static var FIELD: Color = Color("0D1014")
static var TOOLTIP_BG: Color = Color("0B0D10")
