extends RefCounted
const Data = preload("res://scripts/ui/strategic_hud_data.gd")

func run(u) -> void:
	u._new()
	u._chk("hud_compact_money",Data.compact(50.4e6,true)=="50,4 mil. €")
	u._chk("hud_negative_money",Data.compact(-2.5e6,true)=="-2,5 mil. €")
	var trend = Data.new()
	trend.sample({"cash":100.0},0,1)
	u._chk("hud_no_invented_history",trend.delta.is_empty() and trend.trend_text("cash").contains("zatiaľ"))
	trend.sample({"cash":120.0},0,1)
	u._chk("hud_same_day_no_fake_trend",trend.delta.is_empty())
	trend.sample({"cash":150.0},1,1)
	u._chk("hud_daily_difference",is_equal_approx(trend.delta.cash,30.0) and trend.interval==1)
	trend.sample({"cash":900.0},1,2)
	u._chk("hud_load_clears_trend",trend.delta.is_empty() and trend.interval==0)
	var ids := {}
	var unique := true
	for group in Data.GROUPS.values():
		for id in group:
			if ids.has(id): unique=false
			ids[id]=true
	u._chk("hud_complete_commodity_groups",unique and ids.size()==DataLoader.commodities.size() and DataLoader.commodities.keys().all(func(id):return ids.has(id)))
	var power := Data.power({"electricity":{"produced":240.0,"consumed":120.0,"demand":480.0}},true)
	u._chk("hud_mwh_to_mw",power.made==10.0 and power.used==5.0 and power.need==20.0 and power.ratio==.5)
	var warn := Data.power({"electricity":{"produced":95.0,"demand":100.0}},true)
	var good := Data.power({"electricity":{"produced":100.0,"demand":100.0}},true)
	u._chk("hud_power_thresholds",power.state=="deficit" and warn.state=="warning" and good.state=="ok")
	u._chk("hud_power_no_false_surplus",Data.power({},false).state=="unknown" and Data.power({},true).state=="idle")
	GameState.firms = [{"id":"both","owner":"player","facilities":[{"recipe":"power_coal","inventory":{"coal":5.0}},{"recipe":"steel_mill","inventory":{"coal":7.0}}]}, {"id":"closed","owner":"player","closed":true,"facilities":[{"recipe":"power_coal"}]},{"id":"npc","owner":"ai","facilities":[{"recipe":"power_coal"}]}]
	var roles := Data.roles("electricity")
	u._chk("hud_roles_all_facilities",roles.size()==1 and roles.get("both",0)==3)
	var before := JSON.stringify(GameState.to_dict())
	var rng = GameState.rng.state
	var resources := Data.resources()
	u._chk("hud_stock_read_only",resources.rows.coal.stock==12.0 and resources.rows.coal.price==MarketSystem.price(GameState.selected_iso,"coal") and before==JSON.stringify(GameState.to_dict()) and rng==GameState.rng.state)
	u._new()
	GameState.firms.clear()
	GameState.config.progression = false
	GameState.player.cash = 1e10
	var cafe_error = GameState.found_firm("cafe","HUD kaviareň","SK")
	var service_error = GameState.found_firm("hospital","HUD nemocnica","SK")
	GameState.simulate_day()
	resources = Data.resources()
	var cafe: Dictionary = GameState.player_firms()[0]
	var flows: Array = cafe.get("goods_flow",[])
	var recorded := float(flows[-1].outputs.get("food_service|SK",{}).get("produced",0)) if not flows.is_empty() else 0.0
	u._chk("hud_actual_daily_production",cafe_error=="" and service_error=="" and resources.known and recorded>0 and is_equal_approx(resources.rows.food_service.produced,recorded))
	var batches: float = recorded/(58.0*IndustrySystem._yield_mult(cafe,"cafe"))
	u._chk("hud_consumption_includes_services",is_equal_approx(resources.rows.coffee.consumed,batches*.004) and is_equal_approx(resources.rows.electricity.consumed,batches*.12+1.5))
	var last_complete: Dictionary = IndustrySystem.hud_resources.duplicate(true)
	IndustrySystem.settle_start()
	u._chk("hud_partial_day_keeps_completed",Data.resources().known and IndustrySystem.hud_resources==last_complete)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	var error = GameState.from_dict(saved)
	u._chk("hud_v3_load_unknown_flows",error=="" and saved.v==3 and not saved.has("hud_resources") and not Data.resources().known)
