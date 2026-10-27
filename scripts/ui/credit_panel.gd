extends VBoxContainer
# JUAN5 #18: uver so zalohou (kolateral) a maly nezabezpeceny uver
var host
var info: Label
var amount: SpinBox
var cash_pledge: SpinBox
var firm_box: VBoxContainer
var _sig = ""

var body: VBoxContainer
func _ready() -> void:
	add_theme_constant_override("separation", 4)
	var t = Button.new()
	t.name = "CreditToggle"
	t.text = "Úver so zálohou / bez zálohy ▸"
	t.toggle_mode = true
	add_child(t)
	body = VBoxContainer.new()
	body.visible = false
	t.toggled.connect(func(on): body.visible = on; refresh())
	add_child(body)
	_build(body)

func _build(p: VBoxContainer) -> void:
	info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(info)
	amount = SpinBox.new()
	amount.min_value = 1000
	amount.max_value = 1.0e9
	amount.step = 1000
	amount.value = 50000
	amount.prefix = "Suma €"
	p.add_child(amount)
	cash_pledge = SpinBox.new()
	cash_pledge.min_value = 0
	cash_pledge.max_value = 1.0e9
	cash_pledge.step = 1000
	cash_pledge.prefix = "Hotovosť do zálohy €"
	p.add_child(cash_pledge)
	firm_box = VBoxContainer.new()
	firm_box.name = "PledgeFirms"
	p.add_child(firm_box)
	var b = Button.new()
	b.name = "SecuredLoan"
	b.text = "Požiadať o úver so zálohou"
	b.pressed.connect(_on_secured)
	p.add_child(b)
	var u = Button.new()
	u.name = "UnsecuredLoan"
	u.text = "Nezabezpečený úver 30 000 € (vyšší úrok)"
	u.pressed.connect(_on_unsecured)
	p.add_child(u)
	refresh()

func _process(_d: float) -> void:
	if not is_visible_in_tree() or not GameState.running:
		return
	var sig = ""
	for f in GameState.player_firms():
		sig += str(f.id) + str(f.get("pledged", ""))
	sig += str(int(GameState.day_index / 7))
	if sig != _sig:
		_sig = sig
		refresh()

func selected_items() -> Array:
	var items: Array = []
	for c in firm_box.get_children():
		if c is CheckBox and c.button_pressed:
			items.append({"kind": "firm", "id": str(c.get_meta("fid"))})
	if cash_pledge.value > 0:
		items.append({"kind": "cash", "amount": float(cash_pledge.value)})
	return items

func refresh() -> void:
	if not GameState.running:
		info.text = "Najprv spusti hru."
		return
	var keep: Dictionary = {}
	for c in firm_box.get_children():
		if c is CheckBox and c.button_pressed:
			keep[str(c.get_meta("fid"))] = true
		c.queue_free()
	for f in GameState.player_firms():
		var cb = CheckBox.new()
		cb.set_meta("fid", str(f.id))
		var v = BankingSystem.asset_market_value({"kind": "firm", "id": str(f.id)})
		var pl = str(f.get("pledged", "")) != ""
		cb.text = "%s – hodnota %s%s" % [str(f.name), EconMath.eur(v), " (už založená)" if pl else ""]
		cb.disabled = pl
		cb.button_pressed = keep.has(str(f.id))
		cb.toggled.connect(func(_on): _update_info())
		firm_box.add_child(cb)
	_update_info()

func _update_info() -> void:
	var cv = BankingSystem.collateral_value(selected_items())
	info.text = "Limit banky: %s. Banka uzná z firmy 50 %%, z nehnuteľnosti 60 %%, z hotovosti 70 %% hodnoty. Vybrané zálohy: %s. Kým beží úver, založené veci nepredáš; pri nesplácaní ich banka zoberie." % [EconMath.eur(BankingSystem.loan_limit()), EconMath.eur(cv)]

func _on_secured() -> void:
	var res: Dictionary = BankingSystem.request_secured_loan(float(amount.value), 5, selected_items())
	_report(res)

func _on_unsecured() -> void:
	_report(BankingSystem.request_unsecured_loan(30000.0, 3))

func _report(res: Dictionary) -> void:
	if host:
		if bool(res.get("ok", false)):
			host._feedback("Úver schválený: +%s, úrok %s" % [EconMath.eur(float(res.amount)), EconMath.pct(float(res.rate))], true)
		else:
			host._feedback("Úver: %s" % str(res.get("reason", "")), false)
		host._refresh_label()
	_sig = ""
