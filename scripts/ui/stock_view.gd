extends VBoxContainer
# JUAN5 #19: Burza – index, zoznam titulov, graf, portfolio, IPO, holding/spin-off, takeover
var host
var head: Label
var lock: Label
var list: ItemList
var chart: Control
var qty: SpinBox
var detail: Label
var corp_name: LineEdit
var corp_firms: VBoxContainer
var corp_pick: OptionButton
var sector_pick: OptionButton
var sector_info: Label
var absorb_b: Button
var quote_l: Label
var buy_b: Button
var sell_b: Button

func _qty_now(from_text: bool) -> float:
	if from_text:
		var t = qty.get_line_edit().text.replace("Kusov", "").replace(" ", "").strip_edges()
		if t.is_valid_float():
			return float(t)
	return float(qty.value)

func _update_quote(from_text: bool = false) -> void:
	if quote_l == null:
		return
	var q = _qty_now(from_text)
	if _sel == "" or StockMarket.listing(_sel).is_empty():
		quote_l.text = "Vyber titul v zozname – uvidíš cenu nákupu/predaja."
		quote_l.remove_theme_color_override("font_color")
		if buy_b: buy_b.disabled = true
		if sell_b: sell_b.disabled = true
		return
	var b = StockMarket.quote(_sel, q, "buy")
	var s = StockMarket.quote(_sel, q, "sell")
	var txt = "NÁKUP %.0f ks: %s/akcia · spolu %s + poplatok %s = %s · podiel po %.2f %% · hotovosť po %s" % [q, EconMath.eur(float(b.get("px", 0))), EconMath.eur(float(b.get("gross", 0))), EconMath.eur(float(b.get("fee", 0))), EconMath.eur(float(b.get("total", 0))), float(b.get("stake_after", 0)) * 100.0, EconMath.eur(float(b.get("cash_after", 0)))]
	if StockMarket.owned(_sel) > 0.0:
		txt += "\nPREDAJ %.0f ks: %s/akcia · výnos %s − poplatok %s = %s · podiel po %.2f %%" % [q, EconMath.eur(float(s.get("px", 0))), EconMath.eur(float(s.get("gross", 0))), EconMath.eur(float(s.get("fee", 0))), EconMath.eur(float(s.get("total", 0))), float(s.get("stake_after", 0)) * 100.0]
	if not bool(b.get("ok", false)):
		txt += "\n⚠ " + str(b.get("reason", ""))
		quote_l.add_theme_color_override("font_color", UiPalette.BAD)
	else:
		quote_l.remove_theme_color_override("font_color")
	quote_l.text = txt
	if buy_b: buy_b.disabled = not bool(b.get("ok", false))
	if sell_b: sell_b.disabled = not bool(s.get("ok", false))
var _sel = ""
var _wk = -1

