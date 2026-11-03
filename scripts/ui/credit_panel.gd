extends VBoxContainer
# JUAN5 #18: uver so zalohou (kolateral) a maly nezabezpeceny uver
var host
var info: Label
var quote: Label
var amount: SpinBox
var years_opt: OptionButton
var cash_pledge: SpinBox
var firm_box: VBoxContainer
var repay_amount: SpinBox
var loans_box: VBoxContainer
var sav_info: Label
var sav_amount: SpinBox
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
	amount.value_changed.connect(func(_v): _update_info())
	p.add_child(amount)
	years_opt = OptionButton.new()
	years_opt.name = "LoanYears"
	for y in [1, 3, 5, 10, 20]:
		years_opt.add_item("%d rokov" % y)
		years_opt.set_item_metadata(years_opt.item_count - 1, y)
	years_opt.select(2)
	years_opt.item_selected.connect(func(_i): _update_info())
	p.add_child(years_opt)
	quote = Label.new()
	quote.name = "LoanQuote"
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(quote)
	cash_pledge = SpinBox.new()
	cash_pledge.min_value = 0
	cash_pledge.max_value = 1.0e9
	cash_pledge.step = 1000
	cash_pledge.prefix = "Hotovosť do zálohy €"
	cash_pledge.value_changed.connect(func(_v): _update_info())
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
	u.text = "Požiadať o nezabezpečený úver"
	u.pressed.connect(_on_unsecured)
	p.add_child(u)
	var lh = Label.new()
	lh.text = "Aktívne úvery"
	lh.theme_type_variation = "HeaderLabel"
	p.add_child(lh)
	repay_amount = SpinBox.new()
	repay_amount.name = "RepayAmount"
	repay_amount.min_value = 1
	repay_amount.max_value = 1.0e9
	repay_amount.step = 100
	repay_amount.value = 1000
	repay_amount.prefix = "Splatiť časť €"
	p.add_child(repay_amount)
	loans_box = VBoxContainer.new()
	loans_box.name = "ActiveLoans"
	p.add_child(loans_box)
	var sh = Label.new()
	sh.text = "Sporiaci účet"
	sh.theme_type_variation = "HeaderLabel"
	p.add_child(sh)
	sav_info = Label.new()
	sav_info.name = "SavingsInfo"
	sav_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(sav_info)
	sav_amount = SpinBox.new()
	sav_amount.name = "SavingsAmount"
	sav_amount.min_value = 1
	sav_amount.max_value = 1.0e9
	sav_amount.step = 100
	sav_amount.value = 1000
	sav_amount.prefix = "Suma €"
	p.add_child(sav_amount)
	var row = HBoxContainer.new()
	p.add_child(row)
	var dep = Button.new()
	dep.name = "SavingsDeposit"
	dep.text = "Vložiť"
	dep.pressed.connect(_on_deposit)
	row.add_child(dep)
	var wd = Button.new()
	wd.name = "SavingsWithdraw"
	wd.text = "Vybrať"
	wd.pressed.connect(_on_withdraw)
	row.add_child(wd)
	refresh()

func _process(_d: float) -> void:
	if not is_visible_in_tree() or not GameState.running:
		return
	var sig = _signature()
	if sig != _sig:
		_sig = sig
		refresh()

func _signature() -> String:
	var sig = ""
	for f in GameState.player_firms():
		sig += str(f.id) + str(f.get("pledged", ""))
	sig += str(int(GameState.day_index / 7))
	var sav = GameState.player.get("savings", {})
	if typeof(sav) == TYPE_DICTIONARY:
		sig += "|s" + str(sav.get("balance", 0.0)) + str(sav.get("bank_id", ""))
	for l in GameState.player.get("loans", []):
		sig += "|" + str(l.get("id", "")) + str(l.get("remaining", 0)) + str(l.get("paid", false)) + str(l.get("missed", 0))
	return sig

func _years() -> int:
	if years_opt == null or years_opt.selected < 0:
		return 5
	return int(years_opt.get_item_metadata(years_opt.selected))

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
		if quote:
			quote.text = ""
		if sav_info:
			sav_info.text = "Sporiaci účet je dostupný po štarte hry."
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
	_refresh_loans()
	_refresh_savings()

func _update_info() -> void:
	if info == null or not GameState.running:
		return
	var cv = BankingSystem.collateral_value(selected_items())
	var yrs = _years()
	info.text = "Limit banky: %s. Banka uzná z firmy 50 %%, z nehnuteľnosti 60 %%, z hotovosti 70 %% hodnoty. Vybrané zálohy: %s. Doba %d rokov. Kým beží úver, založené veci nepredáš; pri nesplácaní ich banka zoberie." % [EconMath.eur(BankingSystem.loan_limit()), EconMath.eur(cv), yrs]
	if quote == null:
		return
	var q = BankingSystem.loan_quote(float(amount.value), yrs, 0.0)
	var u_amt = minf(float(amount.value), BankingSystem.UNSECURED_MAX)
	var uq = BankingSystem.loan_quote(u_amt, yrs, BankingSystem.UNSECURED_RATE_ADD)
	var extra = ""
	if float(amount.value) > BankingSystem.UNSECURED_MAX + 0.01:
		extra = " Nezabezpečený úver je max %s." % EconMath.eur(BankingSystem.UNSECURED_MAX)
	quote.text = "Náhľad so zálohou: úrok %s, splátka %s. Bez zálohy: úrok %s, splátka %s (z %s).%s" % [EconMath.pct(float(q.rate)), EconMath.eur(float(q.payment)), EconMath.pct(float(uq.rate)), EconMath.eur(float(uq.payment)), EconMath.eur(u_amt), extra]

