extends CanvasLayer

var host: Node
var steps: Array = []
var index: int = 0
var target: Control
var panel: PanelContainer
var label: Label
var next_button: Button
var firms0: int = 0
var debt0: float = 0.0
var paused_on_enter: bool = true
var dim: Color = Color(0.0, 0.0, 0.0, 0.55)

func _ready() -> void:
	layer = 60
	var veil = Control.new()
	veil.name = "Veil"
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.draw.connect(_draw_veil)
	add_child(veil)
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = Vector2(360, 0)
	add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(340, 0)
	box.add_child(label)
	next_button = Button.new()
	next_button.text = "Ďalej"
	next_button.focus_mode = Control.FOCUS_NONE
	next_button.pressed.connect(_next)
	box.add_child(next_button)
	_steps()
	visible = false

func _steps() -> void:
	steps = [
		{"text": "Vitaj v Projekt-47. Hra je pozastavená. Čas spustíš tlačidlom 1x alebo klávesom 1.", "button": "1x", "tab": "", "kind": "unpause"},
		{"text": "Tu vidíš dátum a hotovosť. Hotovosť klesá o mzdy a dane.", "button": "", "tab": "", "kind": "next"},
		{"text": "Pozastav hru medzerníkom alebo tlačidlom Pauza, kým sa rozhoduješ.", "button": "Pauza", "tab": "", "kind": "pause"},
		{"text": "Založ firmu v záložke Založiť. Sivé odvetvie je drahé. Vyber také, na ktoré máš.", "button": "", "tab": "Založiť", "kind": "firms"},
		{"text": "Málo peňazí? Vezmi pôžičku v záložke Pôžičky. Splátka ide každý mesiac.", "button": "Pôžička", "tab": "Pôžičky", "kind": "debt"},
		{"text": "Spusti výskum Logistika I. Zníži náklady na dopravu.", "button": "Logistika I", "tab": "Firma", "kind": "research"},
		{"text": "Klikni na krajinu na mape. Panel vpravo ukáže jej názov.", "button": "", "tab": "", "kind": "country"},
		{"text": "Tlačidlom Svet / Región priblížiš vybranú krajinu.", "button": "Svet / Región", "tab": "", "kind": "zoom"},
		{"text": "V záložke Vplyv môžeš lobovať u vlád (napr. za obchodnú zmluvu). Štát ťa nepočúva automaticky – rozhoduje podľa tvojho vplyvu. Pokračuj tlačidlom Ďalej.", "button": "", "tab": "Vplyv", "kind": "next"},
		{"text": "Hotovo. Tutoriál zopakuješ v menu pod Nastavenia.", "button": "", "tab": "", "kind": "done"},
	]

func start(root: Node) -> void:
	host = root
	index = 0
	visible = true
	_enter()

func _enter() -> void:
	if index >= steps.size():
		_finish()
		return
	var step: Dictionary = steps[index]
	paused_on_enter = GameState.paused
	var tab_name = str(step.get("tab", ""))
	if tab_name != "" and host.has_method("show_tab"):
		host.show_tab(tab_name)
	target = _find(str(step.get("button", "")))
	var kind = str(step.get("kind", ""))
	if kind == "next" and str(step.get("button", "")) == "":
		target = host.speed_bar.date_label if host.speed_bar else null
	if kind == "country":
		target = host.map
		host.tutorial_saw_country = false
	if kind == "firms":
		firms0 = GameState.player_firms().size()
		target = _find("Kaviareň")
		if target == null:
			target = _find("Poľnohospodárstvo")
	if kind == "debt":
		debt0 = GameState.debt()
	label.text = str(step.get("text", ""))
	next_button.visible = str(step.get("kind", "")) != "done"
	if str(step.get("kind", "")) == "done":
		next_button.visible = true
		next_button.text = "Zavrieť"
	else:
		next_button.text = "Ďalej"
	_place()

func _process(_delta: float) -> void:
	if not visible or index >= steps.size():
		return
	var kind = str(steps[index].get("kind", ""))
	var research = GameState.player.get("research", {})
	if typeof(research) != TYPE_DICTIONARY:
		research = {}
	if kind == "unpause" and paused_on_enter and not GameState.paused:
		_next()
	elif kind == "pause" and not paused_on_enter and GameState.paused:
		_next()
	elif kind == "firms" and GameState.player_firms().size() > firms0:
		_next()
	elif kind == "debt" and GameState.debt() > debt0 + 1.0:
		_next()
	elif kind == "research" and str(research.get("id", "")) == "logistics1":
		_next()
	elif kind == "country" and bool(host.tutorial_saw_country):
		_next()
	elif kind == "zoom" and str(GameState.view_mode) == "region":
		_next()
	_place()

func _next() -> void:
	if index >= steps.size() - 1 or str(steps[index].get("kind", "")) == "done":
		_finish()
		return
	index += 1
	_enter()

func _finish() -> void:
	visible = false
	var cfg = ConfigFile.new()
	cfg.load("user://tutorial.cfg")
	cfg.set_value("tutorial", "finished", true)
	cfg.set_value("tutorial", "done_step", steps.size())
	cfg.save("user://tutorial.cfg")

func _find(fragment: String) -> Control:
	if fragment == "" or host == null:
		return null
	return _walk(host, fragment)

func _walk(node: Node, fragment: String) -> Control:
	if node is Button and str((node as Button).text).find(fragment) >= 0:
		return node
	for child in node.get_children():
		if child == self:
			continue
		var hit = _walk(child, fragment)
		if hit != null:
			return hit
	return null

func _place() -> void:
	var veil = get_node_or_null("Veil")
	if veil:
		veil.queue_redraw()
	var view = get_viewport().get_visible_rect().size
	var bubble = Vector2(16, view.y - 170)
	if target != null and is_instance_valid(target):
		var hole = target.get_global_rect()
		if hole.size.y < 220.0:
			bubble = Vector2(hole.position.x, hole.position.y + hole.size.y + 12)
			if bubble.y + 160 > view.y:
				bubble.y = hole.position.y - 160
	bubble.x = clampf(bubble.x, 8.0, max(8.0, view.x - 380.0))
	bubble.y = clampf(bubble.y, 8.0, max(8.0, view.y - 160.0))
	panel.position = bubble

func _draw_veil() -> void:
	var veil: Control = get_node("Veil")
	var view = veil.size
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		veil.draw_rect(Rect2(Vector2.ZERO, view), dim)
		return
	var hole = target.get_global_rect().grow(6)
	hole.position -= veil.global_position
	veil.draw_rect(Rect2(0, 0, view.x, max(0.0, hole.position.y)), dim)
	veil.draw_rect(Rect2(0, hole.position.y, max(0.0, hole.position.x), hole.size.y), dim)
	veil.draw_rect(Rect2(hole.position.x + hole.size.x, hole.position.y, max(0.0, view.x - hole.position.x - hole.size.x), hole.size.y), dim)
	veil.draw_rect(Rect2(0, hole.position.y + hole.size.y, view.x, max(0.0, view.y - hole.position.y - hole.size.y)), dim)
	veil.draw_rect(hole, UiPalette.ACCENT, false, 2.0)
