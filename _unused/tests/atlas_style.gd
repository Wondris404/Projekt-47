extends RefCounted
const Style = preload("res://scripts/ui/atlas_style.gd")

func run(u, host: Node) -> void:
	u._new()
	# Existing customer overlay lazily initializes optional v3 Empire fields.
	# Warm those defaults before checking presentation for state changes.
	Empire.st()
	var before = GameState.to_dict()
	var rng = GameState.rng.state
	var far := Style.political_color("SK",1.0)
	var close := Style.political_color("SK",22.0)
	u._chk("atlas_style_political_lod", far.a > close.a and is_equal_approx(close.a,.1))
	u._chk("atlas_style_stable_country_color", far == Style.political_color("SK",1.0) and far != Style.political_color("FR",1.0))
	u._chk("atlas_style_long_name_wrap", Style.label_lines("Spojené kráľovstvo").size()==2 and Style.label_lines("Slovensko")==PackedStringArray(["SLOVENSKO"]))
	u._chk("atlas_style_small_country_hidden", Style.label_size(Style.label_lines("Slovensko"),Vector2(10,10))<11)
	u._chk("atlas_style_large_name_bounded", Style.label_size(Style.label_lines("Slovensko"),Vector2(1000,1000))<=40)
	var occupied: Array = []
	var view := Rect2(0,0,400,300)
	var first := Style.reserve_label(Rect2(10,10,100,20),occupied,view)
	var overlap := Style.reserve_label(Rect2(50,15,100,20),occupied,view)
	u._chk("atlas_style_label_collision", first and not overlap and occupied.size()==1)
	u._chk("atlas_style_label_clipping", not Style.reserve_label(Rect2(390,290,50,20),occupied,view))
	var map = WorldMap.new()
	host.add_child(map)
	map.size = Vector2(800,600)
	map.atlas = true
	map._zoom_at(Vector2(400,300),5.0)
	var original = map.capital_of("SK")
	u._chk("atlas_style_geography_picking", map._pick(map._to_screen(original))=="SK")
	map.cust_mode = true
	u._chk("atlas_style_custom_overlay_retained", is_equal_approx(map._color("SK").a,.62))
	u._chk("atlas_style_simulation_unchanged", GameState.rng.state==rng and JSON.stringify(GameState.to_dict())==JSON.stringify(before))
	map.free()
