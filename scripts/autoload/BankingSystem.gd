extends Node

const BOND_FACE = 100.0  # referencny par jednej jednotky v knihe objednavok
const BOND_PX_MIN = 50.0   # pasmo ceny objednavky okolo paru (mimo -> ok:false)
const BOND_PX_MAX = 150.0
const BOND_FALLBACK_COUPON = 0.05  # ked chyba centralna banka krajiny
# Nominal dlhopisu z knihy = zaplatena suma (face = cost); kupon = statny vynos, nie cena.

func setup_central() -> void:
	GameState.central.clear()
	for iso in DataLoader.country_ids:
		var c: Dictionary = GameState.world[iso]
		var infl = float(c.get("inflation", 0.03))
		var lend = float(c.get("lending_rate", infl + 0.02))
		var policy = EconMath.cl(lend * 0.75, 0.002, 0.28)
		if infl > 0.15:
			policy = EconMath.cl(infl * 0.8, 0.01, 0.35)
		GameState.central[iso] = {"policy": policy, "target": 0.02}

func daily() -> void:
	_service_explicit_loans()
	for bank in GameState.banks:
		if bank.get("failed", false):
			continue
		if str(bank.owner) == "player":
			_tick_player_bank(bank)
		else:
			_tick_ai_bank(bank)
	service_bonds()
	_mark_stocks()

func monthly() -> void:
	update_rates()
	_refresh_rating()
	for bank in GameState.banks:  # JUAN3: spotrebitelske uvery NPC ludom
		if str(bank.get("owner", "")) == "player" and not bank.get("failed", false):
			var sovereign = SovereignLoans.monthly(bank) if not bank.get("sovereign_loans", []).is_empty() else {"interest": 0.0, "loss": 0.0}
			var advisor_cost = _advisor_month(bank)
			SovereignLoans.advisor_invest(bank)
			consumer_month(bank)
			BankProducts.monthly(bank)  # JUAN4: hypoteky, firemne uvery, sporiace ucty, CAR
			if not bank.get("month_hist", []).is_empty():
				var row: Dictionary = bank.month_hist[-1]
				row.rev = float(row.get("rev", 0.0)) + float(sovereign.interest)
				row.costs = float(row.get("costs", 0.0)) + advisor_cost + float(sovereign.loss)
				row.profit = float(row.rev) - float(row.costs)
				row.loans = float(row.get("loans", 0.0)) + SovereignLoans.outstanding(bank)

const ADVISOR_SALARY = 3500.0

func _advisor_log(bank: Dictionary, message: String) -> void:
	var advisor: Dictionary = bank.get("advisor", {})
	var log: Array = advisor.get("log", [])
	log.append({"day": GameState.day_index, "text": message})
	while log.size() > 24:
		log.pop_front()
	advisor["log"] = log
	bank["advisor"] = advisor

func hire_advisor(bank: Dictionary) -> String:
	if bank.is_empty() or str(bank.get("owner", "")) != "player" or bool(bank.get("failed", false)):
		return "Banka nie je dostupná."
	var advisor: Dictionary = bank.get("advisor", {})
	if bool(advisor.get("hired", false)):
		return "Poradca už pracuje v banke."
	if float(bank.get("reserves", 0.0)) < ADVISOR_SALARY:
		return "Banka nemá rezervu ani na jeden mesačný plat."
	advisor["hired"] = true
	advisor["salary"] = ADVISOR_SALARY
	advisor["override_until"] = 0
	bank["advisor"] = advisor
	_advisor_log(bank, "Poradca nastúpil; mesačný plat %s." % EconMath.eur(ADVISOR_SALARY))
	return ""

func fire_advisor(bank: Dictionary) -> String:
	if bank.is_empty() or str(bank.get("owner", "")) != "player":
		return "Banka nie je dostupná."
	var advisor: Dictionary = bank.get("advisor", {})
	if not bool(advisor.get("hired", false)):
		return "Banka nemá poradcu."
	advisor["hired"] = false
	bank["advisor"] = advisor
	_advisor_log(bank, "Poradca bol prepustený.")
	return ""

func advisor_override(bank: Dictionary) -> void:
	var advisor: Dictionary = bank.get("advisor", {})
	if bool(advisor.get("hired", false)):
		advisor["override_until"] = GameState.day_index + 30
		bank["advisor"] = advisor
		_advisor_log(bank, "Hráč zmenil nastavenia; poradca ich ponechá 30 dní.")

func _advisor_month(bank: Dictionary) -> float:
	var advisor: Dictionary = bank.get("advisor", {})
	if not bool(advisor.get("hired", false)):
		return 0.0
	var salary = maxf(0.0, float(advisor.get("salary", ADVISOR_SALARY)))
	if float(bank.get("reserves", 0.0)) < salary:
		advisor["hired"] = false
		bank["advisor"] = advisor
		_advisor_log(bank, "Poradca odišiel: banka nemá na mesačný plat.")
		return 0.0
	bank.reserves = float(bank.reserves) - salary
	bank.equity = float(bank.equity) - salary
	if GameState.day_index < int(advisor.get("override_until", 0)):
		_advisor_log(bank, "Manuálne nastavenie hráča zostáva v platnosti; plat %s." % EconMath.eur(salary))
		return salary
	var iso = str(bank.get("country", ""))
	var country: Dictionary = GameState.world.get(iso, {})
	var policy = float(GameState.central.get(iso, {}).get("policy", 0.03))
	var risk = clampf(float(country.get("unemployment", 0.05)) + float(country.get("political_risk", 0.1)) * 0.2, 0.0, 0.5)
	var strict = clampf(0.40 + risk, 0.40, 0.85)
	var reserve = clampf(maxf(LawSystem.min_reserve(iso), 0.18 + risk * 0.25), 0.0, 0.9)
	var deposit = clampf(policy * 0.55, 0.0, 0.20)
	bank.strictness = strict
	bank.lending_rate = clampf(policy + 0.055 + risk * 0.08, 0.005, 0.4)
	bank.cons_rate = clampf(policy + 0.09 + risk * 0.1, 0.01, 0.4)
	BankProducts.set_rates(bank, deposit, clampf(policy + 0.035 + risk * 0.05, 0.005, 0.3), clampf(policy + 0.065 + risk * 0.08, 0.005, 0.4), reserve)
	_advisor_log(bank, "Riziko %.0f %%; rezerva %.0f %%, prísnosť %.0f %%, vklady %s, úvery ľuďom %s; plat %s." % [risk * 100.0, reserve * 100.0, strict * 100.0, EconMath.pct(deposit), EconMath.pct(float(bank.cons_rate)), EconMath.eur(salary)])
	return salary

# DEAD: volane len z DEAD issue_loan (etapa 0: nezmazane, len oznacene)
func offer_for(bank: Dictionary, years: int) -> Dictionary:
	var iso = str(bank.country)
	var rating = int(GameState.player.get("rating", 40))
	var spread = 0.02 + (100 - rating) / 100.0 * 0.1 + float(GameState.world[iso].political_risk) * 0.04
	var rate = float(bank.get("lending_rate", bank.get("loan_rate", 0.05))) + spread
	var max_amt = _max_loan()
	return {"rate": rate, "max": max_amt, "years": years}

# DEAD: volane len z DEAD offer_for (etapa 0: nezmazane, len oznacene)
func _max_loan() -> float:
	var profit = 0.0
	for firm in GameState.firms:
		if firm.owner != "player":
			continue
		for row in firm.get("history", []):
			profit += float(row.get("profit", 0.0))
	var annual = profit / max(GameState.day_index, 1) * 365.0
	var assets = 0.0
	for firm2 in GameState.firms:
		if firm2.owner != "player":
			continue
		var ind: Dictionary = DataLoader.industries.get(firm2.industry, {})
		assets += float(ind.get("cost", 0.0))
	return max(20000.0, annual * 3.5 + assets * 0.45 + float(GameState.player.cash) * 0.3)

