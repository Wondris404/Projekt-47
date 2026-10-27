extends HBoxContainer

signal pause_pressed
signal speed_pressed(index: int)
signal day_pressed

var date_label: Label
var cash_label: Label
var debt_label: Label
var credit_label: Label
var speed_buttons: Dictionary = {}
var pause_button: Button

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	date_label = _metric("01.01.2024", 110)
	cash_label = _metric("0 €", 140)
	debt_label = _metric("Dlh 0 €", 120)
	var sep = VSeparator.new()
	add_child(sep)
	pause_button = Button.new()
	pause_button.text = "Pauza"
	pause_button.tooltip_text = "Medzerník"
	pause_button.pressed.connect(func(): pause_pressed.emit())
	add_child(pause_button)
	var group = ButtonGroup.new()
	_speed_button("1x", 1, "1.2 dní/s", group)
	_speed_button("4x", 2, "6 dní/s", group)
	_speed_button("10x", 3, "24 dní/s", group)
	var day_b = Button.new()
	day_b.text = "+1 deň"
	day_b.pressed.connect(func(): day_pressed.emit())
	add_child(day_b)
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(8, 0)
	add_child(spacer)
	credit_label = Label.new()
	credit_label.text = "Projekt-47 — Wondris404"
	credit_label.custom_minimum_size = Vector2(48, 0)
	credit_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	credit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	credit_label.add_theme_color_override("font_color", UiPalette.TEXT_DIM)
	credit_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	credit_label.tooltip_text = credit_label.text
	add_child(credit_label)
	mark_speed(1)

func _metric(text: String, width: int) -> Label:
	var label = Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 0)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.tooltip_text = text
	add_child(label)
	return label

func _speed_button(title: String, index: int, tip: String, group: ButtonGroup) -> void:
	var button = Button.new()
	button.text = title
	button.toggle_mode = true
	button.button_group = group
	button.tooltip_text = tip
	button.pressed.connect(func(): speed_pressed.emit(index))
	add_child(button)
	speed_buttons[index] = button

func mark_speed(index: int) -> void:
	for key in speed_buttons.keys():
		var button: Button = speed_buttons[key]
		button.set_pressed_no_signal(int(key) == index)

func set_cash(amount: float) -> void:
	cash_label.text = EconMath.eur(amount)
	cash_label.tooltip_text = cash_label.text
	var col = UiPalette.OK if amount >= 0.0 else UiPalette.BAD.lightened(0.15)
	cash_label.add_theme_color_override("font_color", col)

func set_debt(text: String) -> void:
	debt_label.text = text
	debt_label.tooltip_text = text
