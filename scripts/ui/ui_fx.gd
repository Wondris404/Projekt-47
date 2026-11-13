extends Node
# p47/gfx: globalne UI efekty (hover/klik feedback, fade prepinania zaloziek, prechod do hry).
# Pripaja sa raz v main._build_play(); v headless testoch sa nevytvara. Vsetko su kratke Tweeny (ziadny _process).

const HOVER_SCALE := 1.025
const PRESS_SCALE := 0.965
const HOVER_TIME := 0.12
const PRESS_TIME := 0.07
const TAB_FADE := 0.16
const META := &"p47_fx"

static var enabled := true

# v headless (testy) su efekty vypnute – ziadne nove uzly ani tweeny
static func active() -> bool:
	return enabled and DisplayServer.get_name() != "headless"

func _ready() -> void:
	name = "UiFx"
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	_scan(get_tree().root)

func _scan(n: Node) -> void:
	_on_node_added(n)
	for c in n.get_children():
		_scan(c)

func _on_node_added(n: Node) -> void:
	if not active() or n.has_meta(META):
		return
	if n is Button:
		n.set_meta(META, true)
		_wire_button(n)
	elif n is TabContainer:
		n.set_meta(META, true)
		n.tab_changed.connect(_on_tab_changed.bind(n))

# --- tlacidla: jemne zvacsenie + rozjasnenie pri hover, "stlacenie" pri kliku ---
func _wire_button(b: Button) -> void:
	b.mouse_entered.connect(func(): _hover(b, true))
	b.mouse_exited.connect(func(): _hover(b, false))
	b.button_down.connect(func(): _press(b, true))
	b.button_up.connect(func(): _press(b, false))
	b.resized.connect(func(): b.pivot_offset = b.size * 0.5)
	b.pivot_offset = b.size * 0.5

static func _big(b: Button) -> bool:
	# siroke tlacidla (napr. cele riadky v paneli) iba rozjasnit, nezvacsovat – nech nepretekaju
	return b.size.x > 360.0

func _tween_for(b: Button) -> Tween:
	var old = b.get_meta(&"p47_tw", null)
	if old is Tween and old.is_valid():
		old.kill()
	var tw := b.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	b.set_meta(&"p47_tw", tw)
	return tw

func _hover(b: Button, on: bool) -> void:
	if not is_instance_valid(b) or not b.is_inside_tree():
		return
	if on and b.disabled:
		return
	var tw := _tween_for(b)
	var s := HOVER_SCALE if (on and not _big(b)) else 1.0
	tw.tween_property(b, "scale", Vector2(s, s), HOVER_TIME)
	tw.tween_property(b, "self_modulate", Color(1.12, 1.1, 1.05) if on else Color.WHITE, HOVER_TIME)

func _press(b: Button, down: bool) -> void:
	if not is_instance_valid(b) or not b.is_inside_tree() or b.disabled:
		return
	var tw := _tween_for(b)
	var hover_s := 1.0 if _big(b) else HOVER_SCALE
	var s := PRESS_SCALE if down else (hover_s if b.is_hovered() else 1.0)
	if _big(b):
		s = 0.99 if down else 1.0
	tw.tween_property(b, "scale", Vector2(s, s), PRESS_TIME if down else HOVER_TIME * 1.5).set_trans(Tween.TRANS_BACK if not down else Tween.TRANS_CUBIC)

# --- zalozky: novy obsah sa jemne vynori ---
func _on_tab_changed(idx: int, tabs: TabContainer) -> void:
	var page := tabs.get_tab_control(idx)
	if page == null:
		return
	fade_in(page, TAB_FADE)

# --- verejne pomocky ---
static func fade_in(c: CanvasItem, dur: float = 0.2) -> void:
	if not active() or c == null or not c.is_inside_tree():
		return
	c.modulate.a = 0.0
	var tw := c.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(c, "modulate:a", 1.0, dur)

# okno/panel: fade + jemne "vyskocenie" zo stredu
static func pop_in(c: Control, dur: float = 0.22) -> void:
	if not active() or c == null or not c.is_inside_tree():
		return
	c.pivot_offset = c.size * 0.5
	c.modulate.a = 0.0
	c.scale = Vector2(0.94, 0.94)
	var tw := c.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(c, "scale", Vector2.ONE, dur)
	tw.tween_property(c, "modulate:a", 1.0, dur * 0.8).set_trans(Tween.TRANS_SINE)

# prechod medzi "scenami" (menu -> hra): cierna clona, ktora zmizne
static func curtain(host: Node, dur: float = 0.45, color: Color = Color(0.02, 0.025, 0.035)) -> void:
	if not active() or host == null or not host.is_inside_tree():
		return
	var c := ColorRect.new()
	c.name = "P47Curtain"
	c.color = color
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.z_index = 200
	host.add_child(c)
	var tw := c.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(c, "modulate:a", 0.0, dur)
	tw.tween_callback(c.queue_free)
