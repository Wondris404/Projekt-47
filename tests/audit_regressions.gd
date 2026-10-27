extends RefCounted

func run(u) -> void:
	_trade_ledger(u)

func _trade_ledger(u) -> void:
	u._new()
	GameState.config.progression = false
	GameState.player.cash = 2.0e8
	var err = GameState.found_firm("trade_desk", "Audit obchodu", "SK")
	u._chk("audit_trade_setup", err == "", err)
	if err != "":
		return
	var firm: Dictionary = GameState.player_firms()[-1]
	var fac: Dictionary = firm.facilities[0]
	fac.src = "SK"
	fac.dst = "CZ"
	fac.cargo = "coffee"
	GameState.markets.SK.coffee.price = 100.0
	GameState.markets.CZ.coffee.price = 10000.0
	GameState.markets.SK.coffee.stock = 10000.0
	GameState.markets.CZ.coffee.last_dem = 1000.0
	GameState.markets.CZ.coffee.last_sup = 0.0
	var before = float(firm.cash)
	IndustrySystem.settle()
	var h: Dictionary = firm.history[-1]
	var trade: Dictionary = firm.goods_flow[-1].trades[0]
	u._chk("audit_trade_revenue", is_equal_approx(float(h.rev), float(trade.revenue)))
	u._chk("audit_trade_cost", is_equal_approx(float(h.cogs), float(trade.cost)))
	u._chk("audit_trade_profit_matches_cash", is_equal_approx(float(h.profit), float(firm.cash) - before))
	u._chk("audit_trade_tax", is_equal_approx(float(h.tax), IndustrySystem.tax_due("SK", float(trade.revenue) - float(trade.cost))))
