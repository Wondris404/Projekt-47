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
	if active():
		_bind_game()

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

# ---------------------------------------------------------------------------
# p47/gfx: efekty pri hernych udalostiach (iba citanie signalov, logika hry sa nemeni)
# ---------------------------------------------------------------------------
const BURST_GOLD := Color(1.0, 0.8, 0.4)
const BURST_GREEN := Color(0.45, 0.9, 0.5)
const CRISIS_RED := Color(0.85, 0.12, 0.08)
var _fx_layer: CanvasLayer
var _done_count := -1
var _last_crisis_ms := -100000
var _last_burst_ms := {}

func _bind_game() -> void:
	_fx_layer = CanvasLayer.new()
	_fx_layer.name = "P47FxLayer"
	_fx_layer.layer = 60
	add_child(_fx_layer)
	GameState.day_passed.connect(_on_day_fx)
	GameState.news_posted.connect(_on_news_fx)
	IndustrySystem.firm_upgraded.connect(func(_id, _a, _b): burst_at(_anchor("Metric_firms"), BURST_GOLD, "upgrade"))
	IndustrySystem.dividends_paid.connect(func(total): if float(total) > 0.0: burst_at(_anchor("Metric_cash"), BURST_GOLD, "income"))

func _anchor(node_name: String) -> Vector2:
	var n = get_tree().root.find_child(node_name, true, false)
	if n is Control and n.is_visible_in_tree():
		return n.get_global_rect().get_center()
	return get_viewport().get_visible_rect().size * Vector2(0.5, 0.2)

func _on_day_fx(_day: int) -> void:
	if not GameState.running or GameState.player.is_empty():
		return
	var done = GameState.player.get("done", [])
	var n: int = done.size() if typeof(done) == TYPE_ARRAY else 0
	if _done_count >= 0 and n > _done_count:
		burst_at(get_viewport().get_visible_rect().size * Vector2(0.5, 0.5), BURST_GREEN, "research", 48)
	_done_count = n

func _on_news_fx(text: String) -> void:
	if not GameState.running:
		return
	var cat := str(GameState.news_category(text))
	if cat in ["šoky", "vojna"]:
		crisis_pulse()

# kratky "vybuch" svetielok (jednorazovy CPUParticles2D, sam sa zmaze)
func burst_at(pos: Vector2, color: Color, key: String = "", amount: int = 28) -> void:
	if not active() or _fx_layer == null:
		return
	var now := Time.get_ticks_msec()
	if key != "" and now - int(_last_burst_ms.get(key, -100000)) < 600:
		return  # pri 10x rychlosti nezahltit obrazovku
	_last_burst_ms[key] = now
	var p := CPUParticles2D.new()
	p.texture = preload("res://assets/ui/p47/spark.svg")
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = amount
	p.lifetime = 0.9
	p.position = pos
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 160)
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 220.0
	p.damping_min = 40.0
	p.damping_max = 80.0
	p.scale_amount_min = 0.15
	p.scale_amount_max = 0.45
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color, 1.0))
	ramp.set_color(1, Color(color, 0.0))
	p.color_ramp = ramp
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	_fx_layer.add_child(p)
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.3).timeout.connect(p.queue_free)

# kriza/vojna: cerveny okraj obrazovky kratko pulzne
func crisis_pulse() -> void:
	if not active() or _fx_layer == null:
		return
	var now := Time.get_ticks_msec()
	if now - _last_crisis_ms < 1500:
		return
	_last_crisis_ms = now
	var r := ColorRect.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/ui/edge_pulse.gdshader")
	m.set_shader_parameter("tint", CRISIS_RED)
	r.material = m
	r.modulate.a = 0.0
	_fx_layer.add_child(r)
	var tw := r.create_tween().set_trans(Tween.TRANS_SINE)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(r, "modulate:a", 1.0, 0.18)
	tw.tween_property(r, "modulate:a", 0.0, 0.7)
	tw.tween_callback(r.queue_free)

# animovane cislo v Label (top bar): text plynule dobehne na cielovu hodnotu + farebny zablesk
static func animate_number(label: Label, from_v: float, to_v: float, fmt: Callable, up_color: Color, down_color: Color, dur: float = 0.45) -> void:
	label.text = fmt.call(to_v)
	if not active() or not label.is_inside_tree() or is_equal_approx(from_v, to_v):
		return
	var old = label.get_meta(&"p47_num_tw", null)
	if old is Tween and old.is_valid():
		old.kill()
	var tw := label.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	label.set_meta(&"p47_num_tw", tw)
	tw.tween_method(func(v: float): label.text = fmt.call(v), from_v, to_v, dur)
	var flash := up_color if to_v > from_v else down_color
	label.self_modulate = flash.lightened(0.25)
	tw.tween_property(label, "self_modulate", Color.WHITE, dur * 1.6)
