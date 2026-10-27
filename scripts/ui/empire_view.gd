extends VBoxContainer
# JUAN10: okno "Portfólio a majetok" – osobne staty (HOI4 styl), kupa statu, charita, centrala (HQ) + financna divizia, fondy, budovy.
var host
var stats_l: Label
var state_l: Label
var gov_pick: OptionButton
var don_amt: SpinBox
var char_l: Label
var corp_pick: OptionButton
var hq_l: Label
var fin_box: VBoxContainer
var fund_l: Label
var msg: Label
var _wk = -1
var cust_sort: OptionButton
var cust_scope: OptionButton
var cust_l: Label
var logo_v: Control
var corp_ren: LineEdit
var logo_ed: AcceptDialog
var re_group: OptionButton
var re_type: OptionButton
var re_sort: OptionButton
var re_sum: Label
var re_list: ItemList
var media_l: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_theme_constant_override("separation", 6)
	msg = Label.new()
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(msg)
	_h("OSOBNÉ ŠTATISTIKY")
	stats_l = _lab()
	_h("ŠTÁT (vybraná krajina na mape)")
	state_l = _lab()
	var r = HBoxContainer.new()
	add_child(r)
	_btn(r, "Kúpiť štát", func(): _act(Empire.buy_state(GameState.selected_iso)))
	gov_pick = OptionButton.new()
	for g in PoliticsSystem.GOV_NAMES.keys():
		gov_pick.add_item(str(PoliticsSystem.GOV_NAMES[g]))
		gov_pick.set_item_metadata(gov_pick.item_count - 1, str(g))
	r.add_child(gov_pick)
	_btn(r, "Zmeniť systém", func(): _act(Empire.set_state_gov(GameState.selected_iso, str(gov_pick.get_item_metadata(gov_pick.selected)))))
	_h("CHARITA (vybraná krajina)")
	var r2 = HBoxContainer.new()
	add_child(r2)
	don_amt = SpinBox.new()
	don_amt.min_value = 1000
	don_amt.max_value = 1e9
	don_amt.step = 1000
	don_amt.value = 50000
	don_amt.suffix = "€"
	r2.add_child(don_amt)
	var db = _btn(r2, "Darovať", func(): _act(Empire.donate(GameState.selected_iso, float(don_amt.value))))
	db.name = "DonateButton"
	char_l = _lab()
	_h("KORPORÁCIA: CENTRÁLA (HQ) A FINANČNÁ DIVÍZIA")
	corp_pick = OptionButton.new()
	corp_pick.item_selected.connect(func(_i): _wk = -2)
	add_child(corp_pick)
	var lr = HBoxContainer.new()  # JUAN21: logo + premenovanie korporacie
	add_child(lr)
	logo_v = preload("res://scripts/ui/logo_view.gd").new()
	logo_v.name = "CorpLogo"
	logo_v.custom_minimum_size = Vector2(56, 56)
	lr.add_child(logo_v)
	var lb = _btn(lr, "Upraviť logo", func():
		if _cid() == "":
			_act("Najprv vytvor korporáciu (Burza → Korporácia / Holding).")
			return
		logo_ed.open_for(_cid()))
	lb.name = "EditLogo"
	corp_ren = LineEdit.new()
	corp_ren.placeholder_text = "Nový názov korporácie"
	corp_ren.custom_minimum_size = Vector2(170, 0)
	lr.add_child(corp_ren)
	var rb = _btn(lr, "Premenovať", func(): _act(Brand.rename_corp(_cid(), corp_ren.text)))
	rb.name = "RenameCorp"
	logo_ed = preload("res://scripts/ui/logo_editor.gd").new()
	logo_ed.name = "LogoEditor"
	logo_ed.saved.connect(func(_c): _wk = -2)
	add_child(logo_ed)
	hq_l = _lab()
	var r3 = HBoxContainer.new()
	add_child(r3)
	var hb = _btn(r3, "Umiestniť / presunúť HQ na mape", _place_hq)
	hb.name = "PlaceHQ"
	fin_box = VBoxContainer.new()
	add_child(fin_box)
	_h("ODBERATELIA (kto od teba kupuje)")
	var r4 = HBoxContainer.new()
	add_child(r4)
	cust_scope = OptionButton.new()
	cust_scope.name = "CustScope"
	cust_scope.add_item("Vybraná korporácia")
	cust_scope.add_item("Všetky moje firmy")
	cust_scope.item_selected.connect(func(_i): _fill_cust())
	r4.add_child(cust_scope)
	cust_sort = OptionButton.new()
	cust_sort.name = "CustSort"
	for it in [["Zoradiť: €", "eur"], ["Zoradiť: množstvo", "qty"], ["Zoradiť: krajina", "country"], ["Zoradiť: tovar", "good"]]:
		cust_sort.add_item(str(it[0]))
		cust_sort.set_item_metadata(cust_sort.item_count - 1, str(it[1]))
	cust_sort.item_selected.connect(func(_i): _fill_cust())
	r4.add_child(cust_sort)
	cust_l = _lab()
	cust_l.name = "CustomersText"
	_h("MÉDIÁ A TELEKOM – koľko % ľudí ich používa")  # JUAN22
	media_l = _lab()
	media_l.name = "MediaReach"
	_h("NEHNUTEĽNOSTI (budovy v mestách)")  # JUAN21
	var r5 = HBoxContainer.new()
	add_child(r5)
	re_group = _opt(r5, "ReGroup", [["Podľa mesta", "city"], ["Podľa krajiny", "country"], ["Podľa typu", "type"]])
	re_type = _opt(r5, "ReType", [["Všetky typy", ""]] + Empire.PROP_TYPES.keys().map(func(k): return [str(Empire.PROP_TYPES[k].name), k]))
	re_sort = _opt(r5, "ReSort", [["Zoradiť: hodnota", "value"], ["Zoradiť: príjem", "rent"], ["Zoradiť: počet", "count"], ["Zoradiť: názov", "name"]])
	re_sum = _lab()
	re_sum.name = "RealtySummary"
	re_list = ItemList.new()
	re_list.name = "RealtyList"
	re_list.custom_minimum_size = Vector2(0, 150)
	re_list.item_activated.connect(_re_go)
	re_list.item_clicked.connect(func(i, _p, _b): _re_go(i))
	add_child(re_list)
	_h("INVESTIČNÉ FONDY")
	fund_l = _lab()

