extends VBoxContainer

const DESCRIPTIONS = preload("res://scripts/business_descriptions.gd")

const GROUPS = {
	"Poľnohospodárstvo": ["cafe", "wheat_farm", "coffee_farm", "livestock"],
	"Ťažba": ["oil_well", "gas_well", "coal_mine", "iron_mine", "copper_mine"],
	"Priemysel": ["power_coal", "steel_mill", "chem_plant", "pharma_lab", "textile_mill", "electronics_plant", "auto_plant", "arms_plant", "construction_co", "oil_refinery", "gas_works"],
	"Služby": ["logistics_hub", "finance_office", "pmc_unit", "trade_desk", "cargo_port", "hospital"],
	"Školstvo": ["school_primary", "school_high", "university", "corp_academy"],  # JUAN-P47: len sukromne skoly
	"Malé podniky": ["restaurant", "bakery", "gym", "auto_service", "eshop", "real_estate"],  # JUAN5
	"Stredné podniky": ["hotel", "supermarket", "warehouse", "software", "ad_agency", "clinic"],
	"Veľké podniky": ["chip_fab", "airline", "telecom", "solar_plant", "gas_plant", "nuclear_plant", "shipyard", "aircraft_plant", "data_center", "ai_firm", "airport"],
	"Financie": ["insurance", "invest_fund", "stock_broker"],
	"Médiá": ["tv_station", "social_network", "newspaper"],
	"Šedá zóna": ["casino", "offshore"],
}
const ORDER = ["Malé podniky", "Poľnohospodárstvo", "Ťažba", "Priemysel", "Služby", "Školstvo", "Stredné podniky", "Veľké podniky", "Financie", "Médiá", "Šedá zóna"]

var host: Node
var search_box: LineEdit
var bodies: Dictionary = {}
var heads: Dictionary = {}
var buttons: Array = []

func setup(main_node: Node) -> void:
	host = main_node
	search_box = LineEdit.new()
	search_box.placeholder_text = "Hľadať…"
	search_box.text_changed.connect(_filter)
	add_child(search_box)
	var first = true
	for group_name in ORDER:
		var ids: Array = []
		for ind_id in GROUPS[group_name]:
			if DataLoader.industries.has(ind_id):
				ids.append(ind_id)
		var head = Button.new()
		head.flat = true
		head.toggle_mode = true
		head.button_pressed = first
		head.add_theme_color_override("font_color", UiPalette.ACCENT)
		head.add_theme_color_override("font_hover_color", UiPalette.ACCENT)
		head.add_theme_color_override("font_pressed_color", UiPalette.ACCENT)
		head.add_theme_color_override("font_focus_color", UiPalette.ACCENT)
		head.pressed.connect(_toggle.bind(group_name))
		add_child(head)
		heads[group_name] = head
		var body = GridContainer.new()
		body.columns = 1
		body.visible = first
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(body)
		bodies[group_name] = body
		for ind_id in ids:
			var row: Dictionary = DataLoader.industries[ind_id]
			var button = Button.new()
			button.text = str(row.get("name", ind_id))
			button.tooltip_text = "%s\nCena %s\nTrieda: %s" % [DESCRIPTIONS.describe(str(ind_id)), EconMath.eur(float(row.get("cost", 0.0))), IndustrySystem.TIER_NAMES.get(str(row.get("tier", "small")), "")]
			button.set_meta("ind", ind_id)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.clip_text = true
			button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			button.pressed.connect(host._on_place_industry.bind(ind_id))
			button.set_meta("fold", _fold(button.text))
			body.add_child(button)
			buttons.append(button)
		_retitle(group_name, ids.size())
		first = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_columns()

func _apply_columns() -> void:
	var cols = 2 if size.x >= 420.0 else 1
	for group_name in bodies.keys():
		var body: GridContainer = bodies[group_name]
		body.columns = cols

func _toggle(group_name: String) -> void:
	var body: GridContainer = bodies[group_name]
	body.visible = heads[group_name].button_pressed
	if search_box and search_box.text != "":
		_filter(search_box.text)
	else:
		_retitle(group_name, body.get_child_count())

func _retitle(group_name: String, count: int) -> void:
	var body: GridContainer = bodies[group_name]
	var mark = "▾" if body.visible else "▸"
	heads[group_name].text = "%s %s (%d)" % [mark, group_name, count]

func _filter(text: String) -> void:
	var needle = _fold(text)
	for group_name in ORDER:
		var body: GridContainer = bodies[group_name]
		var shown = 0
		for button in body.get_children():
			var show = needle == "" or str(button.get_meta("fold")).find(needle) >= 0
			button.visible = show
			if show:
				shown += 1
		if needle == "":
			body.visible = heads[group_name].button_pressed
		else:
			body.visible = shown > 0
		_retitle(group_name, shown if needle != "" else body.get_child_count())

func _fold(text: String) -> String:
	var map = {
		"á": "a", "ä": "a", "č": "c", "ď": "d", "é": "e", "í": "i", "ĺ": "l", "ľ": "l",
		"ň": "n", "ó": "o", "ô": "o", "ŕ": "r", "š": "s", "ť": "t", "ú": "u", "ý": "y", "ž": "z",
	}
	var out = ""
	for ch in text.to_lower():
		out += str(map.get(ch, ch))
	return out
