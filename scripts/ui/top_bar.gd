extends VBoxContainer

signal pause_pressed
signal speed_pressed(index: int)
signal day_pressed
signal resources_pressed
const Chrome = preload("res://scripts/ui/strategic_skin.gd")
const Data = preload("res://scripts/ui/strategic_hud_data.gd")
const METRICS := [["cash","Peniaze","money",true],["debt","Dlh","debt",true],["worth","Majetok","money",true],["employees","Ľudia","employees",false],["influence","Vplyv","influence",false],["popularity","Popularita","popularity",false],["security","Bezpečnosť","res://assets/icons/pmc_unit.png",false],["firms","Firmy","res://assets/icons/hq.png",false],["states","Štáty","states",false]]
var date_label: Label
var cash_label: Label
var debt_label: Label
var credit_label: Label
var speed_buttons: Dictionary = {}
var pause_button: Button
var resources_button: Button
var cards: Dictionary = {}
var trends = Data.new()
var first: BoxContainer
var finance: HFlowContainer
var clock_box: VBoxContainer
var clock_status: Label

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_theme_constant_override("separation",4)
	first = BoxContainer.new()
	first.add_theme_constant_override("separation",8)
	add_child(first)
	finance = HFlowContainer.new()
	finance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finance.add_theme_constant_override("h_separation",4)
	finance.add_theme_constant_override("v_separation",4)
	first.add_child(finance)
	for spec in METRICS.slice(0,2): _metric(finance,spec,154)
	cash_label = cards.cash.value
	debt_label = cards.debt.value
	clock_box = VBoxContainer.new()
	clock_box.size_flags_horizontal = Control.SIZE_SHRINK_END
	first.add_child(clock_box)
	var date_row := HBoxContainer.new()
	date_row.alignment = BoxContainer.ALIGNMENT_END
	clock_box.add_child(date_row)
	date_row.add_child(Chrome.badge(Chrome.icon("clock"),Color("283435"),22))
	date_label = Label.new()
	date_label.text = "01.01.2024"
	date_label.add_theme_font_size_override("font_size",15)
	date_row.add_child(date_label)
	clock_status = Label.new()
	clock_status.add_theme_font_size_override("font_size",11)
	clock_status.add_theme_color_override("font_color",Chrome.GOLD)
	date_row.add_child(clock_status)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation",3)
	controls.alignment = BoxContainer.ALIGNMENT_END
	clock_box.add_child(controls)
	pause_button = _clock_button(controls,"pause","Pauza / pokračovať · Medzerník")
	pause_button.toggle_mode = true
	pause_button.pressed.connect(func(): pause_pressed.emit(); sync_clock())
	var group := ButtonGroup.new()
	for i in [1,2,3]:
		var title: String = ["1x","4x","10x"][i-1]
		var b := _clock_button(controls,"speed_"+title,"Rýchlosť %s · %s herných dní/s" % [title,["1,2","6","24"][i-1]])
		b.toggle_mode = true
		b.button_group = group
		b.pressed.connect(func(): speed_pressed.emit(i); sync_clock())
		speed_buttons[i] = b
	var day_button := preload("res://scripts/ui/hud_button.gd").new()
	day_button.text = "+1 deň"
	day_button.tooltip_text = "Uzavrieť jeden herný deň"
	Chrome.button(day_button)
	day_button.pressed.connect(func(): day_pressed.emit(); sync_clock())
	controls.add_child(day_button)
	var other := HFlowContainer.new()
	other.add_theme_constant_override("h_separation",4)
	other.add_theme_constant_override("v_separation",4)
	add_child(other)
	for spec in METRICS.slice(2): _metric(other,spec,132 if spec[0]=="worth" else 94)
	resources_button = preload("res://scripts/ui/hud_button.gd").new()
	resources_button.text = "Suroviny a energia"
	resources_button.icon = preload("res://scripts/ui/goods_icons.gd").icon("electricity")
	resources_button.expand_icon = true
	resources_button.add_theme_constant_override("icon_max_width",22)
	resources_button.custom_minimum_size = Vector2(162,48)
	resources_button.toggle_mode = true
	resources_button.tooltip_text = "Výroba, spotreba, sklady a elektrická bilancia tvojich firiem"
	Chrome.button(resources_button)
	resources_button.pressed.connect(func(): resources_pressed.emit())
	other.add_child(resources_button)
	credit_label = Label.new() # Kept for existing integrations; title is in the window caption.
	credit_label.visible = false
	add_child(credit_label)
	resized.connect(_layout)
	GameState.day_passed.connect(_on_day)
	_layout()

