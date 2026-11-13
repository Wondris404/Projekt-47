extends Control

signal new_game_requested(cfg: Dictionary)
signal continue_requested
signal load_requested(slot: int)
signal save_requested(slot: int)  # JUAN-FIX
signal quit_requested
signal back_requested
signal tutorial_repeat_requested
signal scale_selected(index: int)

var home: Control
var new_panel: Control
var load_panel: Control
var settings_panel: Control
var continue_button: Button
var back_button: Button
var country_list: ItemList
var seed_box: SpinBox
var tutorial_box: CheckBox
var starter_box: CheckBox
var dlc_box: CheckBox
var dlc_pass: LineEdit
var dlc_money: SpinBox
var dlc_error: Label
var load_note: Label
var save_button: Button
var load_buttons: Array = []
var menu_note: Label
var mode_id = "medium"  # JUAN4
var mode_label: Label
var nick_box: LineEdit
var gender_box: OptionButton
const GENDERS = ["muž", "žena", "iné"]
# p47/gfx: ikony tlacidiel menu (assets/ui/p47, vlastne CC0)
const MENU_ICONS = {"Pokračovať": "icon_continue", "Nová hra": "icon_new", "Uložiť hru": "icon_save", "Načítať hru": "icon_load",
	"Nastavenia": "icon_settings", "Koniec": "icon_quit", "Späť do hry": "icon_play", "Späť": "icon_back", "Štart": "icon_play",
	"Zopakovať tutoriál": "icon_tutorial"}
var particles: CPUParticles2D
var parallax: Control

# JUAN5: celoobrazovkove menu v pixel style intra (jachta + skyline), mapa a herne UI su skryte (main._set_game_visible)
signal dev_requested
var bg_tex: TextureRect
var shade: ColorRect
var logo: Label
var modes_panel: Control
var dev_button: Button
var _t = 0.0
var center_panel: PanelContainer
var logo_img: TextureRect
var scroll: ScrollContainer
var stack_ref: VBoxContainer
var new_buttons: HBoxContainer
var sub_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 50
	var bg = ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg_tex = TextureRect.new()
	bg_tex.name = "MenuBackground"
	var img_path = "res://assets/ui/menu_bg.png"
	if true:
		bg_tex.texture = preload("res://scripts/ui/tex_util.gd").load_tex(img_path)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_tex.modulate = Color(0.85, 0.85, 0.9)
	add_child(bg_tex)
	parallax = preload("res://scripts/ui/menu_parallax.gd").new()  # p47/gfx (kolo 2): parallax vrstvy + svetla
	add_child(parallax)
	shade = ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.05, 0.25)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_add_particles()  # p47/gfx: jemne svetielka nad mestom
	visibility_changed.connect(_on_vis_fx)  # p47/gfx: prechody menu <-> hra
	var root = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 14)
	add_child(root)
	var lg = TextureRect.new()
	lg.name = "LogoImage"
	lg.texture = preload("res://scripts/ui/tex_util.gd").load_tex("res://assets/ui/logo.png")
	lg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lg.custom_minimum_size = Vector2(0, 220)
	root.add_child(lg)
	logo_img = lg
	logo = Label.new()
	logo.name = "Logo"
	logo.text = "PROJEKT-47"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25))
	logo.add_theme_color_override("font_outline_color", Color(0.25, 0.05, 0.1))
	logo.add_theme_constant_override("outline_size", 10)
	logo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))  # JUAN16
	logo.add_theme_constant_override("shadow_offset_x", 4)
	logo.add_theme_constant_override("shadow_offset_y", 4)
	var head_font = load("res://ui/theme_p47.tres").get_font("font", "HeaderLabel")  # p47/gfx: titulok pismom Oswald
	if head_font:
		logo.add_theme_font_override("font", head_font)
	root.add_child(logo)
	var sub = Label.new()
	sub_label = sub
	sub.text = "Staň sa najbohatším človekom na svete."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	root.add_child(sub)
	var cc = CenterContainer.new()
	root.add_child(cc)
	center_panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.045, 0.09, 0.82)  # JUAN16: pixelovy panel so stinom
	sb.border_color = Color(1.0, 0.78, 0.25, 0.85)
	sb.set_border_width_all(3)
	sb.set_content_margin_all(18)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 18  # p47/gfx: makky tien a zaoblenie namiesto tvrdeho pixeloveho
	sb.shadow_offset = Vector2(0, 8)
	sb.set_corner_radius_all(12)
	sb.anti_aliasing = true
	sb.expand_margin_left = 0
	center_panel.add_theme_stylebox_override("panel", sb)
	center_panel.custom_minimum_size = Vector2(380, 0)
	cc.add_child(center_panel)
	# JUAN7: obsah panelu v ScrollContaineri (koliesko mysi), vyska obmedzena oknom, Spat/Start vzdy viditelne
	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	center_panel.add_child(outer)
	scroll = ScrollContainer.new()
	scroll.name = "MenuScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	outer.add_child(scroll)
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(stack)
	stack_ref = stack
	new_buttons = HBoxContainer.new()
	new_buttons.name = "NewButtons"
	new_buttons.add_theme_constant_override("separation", 8)
	new_buttons.visible = false
	outer.add_child(new_buttons)
	var bb = _button(new_buttons, "Späť", func(): _show_only(modes_panel))
	bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb2 = _button(new_buttons, "Štart", _emit_new)
	sb2.name = "StartButton"
	sb2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home = _home()
	modes_panel = _modes()
	new_panel = _new_game()
	load_panel = _load_game()
	settings_panel = _settings()
	for c in [home, modes_panel, new_panel, load_panel, settings_panel]:
		stack.add_child(c)
	var credit = Label.new()
	credit.name = "Credit"
	credit.text = "wondris404"
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 0.8))
	root.add_child(credit)
	_fit()
	get_viewport().size_changed.connect(_fit)
	_show_only(home)