func _h(t: String) -> void:
	var l = Label.new()
	l.text = t
	l.theme_type_variation = "HeaderLabel"
	add_child(l)

func _lab() -> Label:
	var l = Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(l)
	return l

func _btn(p: Node, t: String, cb: Callable) -> Button:
	var b = Button.new()
	b.text = t
	b.pressed.connect(cb)
	p.add_child(b)
	return b

func _act(err: String) -> void:
	msg.text = "OK." if err == "" else err
	msg.add_theme_color_override("font_color", Color("6FCF6F") if err == "" else UiPalette.BAD)
	_wk = -2
	refresh()
	if host and host.has_method("_refresh_label"):
		host._refresh_label()

func _cid() -> String:
	if corp_pick.item_count == 0 or corp_pick.selected < 0:
		return ""
	return str(corp_pick.get_item_metadata(corp_pick.selected))

func _place_hq() -> void:
	var cid = _cid()
	if cid == "":
		_act("Najprv vytvor korporáciu (Burza → Korporácia / Holding).")
		return
	GameState.player["hq_corp"] = cid
	if host:
		host.start_hq_place()

func _process(_d: float) -> void:
	if not is_visible_in_tree():
		return
	var wk = GameState.day_index if GameState.running else -1
	if wk != _wk:
		refresh()