func _clock_button(parent: Container, icon_id: String, tip: String) -> Button:
	var b := preload("res://scripts/ui/hud_button.gd").new()
	b.icon = Chrome.icon(icon_id)
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width",24)
	b.custom_minimum_size = Vector2(34,32)
	b.tooltip_text = tip
	Chrome.button(b)
	parent.add_child(b)
	return b

func _metric(parent: Container, spec: Array, width: int) -> void:
	var panel := preload("res://scripts/ui/hud_metric.gd").new()
	panel.name = "Metric_"+spec[0]
	panel.add_theme_stylebox_override("panel",Chrome.frame())
	panel.custom_minimum_size = Vector2(width,48)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation",5)
	panel.add_child(row)
	var texture: Texture2D = preload("res://scripts/ui/tex_util.gd").load_tex(spec[2]) if str(spec[2]).begins_with("res://") else Chrome.icon(spec[2])
	row.add_child(Chrome.badge(texture,Color("2b3233"),28))
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_theme_constant_override("separation",0)
	row.add_child(texts)
	var title := Label.new()
	title.text = spec[1]
	title.add_theme_font_size_override("font_size",10)
	title.add_theme_color_override("font_color",Chrome.MUTED)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(title)
	var value := Label.new()
	value.text = "—"
	value.add_theme_font_size_override("font_size",16 if spec[0] in ["cash","debt"] else 13)
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(value)
	var arrow := Label.new()
	arrow.text = "·"
	arrow.add_theme_font_size_override("font_size",12)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(arrow)
	cards[spec[0]] = {"panel":panel,"value":value,"arrow":arrow,"money":spec[3],"title":spec[1]}

func _layout() -> void:
	if first == null: return
	first.vertical = size.x<540
	clock_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL if first.vertical else Control.SIZE_SHRINK_END

func _on_day(_day: int) -> void:
	# Keep exact daily samples; render the text at the host's throttled UI refresh.
	if GameState.running: trends.sample(Data.values(),GameState.day_index,GameState.state_revision)

func refresh() -> void:
	if not GameState.running: return
	trends.sample(Data.values(),GameState.day_index,GameState.state_revision)
	for key in cards:
		var card: Dictionary = cards[key]
		var value := float(trends.current.get(key,0))
		card.value.text = Data.compact(value,card.money)
		var change := float(trends.delta.get(key,0))
		var col := Chrome.TEXT
		if trends.delta.has(key) and not is_zero_approx(change):
			col = Chrome.UP if (change>0) != (key=="debt") else Chrome.DOWN
		card.arrow.text = ("↑" if change>0 else ("↓" if change<0 else "→")) if trends.delta.has(key) else "·"
		card.arrow.add_theme_color_override("font_color",col)
		card.value.add_theme_color_override("font_color",Chrome.DOWN if key=="cash" and value<0 else col)
		card.panel.tooltip_text = card.title+"\n"+Data.sources(key)+"\n\n"+trends.trend_text(key,card.money)
	sync_clock()

func sync_clock() -> void:
	date_label.text = EconMath.date_sk(int(GameState.date.y),int(GameState.date.m),int(GameState.date.d))
	date_label.tooltip_text = "Herný dátum · čas plynie iba pri spustenej simulácii"
	clock_status.text = "PAUZA" if GameState.paused else "BEŽÍ"
	pause_button.set_pressed_no_signal(GameState.paused)
	mark_speed(GameState.speed_index)

func mark_speed(index: int) -> void:
	for key in speed_buttons: speed_buttons[key].set_pressed_no_signal(int(key)==index and not GameState.paused)

func set_cash(_amount: float) -> void:
	refresh()

func set_debt(_text: String) -> void:
	pass # Updated together with all other metrics, from the numeric source.
