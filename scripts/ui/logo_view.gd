extends Control
# JUAN21: nahlad loga korporacie
var corp_id := ""
var logo: Dictionary = {}
var font: Font

func _ready() -> void:
	font = load("res://assets/fonts/NotoSans-Regular.ttf")
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(64, 64)

func _draw() -> void:
	var l = logo if not logo.is_empty() else (Brand.logo(corp_id) if corp_id != "" else {})
	if l.is_empty():
		return
	var s = minf(size.x, size.y)
	Brand.draw_logo(self, Rect2((size - Vector2(s, s)) * 0.5, Vector2(s, s)), l, font)