func refresh() -> void:
	_wk = GameState.day_index if GameState.running else -1
	if not GameState.running:
		return
	var s = Empire.stats()
	stats_l.text = "Majetok %s  |  Hotovosť %s\nZamestnanci %.0f   Vplyv %.0f   Popularita %.0f/100   Bezpečnosť %d\nFirmy %d v %d krajinách   Holdingy %d   Budovy %d   Štáty %d" % [
		EconMath.eur(float(s.worth)), EconMath.eur(float(s.cash)), float(s.employees), float(s.influence), float(s.popularity), int(s.security), int(s.firms), int(s.countries), int(s.corps), int(s.buildings), int(s.states)]
	stats_l.text += "\n" + Society.portfolio_text()  # JUAN-P47: pristavy a skoly
	var iso = GameState.selected_iso
	var gov = str(PoliticsSystem.country(iso).get("gov", "")) if iso != "" else ""
	state_l.text = "%s – systém %s, cena %s (treba čisté imanie %s). %s" % [Empire._name(iso), str(PoliticsSystem.GOV_NAMES.get(gov, gov)), EconMath.eur(Empire.state_price(iso)), EconMath.eur(Empire.state_price(iso) * 1.5), "VLASTNÍŠ – tvoje firmy tu platia polovičnú daň." if Empire.owns_state(iso) else ""]
	gov_pick.disabled = not Empire.owns_state(iso)
	var cl: Array = Empire.st().charity_log
	char_l.text = "Dar zvýši popularitu (klesajúci výnos, max +5 za mesiac v krajine) a trochu vplyv.\n" + "\n".join(cl.slice(0, 4))
	var sel = _cid()
	corp_pick.clear()
	for c in StockMarket.ex().corps.values():
		corp_pick.add_item("%s (%d firiem)" % [str(c.name), (c.get("firms", []) as Array).size() + (c.get("members", []) as Array).size()])
		corp_pick.set_item_metadata(corp_pick.item_count - 1, str(c.id))
		if str(c.id) == sel:
			corp_pick.select(corp_pick.item_count - 1)
	var cid = _cid()
	if logo_v:
		logo_v.corp_id = cid
		logo_v.queue_redraw()
	_fill_realty()
	_fill_media()
	_fill_fin(cid)
	_fill_cust()
	var ft = ""
	for f in GameState.player_firms():
		if str(f.get("industry", "")) != "invest_fund":
			continue
		ft += "%s:\n" % str(f.name)
		var re = Empire.fund_realty(f)
		ft += "  Budovy %d · hodnota %s · nájom %s/mes. · podiel %.1f %% / cieľ %.0f %%\n" % [int(re.count), EconMath.eur(float(re.value)), EconMath.eur(float(re.rent)), float(re.share) * 100.0, float(re.target) * 100.0]
		var rows = Empire.fund_rows(f)
		if rows.is_empty():
			ft += "  zatiaľ nedrží akcie (fond investuje podľa dostupnej hotovosti a cieľa budov)\n"
		for r in rows.slice(0, 8):
			ft += "  %s %s (%s): %.0f ks = %s\n" % [str(r.ticker), str(r.name), str(r.sector), float(r.qty), EconMath.eur(float(r.value))]
		for lg in (f.get("fund", {}).get("log", []) as Array).slice(0, 3):
			ft += "  • %s\n" % str(lg)
	fund_l.text = ft if ft != "" else "Nemáš investičný fond. Postav ho: Založiť → Postaviť na mape → Investičný fond."