# DEAD: bez volajuceho; uver bez monthly_payment sa nikdy nesplati (etapa 0: nezmazane, len oznacene)
func issue_loan(bank_id: String, amount: float, years: int) -> String:
	var bank = _bank(bank_id)
	if bank.is_empty():
		return "Banka neexistuje."
	if bank.get("failed", false):
		return "Banka je padnutá."
	var years_c = clampi(years, 1, 12)
	var info = offer_for(bank, years_c)
	amount = min(amount, float(info.max))
	if amount < 5000.0:
		return "Suma je pod minimom alebo nad limitom ratingu."
	if float(bank.reserves) < amount:
		return "Banka nemá dosť rezerv."
	var days = years_c * 365
	var rate = float(info.rate)
	var pay = EconMath.annuity(amount, rate, days)
	GameState.player.cash = float(GameState.player.cash) + amount
	bank.reserves = float(bank.reserves) - amount
	bank.explicit = float(bank.get("explicit", 0.0)) + amount
	GameState.player.loans.append({
		"id": "L%d" % GameState.next_loan,
		"lender": bank_id,
		"principal": amount,
		"remaining": amount,
		"annual_rate": rate,
		"daily_payment": pay,
		"days_left": days,
		"missed": 0,
	})
	GameState.next_loan += 1
	GameState.post_news("Úver %s na %d rokov, sadzba %s, splátka %s / deň." % [EconMath.eur(amount), years_c, EconMath.pct(rate), EconMath.eur(pay)])
	return ""

func found_player_bank(bank_name: String, iso: String) -> String:
	# JUAN9: hrac moze mat viac bank (kazda je firma na mape); bank_id = aktivna banka v detaile
	var capital = 500000.0
	if float(GameState.player.cash) < capital:
		return "Na licenciu a kapitál treba 500 000 €."
	GameState.player.cash = float(GameState.player.cash) - capital
	var pol = float(GameState.central[iso].policy)
	var id = "pb%d" % GameState.next_bank
	GameState.next_bank += 1
	GameState.banks.append({
		"id": id,
		"name": bank_name if bank_name != "" else "Moja banka",
		"owner": "player",
		"country": iso,
		"equity": capital,
		"reserves": capital,
		"deposits": 0.0,
		"npc_loans": 0.0,
		"explicit": 0.0,
		"deposit_rate": pol * 0.5,
		"lending_rate": pol + 0.035,
		"strictness": 0.4,
		"confidence": 0.62,
		"owe_cb": 0.0,
		"defaults_total": 0.0,
		"profit_recent": 0.0,
		"failed": false,
	})
	GameState.player.bank_id = id
	var ids: Array = GameState.player.get("bank_ids", [])
	ids.append(id)
	GameState.player["bank_ids"] = ids
	GameState.post_news("Licencia udelená. %s otvára pobočku v krajine %s." % [bank_name, GameState.world[iso].get("name_sk", iso)])
	return ""

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func set_player_bank(dep: float, lend: float, strictness: float) -> void:
	var bank = _player_bank()
	if bank.is_empty():
		return
	bank.deposit_rate = EconMath.cl(dep, 0.0, 0.25)
	bank.lending_rate = EconMath.cl(lend, 0.005, 0.4)
	bank.strictness = EconMath.cl(strictness, 0.0, 1.0)

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func inject(amount: float) -> String:
	var bank = _player_bank()
	if bank.is_empty():
		return "Nemáš banku."
	if amount <= 0.0 or float(GameState.player.cash) < amount:
		return "Nie dosť hotovosti."
	GameState.player.cash = float(GameState.player.cash) - amount
	bank.equity = float(bank.equity) + amount
	bank.reserves = float(bank.reserves) + amount
	bank.confidence = min(0.95, float(bank.confidence) + 0.04)
	return ""

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func discount_window() -> String:
	var bank = _player_bank()
	if bank.is_empty():
		return "Nemáš banku."
	var need = max(0.0, float(bank.deposits) * 0.12 - float(bank.reserves))
	if need < 1000.0:
		return "Rezervy stačia, okno netreba."
	bank.reserves = float(bank.reserves) + need
	bank.owe_cb = float(bank.owe_cb) + need
	GameState.post_news("Diskontné okno: %s. Sadzba nad politikou." % EconMath.eur(need))
	return ""

func post_bond_order(side: String, price: float, qty: float) -> Dictionary:
	if side != "bid" and side != "ask":
		return {"ok": false, "filled": 0, "open": open_bond_orders().size()}
	if price <= 0.0 or qty <= 0.0 or EconMath.is_bad(price) or EconMath.is_bad(qty):
		return {"ok": false, "filled": 0, "open": open_bond_orders().size()}
	if price < BOND_PX_MIN or price > BOND_PX_MAX:
		return {"ok": false, "reason": "price_band", "filled": 0, "open": open_bond_orders().size()}
	GameState.bond_orders.append({
		"id": "o%d" % GameState.bond_orders.size(),
		"side": side,
		"price": price,
		"qty": qty,
	})
	var filled = _match_bond_orders()
	return {"ok": true, "filled": filled, "open": open_bond_orders().size()}

func open_bond_orders() -> Array:
	var out: Array = []
	for row in GameState.bond_orders:
		if float(row.get("qty", 0.0)) > 0.0001:
			out.append(row)
	return out

func _match_bond_orders() -> int:
	var fills = 0
	while true:
		var bid = {}
		var ask = {}
		for row in GameState.bond_orders:
			if float(row.get("qty", 0.0)) <= 0.0001:
				continue
			if str(row.get("side", "")) == "bid" and (bid.is_empty() or float(row.price) > float(bid.price)):
				bid = row
			if str(row.get("side", "")) == "ask" and (ask.is_empty() or float(row.price) < float(ask.price)):
				ask = row
		if bid.is_empty() or ask.is_empty() or float(bid.price) + 0.0001 < float(ask.price):
			break
		var q = min(float(bid.qty), float(ask.qty))
		var px = float(ask.price)
		var cost = px * q
		if float(GameState.player.cash) + 0.001 < cost:
			break
		GameState.player.cash = float(GameState.player.cash) - cost
		var bond_iso = str(GameState.player.get("home", "SK"))
		GameState.player.bonds.append({
			"country": bond_iso,
			"face": cost,
			"coupon": _bond_yield(bond_iso) if (GameState.central.has(bond_iso) and GameState.world.has(bond_iso)) else BOND_FALLBACK_COUPON,
			"years_left": 5.0,
		})
		bid.qty = float(bid.qty) - q
		ask.qty = float(ask.qty) - q
		fills += 1
	return fills

func buy_bond(iso: String, face: float) -> String:
	if not GameState.central.has(iso):
		return "Neznáma krajina."
	if face < 1000.0 or float(GameState.player.cash) < face:
		return "Na dlhopis nie je hotovosť."
	var yld = _bond_yield(iso)
	GameState.player.cash = float(GameState.player.cash) - face
	GameState.player.bonds.append({
		"country": iso,
		"face": face,
		"coupon": yld,
		"years_left": 5.0,
	})
	GameState.post_news("Štátny dlhopis %s, kupón %s." % [GameState.world[iso].get("name_sk", iso), EconMath.pct(yld)])
	return ""

# DEAD: bez volajuceho (_bond_value vola len GameState.net_worth, ktory je tiez DEAD) (etapa 0: nezmazane, len oznacene)
func sell_bond(index: int) -> String:
	var bonds: Array = GameState.player.bonds
	if index < 0 or index >= bonds.size():
		return "Zlý dlhopis."
	var b: Dictionary = bonds[index]
	var value = _bond_value(b)
	GameState.player.cash = float(GameState.player.cash) + value
	bonds.remove_at(index)
	GameState.post_news("Predaj dlhopisu za %s." % EconMath.eur(value))
	return ""