# prisposobenie rozliseniu: velkost loga a sirka panelu podla vysky okna
func _fit() -> void:
	var vs = get_viewport_rect().size
	var k = clampf(vs.y / 720.0, 0.6, 2.5)
	logo.add_theme_font_size_override("font_size", int(48 * k))
	logo_img.custom_minimum_size = Vector2(0, int(vs.y * (0.22 if vs.y >= 700 else 0.14)))
	sub_label.visible = vs.y >= 650
	center_panel.custom_minimum_size = Vector2(clampf(vs.x * 0.32, 320.0, 620.0), 0)

func _process(delta: float) -> void:
	if not visible or bg_tex == null:
		return
	_cap_scroll()
	_t += delta
	if logo_img:  # JUAN16: jemne "dychanie" pecate a pulz titulku
		logo_img.pivot_offset = logo_img.size * 0.5
		logo_img.scale = Vector2.ONE * (1.0 + 0.015 * sin(_t * 1.6))
		logo.modulate = Color(1, 1, 1).lerp(Color(1.25, 1.15, 0.9), 0.5 + 0.5 * sin(_t * 1.2))
	# pomaly "kamerovy" pohyb po pixelovom obrazku (bez blikania)
	var vs = get_viewport_rect().size
	bg_tex.size = vs * 1.08
	bg_tex.position = Vector2(-vs.x * 0.04 + sin(_t * 0.07) * vs.x * float(DesignManager.motion("menu_parallax", 0.035)), -vs.y * 0.04 + cos(_t * 0.05) * vs.y * float(DesignManager.motion("menu_parallax_y", 0.02)))  # P47 DESIGNS: motion
	if parallax:  # p47/gfx: najhlbsia vrstva sa hybe s mysou najmenej
		bg_tex.position += parallax.layer_offset(0.6)
		if particles:
			particles.position = Vector2(vs.x * 0.5, vs.y * 0.82) + parallax.layer_offset(2.8)

# vyska scrollu = min(obsah, volne miesto v okne); prepocita sa kazdy frame (resize okna, prepnutie panelu)
func _cap_scroll() -> void:
	if scroll == null or stack_ref == null:
		return
	var vs = get_viewport_rect().size
	var used = logo_img.custom_minimum_size.y + logo.get_combined_minimum_size().y + (sub_label.get_combined_minimum_size().y if sub_label.visible else 0.0)
	used += 40.0 + 32.0 + 14.0 * 4.0 + 40.0  # wondris404, okraje panelu, medzery, rezerva
	if new_buttons.visible:
		used += new_buttons.get_combined_minimum_size().y + 8.0
	var max_h = maxf(120.0, vs.y - used)
	var want = minf(stack_ref.get_combined_minimum_size().y, max_h)
	if absf(scroll.custom_minimum_size.y - want) > 0.5:
		scroll.custom_minimum_size = Vector2(0, want)