class Chart extends Control:
	var data: Array = []
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.06, 0.1))
		if data.size() < 2 or size.x < 8.0 or size.y < 8.0:
			return
		var lo = data.min()
		var hi = data.max()
		var span = maxf(hi - lo, absf(hi) * 0.001 + 0.0001)
		var pts = PackedVector2Array()
		for i in data.size():
			pts.append(Vector2(size.x * i / float(data.size() - 1), size.y - (float(data[i]) - lo) / span * (size.y - 6) - 3))
		draw_polyline(pts, Color(0.3, 0.9, 0.5) if data[-1] >= data[0] else Color(0.95, 0.35, 0.3), 2.0)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_theme_constant_override("separation", 6)
	head = Label.new()
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(head)
	lock = Label.new()
	lock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lock.add_theme_color_override("font_color", UiPalette.BAD)
	add_child(lock)
	chart = Chart.new()
	chart.custom_minimum_size = Vector2(0, 120)
	add_child(chart)
	var frow = HBoxContainer.new()  # JUAN10: filter podla sektora + sektorove indexy
	add_child(frow)
	var fl = Label.new()
	fl.text = "Sektor:"
	frow.add_child(fl)
	sector_pick = OptionButton.new()
	sector_pick.name = "SectorPick"
	sector_pick.add_item("Všetky sektory")
	sector_pick.set_item_metadata(0, "")
	for sk in StockMarket.SECTORS.keys():
		sector_pick.add_item(str(StockMarket.SECTORS[sk].name))
		sector_pick.set_item_metadata(sector_pick.item_count - 1, str(sk))
	sector_pick.item_selected.connect(func(_i): refresh())
	frow.add_child(sector_pick)
	sector_info = Label.new()
	sector_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sector_info.add_theme_font_size_override("font_size", 11)
	add_child(sector_info)
	list = ItemList.new()
	list.name = "StockList"
	list.custom_minimum_size = Vector2(0, 220)
	list.item_selected.connect(func(i): _sel = str(list.get_item_metadata(i)); _show_sel())
	add_child(list)
	detail = Label.new()
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(detail)
	qty = SpinBox.new()
	qty.min_value = 1
	qty.max_value = 1000000
	qty.value = 1000
	qty.prefix = "Kusov"
	add_child(qty)
	qty.value_changed.connect(func(_v): _update_quote())
	qty.get_line_edit().text_changed.connect(func(_t): _update_quote(true))
	quote_l = Label.new()  # JUAN10: zivy nahlad ceny obchodu
	quote_l.name = "TradeQuote"
	quote_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(quote_l)
	var row = HBoxContainer.new()
	add_child(row)
	buy_b = _btn(row, "Kúpiť", func(): _act(StockMarket.buy(_sel, float(qty.value))))
	sell_b = _btn(row, "Predať", func(): _act(StockMarket.sell(_sel, float(qty.value))))
	_btn(row, "Prevziať (>50 %)", func(): _act(StockMarket.takeover(_sel)))
	absorb_b = _btn(row, "Začleniť do korporácie", func(): _act(StockMarket.absorb_into_corp(_corp_id(), _sel)))
	absorb_b.name = "AbsorbButton"
	absorb_b.tooltip_text = "Vlastníš viac ako 50 %: firmu začleníš do korporácie vybranej nižšie (Korporácia / Holding)."
	absorb_b.visible = false
	var ch = Label.new()
	ch.text = "KORPORÁCIA / HOLDING"
	add_child(ch)
	corp_name = LineEdit.new()
	corp_name.placeholder_text = "Názov korporácie"
	corp_name.text = "Wondris Holding"
	add_child(corp_name)
	corp_firms = VBoxContainer.new()
	add_child(corp_firms)
	_btn(self, "Založiť korporáciu z vybraných firiem", _on_corp)
	corp_pick = OptionButton.new()
	add_child(corp_pick)
	var r2 = HBoxContainer.new()
	add_child(r2)
	_btn(r2, "IPO korporácie (30 %)", func(): _act(StockMarket.ipo_corp(_corp_id(), 0.3)))
	_btn(r2, "Pridať vybranú firmu", func(): _act(_each_checked(func(fid): return StockMarket.corp_add(_corp_id(), fid))))
	_btn(r2, "Spin-off vybranej", func(): _act(_each_checked(func(fid): return StockMarket.spin_off(_corp_id(), fid))))
	refresh()

func _btn(p: Node, t: String, cb: Callable) -> Button:
	var b = Button.new()
	b.text = t
	b.pressed.connect(cb)
	p.add_child(b)
	return b

func _corp_id() -> String:
	if corp_pick.item_count == 0 or corp_pick.selected < 0:
		return ""
	return str(corp_pick.get_item_metadata(corp_pick.selected))

func _each_checked(fn: Callable) -> String:
	var any = false
	for c in corp_firms.get_children():
		if c is CheckBox and c.button_pressed:
			any = true
			var e = str(fn.call(str(c.get_meta("fid"))))
			if e != "":
				return e
	return "" if any else "Zaškrtni firmu."

func _on_corp() -> void:
	var ids: Array = []
	for c in corp_firms.get_children():
		if c is CheckBox and c.button_pressed:
			ids.append(str(c.get_meta("fid")))
	_act(StockMarket.create_corp(corp_name.text, ids))

func _act(err: String) -> void:
	if host:
		host._feedback("Burza: %s" % ("hotovo." if err == "" else err), err == "")
		host._refresh_label()
	refresh()

func _process(_d: float) -> void:
	if is_visible_in_tree() and GameState.running and int(GameState.day_index / 7) != _wk:
		refresh()