func _bond_yield(iso: String) -> float:
	var c: Dictionary = GameState.world[iso]
	return EconMath.cl(float(GameState.central[iso].policy) + float(c.political_risk) * 0.35 + max(0.0, float(c.debt_gdp) - 0.6) * 0.04, 0.004, 0.3)

func _bond_value(b: Dictionary) -> float:
	var now = max(_bond_yield(str(b.country)), 0.004)
	var t = max(float(b.get("years_left", 0.0)), 0.0)
	var disc = pow(1.0 + now, -t)
	var v = float(b.face) * (float(b.coupon) * (1.0 - disc) / now + disc)
	return EconMath.cl(v, float(b.face) * 0.55, float(b.face) * 1.45)

func issue_bond(face: float, coupon: float, years: float) -> String:
	if face < 100.0 or coupon < 0.0 or years <= 0.0:
		return "Neplatná emisia."
	GameState.player.cash = float(GameState.player.cash) + face
	if not GameState.player.has("bonds"):
		GameState.player.bonds = []
	GameState.player.bonds.append({
		"country": str(GameState.player.get("home", "SK")),
		"face": face,
		"coupon": coupon,
		"years_left": years,
		"issuer": "player",
	})
	GameState.post_news("Emisia dlhopisu %s, kupón %s, %s rokov." % [EconMath.eur(face), EconMath.pct(coupon), str(years)])
	return ""

# JUAN13 (t810u): emisia s nahladom – vynos podla trhu, limit podla imania
func player_bond_outstanding() -> float:
	var s = 0.0
	for b in GameState.player.get("bonds", []):
		if str(b.get("issuer", "")) == "player":
			s += float(b.get("face", 0.0))
	return s

func bond_limit() -> float:
	return maxf(200000.0, GameState.net_worth() * 0.5)

func bond_quote(face: float, coupon: float, years: float) -> Dictionary:
	var iso = str(GameState.player.get("home", "SK"))
	var y = (_bond_yield(iso) if GameState.central.has(iso) else 0.04) + 0.02  # firma plati prirazku nad statom
	var disc = pow(1.0 + y, -years)
	var v = face * (coupon * (1.0 - disc) / maxf(y, 0.001) + disc)
	var proceeds = clampf(v, face * 0.5, face * 1.05)
	var reason = ""
	if face < 1000.0 or years < 1.0:
		reason = "Minimálne 1 000 € na 1 rok."
	elif player_bond_outstanding() + face > bond_limit():
		reason = "Prekročíš limit emisií (%s)." % EconMath.eur(bond_limit())
	return {"proceeds": proceeds, "market_yield": y, "coupon_year": face * coupon, "total_interest": face * coupon * years, "limit": bond_limit(), "outstanding": player_bond_outstanding(), "reason": reason}

func issue_bond_ex(face: float, coupon: float, years: float) -> String:
	var q = bond_quote(face, coupon, years)
	if str(q.reason) != "":
		return str(q.reason)
	var e = issue_bond(face, coupon, years)
	if e == "":
		GameState.player.cash = float(GameState.player.cash) - face + float(q.proceeds)  # investori zaplatili trhovu cenu
	return e

func issue_shares(firm_id: String, qty: int, price: float) -> String:
	if qty < 1 or price <= 0.0:
		return "Neplatná emisia akcií."
	var firm = GameState.firm_by_id(firm_id)
	if firm.is_empty() or str(firm.get("owner", "")) != "player":
		return "Žiadna firma."
	firm.shares = int(firm.get("shares", 1000)) + qty
	firm.public = min(0.9, float(firm.get("public", 0.0)) + float(qty) / float(firm.shares))
	firm.share_price = price
	GameState.player.cash = float(GameState.player.cash) + price * float(qty)
	GameState.post_news("Emisia %d akcií %s za %s." % [qty, firm.get("name", firm_id), EconMath.eur(price)])
	return ""

func service_bonds() -> Dictionary:
	var coupon_paid = 0.0
	var matured = 0
	var bonds: Array = GameState.player.get("bonds", [])
	var i = bonds.size() - 1
	while i >= 0:
		var b: Dictionary = bonds[i]
		var pay = float(b.get("face", 0.0)) * float(b.get("coupon", 0.0)) / 365.0
		var player_owes = str(b.get("issuer", "state")) == "player"
		if player_owes:
			GameState.player.cash = float(GameState.player.cash) - pay
		else:
			GameState.player.cash = float(GameState.player.cash) + pay
		coupon_paid += pay
		b.years_left = float(b.get("years_left", 1.0)) - 1.0 / 365.0
		if float(b.years_left) <= 0.0:
			var face = float(b.get("face", 0.0))
			if player_owes:
				GameState.player.cash = float(GameState.player.cash) - face
			else:
				GameState.player.cash = float(GameState.player.cash) + face
			bonds.remove_at(i)
			matured += 1
		i -= 1
	return {"coupon": coupon_paid, "matured": matured}

# DEAD: volane len z DEAD _service_explicit_loans (etapa 0: nezmazane, len oznacene)
func apply_installment(loan: Dictionary, cash: float) -> Dictionary:
	var pay = float(loan.get("daily_payment", 0.0))
	var interest = float(loan.get("remaining", 0.0)) * float(loan.get("annual_rate", 0.0)) / 365.0
	var principal = max(0.0, pay - interest)
	if cash + 0.001 < pay:
		return {"ok": false, "cash": cash, "interest": interest, "principal": principal}
	cash -= pay
	loan.remaining = max(0.0, float(loan.remaining) - principal)
	loan.days_left = int(loan.get("days_left", 0)) - 1
	loan.missed = 0
	return {"ok": true, "cash": cash, "interest": interest, "principal": principal}

# DEAD: prvy riadok je return -> telo je nedosiahnutelne; volane z daily() (etapa 0: nezmazane, len oznacene)
func _service_explicit_loans() -> void:
	return
	var still: Array = []
	for loan in GameState.player.loans:
		if float(loan.remaining) <= 1.0:
			continue
		var pay = float(loan.daily_payment)
		if float(GameState.player.cash) < pay:
			_pull_dividend(pay - float(GameState.player.cash))
		var applied: Dictionary = apply_installment(loan, float(GameState.player.cash))
		if bool(applied.get("ok", false)):
			GameState.player.cash = float(applied.cash)
			var bank = _bank(str(loan.lender))
			if not bank.is_empty():
				bank.reserves = float(bank.reserves) + pay
				bank.explicit = max(0.0, float(bank.get("explicit", 0.0)) - float(applied.principal))
				bank.equity = float(bank.equity) + float(applied.interest)
			if float(loan.remaining) > 1.0:
				still.append(loan)
		else:
			loan.missed = int(loan.missed) + 1
			if int(loan.missed) >= 5:
				_default(loan)
				if float(loan.remaining) > 1.0 and not GameState.player.get("bankrupt", false):
					still.append(loan)
			else:
				still.append(loan)
				GameState.post_news("Zmeškaná splátka (%d/5)." % int(loan.missed))
	GameState.player.loans = still