func _modes() -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.visible = false
	var mh = Label.new()
	mh.text = "NOVÁ HRA — vyber mód"
	mh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mh.add_theme_color_override("font_color", UiPalette.ACCENT)
	box.add_child(mh)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	for m in ["easy", "tutorial", "medium", "hard", "realistic", "story"]:
		var mb = _button(grid, "Story" if m == "story" else str(Difficulty.MODES[m].name), _pick_mode.bind(m))
		mb.name = "Mode_" + m
		mb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mb.tooltip_text = "Príbehový režim – pripravuje sa." if m == "story" else Difficulty.describe(m)
	_button(box, "Späť", func(): _show_only(home))
	return box

func show_home(game_running: bool) -> void:
	_show_only(home)
	# JUAN-FIX: Pokračovať bolo vypnuté, kým neexistoval save, a save sa nedal nikde vytvoriť.
	# Teraz: bežiaca hra -> pokračuje v nej; inak načíta posledný save.
	var can_load = SaveSystem.has_slot(1) or SaveSystem.has_slot(2) or SaveSystem.has_slot(3)
	continue_button.disabled = not (can_load or game_running)
	back_button.visible = false
	save_button.visible = game_running
	menu_note.text = ""
	menu_note.visible = false
	_refresh_load_buttons()
	visible = true
	_animate_in()

func _home() -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	continue_button = _button(box, "Pokračovať", func(): continue_requested.emit())
	continue_button.name = "Continue"
	var nb = _button(box, "Nová hra", func(): _show_only(modes_panel))
	nb.name = "NewGame"
	save_button = _button(box, "Uložiť hru", func(): save_requested.emit(1))
	save_button.visible = false
	_button(box, "Načítať hru", _open_load)
	_button(box, "Nastavenia", _open_settings)
	# Dev tlačidlo zrušené: nahradila ho cheat konzola (3× Ctrl+C počas hry)
	_button(box, "Koniec", func(): quit_requested.emit())
	back_button = _button(box, "Späť do hry", func(): back_requested.emit())
	back_button.visible = false
	menu_note = Label.new()
	menu_note.visible = false
	menu_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_note.add_theme_color_override("font_color", UiPalette.OK)
	box.add_child(menu_note)
	return box