func refresh() -> void:
	if not GameState.running:
		head.text = "Burza – spusti hru."
		_wk = -1
		return
	_wk = int(GameState.day_index / 7)
	var x = StockMarket.ex()
	if x.list.is_empty():
		StockMarket.setup()
	lock.text = "" if StockMarket.unlocked() else "Zamknuté: výskum Úverový scoring alebo cieľ Financie. Kurzy môžeš sledovať."
	var idx: Array = x.index
	head.text = "INDEX P47: %.1f | nálada trhu %+.0f %% | tvoje portfólio %s" % [StockMarket.index_value(), float(x.mood) * 100.0, EconMath.eur(StockMarket.portfolio_value())]
	list.clear()
	var fsec = "" if sector_pick == null or sector_pick.selected < 0 else str(sector_pick.get_item_metadata(sector_pick.selected))
	var parts: Array = []
	for sk in StockMarket.SECTORS.keys():
		var si = StockMarket.sector_index(sk)
		if si > 0.0:
			parts.append("%s %.0f" % [str(StockMarket.SECTORS[sk].name), si])
	sector_info.text = "Sektorové indexy (štart = 1000): " + " · ".join(parts) + "\nNázvy firiem sú paródie – akákoľvek podobnosť so skutočnými firmami je čistá satira."
	var last_sec = ""
	var rows_sorted: Array = StockMarket.listings()
	rows_sorted.sort_custom(func(a, b): return [StockMarket.sector_of_row(a), str(a.ticker)] < [StockMarket.sector_of_row(b), str(b.ticker)])
	for row in rows_sorted:
		if fsec != "" and StockMarket.sector_of_row(row) != fsec:
			continue
		if StockMarket.sector_of_row(row) != last_sec:
			last_sec = StockMarket.sector_of_row(row)
			var hi = list.add_item("— %s —" % str(StockMarket.SECTORS.get(last_sec, {}).get("name", last_sec)))
			list.set_item_disabled(hi, true)
			list.set_item_selectable(hi, false)
			list.set_item_metadata(hi, "")
		var h: Array = row.hist
		var chg = 0.0 if h.size() < 2 else (float(h[-1]) / maxf(float(h[-2]), 0.0001) - 1.0) * 100.0
		var tag = {"nat": "", "rival": " [AI]", "player": " [TVOJA]", "corp": " [HOLDING]"}.get(str(row.kind), "")
		var i = list.add_item("%s  %s%s  %s  %+.1f %%  máš %.1f %%%s" % [str(row.ticker), str(row.name), tag, EconMath.eur(float(row.price)), chg, StockMarket.stake(str(row.ticker)) * 100.0, " (ovládaš)" if bool(row.get("controlled", false)) else ""])
		list.set_item_metadata(i, str(row.ticker))
		if str(row.kind) == "corp" and str(row.get("corp", "")) != "":  # JUAN21: logo korporacie
			list.set_item_icon(i, Brand.logo_texture(str(row.corp)))
	chart.data = idx if _sel == "" else StockMarket.listing(_sel).get("hist", [])
	chart.queue_redraw()
	for c in corp_firms.get_children():
		c.queue_free()
	for f in GameState.player_firms():
		var cb = CheckBox.new()
		cb.set_meta("fid", str(f.id))
		cb.text = "%s%s" % [str(f.name), " [%s]" % str(f.corp) if str(f.get("corp", "")) != "" else ""]
		corp_firms.add_child(cb)
	corp_pick.clear()
	for c in x.corps.values():
		corp_pick.add_item("%s (%s, %d firiem, hodnota %s)" % [str(c.name), str(c.get("ticker", "")), c.firms.size(), EconMath.eur(StockMarket.corp_value(c))])
		corp_pick.set_item_metadata(corp_pick.item_count - 1, str(c.id))
		corp_pick.set_item_icon(corp_pick.item_count - 1, Brand.logo_texture(str(c.id)))
	_show_sel()

func _show_sel() -> void:
	var row = StockMarket.listing(_sel)
	if absorb_b:
		absorb_b.visible = StockMarket.can_absorb(_sel)
		absorb_b.disabled = corp_pick == null or corp_pick.item_count == 0
		absorb_b.text = "Začleniť do korporácie" + ("" if corp_pick == null or corp_pick.item_count != 0 else " (najprv vytvor korporáciu)")
	_update_quote()
	if row.is_empty():
		detail.text = "Vyber titul. Graf ukazuje index."
		return
	detail.text = "%s (%s) – sektor %s, krajina %s, zisk/akcia %s, kurz %s, máš %.0f ks (%.1f %%)." % [str(row.name), str(row.ticker), str(StockMarket.SECTORS.get(str(row.sector), {}).get("name", "")), str(row.iso), EconMath.eur(float(row.eps)), EconMath.eur(float(row.price)), StockMarket.owned(_sel), StockMarket.stake(_sel) * 100.0]
	chart.data = row.hist
	chart.queue_redraw()
