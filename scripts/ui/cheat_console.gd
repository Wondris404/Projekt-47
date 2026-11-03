extends Control
# Cheat konzola (nahrádza Dev mód). Otvára sa 3× Ctrl+C počas hry.

var main: Node
var output: RichTextLabel
var line: LineEdit
var history: Array = []
var hist_idx := 0

const HELP := """Príkazy:
  help — tento zoznam
  money <x> — pridá x € (napr. money 1000000, money 5m, money 2b)
  research all — dokončí všetok výskum
  unlock all — odomkne všetko (burza, priemysel bez progresie, šedé odvetvia, ciele)
  dev — ako starý Dev mód: unlock all + výskum + 50 M €
  skip <n> — preskočí n dní (predvolene 30), vypíše ms/deň
  event — recesia + pád burzy vo vybranej krajine
  war [ISO] — vojna vybranej/zadanej krajiny so susedom
  errors — log chýb
  fps — FPS a stav hry
  clear — vyčistí výstup
  close — zatvorí konzolu (aj Esc)"""

func setup(m: Node) -> void:
	main = m
	name = "CheatConsole"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # blokuje kliky do hry
	z_index = 60
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var pc = PanelContainer.new()
	pc.position = Vector2(20, 80)
	pc.custom_minimum_size = Vector2(560, 340)
	add_child(pc)
	var vb = VBoxContainer.new()
	pc.add_child(vb)
	var title = Label.new()
	title.text = "Cheat konzola — napíš help (Esc zatvorí)"
	vb.add_child(title)
	output = RichTextLabel.new()
	output.name = "CheatOutput"
	output.scroll_following = true
	output.selection_enabled = true
	output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output.custom_minimum_size = Vector2(540, 270)
	vb.add_child(output)
	line = LineEdit.new()
	line.name = "CheatInput"
	line.placeholder_text = "príkaz…"
	line.text_submitted.connect(_on_submit)
	line.gui_input.connect(_on_line_input)
	vb.add_child(line)
	visible = false

func open() -> void:
	visible = true
	line.clear()
	line.grab_focus()
	if output.get_parsed_text() == "":
		print_line("Napíš help pre zoznam príkazov.")

func close() -> void:
	visible = false
	line.release_focus()

func print_line(t: String) -> void:
	output.append_text(t.replace("[", "[lb]") + "\n")

func _on_line_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed:
		return
	var k = ev as InputEventKey
	if k.keycode == KEY_ESCAPE:
		close()
		accept_event()
	elif k.keycode == KEY_UP and history.size() > 0:
		hist_idx = maxi(0, hist_idx - 1)
		line.text = history[hist_idx]
		line.caret_column = line.text.length()
		accept_event()
	elif k.keycode == KEY_DOWN and history.size() > 0:
		hist_idx = mini(history.size(), hist_idx + 1)
		line.text = history[hist_idx] if hist_idx < history.size() else ""
		line.caret_column = line.text.length()
		accept_event()

func _on_submit(t: String) -> void:
	line.clear()
	t = t.strip_edges()
	if t == "":
		return
	history.append(t)
	hist_idx = history.size()
	print_line("> " + t)
	print_line(run(t))
	if visible:
		line.grab_focus()

static func parse_amount(s: String) -> float:
	s = s.strip_edges().to_lower().replace(" ", "").replace(",", ".")
	var mul := 1.0
	if s.ends_with("k"): mul = 1.0e3
	elif s.ends_with("m"): mul = 1.0e6
	elif s.ends_with("b") or s.ends_with("mld"): mul = 1.0e9
	s = s.trim_suffix("mld").trim_suffix("k").trim_suffix("m").trim_suffix("b")
	if not s.is_valid_float():
		return NAN
	return s.to_float() * mul

func run(cmd: String) -> String:
	var p: PackedStringArray = cmd.strip_edges().split(" ", false)
	if p.is_empty():
		return ""
	var c = p[0].to_lower()
	var arg = " ".join(p.slice(1)).to_lower()
	if c == "help" or c == "?":
		return HELP
	if c == "clear":
		output.clear()
		return ""
	if c == "close" or c == "exit":
		close()
		return ""
	if not GameState.running:
		return "Najprv spusti hru."
	var out := ""
	match c:
		"money":
			var x = parse_amount(arg)
			if is_nan(x):
				return "Použitie: money <x>  (napr. money 1000000 alebo money 5m)"
			GameState.player.cash = float(GameState.player.cash) + x
			out = "Pridané %s €. Hotovosť: %s €." % [String.num(x, 0), String.num(float(GameState.player.cash), 0)]
		"research":
			if arg != "all":
				return "Použitie: research all"
			out = "Dokončený výskum: %d položiek." % main._cheat_research_all()
		"unlock":
			if arg != "all":
				return "Použitie: unlock all"
			main._cheat_unlock_all()
			out = "Všetko odomknuté (burza, priemysel, šedé odvetvia, ciele)."
		"dev":
			main._apply_dev()
			out = "Dev efekty zapnuté: všetko odomknuté, výskum hotový, +50 M €."
		"skip":
			var n = int(arg) if arg.is_valid_int() else 30
			n = clampi(n, 1, 3650)
			var t0 = Time.get_ticks_msec()
			for i in n:
				GameState.simulate_day()
			out = "Preskočené %d dní (%.1f ms/deň)." % [n, float(Time.get_ticks_msec() - t0) / float(n)]
		"event":
			main._dev_event()
			out = "Udalosť: recesia + pád burzy."
		"war":
			var prev = GameState.selected_iso
			if arg != "":
				GameState.selected_iso = arg.to_upper()
			main._dev_war()
			GameState.selected_iso = prev
			out = "Vojna spustená."
		"errors":
			return main._dev_error_text()
		"fps":
			return "FPS %d, deň %d" % [Engine.get_frames_per_second(), int(GameState.day_index)]
		_:
			return "Neznámy príkaz „%s“. Napíš help." % c
	main._refresh_label()
	return out