func _new_game() -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.visible = false
	var title = Label.new()
	title.text = "Nová hra"
	title.theme_type_variation = "HeaderLabel"
	box.add_child(title)
	mode_label = Label.new()
	mode_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mode_label.add_theme_color_override("font_color", UiPalette.ACCENT)
	box.add_child(mode_label)
	nick_box = LineEdit.new()
	nick_box.placeholder_text = "Tvoja prezývka"
	nick_box.max_length = 20
	nick_box.text = "Wondris"
	box.add_child(nick_box)
	gender_box = OptionButton.new()
	for g in GENDERS:
		gender_box.add_item(g)
	gender_box.tooltip_text = "\n".join(PoliticsSystem.GENDER_TIPS.values())
	gender_box.item_selected.connect(func(i): gender_box.tooltip_text = str(PoliticsSystem.GENDER_TIPS[GENDERS[i]]))
	box.add_child(gender_box)
	country_list = ItemList.new()
	country_list.custom_minimum_size = Vector2(0, 160)
	var rows: Array = []
	for iso in DataLoader.country_ids:
		rows.append({"iso": str(iso), "name": str(DataLoader.countries[iso].get("name_sk", iso))})
	rows.sort_custom(func(a, b): return str(a.name) < str(b.name))
	var select_row = 0
	for i in rows.size():
		country_list.add_item(str(rows[i].name))
		country_list.set_item_metadata(i, str(rows[i].iso))
		if str(rows[i].iso) == "SK":
			select_row = i
	if country_list.item_count > 0:
		country_list.select(select_row)
	box.add_child(country_list)
	var year = SpinBox.new()
	year.min_value = 2024
	year.max_value = 2024
	year.value = 2024
	year.editable = false
	year.tooltip_text = "1950 čaká na dáta. Hra zatiaľ používa rok 2024."
	box.add_child(year)
	seed_box = SpinBox.new()
	seed_box.min_value = 1
	seed_box.max_value = 999999
	seed_box.value = 47
	seed_box.prefix = "Seed "
	box.add_child(seed_box)
	var cfg = ConfigFile.new()
	var finished = false
	if cfg.load("user://tutorial.cfg") == OK:
		finished = bool(cfg.get_value("tutorial", "finished", false))
	starter_box = CheckBox.new()
	starter_box.text = "Štartovací balík (pôžička a kaviareň)"
	starter_box.button_pressed = true
	box.add_child(starter_box)
	dlc_box = CheckBox.new()
	dlc_box.text = "Halloween DLC: Zombie apokalypsa"
	dlc_box.button_pressed = false
	dlc_box.toggled.connect(_on_dlc_toggled)
	box.add_child(dlc_box)
	dlc_pass = LineEdit.new()
	dlc_pass.placeholder_text = "Heslo DLC"
	dlc_pass.secret = true
	dlc_pass.visible = false
	dlc_pass.text_submitted.connect(func(_t): _try_dlc_password())
	box.add_child(dlc_pass)
	dlc_error = Label.new()
	dlc_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlc_error.visible = false
	box.add_child(dlc_error)
	dlc_money = SpinBox.new()
	dlc_money.min_value = 10000
	dlc_money.max_value = 1000000000
	dlc_money.step = 10000
	dlc_money.value = 150000
	dlc_money.prefix = "Štart "
	dlc_money.tooltip_text = "Štartovné peniaze (€). Predvolená suma je ako v normálnej hre."
	dlc_money.visible = false
	box.add_child(dlc_money)
	return box

func _load_game() -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.visible = false
	var title = Label.new()
	title.text = "Načítať"
	title.theme_type_variation = "HeaderLabel"
	box.add_child(title)
	load_note = Label.new()
	load_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(load_note)
	for slot in [1, 2, 3]:
		var caption = "Slot %d" % slot
		if not SaveSystem.has_slot(slot):
			caption += " (prázdny)"
		var button = _button(box, caption, _emit_load.bind(slot))
		button.disabled = not SaveSystem.has_slot(slot)
		load_buttons.append(button)
	_button(box, "Späť", func(): _show_only(home))
	return box

func _settings() -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.visible = false
	var title = Label.new()
	title.text = "Nastavenia"
	title.theme_type_variation = "HeaderLabel"
	box.add_child(title)
	var scale = OptionButton.new()
	scale.add_item("Mierka 1.0")
	scale.add_item("Mierka 1.25")
	scale.add_item("Mierka 1.5")
	scale.item_selected.connect(func(index): scale_selected.emit(index))
	box.add_child(scale)
	var gq = OptionButton.new()  # JUAN23
	gq.name = "GfxQuality"
	gq.add_item("Grafika: automaticky")
	gq.add_item("Grafika: vysoká")
	gq.add_item("Grafika: nízka (slabší notebook)")
	gq.select(["auto", "high", "low"].find(preload("res://scripts/gfx.gd").setting()))
	gq.tooltip_text = "Nízka: bez animácií mapy, pobrežných plytčín a stožiarov vedení. Automaticky = nízka na integrovanej grafike."
	gq.item_selected.connect(func(i): preload("res://scripts/gfx.gd").set_setting(["auto", "high", "low"][i]))
	box.add_child(gq)
	box.add_child(DesignManager.make_picker())  # P47 DESIGNS
	_button(box, "Zopakovať tutoriál", func(): tutorial_repeat_requested.emit())
	_button(box, "Späť", func(): _show_only(home))
	return box

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 40)
	_menu_style(button)  # JUAN16
	if MENU_ICONS.has(text):  # p47/gfx: vlastne SVG ikony
		button.icon = load("res://assets/ui/p47/%s.svg" % MENU_ICONS[text])
		button.expand_icon = false
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _show_only(which: Control) -> void:
	home.visible = which == home
	modes_panel.visible = which == modes_panel
	if new_buttons:
		new_buttons.visible = which == new_panel
	if scroll:
		scroll.scroll_vertical = 0
	new_panel.visible = which == new_panel
	load_panel.visible = which == load_panel
	settings_panel.visible = which == settings_panel
	if visible and which != null:
		preload("res://scripts/ui/ui_fx.gd").fade_in(which, DesignManager.dur("menu_page_fade", 0.18))  # p47/gfx

