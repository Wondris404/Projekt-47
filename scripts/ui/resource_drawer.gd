extends PanelContainer
const Chrome = preload("res://scripts/ui/strategic_skin.gd")
const Data = preload("res://scripts/ui/strategic_hud_data.gd")
const Goods = preload("res://scripts/ui/goods_icons.gd")
var host: Node
var pin: Button
var clear_button: Button
var subtitle: Label
var energy_label: Label
var energy_detail: Label
var energy_bar: ProgressBar
var scroll: ScrollContainer
var row_controls: Dictionary = {}
var groups: Dictionary = {}
var selected := ""
var _revision := -1
var _tween: Tween
var _group := ButtonGroup.new()
var _closing := false
var last_snapshot: Dictionary = {}

func _ready() -> void:
	name = "ResourceDrawer"
	z_index = 45
	visible = false
	add_theme_stylebox_override("panel",Chrome.frame(true))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_group.allow_unpress = true
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",6)
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(body)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_PASS
	body.add_child(head)
	head.add_child(Chrome.badge(Goods.icon("electricity"),Color("3e4235"),28))
	var title := _label("SUROVINY A ENERGIA",16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(title)
	pin = preload("res://scripts/ui/hud_button.gd").new()
	pin.text = "Pripnúť"
	pin.toggle_mode = true
	pin.tooltip_text = "Pripnutý panel zostáva otvorený pri kliknutí na mapu. Presúvaj za hlavičku, veľkosť meň za okraje."
	Chrome.button(pin)
	pin.toggled.connect(func(on): pin.text = "Pripnuté" if on else "Pripnúť")
	head.add_child(pin)
	var close := preload("res://scripts/ui/hud_button.gd").new()
	close.text = "✕"
	close.name = "CloseResources"
	close.tooltip_text = "Zavrieť · Esc"
	Chrome.button(close)
	close.pressed.connect(close_panel)
	head.add_child(close)
	subtitle = _label("Tvoje firmy · posledný uzavretý deň",12)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(subtitle)
	energy_label = _label("Elektrina",14)
	energy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(energy_label)
	energy_bar = ProgressBar.new()
	energy_bar.show_percentage = false
	energy_bar.custom_minimum_size.y = 10
	body.add_child(energy_bar)
	energy_detail = _label("",11)
	energy_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(energy_detail)
	var legend := _label("Atlas: zelená = výrobca · medená = odberateľ · fialová = oboje",11)
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(legend)
	clear_button = preload("res://scripts/ui/hud_button.gd").new()
	clear_button.text = "Klikni na surovinu → zvýrazni tvoje firmy na Atlase"
	clear_button.clip_text = true
	Chrome.button(clear_button)
	clear_button.pressed.connect(func(): select_resource(""))
	body.add_child(clear_button)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",4)
	scroll.add_child(list)
	var icons := ["electricity","iron_ore","steel","electronics"]
	var n := 0
	for group_name in Data.GROUPS:
		var button := preload("res://scripts/ui/hud_button.gd").new()
		button.text = group_name+"  ▾"
		button.icon = Goods.icon(icons[n])
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width",22)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = n<2
		Chrome.button(button)
		list.add_child(button)
		var items := VBoxContainer.new()
		items.add_theme_constant_override("separation",3)
		items.visible = button.button_pressed
		list.add_child(items)
		groups[group_name] = {"button":button,"items":items}
		button.toggled.connect(func(on): items.visible=on; button.text=group_name+("  ▾" if on else "  ▸"))
		for cid in Data.GROUPS[group_name]: _row(items,cid)
		n += 1
	host.win_mgr.register(self,"resources",default_rect,45,Vector2(320,270))
	resized.connect(_reflow)
	visibility_changed.connect(func(): host.speed_bar.resources_button.set_pressed_no_signal(visible))
	# The host refreshes visible content at most five times per second.

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Chrome.TEXT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _row(parent: Container, cid: String) -> void:
	var b := preload("res://scripts/ui/hud_button.gd").new()
	b.name = "Resource_"+cid
	b.toggle_mode = true
	b.button_group = _group
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0,78)
	Chrome.button(b)
	parent.add_child(b)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,7)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation",3)
	margin.add_child(box)
	var title := HBoxContainer.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	var tint: Color = {"coal":Color("323842"),"iron_ore":Color("76503b"),"meat":Color("703e4b")}.get(cid,Color("34403e"))
	title.add_child(Chrome.badge(Goods.icon(cid),tint,24))
	var commodity: Dictionary = DataLoader.commodity(cid)
	var label := _label(str(commodity.get("name",cid))+" · "+str(commodity.get("unit","")),13)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_child(label)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",3)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(grid)
	var fields := {}
	for item in [["produced","Produkcia / deň"],["consumed","Spotreba / deň"],["balance","Bilancia / deň"],["stock","Sklad"],["price","Cena / jednotka"]]:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_theme_constant_override("separation",0)
		grid.add_child(cell)
		var name_label := _label(item[1],10)
		name_label.add_theme_color_override("font_color",Chrome.MUTED)
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		cell.add_child(name_label)
		var value := _label("—",13)
		value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		cell.add_child(value)
		fields[item[0]] = value
	row_controls[cid] = {"button":b,"grid":grid,"fields":fields}
	b.pressed.connect(func(): select_resource(cid if b.button_pressed else ""))

func default_rect() -> Rect2:
	var vp := get_viewport_rect().size
	var top: float = host.speed_bar.get_global_rect().end.y+8
	var desired := Vector2(minf(780,vp.x-20),minf(570,vp.y-top-10))
	return Rect2(Vector2(10,minf(top,maxf(0,vp.y-maxf(270,desired.y)))) ,Vector2(desired.x,maxf(270,desired.y)))