# Prevod firma -> hrac. S firmou (JUAN-FIX K0c4): vyplati presne `need` z tejto firmy ako dividendu.
# Bez firmy (stary DEAD volajuci _service_explicit_loans): berie z firiem nad 2000 EUR na splatku.
func _pull_dividend(need: float, from_firm: Dictionary = {}) -> void:
	if need <= 0.0:
		return
	if not from_firm.is_empty():
		var amt = min(need, max(0.0, float(from_firm.cash)))
		from_firm.cash = float(from_firm.cash) - amt
		GameState.player.cash = float(GameState.player.cash) + amt
		GameState.post_news("Dividenda z %s: +%s" % [str(from_firm.get("name", "firma")), EconMath.eur(amt)])
		return
	for firm in GameState.firms:
		if firm.owner != "player" or firm.get("closed", false):
			continue
		var take = min(need, max(0.0, float(firm.cash) - 2000.0))
		if take <= 0.0:
			continue
		firm.cash = float(firm.cash) - take
		GameState.player.cash = float(GameState.player.cash) + take
		need -= take
		GameState.post_news("Manažér poslal %s na splátku úveru." % EconMath.eur(take))
		if need <= 0.0:
			return

# DEAD: volane len z DEAD _service_explicit_loans (etapa 0: nezmazane, len oznacene)
func _default(loan: Dictionary) -> void:
	if bool(loan.get("secured", false)) and not bool(loan.get("released", false)):
		seize_collateral(loan)
		return
	var seized = false
	for firm in GameState.firms:
		if firm.owner != "player" or firm.get("closed", false) or str(firm.get("pledged", "")) != "":
			continue
		var ind: Dictionary = DataLoader.industries.get(firm.industry, {})
		var salvage = float(ind.get("cost", 50000.0)) * 0.4
		firm.closed = true
		GameState.player.cash = float(GameState.player.cash) + salvage
		loan.remaining = max(0.0, float(loan.remaining) - salvage)
		GameState.post_news("Exekúcia: %s zabavená, výťažok %s." % [firm.name, EconMath.eur(salvage)])
		seized = true
		break
	if float(loan.remaining) > 1000.0 and not seized and float(GameState.player.cash) <= 0.0:
		GameState.player.bankrupt = true
		GameState.paused = true
		GameState.post_news("Bankrot. Veritelia si rozobrali, čo ostalo.")

func _tick_player_bank(bank: Dictionary) -> void:
	var iso = str(bank.country)
	var c: Dictionary = GameState.world[iso]
	var policy = float(GameState.central[iso].policy)
	var market_dep = policy * 0.55
	var market_lend = policy + 0.03 + float(c.political_risk) * 0.04
	var gdp_eur = float(c.gdp_usd) / max(GameState.usd_per_eur, 0.2)
	var pool = gdp_eur * 0.0000035 * float(bank.confidence)
	var edge = float(bank.deposit_rate) - market_dep
	var inflow = pool * EconMath.cl(0.12 + edge * 10.0, 0.0, 0.85)
	var outflow = float(bank.deposits) * (0.0035 + max(0.0, market_dep - float(bank.deposit_rate)) * 0.35)
	var ratio = float(bank.get("reserve_ratio", 0.1))
	if bool(bank.get("advisor", {}).get("hired", false)):
		ratio = maxf(ratio, float(bank.get("reserve_target", ratio)))
	var liq = float(bank.reserves) / max(float(bank.deposits), 1.0)
	if float(bank.deposits) > 1000.0 and liq < ratio:
		outflow += float(bank.deposits) * 0.045
		bank.confidence = float(bank.confidence) - 0.025
		if int(GameState.day_index) % 7 == 0:
			GameState.post_news("Run na %s. Vkladatelia vyberajú." % bank.name)
	else:
		bank.confidence = min(0.95, float(bank.confidence) + 0.0015)
	outflow = minf(outflow, float(bank.deposits) + inflow)
	bank.deposits = max(0.0, float(bank.deposits) + inflow - outflow)
	bank.reserves = float(bank.reserves) + inflow - outflow
	var lend_edge = market_lend - float(bank.get("lending_rate", bank.get("loan_rate", 0.05)))
	var demand = pool * EconMath.cl(0.15 + lend_edge * 7.0, 0.02, 1.0) * (1.0 - float(bank.strictness) * 0.65)
	var liabilities = float(bank.deposits) + (float(bank.get("savings", 0.0)) if bool(bank.get("advisor", {}).get("hired", false)) else 0.0)
	var room = float(bank.reserves) - liabilities * ratio
	room = minf(room, maxf(0.0, float(bank.equity) / BankProducts.MIN_CAR - BankProducts.rwa(bank)))
	var new_loans = min(max(0.0, demand), max(0.0, room))
	bank.npc_loans = float(bank.npc_loans) + new_loans
	bank.reserves = float(bank.reserves) - new_loans
	var repay = float(bank.npc_loans) / (365.0 * 4.0)
	bank.npc_loans = float(bank.npc_loans) - repay
	bank.reserves = float(bank.reserves) + repay
	var inc = float(bank.npc_loans) * float(bank.get("lending_rate", bank.get("loan_rate", 0.05))) / 365.0
	var expn = float(bank.deposits) * float(bank.deposit_rate) / 365.0
	var cb_rate = policy + 0.03
	var cb_int = float(bank.owe_cb) * cb_rate / 365.0
	bank.reserves = float(bank.reserves) + inc - expn - cb_int
	bank.equity = float(bank.equity) + inc - expn - cb_int
	if float(bank.owe_cb) > 0.0 and float(bank.reserves) > float(bank.deposits) * 0.15:
		var back = min(float(bank.owe_cb), float(bank.reserves) * 0.02)
		bank.owe_cb = float(bank.owe_cb) - back
		bank.reserves = float(bank.reserves) - back
	var def_rate = (0.00004 + float(c.unemployment) * 0.00015) * float(GameState.player.modifiers.get("default_mult", 1.0))
	if GeopoliticsSystem.at_war(iso):
		def_rate += 0.0002
	def_rate *= 1.0 - float(bank.strictness) * 0.4
	var loss = float(bank.npc_loans) * def_rate
	bank.npc_loans = max(0.0, float(bank.npc_loans) - loss)
	bank.equity = float(bank.equity) - loss
	bank.defaults_total = float(bank.defaults_total) + loss
	bank.profit_recent = float(bank.get("profit_recent", 0.0)) * 0.95 + (inc - expn - loss - cb_int)
	flag_liquidity(bank)
	if bool(bank.get("bank_run", false)):
		var pull = float(bank.deposits) * 0.04
		bank.deposits = max(0.0, float(bank.deposits) - pull)
		bank.reserves = float(bank.reserves) - pull
		bank.run_withdrawn = float(bank.get("run_withdrawn", 0.0)) + pull
		flag_liquidity(bank)
	if float(bank.equity) <= 0.0:
		bank.failed = true
		if str(GameState.player.get("bank_id", "")) == str(bank.get("id", "")):
			GameState.player.bank_id = ""
		GameState.post_news("%s skrachovala. Licencia zanikla, kapitál je preč." % bank.name)

func _tick_ai_bank(bank: Dictionary) -> void:
	var iso = str(bank.country)
	var c: Dictionary = GameState.world[iso]
	var def_rate = 0.00003 + float(c.unemployment) * 0.0001
	if GeopoliticsSystem.at_war(iso):
		def_rate += 0.00012
	var loss = float(bank.npc_loans) * def_rate
	bank.npc_loans = max(0.0, float(bank.npc_loans) - loss)
	bank.equity = float(bank.equity) - loss
	var inc = float(bank.npc_loans) * float(bank.get("lending_rate", bank.get("loan_rate", 0.05))) / 365.0
	var expn = float(bank.deposits) * float(bank.deposit_rate) / 365.0
	bank.equity = float(bank.equity) + inc - expn
	bank.reserves = float(bank.reserves) + inc - expn
	if float(bank.equity) < 0.0:
		bank.failed = true