func _open_new() -> void:
	_pick_mode("medium")

func _refresh_load_buttons() -> void:
	for i in load_buttons.size():
		var slot = i + 1
		var b: Button = load_buttons[i]
		b.text = "Slot %d%s" % [slot, "" if SaveSystem.has_slot(slot) else " (prázdny)"]
		b.disabled = not SaveSystem.has_slot(slot)

func show_note(text: String) -> void:
	menu_note.text = text
	menu_note.visible = text != ""

func _open_load() -> void:
	_refresh_load_buttons()
	load_note.text = ""
	_show_only(load_panel)

func _open_settings() -> void:
	_show_only(settings_panel)

func _pick_mode(m: String) -> void:
	if m == "story":
		show_note("Na tomto sa pracuje — wondris404")
		_show_only(home)
		return
	mode_id = m
	mode_label.text = Difficulty.describe(m) + ("\nTutoriál ťa prevedie 10 krokmi." if m == "tutorial" else "")
	starter_box.button_pressed = m != "tutorial"
	if dlc_money:
		dlc_money.value = Difficulty.start_cash(m)
	_show_only(new_panel)

func _on_dlc_toggled(on: bool) -> void:
	dlc_error.visible = false
	dlc_error.text = ""
	if not on:
		dlc_pass.visible = false
		dlc_money.visible = false
		return
	if ZombieSystem.unlocked():
		dlc_pass.visible = false
		dlc_money.visible = true
	else:
		dlc_pass.visible = true
		dlc_pass.text = ""
		dlc_money.visible = false

func _try_dlc_password() -> bool:
	if ZombieSystem.password_ok(dlc_pass.text):
		ZombieSystem.set_unlocked()
		dlc_pass.visible = false
		dlc_money.visible = true
		dlc_error.visible = false
		return true
	dlc_box.button_pressed = false
	dlc_pass.visible = false
	dlc_money.visible = false
	dlc_error.visible = true
	dlc_error.text = "Nesprávne heslo"
	dlc_error.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	return false

func _emit_new() -> void:
	var iso = "SK"
	var selected = country_list.get_selected_items()
	if selected.size() > 0:
		iso = str(country_list.get_item_metadata(selected[0]))
	var zombie_on = dlc_box != null and dlc_box.button_pressed
	if zombie_on and not ZombieSystem.unlocked():
		if not _try_dlc_password():
			return
	new_game_requested.emit({
		"country": iso,
		"year": 2024,
		"seed": int(seed_box.value),
		"starter": starter_box.button_pressed,
		"tutorial": mode_id == "tutorial",
		"mode": mode_id,
		"nick": nick_box.text.strip_edges() if nick_box.text.strip_edges() != "" else "Hráč",
		"gender": GENDERS[maxi(gender_box.selected, 0)],
		"zombie_mode": zombie_on,
		"zombie_start_money": int(dlc_money.value) if zombie_on and dlc_money else 0,
	})

func _emit_load(slot: int) -> void:
	load_requested.emit(slot)

func show_load_error(text: String) -> void:
	load_note.text = text
	_show_only(load_panel)
	visible = true

