extends AcceptDialog
# JUAN21: editor loga korporacie (tvar, farby, symbol, text)
const LV = preload("res://scripts/ui/logo_view.gd")
var corp_id := ""
var shape_p: OptionButton
var sym_p: OptionButton
var bg_b: ColorPickerButton
var fg_b: ColorPickerButton
var txt: LineEdit
var prev: Control
var err_l: Label
signal saved(cid: String)

func _init() -> void:
	title = "Logo korporácie"
	ok_button_text = "Uložiť logo"
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root = HBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	add_child(root)
	prev = LV.new()
	prev.name = "LogoPreview"
	prev.custom_minimum_size = Vector2(150, 150)
	root.add_child(prev)
	var g = GridContainer.new()
	g.columns = 2
	root.add_child(g)
	shape_p = _opt(g, "Tvar", Brand.SHAPES)
	sym_p = _opt(g, "Symbol", Brand.SYMBOLS)
	bg_b = _col(g, "Pozadie")
	fg_b = _col(g, "Symbol a text")
	var l = Label.new()
	l.text = "Text / iniciály (max 4)"
	g.add_child(l)
	txt = LineEdit.new()
	txt.max_length = 4
	txt.text_changed.connect(func(_t): _upd())
	g.add_child(txt)
	err_l = Label.new()
	g.add_child(err_l)
	confirmed.connect(_save)

func _opt(g: Node, label: String, items: Dictionary) -> OptionButton:
	var l = Label.new()
	l.text = label
	g.add_child(l)
	var o = OptionButton.new()
	for k in items.keys():
		o.add_item(str(items[k]))
		o.set_item_metadata(o.item_count - 1, str(k))
	o.item_selected.connect(func(_i): _upd())
	g.add_child(o)
	return o

func _col(g: Node, label: String) -> ColorPickerButton:
	var l = Label.new()
	l.text = label
	g.add_child(l)
	var c = ColorPickerButton.new()
	c.custom_minimum_size = Vector2(90, 28)
	c.color_changed.connect(func(_c): _upd())
	g.add_child(c)
	return c

func _sel(o: OptionButton, v: String) -> void:
	for i in o.item_count:
		if str(o.get_item_metadata(i)) == v:
			o.select(i)

func open_for(cid: String) -> void:
	corp_id = cid
	var l = Brand.logo(cid)
	_sel(shape_p, str(l.shape))
	_sel(sym_p, str(l.symbol))
	bg_b.color = Color(str(l.bg))
	fg_b.color = Color(str(l.fg))
	txt.text = str(l.text)
	_upd()
	popup_centered(Vector2i(520, 260))

func current() -> Dictionary:
	return {"shape": str(shape_p.get_item_metadata(shape_p.selected)), "symbol": str(sym_p.get_item_metadata(sym_p.selected)), "bg": bg_b.color.to_html(false), "fg": fg_b.color.to_html(false), "text": txt.text}

func _upd() -> void:
	prev.logo = current()
	prev.queue_redraw()

func _save() -> void:
	var e = Brand.set_logo(corp_id, current())
	err_l.text = e
	if e == "":
		saved.emit(corp_id)
