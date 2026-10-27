extends VBoxContainer
# JUAN13 (t810u): dlhopisy hraca v zalozke Pôžičky – emisia s popisanymi poliami + nahlad, zoznam vydanych.
var host
var amount: SpinBox
var coupon: SpinBox
var years: SpinBox
var preview: Label
var list_l: Label
var issue_b: Button
var _sig = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var h = Label.new()
	h.text = "DLHOPISY"
	h.theme_type_variation = "HeaderLabel"
	h.tooltip_text = "Dlhopis = pôžička od investorov. Dostaneš peniaze hneď, každý deň platíš kupón (úrok) a na konci splatnosti vrátiš celú istinu."
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(h)
	var ex = Label.new()
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ex.add_theme_font_size_override("font_size", 11)
	ex.text = "Investori ti požičajú sumu, ty platíš kupón a na konci vrátiš istinu. Ak je kupón nižší ako trhový výnos, kúpia ho len s diskontom (dostaneš menej)."
	add_child(ex)
	amount = _row("Suma (istina) €", 1000, 1e9, 1000, 100000, "Koľko si požičiavaš – toľko vrátiš na konci.")
	coupon = _row("Kupón % ročne", 0.0, 25.0, 0.25, 5.0, "Ročný úrok, ktorý platíš investorom (denne).")
	years = _row("Splatnosť (roky)", 1, 30, 1, 5, "O koľko rokov vrátiš istinu.")
	preview = Label.new()
	preview.name = "BondPreview"
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(preview)
	issue_b = Button.new()
	issue_b.name = "IssueBond"
	issue_b.text = "Vydať dlhopis"
	issue_b.pressed.connect(_issue)
	add_child(issue_b)
	var h2 = Label.new()
	h2.text = "VYDANÉ DLHOPISY"
	h2.theme_type_variation = "HeaderLabel"
	add_child(h2)
	list_l = Label.new()
	list_l.name = "BondList"
	list_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(list_l)
	refresh()

func _row(t: String, lo: float, hi: float, st: float, v: float, tip: String) -> SpinBox:
	var r = HBoxContainer.new()
	add_child(r)
	var l = Label.new()
	l.text = t
	l.tooltip_text = tip
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(l)
	var s = SpinBox.new()
	s.min_value = lo
	s.max_value = hi
	s.step = st
	s.value = v
	s.tooltip_text = tip
	s.value_changed.connect(func(_x): _update())
	r.add_child(s)
	return s

func _issue() -> void:
	var e = BankingSystem.issue_bond_ex(float(amount.value), float(coupon.value) / 100.0, float(years.value))
	if host:
		host._feedback("Dlhopis: " + ("vydaný." if e == "" else e), e == "")
		host._refresh_label()
	refresh()

func _process(_d: float) -> void:
	if not is_visible_in_tree() or not GameState.running:
		return
	var s = "%d|%d" % [GameState.day_index, (GameState.player.get("bonds", []) as Array).size()]
	if s != _sig:
		refresh()

func _update() -> void:
	if not GameState.running:
		preview.text = ""
		return
	var q = BankingSystem.bond_quote(float(amount.value), float(coupon.value) / 100.0, float(years.value))
	preview.text = "Dostaneš teraz: %s (trhový výnos %.2f %%)\nKupón ročne: %s · úroky spolu: %s · na konci vrátiš %s\nLimit emisií: %s (vydané %s)%s" % [
		EconMath.eur(float(q.proceeds)), float(q.market_yield) * 100.0, EconMath.eur(float(q.coupon_year)), EconMath.eur(float(q.total_interest)), EconMath.eur(float(amount.value)),
		EconMath.eur(float(q.limit)), EconMath.eur(float(q.outstanding)), "" if str(q.reason) == "" else "\n⚠ " + str(q.reason)]
	preview.add_theme_color_override("font_color", UiPalette.BAD if str(q.reason) != "" else UiPalette.TEXT)
	issue_b.disabled = str(q.reason) != ""

func refresh() -> void:
	if not GameState.running:
		return
	_sig = "%d|%d" % [GameState.day_index, (GameState.player.get("bonds", []) as Array).size()]
	_update()
	var t = ""
	for b in GameState.player.get("bonds", []):
		if str(b.get("issuer", "")) != "player":
			continue
		t += "• %s · kupón %.2f %% (%s/rok) · splatnosť o %.1f roka\n" % [EconMath.eur(float(b.face)), float(b.coupon) * 100.0, EconMath.eur(float(b.face) * float(b.coupon)), float(b.years_left)]
	list_l.text = t if t != "" else "Zatiaľ žiadne."