# ===================== JUAN16: vzhlad menu =====================
func _menu_style(b: Button) -> void:
	var mk = func(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
		var st = StyleBoxFlat.new()
		st.bg_color = bg
		st.border_color = border
		st.set_border_width_all(bw)
		st.border_width_left = bw + 2
		st.set_content_margin_all(8)
		st.content_margin_left = 14
		st.set_corner_radius_all(8)  # p47/gfx: zaoblene, vyhladene
		st.anti_aliasing = true
		st.shadow_color = Color(0, 0, 0, 0.35)
		st.shadow_size = 3
		st.shadow_offset = Vector2(0, 2)
		return st
	b.add_theme_stylebox_override("normal", mk.call(Color(0.1, 0.11, 0.17, 0.92), Color(0.32, 0.3, 0.42), 2))
	b.add_theme_stylebox_override("hover", mk.call(Color(0.2, 0.15, 0.08, 0.95), Color(1.0, 0.78, 0.25), 2))
	b.add_theme_stylebox_override("pressed", mk.call(Color(1.0, 0.7, 0.2, 1.0), Color(1.0, 0.9, 0.5), 2))
	b.add_theme_stylebox_override("focus", mk.call(Color(0, 0, 0, 0), Color(1.0, 0.78, 0.25, 0.6), 1))
	b.add_theme_stylebox_override("disabled", mk.call(Color(0.08, 0.08, 0.11, 0.7), Color(0.2, 0.2, 0.25), 2))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.4))
	b.add_theme_color_override("font_pressed_color", Color(0.1, 0.06, 0.02))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	b.add_theme_constant_override("outline_size", 3)
	b.add_theme_color_override("icon_normal_color", Color(1.0, 0.78, 0.25, 0.9))
	b.add_theme_color_override("icon_hover_color", Color(1.0, 0.9, 0.55))
	b.add_theme_color_override("icon_pressed_color", Color(0.1, 0.06, 0.02))
	b.add_theme_constant_override("icon_max_width", 20)
	# p47/gfx: hover feedback robi UiFx (scale + jas); text sa uz pri hover nemeni (bez skakania layoutu)

func _animate_in() -> void:
	if home == null or not is_inside_tree():
		return
	var i = 0
	for c in home.get_children():
		if c is Button and c.visible:
			c.modulate.a = 0.0
			var tw = create_tween()
			tw.tween_interval(0.05 * i)
			tw.tween_property(c, "modulate:a", 1.0, 0.25)
			i += 1

# p47/gfx: pomaly stupajuce teple svetielka (CPUParticles2D kvoli GL Compatibility), na slabom HW menej
func _add_particles() -> void:
	particles = CPUParticles2D.new()
	particles.name = "MenuParticles"
	particles.texture = load("res://assets/ui/p47/spark.svg")
	var low = preload("res://scripts/gfx.gd").low()
	particles.amount = 16 if low else 36
	particles.lifetime = 9.0
	particles.preprocess = 9.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.direction = Vector2(0, -1)
	particles.spread = 25.0
	particles.gravity = Vector2(0, -4)
	particles.initial_velocity_min = 8.0
	particles.initial_velocity_max = 22.0
	particles.scale_amount_min = 0.12
	particles.scale_amount_max = 0.38
	var ramp = Gradient.new()
	ramp.set_color(0, Color(1.0, 0.8, 0.45, 0.0))
	ramp.set_color(1, Color(1.0, 0.8, 0.45, 0.0))
	ramp.add_point(0.2, Color(1.0, 0.82, 0.5, 0.55))
	ramp.add_point(0.75, Color(1.0, 0.7, 0.35, 0.35))
	particles.color_ramp = ramp
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	particles.material = mat
	add_child(particles)
	_place_particles()
	get_viewport().size_changed.connect(_place_particles)
	visibility_changed.connect(func(): particles.emitting = visible)

func _place_particles() -> void:
	if particles == null:
		return
	var vs = get_viewport_rect().size
	particles.position = Vector2(vs.x * 0.5, vs.y * 0.82)
	particles.emission_rect_extents = Vector2(vs.x * 0.5, vs.y * 0.12)

# p47/gfx: menu sa pri otvoreni prelnie; pri odchode do hry kratka clona (fade z ciernej)
func _on_vis_fx() -> void:
	var fx = preload("res://scripts/ui/ui_fx.gd")
	if visible:
		fx.fade_in(self, DesignManager.dur("menu_fade_in", 0.25))  # P47 DESIGNS: motion
	elif get_parent() != null:
		fx.snapshot_fade(get_parent(), DesignManager.dur("menu_close", 0.38))  # p47/gfx (kolo 2): menu sa animovane "rozplynie" do hry
