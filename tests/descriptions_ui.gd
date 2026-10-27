extends RefCounted
const Descriptions = preload("res://scripts/business_descriptions.gd")

func run(host: Node) -> void:
	host._on_menu_dev()
	await host.get_tree().process_frame
	var errors: Array[String] = []
	var by_id := {}
	for button in host.build_menu.buttons:
		var id = str(button.get_meta("ind"))
		if by_id.has(id):
			errors.append("duplicate menu item: " + id)
		by_id[id] = button
	for id in DataLoader.industry_ids:
		if not by_id.has(id):
			errors.append("missing menu item: " + id)
			continue
		var description: String = Descriptions.describe(id)
		if description.length() < 30 or not str(by_id[id].tooltip_text).contains(description):
			errors.append("missing tooltip: " + id)
		var recipe: Dictionary = DataLoader.recipes.get(str(DataLoader.industries[id].get("recipe", "")), {})
		if not recipe.get("trade", false):
			for cid in recipe.get("inputs", {}).keys() + recipe.get("outputs", {}).keys():
				var name = str(DataLoader.commodity(str(cid)).get("name", cid)).to_lower()
				if not description.to_lower().contains(name):
					errors.append("missing commodity %s for %s" % [cid, id])
	GameState.player.cash = 1.0e9
	var err = GameState.found_firm("cafe", "", "SK")
	if err != "":
		errors.append("cannot create test firm: " + err)
	else:
		var firm: Dictionary = GameState.player_firms()[0]
		host.open_firm_detail(str(firm.id))
		if not host._detail_info.text.contains(Descriptions.describe("cafe")):
			errors.append("missing firm detail description")
		var detail_goods = host._detail_mgr.get_node_or_null("FirmGoodsIcons")
		if detail_goods == null or detail_goods.get_node_or_null("GoodIcon_coffee") == null:
			errors.append("missing firm detail commodity icon")
	var cafe_index = host.place_list().find("cafe")
	if cafe_index >= 0:
		host.place_kind.select(cafe_index)
		host.place_kind.item_selected.emit(cafe_index)
		var place_goods = host.place_kind.get_parent().get_node_or_null("PlaceGoodsIcons")
		if place_goods == null or place_goods.get_node_or_null("GoodIcon_coffee") == null:
			errors.append("missing build menu commodity icon")
		host.place_kind.select(host.place_list().find("bank"))
		host.place_kind.item_selected.emit(host.place_kind.selected)
		host._on_place_industry("cafe")
		if place_goods == null or place_goods.get_node_or_null("GoodIcon_coffee") == null:
			errors.append("missing icons after selecting from build menu")
	var bank_index = host.place_list().find("bank")
	if bank_index < 0:
		errors.append("missing bank placement option")
	else:
		host.place_kind.select(bank_index)
		host.place_kind.item_selected.emit(bank_index)
		if not host.place_kind.tooltip_text.contains("vklady"):
			errors.append("missing bank tooltip")
		var result: Dictionary = IndustrySystem.place_at("SK", "bank", host.map.capital_of("SK"))
		if not bool(result.get("ok", false)):
			errors.append("cannot create test bank: " + str(result))
		else:
			var banks: Array = BankingSystem.player_banks()
			host.open_firm_detail(str(banks[0].id))
			if not host._detail_info.text.contains(Descriptions.describe("bank")):
				errors.append("missing bank detail description")
			var advisor = host._detail_mgr.get_node_or_null("BankAdvisor")
			if advisor == null:
				errors.append("missing bank advisor button")
			else:
				advisor.pressed.emit()
				if not bool(banks[0].get("advisor", {}).get("hired", false)) or not advisor.text.contains("Prepustiť"):
					errors.append("advisor hire button failed")
				var sovereign = host._detail_mgr.get_node_or_null("SovereignLend")
				if sovereign == null:
					errors.append("missing sovereign lending button")
				else:
					host._sovereign_amount.value = 1000.0
					sovereign.pressed.emit()
					if SovereignLoans.outstanding(banks[0]) < 1000.0:
						errors.append("sovereign loan button failed")
					host._sovereign_auto.button_pressed = true
					host._detail_mgr.get_node("SovereignAdvisorLimits").pressed.emit()
					if not bool(banks[0].get("advisor", {}).get("sovereign_enabled", false)):
						errors.append("sovereign advisor limits failed")
				advisor.pressed.emit()
				if bool(banks[0].get("advisor", {}).get("hired", false)):
					errors.append("advisor fire button failed")
	if errors.is_empty():
		print("P47_DESCRIPTIONS_OK industries=%d" % DataLoader.industry_ids.size())
	else:
		for error in errors:
			print("P47_DESCRIPTIONS_FAIL ", error)
	host.get_tree().quit(0 if errors.is_empty() else 1)
