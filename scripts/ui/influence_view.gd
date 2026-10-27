extends VBoxContainer
# JUAN8: Vplyv / lobing – hrac je podnikatel, nie stat. Statom nic neprikazuje, len ovplyvnuje vladu
# (peniaze + riziko skandalu); vlada rozhoduje so sancou podla vplyvu, typu vlady, strany pri moci a korupcie.
var host
var list: ItemList
var info: Label
var target2: OptionButton
var party: OptionButton
var actions_box: VBoxContainer
var sel_iso = ""
var _rows: Array = []
var _wk = -1

const ACTS = [
	["media_campaign", "Mediálna kampaň (zvýši vplyv)", false],
	["fund_party", "Financovať stranu", false],
	["lobby_party", "Podporiť stranu pred voľbami", false],
	["lobby_relief", "Lobovať: colná úľava s krajinou B", true],
	["lobby_trade", "Lobovať: obchodná zmluva s krajinou B", true],
	["lobby_sanction", "Lobovať: sankcie na krajinu B (konkurent)", true],
	["lobby_embargo", "Lobovať: embargo voči krajine B", true],
	["lobby_peace", "Lobovať za mier", false],
	["war_support", "Podporiť vo vojne (dodávky/financie)", false],
	["lobby_tax", "Lobovať: nižšie dane", false],
	["lobby_reg", "Lobovať: menej regulácie", false],
	["bribe", "Úplatok (len s cieľom Korupcia)", false],
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_theme_constant_override("separation", 6)
	var h = Label.new()
	h.text = "VPLYV A LOBING – si podnikateľ, nie štát. Vlády rozhodujú samy; ty platíš lobing, kampane a strany. Šanca závisí od tvojho vplyvu, typu vlády, strany pri moci a korupcie. Hrozí škandál."
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(h)
	list = ItemList.new()
	list.name = "InfluenceList"
	list.custom_minimum_size = Vector2(0, 260)
	list.item_selected.connect(func(i): sel_iso = str(list.get_item_metadata(i)); _show())
	add_child(list)
	info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info)
	var r = HBoxContainer.new()
	add_child(r)
	var l2 = Label.new()
	l2.text = "Krajina B:"
	r.add_child(l2)
	target2 = OptionButton.new()
	target2.name = "InfluenceTarget2"
	target2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(target2)
	var r2 = HBoxContainer.new()
	add_child(r2)
	var l3 = Label.new()
	l3.text = "Strana:"
	r2.add_child(l3)
	party = OptionButton.new()
	party.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r2.add_child(party)
	actions_box = VBoxContainer.new()
	add_child(actions_box)
	var names: Array = []
	for iso in DataLoader.country_ids:
		names.append([str(DataLoader.countries[iso].get("name_sk", iso)), str(iso)])
	names.sort_custom(func(a, b): return str(a[0]) < str(b[0]))
	for n in names:
		target2.add_item(str(n[0]))
		target2.set_item_metadata(target2.item_count - 1, str(n[1]))
	refresh()

func _process(_d: float) -> void:
	if is_visible_in_tree() and GameState.running and int(GameState.day_index / 7) != _wk:
		refresh()

func country_rows() -> Array:
	var rows: Array = []
	for row in GeopoliticsSystem.relation_rows():
		var iso = str(row.iso)
		rows.append({"iso": iso, "name": str(DataLoader.countries.get(iso, {}).get("name_sk", iso)), "relation": int(row.relation),
			"tariff": float(row.tariff), "flags": row.get("flags", []), "inf": PoliticsSystem.influence(iso)})
	rows.sort_custom(func(a, b): return str(a.name) < str(b.name))
	return rows

func refresh() -> void:
	if not GameState.running:
		info.text = "Spusti hru."
		_wk = -1
		return
	_wk = int(GameState.day_index / 7)
	_rows = country_rows()
	list.clear()
	var home = str(GameState.player.get("home", "SK"))
	var hi = list.add_item("%s (domov) · vplyv %d" % [str(DataLoader.countries.get(home, {}).get("name_sk", home)), int(PoliticsSystem.influence(home))])
	list.set_item_metadata(hi, home)
	for row in _rows:
		var fl = ""
		if not row.flags.is_empty():
			fl = "  [" + ", ".join(row.flags) + "]"
		var i = list.add_item("%s · vzťah %+d · clo %s · vplyv %d%s" % [row.name, row.relation, EconMath.pct(row.tariff), int(row.inf), fl])
		list.set_item_tooltip(i, "%s: vzťah k tvojej domovskej krajine %+d, clo %s, tvoj vplyv %d/100%s" % [row.name, row.relation, EconMath.pct(row.tariff), int(row.inf), fl])
		list.set_item_metadata(i, str(row.iso))
	if sel_iso == "":
		sel_iso = home
	_show()

func _show() -> void:
	var iso = sel_iso
	if iso == "" or not GameState.world.has(iso):
		return
	info.text = PoliticsSystem.text(iso) + "Tvoj vplyv: %d/100 (+%d %% k šanci)" % [int(PoliticsSystem.influence(iso)), int(PoliticsSystem.influence_bonus(iso) * 100)]
	party.clear()
	for q in PoliticsSystem.country(iso).get("parties", []):
		party.add_item(str(q.name))
		party.set_item_metadata(party.item_count - 1, str(q.id))
	for c in actions_box.get_children():
		c.queue_free()
	for a in ACTS:
		var b = Button.new()
		b.name = "Inf_" + str(a[0])
		var cost = PoliticsSystem.action_cost(iso, str(a[0]))
		b.text = "%s – %s, šanca %d %%, škandál %d %%" % [str(a[1]), EconMath.eur(cost), int(PoliticsSystem.action_chance(iso, str(a[0])) * 100), int(PoliticsSystem.scandal_chance(iso, str(a[0])) * 100)]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(_do.bind(str(a[0]), bool(a[2])))
		actions_box.add_child(b)

func _do(action: String, needs_b: bool) -> void:
	var arg = ""
	if needs_b:
		arg = str(target2.get_item_metadata(target2.selected)) if target2.selected >= 0 else ""
	elif action == "fund_party" or action == "lobby_party":
		arg = str(party.get_item_metadata(party.selected)) if party.selected >= 0 else ""
	var res: Dictionary = PoliticsSystem.act(sel_iso, action, arg)
	if host:
		host._feedback(str(res.get("text", "")), bool(res.get("ok", false)) and bool(res.get("success", false)))
		host._refresh_label()
	refresh()