func _refresh_loans() -> void:
	if loans_box == null:
		return
	for c in loans_box.get_children():
		c.queue_free()
	var any = false
	for loan in GameState.player.get("loans", []):
		if bool(loan.get("paid", false)) or float(loan.get("remaining", 0.0)) <= 1.0:
			continue
		any = true
		var lender = BankingSystem._bank(str(loan.get("lender", "")))
		var lname = str(lender.get("name", loan.get("lender", "")))
		var lab = Label.new()
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.text = "%s · %s · zostatok %s · úrok %s · splátka %s · zostáva %d mes. · zmeškané %d" % [
			str(loan.get("id", "")), lname,
			EconMath.eur(float(loan.get("remaining", 0.0))),
			EconMath.pct(float(loan.get("annual_rate", 0.0))),
			EconMath.eur(float(loan.get("monthly_payment", 0.0))),
			int(loan.get("months_left", 0)),
			int(loan.get("missed", 0)),
		]
		loans_box.add_child(lab)
		var row = HBoxContainer.new()
		loans_box.add_child(row)
		var part = Button.new()
		part.text = "Splatiť časť"
		var full = Button.new()
		full.text = "Splatiť celé"
		_bind_repay(part, str(loan.get("id", "")), false)
		_bind_repay(full, str(loan.get("id", "")), true)
		row.add_child(part)
		row.add_child(full)
	if not any:
		var empty = Label.new()
		empty.text = "Žiadny aktívny úver."
		loans_box.add_child(empty)

func _refresh_savings() -> void:
	if sav_info == null:
		return
	var sav = GameState.player.get("savings", {})
	if typeof(sav) != TYPE_DICTIONARY:
		sav = {}
	var bid = str(sav.get("bank_id", ""))
	var bname = "—"
	if bid != "":
		var bank = BankingSystem._bank(bid)
		bname = str(bank.get("name", bid))
	sav_info.text = "Zostatok %s · sadzba %s · banka %s. Úrok je základná sadzba centrálnej banky mínus 0,5 p.b. Garančný fond kryje vklad do 100 000 €." % [
		EconMath.eur(float(sav.get("balance", 0.0))),
		EconMath.pct(float(sav.get("rate", 0.0))),
		bname,
	]

func _on_secured() -> void:
	var res: Dictionary = BankingSystem.request_secured_loan(float(amount.value), _years(), selected_items())
	_report(res)

func _on_unsecured() -> void:
	_report(BankingSystem.request_unsecured_loan(float(amount.value), _years()))

func _bind_repay(btn: Button, lid: String, full: bool) -> void:
	btn.pressed.connect(func(): _repay(lid, full))

func _repay(lid: String, full: bool) -> void:
	var loan = BankingSystem._loan_by_id(lid)
	if loan.is_empty():
		_say("Úver neexistuje.", false)
		return
	var amt = float(loan.get("remaining", 0.0)) if full else float(repay_amount.value)
	var res = BankingSystem.repay_loan(lid, amt)
	if bool(res.get("ok", false)):
		if bool(res.get("closed", false)):
			_say("Úver %s je splatený." % lid, true)
		else:
			_say("Splatené %s, zostatok %s, nová splátka %s." % [EconMath.eur(float(res.get("paid", 0.0))), EconMath.eur(float(res.get("remaining", 0.0))), EconMath.eur(float(res.get("payment", 0.0)))], true)
	else:
		_say("Splatenie: %s" % str(res.get("reason", "")), false)
	_sig = ""
	refresh()

func _on_deposit() -> void:
	var res = BankingSystem.deposit(float(sav_amount.value))
	if bool(res.get("ok", false)):
		_say("Vklad %s. Zostatok %s, sadzba %s." % [EconMath.eur(float(sav_amount.value)), EconMath.eur(float(res.get("balance", 0.0))), EconMath.pct(float(res.get("rate", 0.0)))], true)
	else:
		_say("Vklad: %s" % str(res.get("reason", "")), false)
	_sig = ""
	refresh()

func _on_withdraw() -> void:
	var res = BankingSystem.withdraw(float(sav_amount.value))
	if bool(res.get("ok", false)):
		_say("Výber %s. Zostatok %s." % [EconMath.eur(float(res.get("cash", 0.0))), EconMath.eur(float(res.get("balance", 0.0)))], true)
	else:
		_say("Výber: %s" % str(res.get("reason", "")), false)
	_sig = ""
	refresh()

func _report(res: Dictionary) -> void:
	if bool(res.get("ok", false)):
		_say("Úver schválený: +%s, úrok %s, splátka %s" % [EconMath.eur(float(res.amount)), EconMath.pct(float(res.rate)), EconMath.eur(float(res.get("payment", 0.0)))], true)
	else:
		_say("Úver: %s" % str(res.get("reason", "")), false)
	_sig = ""
	refresh()

func _say(text: String, ok: bool) -> void:
	if host and host.has_method("_feedback"):
		host._feedback(text, ok)
	if host and host.has_method("_refresh_label"):
		host._refresh_label()
