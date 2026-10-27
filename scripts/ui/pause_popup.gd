extends Control
# JUAN11 (t801u): Esc v hre -> male okno v strede nad mapou (hra pozastavena).
var host
var box: VBoxContainer
var panel: PanelContainer
var note: Label
var _was_paused = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 90
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var cc = CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
	cc.add_child(panel)
	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)
	note = Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(300, 0)
	note.visible = false
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	outer.add_child(box)
	outer.add_child(note)
	visible = false

func is_open() -> bool:
	return visible

func open() -> void:
	_was_paused = bool(GameState.paused)
	GameState.paused = true
	visible = true
	_home()

func close() -> void:
	visible = false
	GameState.paused = _was_paused
	if host and host.has_method("_refresh_label"):
		host._refresh_label()

func _clear(title: String) -> void:
	for c in box.get_children():
		c.queue_free()
	note.visible = false
	var t = Label.new()
	t.text = title
	t.theme_type_variation = "HeaderLabel"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)

func _b(text: String, cb: Callable, nm: String = "") -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 38)
	if nm != "":
		b.name = nm
	b.pressed.connect(cb)
	box.add_child(b)
	return b

func _msg(t: String, bad: bool = false) -> void:
	note.text = t
	note.visible = true
	note.add_theme_color_override("font_color", UiPalette.BAD if bad else UiPalette.TEXT)

func _home() -> void:
	_clear("PAUZA")
	_b("Pokračovať", close, "PauseContinue")
	_b("Uložiť hru", _save_dlg, "PauseSave")
	_b("Načítať hru", _load_dlg, "PauseLoad")
	_b("Nastavenia", _settings, "PauseSettings")
	_b("Ukončiť hru", _quit_dlg, "PauseQuit")

func _is_dev() -> bool:
	return bool(GameState.config.get("dev", false))

func _slot_text(slot: int) -> String:
	return "Slot %d%s" % [slot, "" if SaveSystem.has_slot(slot) else " (prázdny)"]

func _save_dlg() -> void:
	_clear("ULOŽIŤ HRU")
	for s in [1, 2, 3]:
		var slot = s
		_b(_slot_text(slot) + (" – prepísať" if SaveSystem.has_slot(slot) else ""), func():
			var ok = host.save_game(slot)
			_save_dlg()
			_msg(("Uložené do slotu %d." % slot) if ok else "Uloženie zlyhalo.", not ok), "SaveSlot%d" % slot)
	_b("Späť", _home)

func _load_dlg() -> void:
	_clear("NAČÍTAŤ HRU")
	for s in [1, 2, 3]:
		var slot = s
		var b = _b(_slot_text(slot), func(): _confirm("Načítať slot %d? Neuložený postup sa stratí." % slot, func():
			visible = false
			host._on_menu_load(slot)), "LoadSlot%d" % slot)
		b.disabled = not SaveSystem.has_slot(slot)
	_b("Späť", _home)

func _settings() -> void:
	_clear("NASTAVENIA")
	var sc = OptionButton.new()
	sc.add_item("Mierka UI 1.0")
	sc.add_item("Mierka UI 1.25")
	sc.add_item("Mierka UI 1.5")
	var f = get_window().content_scale_factor
	sc.select(0 if f < 1.1 else (1 if f < 1.4 else 2))
	sc.item_selected.connect(func(i): host._on_ui_scale(i))
	box.add_child(sc)
	var fs = CheckBox.new()
	fs.text = "Celá obrazovka"
	fs.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs.toggled.connect(func(v): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if v else DisplayServer.WINDOW_MODE_WINDOWED))
	box.add_child(fs)
	_b("Späť", _home)

func _quit_dlg() -> void:
	_clear("UKONČIŤ HRU")
	_b("Do hlavného menu", func(): _confirm("Odísť do hlavného menu? Neuložený postup sa stratí.", func():
		visible = false
		host._quit_to_menu()), "QuitMenu")
	_b("Na plochu", func(): _confirm("Ukončiť hru a odísť na plochu? Neuložený postup sa stratí.", func(): get_tree().quit()), "QuitDesktop")
	_b("Späť", _home)

func _confirm(text: String, yes: Callable) -> void:
	_clear("POTVRDIŤ")
	var l = Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(300, 0)
	box.add_child(l)
	if true:  # JUAN15: aj DEV hra sa dá uložiť
		_b("Najprv uložiť (slot 1) a pokračovať", func():
			host.save_game(1)
			yes.call(), "ConfirmSave")
	_b("Áno", yes, "ConfirmYes")
	_b("Nie", _home, "ConfirmNo")