func _refresh_rating() -> void:
	var profit = 0.0
	for firm in GameState.firms:
		if firm.owner != "player":
			continue
		for row in firm.get("history", []):
			profit += float(row.get("profit", 0.0))
	var debt = 0.0
	for loan in GameState.player.loans:
		debt += float(loan.remaining)
	var assets = float(GameState.player.cash)
	for firm2 in GameState.firms:
		if firm2.owner == "player" and not firm2.get("closed", false):
			assets += float(firm2.cash)
			var ind: Dictionary = DataLoader.industries.get(firm2.industry, {})
			assets += float(ind.get("cost", 0.0)) * 0.5
	var lev = debt / max(assets, 1.0)
	var score = 55.0
	score += EconMath.cl(profit / 50000.0, -25.0, 30.0)
	score -= lev * 28.0
	score -= float(GameState.player.get("missed_total", 0)) * 4.0
	var missed_now = 0
	for loan2 in GameState.player.loans:
		missed_now += int(loan2.missed)
	score -= missed_now * 6.0
	GameState.player.rating = int(EconMath.cl(score, 5.0, 96.0))

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func rating_label(score: int) -> String:
	if score >= 85:
		return "AAA"
	if score >= 75:
		return "AA"
	if score >= 65:
		return "A"
	if score >= 55:
		return "BBB"
	if score >= 45:
		return "BB"
	if score >= 35:
		return "B"
	if score >= 25:
		return "CCC"
	return "D"

func _mark_stocks() -> void:
	if GameState.day_index % 7 != 0:
		return
	for firm in GameState.firms:
		var earn = 0.0
		for row in firm.get("history", []):
			earn += float(row.get("profit", 0.0))
		var annual = earn / max(firm.get("history", []).size(), 1) * 365.0
		var shares = max(1.0, float(firm.get("shares", 1000.0)))
		var pe = 9.0 / (1.0 + float(GameState.central.get(firm.country, {}).get("policy", 0.02)) * 4.0)
		var fundamental = max(0.0, annual) * pe / shares
		var book = float(firm.cash) / shares
		var target = max(book * 0.4, fundamental)
		if target <= 0.0:
			target = float(DataLoader.industries.get(firm.industry, {}).get("cost", 10000.0)) / shares * 0.2
		firm.share_price = lerpf(float(firm.get("share_price", target)), target, 0.35)
		firm.share_price = max(0.5, float(firm.share_price) * (0.99 + GameState.rng.randf() * 0.02))

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func ipo(firm_id: String) -> String:
	var firm = GameState.firm_by_id(firm_id)
	if firm.is_empty() or firm.owner != "player":
		return "Firma nie je tvoja."
	if float(firm.get("public", 0.0)) > 0.05:
		return "Už je na trhu."
	_mark_stocks()
	var slice = 0.3 * float(firm.shares)
	var cash = slice * float(firm.share_price)
	firm.public = 0.3
	GameState.player.cash = float(GameState.player.cash) + cash
	GameState.player.stocks[firm_id] = int(GameState.player.stocks.get(firm_id, 0))
	GameState.post_news("IPO %s vynieslo %s." % [firm.name, EconMath.eur(cash)])
	return ""

func post_stock_order(side: String, ticker: String, price: float, qty: float) -> Dictionary:
	if side != "bid" and side != "ask":
		return {"ok": false, "filled": 0, "open": open_stock_orders().size()}
	if ticker == "" or price <= 0.0 or qty <= 0.0:
		return {"ok": false, "filled": 0, "open": open_stock_orders().size()}
	GameState.stock_orders.append({
		"id": "s%d" % GameState.stock_orders.size(),
		"side": side,
		"ticker": ticker,
		"price": price,
		"qty": qty,
	})
	var filled = _match_stock_orders()
	return {"ok": true, "filled": filled, "open": open_stock_orders().size()}

func open_stock_orders() -> Array:
	var out: Array = []
	for row in GameState.stock_orders:
		if float(row.get("qty", 0.0)) > 0.0001:
			out.append(row)
	return out

func _match_stock_orders() -> int:
	var fills = 0
	while true:
		var bid = {}
		var ask = {}
		for row in GameState.stock_orders:
			if float(row.get("qty", 0.0)) <= 0.0001:
				continue
			if str(row.get("side", "")) == "bid" and (bid.is_empty() or float(row.price) > float(bid.price)):
				bid = row
			if str(row.get("side", "")) == "ask" and (ask.is_empty() or float(row.price) < float(ask.price)):
				ask = row
		if bid.is_empty() or ask.is_empty():
			break
		if str(bid.get("ticker", "")) != str(ask.get("ticker", "")) or float(bid.price) + 0.0001 < float(ask.price):
			break
		var q = min(float(bid.qty), float(ask.qty))
		var px = float(ask.price)
		var cost = px * q
		if float(GameState.player.cash) + 0.001 < cost:
			break
		var ticker = str(ask.get("ticker", ""))
		GameState.player.cash = float(GameState.player.cash) - cost
		GameState.player.stocks[ticker] = int(GameState.player.stocks.get(ticker, 0)) + int(round(q))
		bid.qty = float(bid.qty) - q
		ask.qty = float(ask.qty) - q
		fills += 1
	return fills

func buy_stock(firm_id: String, shares: int) -> String:
	var firm = GameState.firm_by_id(firm_id)
	if firm.is_empty():
		return "Firma neexistuje."
	if float(firm.get("public", 0.0)) <= 0.0 and firm.owner != "player":
		return "Akcie nie sú verejné."
	var cost = float(firm.share_price) * shares
	if float(GameState.player.cash) < cost:
		return "Nie dosť peňazí."
	GameState.player.cash = float(GameState.player.cash) - cost
	GameState.player.stocks[firm_id] = int(GameState.player.stocks.get(firm_id, 0)) + shares
	return ""

# DEAD: bez volajuceho (etapa 0: nezmazane, len oznacene)
func sell_stock(firm_id: String, shares: int) -> String:
	var owned = int(GameState.player.stocks.get(firm_id, 0))
	if shares > owned:
		return "Nemáš toľko akcií."
	var firm = GameState.firm_by_id(firm_id)
	if firm.is_empty():
		return "Firma neexistuje."
	var gain = float(firm.share_price) * shares
	GameState.player.stocks[firm_id] = owned - shares
	GameState.player.cash = float(GameState.player.cash) + gain
	return ""

func player_banks() -> Array:
	var out: Array = []
	for b in GameState.banks:
		if str(b.get("owner", "")) == "player" and not bool(b.get("failed", false)):
			out.append(b)
	return out

func set_active_bank(id: String) -> void:
	GameState.player.bank_id = id

const HELP = "AKO FUNGUJÚ ÚVERY\n• Limit: banka ti požičia najviac toľko, koľko dovoľuje obtiažnosť (100–200k na štarte) + polovica tvojho čistého imania, viac s dobrou reputáciou a splatenými úvermi.\n• Úrok = základná sadzba centrálnej banky + riziková prirážka (tvoje skóre, stabilita krajiny) + obtiažnosť; nezabezpečený úver +4 p.b.\n• Záloha: banka uzná z firmy 50 %, z hotovosti 70 % hodnoty. Založené veci nepredáš. Po 3 nesplatených splátkach si ich banka zoberie.\n• Splátka je mesačná (anuita). Splatený úver zvýši limit.\n• VLASTNÁ BANKA: postav ju na mape ako firmu (Založiť → Banka, v meste). Môžeš mať viac bánk. Banka berie vklady, dáva úvery ľuďom, hypotéky a firemné úvery; zisk = úroky − úroky z vkladov − straty z nesplácania."

func _player_bank() -> Dictionary:
	return _bank(str(GameState.player.get("bank_id", "")))

func _bank(id: String) -> Dictionary:
	for b in GameState.banks:
		if str(b.id) == id:
			return b
	return {}

func max_loan_amount(cashflow: float, credit_score: float, country_rating: float) -> float:
	return max(0.0, 20000.0 + cashflow * 3.0 + credit_score * 2000.0 + country_rating * 1500.0)

