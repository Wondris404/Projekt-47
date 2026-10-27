extends Node

# Individual state loans are optional bank fields, so older v3 saves remain valid.
func risk(iso: String) -> float:
	var c: Dictionary = GameState.world.get(iso, {})
	if c.is_empty():
		return 1.0
	var debt = maxf(0.0, float(c.get("debt_gdp", 0.5)))
	var stability = clampf(float(c.get("stability", 50.0)), 0.0, 100.0)
	return clampf(maxf(0.0, debt - 0.4) * 0.24 + (100.0 - stability) / 100.0 * 0.45 + float(c.get("political_risk", 0.1)) * 0.25, 0.0, 1.0)

func suggested_rate(iso: String) -> float:
	var policy = float(GameState.central.get(iso, {}).get("policy", 0.03))
	return clampf(policy + 0.025 + risk(iso) * 0.12, 0.01, 0.4)

func outstanding(bank: Dictionary) -> float:
	var total = 0.0
	for loan in bank.get("sovereign_loans", []):
		total += maxf(0.0, float(loan.get("remaining", 0.0)))
	return total

func lend(bank: Dictionary, iso: String, amount: float, annual_rate: float, months: int) -> String:
	if bank.is_empty() or str(bank.get("owner", "")) != "player" or bool(bank.get("failed", false)):
		return "Banka nie je dostupná."
	if not GameState.world.has(iso):
		return "Neznáma krajina."
	if EconMath.is_bad(amount) or EconMath.is_bad(annual_rate) or amount < 1000.0 or months < 1 or months > 120:
		return "Neplatná suma, sadzba alebo splatnosť."
	if annual_rate < suggested_rate(iso) or annual_rate > 0.4:
		return "Sadzba nezodpovedá riziku krajiny."
	var country: Dictionary = GameState.world[iso]
	var gdp = float(country.get("gdp_usd", 0.0)) / maxf(GameState.usd_per_eur, 0.2)
	if gdp <= 0.0 or float(country.get("debt_gdp", 0.0)) + amount / gdp > 3.5:
		return "Štát má príliš veľký dlh vzhľadom na ekonomiku."
	BankProducts.ensure(bank)
	var liabilities = float(bank.get("deposits", 0.0)) + float(bank.get("savings", 0.0))
	var minimum = liabilities * maxf(float(bank.get("reserve_target", 0.1)), LawSystem.min_reserve(str(bank.get("country", ""))))
	if amount > maxf(0.0, float(bank.get("reserves", 0.0)) - minimum):
		return "Banka nemá dostatočné voľné rezervy."
	var capital_room = maxf(0.0, float(bank.get("equity", 0.0)) / BankProducts.MIN_CAR - BankProducts.rwa(bank))
	if amount > capital_room:
		return "Úver by prekročil kapitálový limit banky."
	bank.reserves = float(bank.reserves) - amount
	var loans: Array = bank.get("sovereign_loans", [])
	loans.append({"country": iso, "principal": amount, "remaining": amount, "rate": annual_rate, "months": months, "started": GameState.day_index})
	bank["sovereign_loans"] = loans
	country.debt_gdp = float(country.get("debt_gdp", 0.0)) + amount / gdp
	country.budget = float(country.get("budget", 0.0)) + amount
	return ""

func monthly(bank: Dictionary, test_roll: float = -1.0) -> Dictionary:
	var keep: Array = []
	var total_interest = 0.0
	var total_loss = 0.0
	for loan in bank.get("sovereign_loans", []):
		var iso = str(loan.get("country", ""))
		var country: Dictionary = GameState.world.get(iso, {})
		if country.is_empty():
			keep.append(loan)
			continue
		var remaining = maxf(0.0, float(loan.get("remaining", 0.0)))
		var term = maxi(1, int(loan.get("months", 1)))
		var gdp = maxf(float(country.get("gdp_usd", 0.0)) / maxf(GameState.usd_per_eur, 0.2), 1.0)
		var chance = 0.00002 + pow(risk(iso), 2.0) * 0.004
		var roll = test_roll if test_roll >= 0.0 else GameState.rng.randf()
		if roll < chance:
			var loss = remaining * 0.5
			var recovered = remaining - loss
			bank.reserves = float(bank.reserves) + recovered
			bank.equity = float(bank.equity) - loss
			bank.defaults_total = float(bank.get("defaults_total", 0.0)) + loss
			country.debt_gdp = maxf(0.0, float(country.get("debt_gdp", 0.0)) - remaining / gdp)
			country.budget = float(country.get("budget", 0.0)) - recovered
			total_loss += loss
			BankingSystem._advisor_log(bank, "%s nesplatilo celý štátny úver; strata %s." % [str(country.get("name_sk", iso)), EconMath.eur(loss)])
			continue
		var interest = remaining * float(loan.get("rate", 0.0)) / 12.0
		var principal = minf(remaining, remaining / float(term))
		bank.reserves = float(bank.reserves) + principal + interest
		bank.equity = float(bank.equity) + interest
		country.budget = float(country.get("budget", 0.0)) - principal - interest
		country.debt_gdp = maxf(0.0, float(country.get("debt_gdp", 0.0)) - principal / gdp)
		total_interest += interest
		loan.remaining = remaining - principal
		loan.months = term - 1
		if int(loan.months) > 0 and float(loan.remaining) > 0.000001:
			keep.append(loan)
	bank["sovereign_loans"] = keep
	return {"interest": total_interest, "loss": total_loss}

func advisor_invest(bank: Dictionary) -> void:
	var advisor: Dictionary = bank.get("advisor", {})
	if not bool(advisor.get("hired", false)) or not bool(advisor.get("sovereign_enabled", false)):
		return
	if GameState.day_index < int(advisor.get("override_until", 0)):
		return
	var iso = str(advisor.get("sovereign_country", bank.get("country", "")))
	var max_risk = clampf(float(advisor.get("sovereign_max_risk", 0.35)), 0.0, 1.0)
	if not GameState.world.has(iso) or risk(iso) > max_risk:
		BankingSystem._advisor_log(bank, "Štátny úver odmietnutý: krajina alebo riziko prekračuje limit.")
		return
	var limit = clampf(float(advisor.get("sovereign_limit", 0.1)), 0.0, 0.5)
	var cap = maxf(0.0, float(bank.get("equity", 0.0)) * limit - outstanding(bank))
	var liabilities = float(bank.get("deposits", 0.0)) + float(bank.get("savings", 0.0))
	var free = maxf(0.0, float(bank.get("reserves", 0.0)) - liabilities * float(bank.get("reserve_target", 0.1)))
	var amount = minf(cap, free * 0.25)
	if amount < 1000.0:
		return
	var years = clampi(int(advisor.get("sovereign_months", 36)), 1, 120)
	var result = lend(bank, iso, amount, suggested_rate(iso), years)
	if result == "":
		BankingSystem._advisor_log(bank, "Štátny úver %s: %s, sadzba %s, splatnosť %d mesiacov." % [str(GameState.world[iso].get("name_sk", iso)), EconMath.eur(amount), EconMath.pct(suggested_rate(iso)), years])
	else:
		BankingSystem._advisor_log(bank, "Štátny úver odmietnutý: " + result)