func _reflow() -> void:
	var columns := 5 if size.x>=620 else 3
	for row in row_controls.values():
		row.grid.columns = columns
		row.button.custom_minimum_size.y = 78 if columns==5 else 111

func toggle() -> void:
	if visible and not _closing: close_panel(); return
	if _tween and _tween.is_running(): _tween.kill()
	_closing = false
	modulate.a = 0
	host.win_mgr.place("resources")
	show()
	refresh()
	_reflow()
	# Let wrapped labels settle at the real width before choosing the final height.
	await get_tree().process_frame
	await get_tree().process_frame
	if _closing or not visible: return
	host.win_mgr.place("resources")
	_reflow()
	var target := position
	position.y = maxf(0,target.y-22)
	modulate.a = 0
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self,"position",target,.18)
	_tween.tween_property(self,"modulate:a",1.0,.18)

func close_panel() -> void:
	if not visible: return
	if _tween and _tween.is_running(): _tween.kill()
	_closing = true
	select_resource("")
	_tween = create_tween()
	_tween.tween_property(self,"modulate:a",0.0,.12)
	_tween.tween_callback(func(): hide(); _closing=false; modulate.a=1.0)

func _input(event: InputEvent) -> void:
	if not visible or _closing: return
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		close_panel()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not pin.button_pressed:
		if not get_global_rect().has_point(event.position) and not host.speed_bar.resources_button.get_global_rect().has_point(event.position): close_panel()

func select_resource(cid: String) -> void:
	selected = cid
	for key in row_controls: row_controls[key].button.set_pressed_no_signal(key==cid)
	var roles: Dictionary = Data.roles(cid) if cid!="" else {}
	host.map.set_resource_focus(cid,roles)
	clear_button.text = "Zrušiť zvýraznenie: %s · %d firiem" % [str(DataLoader.commodity(cid).get("name",cid)),roles.size()] if cid!="" else "Klikni na surovinu → zvýrazni tvoje firmy na Atlase"
	clear_button.tooltip_text = clear_button.text+("\nZvýraznenie je viditeľné iba na Atlas mape." if not host.map.atlas else "")

func refresh() -> void:
	if not visible: return
	if _revision != GameState.state_revision:
		_revision = GameState.state_revision
		select_resource("")
	last_snapshot = Data.resources()
	var known: bool = last_snapshot.known
	var country := str(GameState.world.get(last_snapshot.country,{}).get("name_sk",last_snapshot.country))
	subtitle.text = "Tvoje firmy · "+("posledný uzavretý deň" if known else "toky sa zobrazia po uzavretí dňa")+" · ceny: "+country
	for cid in row_controls:
		var row: Dictionary = last_snapshot.rows.get(cid,{})
		var ui: Dictionary = row_controls[cid]
		for field in ui.fields:
			var value := float(row.get(field,0))
			ui.fields[field].text = "—" if not known and field in ["produced","consumed","balance"] else (("+" if value>0 and field=="balance" else "")+Data.compact(value,field=="price"))
			ui.fields[field].add_theme_color_override("font_color",(Chrome.UP if value>0 else Chrome.DOWN) if known and field=="balance" and not is_zero_approx(value) else Chrome.TEXT)
		var unit := str(DataLoader.commodity(cid).get("unit",""))
		ui.button.tooltip_text = "%s\nZa posledný uzavretý deň: výroba %s, spotreba %s (%s).\nBilancia = produkcia − spotreba; nákup a predaj sa do nej nepočítajú.\nSklad: %s %s vo vlastných prevádzkach.\nReferenčná trhová cena v krajine %s: %s / %s.\nKliknutím zvýrazníš vlastných výrobcov a odberateľov podľa receptov." % [str(DataLoader.commodity(cid).get("name",cid)),Data.number(float(row.get("produced",0)),4) if known else "—",Data.number(float(row.get("consumed",0)),4) if known else "—",unit,Data.number(float(row.get("stock",0)),3),unit,country,EconMath.eur(float(row.get("price",0))),unit]
	var power := Data.power(last_snapshot.rows,known)
	energy_label.text = "ELEKTRINA · %s MW výroba / %s MW spotreba" % [Data.number(power.made,2),Data.number(power.used,2)] if known else "ELEKTRINA · čaká na prvý uzavretý deň"
	energy_detail.text = "Potreba %s MW · krytie vlastnou výrobou %s %%" % [Data.number(power.need,2),Data.number(power.ratio*100,1)] if known and power.need>0 else ("Bez požadovaného odberu." if known else "+1 deň zobrazí skutočné toky. Sklady a ceny sú dostupné ihneď.")
	energy_bar.value = clampf(power.ratio*100,0,100) if known and power.need>0 else 0
	var fill := StyleBoxFlat.new()
	fill.bg_color = {"ok":Chrome.UP,"warning":Chrome.AMBER,"deficit":Chrome.DOWN}.get(power.state,Chrome.MUTED)
	energy_bar.add_theme_stylebox_override("fill",fill)
	energy_bar.tooltip_text = "Denná energia v MWh / 24 = priemerný výkon v MW.\nLišta porovnáva vlastnú výrobu s požadovaným odberom pred obmedzením výroby.\nZelená ≥100 %, oranžová 90–100 %, červená <90 %.\nDeficit vlastnej výroby môže pokryť trh; nejde o výpadok elektrickej siete."
	energy_label.tooltip_text = energy_bar.tooltip_text
	energy_label.mouse_filter = Control.MOUSE_FILTER_PASS
	if selected!="": select_resource(selected)