func risk_premium_for(credit_score: float, country_rating: float) -> float:
	return (100.0 - credit_score) / 100.0 * 0.05 + (100.0 - country_rating) / 100.0 * 0.03

func investment_factor(rate: float) -> float:
	return 1.0 / (1.0 + rate * 10.0)

func capital_demand(rate: float, gdp: float) -> float:
	return gdp * (0.01 + rate * 0.2)

# Etapa 1, krok 4: Taylorovo pravidlo s vyhladzovanim (a_pi = 1.5 > 1), strop 0.40, dno 0.002.
const TAYLOR_RSTAR = 0.015
const TAYLOR_TARGET = 0.02
const TAYLOR_A_PI = 1.5
const TAYLOR_A_Y = 0.5
const RATE_SMOOTH = 0.6
const RATE_MIN = 0.002
const RATE_MAX = 0.4

func update_rates() -> void:
	for iso in GameState.world.keys():
		var c: Dictionary = GameState.world[iso]
		var infl = clampf(float(c.get("inflation", 0.02)), GameState.INFL_MIN, GameState.INFL_MAX)
		var growth = float(c.get("gdp_growth", 0.02))
		var stability = float(c.get("stability", 50.0))
		var gap = clampf(growth - 0.02, -0.06, 0.06)
		var target = TAYLOR_RSTAR + infl + TAYLOR_A_PI * (infl - TAYLOR_TARGET) + TAYLOR_A_Y * gap + (100.0 - stability) / 100.0 * 0.05
		if not GameState.central.has(iso):
			GameState.central[iso] = {}
		var row: Dictionary = GameState.central[iso]
		# vyhladzovanie sa posunie len raz za den (update_rates sa vola aj z request_loan)
		if int(row.get("upd_day", -1)) != GameState.day_index or not row.has("prev_rate"):
			row.prev_rate = float(row.get("base_rate", row.get("policy", 0.02)))
			row.upd_day = GameState.day_index
		var rate = clampf(RATE_SMOOTH * float(row.prev_rate) + (1.0 - RATE_SMOOTH) * target, RATE_MIN, RATE_MAX)
		row.base_rate = rate
		row.policy = rate

func request_loan(amount: float, years: int = 5) -> Dictionary:
	update_rates()
	var iso = str(GameState.player.get("home", ""))
	var score = float(GameState.player.get("credit_score", 55.0))
	var rating = float(GameState.world[iso].get("stability", 50.0))
	var cashflow = 0.0
	for firm in GameState.firms:
		if str(firm.get("owner", "")) != "player":
			continue
		for row in firm.get("history", []):
			cashflow += float(row.get("profit", 0.0))
	cashflow = cashflow / max(GameState.day_index, 1) * 365.0
	var cap = max_loan_amount(cashflow, score, rating)
	if IndustrySystem.progression_on():
		cap = minf(maxf(cap, float(START_LIMIT.get(Difficulty.mode(), 150000.0))), loan_limit())
	var premium = risk_premium_for(score, rating)
	var base = float(GameState.central[iso].get("base_rate", 0.02))
	var rate = max(0.001, base + premium + Difficulty.rate_add() + PoliticsSystem.rate_bonus())  # JUAN4: obtiaznost
	if amount > cap + 0.001:
		return {"ok": false, "reason": "cap", "cap": cap, "rate": rate, "amount": 0.0}
	var bank = {}
	for b in GameState.banks:
		if not b.get("failed", false) and float(b.get("reserves", 0.0)) + 0.001 >= amount:
			bank = b
			break
	if bank.is_empty():
		return {"ok": false, "reason": "underfunded", "cap": cap, "rate": rate, "amount": 0.0}
	var months = max(years, 1) * 12
	var r = rate / 12.0
	var pay = amount / float(months)
	if r > 0.0000001:
		var g = pow(1.0 + r, float(months))
		pay = amount * (r * g) / (g - 1.0)
	GameState.player.cash = float(GameState.player.cash) + amount
	bank.reserves = float(bank.reserves) - amount
	bank.explicit = float(bank.get("explicit", 0.0)) + amount
	GameState.player.loans.append({
		"id": "L%d" % GameState.next_loan,
		"lender": bank.id,
		"principal": amount,
		"remaining": amount,
		"annual_rate": rate,
		"base_rate": base,
		"risk_premium": premium,
		"monthly_payment": pay,
		"days_left": months * 30,
		"months_left": months,
		"missed": 0,
	})
	GameState.next_loan += 1
	return {"ok": true, "reason": "", "cap": cap, "rate": rate, "amount": amount, "payment": pay}

func process_monthly_interest() -> void:
	for loan in GameState.player.loans:
		if float(loan.get("remaining", 0.0)) <= 1.0:
			continue
		var pay = float(loan.get("monthly_payment", 0.0))
		var interest = float(loan.remaining) * float(loan.annual_rate) / 12.0
		var principal = max(0.0, pay - interest)
		if float(GameState.player.cash) + 0.001 < pay:
			loan.missed = int(loan.get("missed", 0)) + 1
			check_bankruptcy()
			continue
		GameState.player.cash = float(GameState.player.cash) - pay
		loan.remaining = max(0.0, float(loan.remaining) - principal)
		loan.months_left = int(loan.get("months_left", 1)) - 1
		loan.missed = 0
		var bank = _bank(str(loan.get("lender", "")))
		if not bank.is_empty():
			bank.reserves = float(bank.reserves) + pay
			bank.explicit = max(0.0, float(bank.get("explicit", 0.0)) - principal)
			bank.equity = float(bank.get("equity", 0.0)) + interest

func check_bankruptcy() -> Dictionary:
	var missed = false
	for loan in GameState.player.loans:
		if int(loan.get("missed", 0)) > 0:
			missed = true
			break
	if not missed:
		return {"ok": false, "seized": false, "score": float(GameState.player.get("credit_score", 55.0))}
	var score = float(GameState.player.get("credit_score", 55.0)) - 15.0
	GameState.player.credit_score = max(0.0, score)
	GameState.player.rating = int(GameState.player.credit_score)
	var seized = false
	var best: Dictionary = {}
	var best_value = -1.0
	for firm in GameState.firms:
		if str(firm.get("owner", "")) != "player" or firm.get("closed", false):
			continue
		var ind: Dictionary = DataLoader.industries.get(firm.get("industry", ""), {})
		var value = float(ind.get("cost", 0.0)) + float(firm.get("cash", 0.0))
		if value > best_value:
			best_value = value
			best = firm
	if not best.is_empty():
		best.closed = true
		seized = true
		GameState.post_news("Exekúcia zobrala %s." % str(best.get("name", best.get("industry", "firmu"))))
	if not GameState.player.has("events"):
		GameState.player.events = []
	GameState.player.events.append({"type": "bankruptcy", "day": GameState.day_index})
	GameState.player.bankrupt = float(GameState.player.cash) <= 0.0 and not seized
	GameState.post_story("bankruptcy", "Bankrot: zmeškaná splátka, credit score klesol, aktívum zabavené.")
	return {"ok": true, "seized": seized, "score": float(GameState.player.credit_score)}