func _fill_fin(cid: String) -> void:
	for c in fin_box.get_children():
		c.queue_free()
	if cid == "":
		hq_l.text = "Nemáš korporáciu. Vytvor ju v Burze (Korporácia / Holding)."
		return
	var h = Empire.hq(cid)
	hq_l.text = ("Centrála: %s (%s). Korporácia platí daň %.1f %% podľa tejto krajiny. Presun stojí %s." % [str(h.city), Empire._name(str(h.iso)), LawSystem.corporate_tax(str(h.iso)) * 100.0, EconMath.eur(Empire.hq_fee(cid))]) if not h.is_empty() else "Centrála nie je umiestnená – firmy platia daň každá vo svojej krajine. Prvé umiestnenie je zadarmo."
	var d = Empire.fin(cid)
	var on = CheckBox.new()
	on.name = "FinOn"
	on.text = "Finančná divízia (pravá ruka) zapnutá" + ("" if not h.is_empty() else " – vyžaduje HQ")
	on.button_pressed = bool(d.on)
	on.toggled.connect(func(v): d.on = v)
	fin_box.add_child(on)
	var pr = HBoxContainer.new()
	fin_box.add_child(pr)
	var pl = Label.new()
	pl.text = "Rozpočet zo ziskov firiem %"
	pr.add_child(pl)
	var ps = SpinBox.new()
	ps.min_value = 0
	ps.max_value = 100
	ps.value = float(d.pct)
	ps.value_changed.connect(func(v): d.pct = v)
	pr.add_child(ps)
	var ml = Label.new()
	ml.text = "max. na obchod €"
	pr.add_child(ml)
	var ms = SpinBox.new()
	ms.min_value = 10000
	ms.max_value = 1e10
	ms.step = 10000
	ms.value = float(d.max_deal)
	ms.value_changed.connect(func(v): d.max_deal = v)
	pr.add_child(ms)
	for opt in [["optimize", "Optimalizovať (upgrady ziskových firiem)"], ["close_losers", "Predávať chronicky stratové (6+ mes.)"], ["trade", "Obchodovať akcie (kúp pod priemerom, predaj nad)"], ["acquire", "Preberať firmy (>50 %) a začleňovať do korporácie"]]:
		var cb = CheckBox.new()
		cb.text = str(opt[1])
		cb.button_pressed = bool(d.get(opt[0], false))
		var key = str(opt[0])
		cb.toggled.connect(func(v): d[key] = v)
		fin_box.add_child(cb)
	var sl = Label.new()
	sl.text = "Sektory (nič = všetky):"
	fin_box.add_child(sl)
	var sf = HFlowContainer.new()
	fin_box.add_child(sf)
	for sk in StockMarket.SECTORS.keys():
		var sc = CheckBox.new()
		sc.text = str(StockMarket.SECTORS[sk].name)
		sc.button_pressed = (d.sectors as Array).has(sk)
		var k2 = str(sk)
		sc.toggled.connect(func(v): (d.sectors.append(k2) if v and not d.sectors.has(k2) else d.sectors.erase(k2)))
		sf.add_child(sc)
	var rep = Label.new()
	rep.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var t = "Rozpočet divízie: %s\nREPORT – stratové firmy:\n" % EconMath.eur(float(d.budget))
	if (d.flags as Array).is_empty():
		t += "  žiadne (alebo divízia ešte nebežala)\n"
	for fl in d.flags:
		t += "  ⚠ %s: %s za mesiac, %d. mesiac v strate\n" % [str(fl.name), EconMath.eur(float(fl.profit)), int(fl.months)]
	t += "AKTIVITA:\n" + "\n".join((d.log as Array).slice(0, 10).map(func(x): return "  • " + str(x)))
	rep.text = t
	fin_box.add_child(rep)

# JUAN15: odberatelia + fokus na korporaciu (klik na HQ)
func focus_corp(cid: String) -> void:
	refresh()
	for i in corp_pick.item_count:
		if str(corp_pick.get_item_metadata(i)) == cid:
			corp_pick.select(i)
	cust_scope.select(0)
	_wk = -2
	refresh()
	call_deferred("_scroll_to_corp")

func _scroll_to_corp() -> void:
	var sc = get_parent()
	if sc is ScrollContainer:
		(sc as ScrollContainer).scroll_vertical = int(corp_pick.position.y) - 30

func _opt(p: Node, nm: String, items: Array) -> OptionButton:
	var o = OptionButton.new()
	o.name = nm
	for it in items:
		o.add_item(str(it[0]))
		o.set_item_metadata(o.item_count - 1, str(it[1]))
	o.item_selected.connect(func(_i): _fill_realty())
	p.add_child(o)
	return o