func create_bank(deposit_rate: float, loan_rate: float, reserve_ratio: float) -> Dictionary:
	var floor = LawSystem.min_reserve(str(GameState.player.get("home", "")))
	if reserve_ratio + 0.000001 < floor:
		return {"ok": false, "reason": "law", "floor": floor}
	var capital = 20000.0
	if float(GameState.player.cash) < capital:
		return {"ok": false, "reason": "capital"}
	GameState.player.cash = float(GameState.player.cash) - capital
	var bank = {
		"id": "pb%d" % GameState.next_bank,
		"name": "Hráčska banka",
		"owner": "player",
		"country": str(GameState.player.home),
		"equity": capital,
		"reserves": capital,
		"deposits": 0.0,
		"npc_loans": 0.0,
		"explicit": 0.0,
		"deposit_rate": deposit_rate,
		"loan_rate": loan_rate,
		"lending_rate": loan_rate,
		"reserve_ratio": reserve_ratio,
		"strictness": 0.4,
		"confidence": 0.7,
		"owe_cb": 0.0,
		"defaults_total": 0.0,
		"profit_recent": 0.0,
		"failed": false,
		"bank_run": false,
		"liquidity": 1.0,
	}
	GameState.next_bank += 1
	var deposit = 80000.0
	bank.deposits = deposit
	bank.reserves = float(bank.reserves) + deposit
	var lend = 50000.0
	bank.npc_loans = lend
	bank.reserves = float(bank.reserves) - lend
	flag_liquidity(bank)
	GameState.banks.append(bank)
	GameState.player.bank_id = bank.id
	GameState.post_news("Banka založená. Vklad NPC a úver AI firme sú v knihe.")
	return {"ok": true, "bank": bank}

func flag_liquidity(bank: Dictionary) -> bool:
	var deposits = max(float(bank.get("deposits", 0.0)), 1.0)
	bank.liquidity = float(bank.get("reserves", 0.0)) / deposits
	bank.bank_run = float(bank.liquidity) < float(bank.get("reserve_ratio", 0.1))
	return bool(bank.bank_run)


# ===== JUAN3: spotrebitelske uvery hracovej banky ludom (NPC) =====
const CONS_TERM = 36          # mesiacov
const CONS_LEND_SHARE = 0.5   # mesacne max 50 % volnej likvidity (rezervy nad povinnu rezervu)

func annuity_payment(principal: float, annual_rate: float, months: int) -> float:
	if months <= 0:
		return principal
	var r = annual_rate / 12.0
	if r <= 0.000001:
		return principal / float(months)
	return principal * r / (1.0 - pow(1.0 + r, -float(months)))

func consumer_rate(bank: Dictionary) -> float:
	return float(bank.get("cons_rate", float(bank.get("lending_rate", bank.get("loan_rate", 0.06))) + 0.04))

func set_consumer_rate(rate: float) -> float:
	var bank = _player_bank()
	if bank.is_empty():
		return -1.0
	bank["cons_rate"] = EconMath.cl(rate, 0.01, 0.40)
	return float(bank.cons_rate)

# Mesacna pravdepodobnost defaultu dlznika: zaklad + nezamestnanost + drahy uver + vojna; scoring a prisnost znizuju.
func consumer_default_rate(bank: Dictionary, rate_override: float = -1.0) -> float:
	var c: Dictionary = GameState.world.get(str(bank.get("country", "")), {})
	var r = rate_override if rate_override >= 0.0 else consumer_rate(bank)
	var d = 0.0015 + float(c.get("unemployment", 0.05)) * 0.02 + max(0.0, r - 0.08) * 0.03
	if GameState.running and GeopoliticsSystem.at_war(str(bank.get("country", ""))):
		d += 0.003
	d *= float(GameState.player.get("modifiers", {}).get("default_mult", 1.0))
	d *= 1.0 - float(bank.get("strictness", 0.4)) * 0.4
	return EconMath.cl(d, 0.0, 0.2)

# Mesacny dopyt ludi po uveroch (EUR): populacia * HDP/obyv * citlivost na sadzbu * (1 - prisnost).
func consumer_demand(bank: Dictionary) -> float:
	var c: Dictionary = GameState.world.get(str(bank.get("country", "")), {})
	var gdp_pc_eur = float(c.get("gdp_pc_usd", 20000.0)) / max(GameState.usd_per_eur, 0.2)
	var base = float(c.get("population", 1000000.0)) * gdp_pc_eur * 0.00002
	var r = consumer_rate(bank)
	return base * EconMath.cl(1.6 - r * 8.0, 0.05, 1.5) * (1.0 - float(bank.get("strictness", 0.4)) * 0.5)

func consumer_month(bank: Dictionary) -> Dictionary:
	var rate = consumer_rate(bank)
	var dr = consumer_default_rate(bank)
	var loans: Array = bank.get("cons_loans", [])
	var collected = 0.0
	var interest = 0.0
	var loss = 0.0
	var keep: Array = []
	for ln in loans:
		var p = float(ln.get("p", 0.0))
		var n = int(ln.get("n", 0))
		var loan_rate = float(ln.get("rate", rate))
		var d = p * consumer_default_rate(bank, loan_rate)
		p -= d
		loss += d
		var pay = annuity_payment(p, loan_rate, n)
		var i = p * loan_rate / 12.0
		p = max(0.0, p - (pay - i))
		n -= 1
		collected += pay
		interest += i
		if n > 0 and p > 1.0:
			keep.append({"p": p, "n": n, "rate": loan_rate})
	var ratio = float(bank.get("reserve_ratio", 0.1))
	if bool(bank.get("advisor", {}).get("hired", false)):
		ratio = maxf(ratio, float(bank.get("reserve_target", ratio)))
	bank.reserves = float(bank.get("reserves", 0.0)) + collected
	var liabilities = float(bank.get("deposits", 0.0)) + (float(bank.get("savings", 0.0)) if bool(bank.get("advisor", {}).get("hired", false)) else 0.0)
	var room = max(0.0, float(bank.reserves) - liabilities * ratio)
	room = minf(room, maxf(0.0, float(bank.get("equity", 0.0)) / BankProducts.MIN_CAR - BankProducts.rwa(bank)))
	var lend = min(consumer_demand(bank), room * CONS_LEND_SHARE)
	if lend >= 100.0:
		keep.append({"p": lend, "n": CONS_TERM, "rate": rate})
		bank.reserves = float(bank.reserves) - lend
	else:
		lend = 0.0
	bank["cons_loans"] = keep
	bank.equity = float(bank.get("equity", 0.0)) + interest - loss
	bank.defaults_total = float(bank.get("defaults_total", 0.0)) + loss
	var outstanding = 0.0
	var next_pay = 0.0
	for ln2 in keep:
		outstanding += float(ln2.p)
		next_pay += annuity_payment(float(ln2.p), float(ln2.get("rate", rate)), int(ln2.n))
	var stats = {"outstanding": outstanding, "repaid": collected, "interest": interest, "loss": loss,
		"new": lend, "monthly_due": next_pay, "default_rate": dr, "rate": rate, "borrowers": keep.size()}
	bank["cons_stats"] = stats
	if str(bank.get("owner", "")) == "player":  # JUAN4: mesacna historia banky pre graf v detaile
		var mh: Array = bank.get("month_hist", [])
		mh.append({"rev": interest, "costs": loss, "profit": interest - loss, "y": int(GameState.date.y), "m": int(GameState.date.m)})
		while mh.size() > 24:
			mh.pop_front()
		bank["month_hist"] = mh
	return stats

# ===== JUAN5 #18: limit uveru, zabezpecene uvery (kolateral), nezabezpeceny uver =====
const START_LIMIT = {"easy": 200000.0, "tutorial": 180000.0, "medium": 150000.0, "hard": 120000.0, "realistic": 100000.0}
# banka uzna len cast hodnoty zalohy (haircut): firma 50 %, budova/nehnutelnost 40 %, hotovost 30 %
const HAIRCUT = {"firm": 0.5, "property": 0.4, "cash": 0.3}
const UNSECURED_MAX = 30000.0
const UNSECURED_RATE_ADD = 0.04

func loan_limit() -> float:
	var base = float(START_LIMIT.get(Difficulty.mode(), 150000.0))
	var nw = maxf(0.0, GameState.net_worth())
	var rep = clampf((float(GameState.player.get("rating", 55)) - 50.0) / 50.0, -0.5, 1.0)
	var repaid = int(GameState.player.get("loans_repaid", 0))
	var lim = base + nw * 0.5 * (1.0 + rep) + float(repaid) * 25000.0
	return maxf(base * 0.5, lim - GameState.debt())

func asset_market_value(item: Dictionary) -> float:
	var kind = str(item.get("kind", ""))
	if kind == "cash":
		return float(item.get("amount", 0.0))
	var firm = GameState.firm_by_id(str(item.get("id", "")))
	if firm.is_empty() or str(firm.get("owner", "")) != "player" or firm.get("closed", false):
		return 0.0
	var ind: Dictionary = DataLoader.industries.get(str(firm.get("industry", "")), {})
	var sc = float(firm.facilities[0].get("scale", 1.0)) if firm.get("facilities", []).size() > 0 else 1.0
	return float(ind.get("cost", 0.0)) * 0.7 * sc + maxf(0.0, float(firm.get("cash", 0.0)))

func collateral_value(items: Array) -> float:
	var v = 0.0
	for it in items:
		var kind = str(it.get("kind", "firm"))
		v += asset_market_value(it) * (1.0 - float(HAIRCUT.get(kind, 0.5)))
	return v

func is_pledged(firm_id: String) -> bool:
	var firm = GameState.firm_by_id(firm_id)
	return not firm.is_empty() and str(firm.get("pledged", "")) != ""

func request_secured_loan(amount: float, years: int, items: Array) -> Dictionary:
	if items.is_empty():
		return {"ok": false, "reason": "Vyber aspoň jednu zálohu."}
	for it in items:
		if str(it.get("kind", "")) != "cash":
			var f = GameState.firm_by_id(str(it.get("id", "")))
			if f.is_empty() or str(f.get("owner", "")) != "player":
				return {"ok": false, "reason": "Záloha nie je tvoja."}
			if str(f.get("pledged", "")) != "":
				return {"ok": false, "reason": "%s je už založená." % str(f.get("name", ""))}
		elif float(it.get("amount", 0.0)) > float(GameState.player.cash) + 0.01:
			return {"ok": false, "reason": "Nemáš toľko hotovosti na zálohu."}
	var cv = collateral_value(items)
	var lim = loan_limit()
	if amount > cv + 0.01:
		return {"ok": false, "reason": "Banka ocenila zálohy na %s (po zrážke). Požaduješ viac." % EconMath.eur(cv), "value": cv, "limit": lim}
	if amount > lim + 0.01:
		return {"ok": false, "reason": "Úverový limit je %s." % EconMath.eur(lim), "value": cv, "limit": lim}
	var res = _make_loan(amount, years, 0.0)
	if not bool(res.get("ok", false)):
		return res
	var loan: Dictionary = GameState.player.loans[GameState.player.loans.size() - 1]
	loan["secured"] = true
	loan["collateral"] = items.duplicate(true)
	for it in items:
		if str(it.get("kind", "")) == "cash":
			var a = float(it.get("amount", 0.0))
			GameState.player.cash = float(GameState.player.cash) - a
			loan["escrow"] = float(loan.get("escrow", 0.0)) + a
		else:
			GameState.firm_by_id(str(it.get("id", ""))).pledged = str(loan.id)
	res["value"] = cv
	res["limit"] = lim
	return res

func request_unsecured_loan(amount: float, years: int = 3) -> Dictionary:
	if amount > UNSECURED_MAX + 0.01:
		return {"ok": false, "reason": "Bez zálohy max %s." % EconMath.eur(UNSECURED_MAX)}
	for l in GameState.player.get("loans", []):
		if bool(l.get("unsecured", false)) and float(l.get("remaining", 0.0)) > 1.0:
			return {"ok": false, "reason": "Nezabezpečený úver už máš."}
	var res = _make_loan(amount, years, UNSECURED_RATE_ADD)
	if bool(res.get("ok", false)):
		GameState.player.loans[GameState.player.loans.size() - 1]["unsecured"] = true
	return res

# spolocne jadro: rovnaka sadzba ako request_loan + prirazka, bez starej "cap" (limit riesi volajuci)
func _make_loan(amount: float, years: int, rate_add: float) -> Dictionary:
	if amount <= 0.0:
		return {"ok": false, "reason": "Zlá suma."}
	update_rates()
	var iso = str(GameState.player.get("home", ""))
	var score = float(GameState.player.get("credit_score", 55.0))
	var rating = float(GameState.world[iso].get("stability", 50.0))
	var premium = risk_premium_for(score, rating)
	var base = float(GameState.central[iso].get("base_rate", 0.02))
	var rate = max(0.001, base + premium + rate_add + Difficulty.rate_add() + PoliticsSystem.rate_bonus())
	var bank = {}
	for b in GameState.banks:
		if not b.get("failed", false) and str(b.get("owner", "")) != "player" and float(b.get("reserves", 0.0)) + 0.001 >= amount:
			bank = b
			break
	if bank.is_empty():
		return {"ok": false, "reason": "Banky nemajú dosť peňazí."}
	var months = max(years, 1) * 12
	var r = rate / 12.0
	var pay = amount / float(months)
	if r > 0.0000001:
		var g = pow(1.0 + r, float(months))
		pay = amount * (r * g) / (g - 1.0)
	GameState.player.cash = float(GameState.player.cash) + amount
	bank.reserves = float(bank.reserves) - amount
	bank.explicit = float(bank.get("explicit", 0.0)) + amount
	GameState.player.loans.append({"id": "L%d" % GameState.next_loan, "lender": bank.id, "principal": amount, "remaining": amount,
		"annual_rate": rate, "base_rate": base, "risk_premium": premium + rate_add, "monthly_payment": pay,
		"days_left": months * 30, "months_left": months, "missed": 0})
	GameState.next_loan += 1
	return {"ok": true, "reason": "", "rate": rate, "amount": amount, "payment": pay}

func _loan_by_id(lid: String) -> Dictionary:
	for l in GameState.player.get("loans", []):
		if str(l.get("id", "")) == lid:
			return l
	return {}

# mesacne: splatene uvery uvolnia zalohy (+ historia splacania), zabezpecene v defaulte -> banka zaberie zalohy
func collateral_monthly() -> void:
	for f in GameState.firms:
		var lid = str(f.get("pledged", ""))
		if lid == "":
			continue
		var l = _loan_by_id(lid)
		if l.is_empty() or float(l.get("remaining", 0.0)) <= 1.0:
			f.pledged = ""
	for l in GameState.player.get("loans", []):
		if bool(l.get("secured", false)) and float(l.get("remaining", 0.0)) <= 1.0 and not bool(l.get("released", false)):
			l.released = true
			GameState.player.cash = float(GameState.player.cash) + float(l.get("escrow", 0.0))
			l.escrow = 0.0
			GameState.player.loans_repaid = int(GameState.player.get("loans_repaid", 0)) + 1
			GameState.post_news("Úver %s splatený – zálohy uvoľnené." % str(l.id))
		elif bool(l.get("secured", false)) and int(l.get("missed", 0)) >= 3 and float(l.get("remaining", 0.0)) > 1.0:
			seize_collateral(l)

func seize_collateral(loan: Dictionary) -> float:
	var got = 0.0
	var esc = float(loan.get("escrow", 0.0))
	got += esc
	loan.escrow = 0.0
	for it in loan.get("collateral", []):
		if str(it.get("kind", "")) == "cash":
			continue
		var f = GameState.firm_by_id(str(it.get("id", "")))
		if f.is_empty() or str(f.get("owner", "")) != "player":
			continue
		got += asset_market_value(it) * 0.6
		f.owner = "bank:" + str(loan.get("lender", ""))
		f.closed = true
		f.pledged = ""
		GameState.post_news("Banka zabrala založený majetok: %s." % str(f.get("name", "")))
	loan.remaining = maxf(0.0, float(loan.remaining) - got)
	loan.missed = 0
	loan.released = true
	return got