func _fill_realty() -> void:
	if re_list == null:
		return
	var g = str(re_group.get_item_metadata(maxi(re_group.selected, 0)))
	var d = Empire.realty_rows(g, str(re_type.get_item_metadata(maxi(re_type.selected, 0))), str(re_sort.get_item_metadata(maxi(re_sort.selected, 0))))
	var t: Dictionary = d.total
	var parts: Array = []
	for k in Empire.PROP_TYPES.keys():
		if d.by_type.has(k):
			var bt = d.by_type[k]
			parts.append("%s %d ks · %s · %s/mes." % [str(Empire.PROP_TYPES[k].name), int(bt.count), EconMath.eur(float(bt.value)), EconMath.eur(float(bt.rent))])
	re_sum.text = "Spolu %d budov, hodnota %s, príjem %s mesačne.\n%s" % [int(t.count), EconMath.eur(float(t.value)), EconMath.eur(float(t.rent)), "\n".join(parts) if not parts.is_empty() else "Žiadne nehnuteľnosti. Kúp ich cez Realitku: klikni na mesto na mape → Kúpiť cez realitku."]
	re_list.clear()
	for r in d.rows:
		var i = re_list.add_item("%s – %d ks · hodnota %s · príjem %s/mes." % [str(r.name), int(r.count), EconMath.eur(float(r.value)), EconMath.eur(float(r.rent))])
		re_list.set_item_metadata(i, {"iso": str(r.iso), "city": str(r.city), "type": str(r.type)})
		re_list.set_item_tooltip(i, "Klikni – priblíži mapu na mesto." if g == "city" else ("Klikni – priblíži na krajinu." if g == "country" else "Klikni – filtruje tento typ."))

func _re_go(i: int) -> void:
	var m: Dictionary = re_list.get_item_metadata(i)
	if str(m.get("type", "")) != "":
		for k in re_type.item_count:
			if str(re_type.get_item_metadata(k)) == str(m.type):
				re_type.select(k)
		re_group.select(0)
		_fill_realty()
		return
	if host and host.has_method("zoom_to_city"):
		host.zoom_to_city(str(m.iso), str(m.city))

func _fill_cust() -> void:
	if cust_l == null:
		return
	var cid = _cid()
	var scope = "*" if cust_scope.selected == 1 or cid == "" else cid
	var c = Empire.customers(scope, str(cust_sort.get_item_metadata(maxi(cust_sort.selected, 0))))
	var t = "%s · spolu %s\n" % ["Posledný celý mesiac" if bool(c.full_month) else "Tento mesiac doteraz", EconMath.eur(float(c.total))]
	var ct: Array = c.countries.keys()
	ct.sort_custom(func(a, b): return float(c.countries[a]) > float(c.countries[b]))
	t += "Podľa krajín: " + ", ".join(ct.slice(0, 8).map(func(k): return "%s %s" % [k, EconMath.eur(float(c.countries[k]))])) + "\n"
	var rows: Array = c.rows
	if rows.is_empty():
		t += "Zatiaľ nikto – tvoje firmy (v tejto korporácii) ešte nič nepredali na trhu."
	for r in rows.slice(0, 25):
		t += "• %s – %s: %s %.1f ks/mes. = %s\n" % [str(r.country), str(r.buyer), str(r.good), float(r.qty), EconMath.eur(float(r.eur))]
	if rows.size() > 25:
		t += "… a ďalších %d riadkov" % (rows.size() - 25)
	cust_l.text = t


func _fill_media() -> void:
	if media_l == null:
		return
	var t = ""
	for f in GameState.player_firms():
		if Brand.is_media(f) and not bool(f.get("closed", false)):
			var r = Brand.media_reach(f)
			t += "• %s (%s, %s): %.1f %% obyvateľov · %s %s · podiel %.0f %%\n" % [str(f.name), str(Brand.MEDIA[str(f.industry)].name), str(GameState.world.get(str(f.country), {}).get("name_sk", f.country)), float(r.pct) * 100.0, Brand._fmt_n(float(r.users)), str(Brand.MEDIA[str(f.industry)].noun), float(r.share) * 100.0]
	media_l.text = t if t != "" else "Nemáš telekom, noviny, televíziu ani sociálnu sieť. Postav ich: Založiť → Veľké podniky / Médiá."
