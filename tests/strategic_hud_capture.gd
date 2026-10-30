extends RefCounted
const OUT := "res://docs/strategic-hud/"
const Data = preload("res://scripts/ui/strategic_hud_data.gd")
var host: Node
var checks: Array = []
var failures := 0
var timings: Dictionary = {}

func frames(n: int = 5) -> void:
	for i in n: await host.get_tree().process_frame

func check(id: String, ok: bool) -> void:
	checks.append({"check":id,"ok":ok})
	if not ok: failures += 1
	print("P47_HUD_UI_", "OK " if ok else "FAIL ",id)

func shot(name: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	host.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+name+".png"))

func mouse(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = point
	event.global_position = point
	host.get_viewport().push_input(event,true)
	await frames(2)

func click(point: Vector2) -> void:
	await mouse(point,true)
	await mouse(point,false)

func drag(from: Vector2, to: Vector2) -> void:
	await mouse(from,true)
	var motion := InputEventMouseMotion.new()
	motion.position = to
	motion.global_position = to
	motion.relative = to-from
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	host.get_viewport().push_input(motion,true)
	await frames(4)
	await mouse(to,false)
	await frames(4)

func run(main: Node) -> void:
	host = main
	host._on_menu_dev()
	GameState.paused = true
	GameState.config.progression = false
	GameState.firms.clear()
	GameState.banks.clear()
	GameState.player.cash = 1.0e10
	for kind in ["power_coal","steel_mill","chip_fab","cafe","wheat_farm","oil_refinery"]:
		var error = GameState.found_firm(kind,"Ukážka · "+kind,"SK")
		if error != "": push_error(error)
	GameState.player.cash = 50.4e6
	GameState.player.loans = [{"remaining":2.5e6,"escrow":0.0,"principal":2.5e6,"rate":0.05,"months":60}]
	if host.side_panel.visible: host.toggle_side_panel()
	await frames(8)
	host.map._camera_initialized = false
	host.map._initialize_camera_frame()
	host.map._zoom_at(host.map.size*.5,22.0/host.map._fit())
	host.map.pan += host.map.size*.5-host.map._to_screen(host.map.project(48.2,17.1))
	host.map.queue_redraw()
	host.win_mgr.persist = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var args := OS.get_cmdline_user_args()
	var tag := str(args[1]) if args.size()>1 else "after"
	host._refresh_label()
	await shot("normal_"+tag)
	if tag=="after":
		await capture_after()
	else:
		host.get_window().size = Vector2i(960,720)
		host.get_window().content_scale_factor = 1.5
		await frames(8)
		await shot("small_150_before")
	var file := FileAccess.open(OUT+"capture_"+tag+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"renderer":RenderingServer.get_video_adapter_name(),"checks":checks,"failures":failures,"timings":timings},"\t")+"\n")
	print("P47_STRATEGIC_CAPTURE_", "OK " if failures==0 else "FAIL ",tag)
	host.get_tree().quit(0 if failures==0 else 1)

func capture_after() -> void:
	var bar = host.speed_bar
	var drawer = host.resource_drawer
	var viewport: Rect2 = host.get_viewport_rect()
	check("bar_fits",viewport.encloses(bar.get_global_rect()))
	var readable := true
	for card in bar.cards.values():
		readable = readable and viewport.encloses(card.panel.get_global_rect()) and card.value.size.x>=card.value.get_minimum_size().x
	check("all_metrics_readable",readable)
	check("clock_right",bar.clock_box.get_global_rect().get_center().x>viewport.size.x*.7)
	GameState.simulate_day()
	GameState.simulate_day()
	host._refresh_label()
	check("tooltip_sources_and_trend",bar.cards.worth.panel.tooltip_text.contains("firemná hotovosť") and bar.cards.worth.panel.tooltip_text.contains("Zmena za 1 deň"))
	await shot("normal_live")
	var hover := InputEventMouseMotion.new()
	hover.position = bar.cards.worth.panel.get_global_rect().get_center()
	hover.global_position = hover.position
	host.get_viewport().push_input(hover,true)
	await host.get_tree().create_timer(.8).timeout
	await shot("metric_tooltip")
	hover = InputEventMouseMotion.new()
	hover.position = host.map.get_global_rect().get_center()
	hover.global_position = hover.position
	host.get_viewport().push_input(hover,true)
	await click(bar.speed_buttons[2].get_global_rect().get_center())
	check("speed_control",GameState.speed_index==2 and not GameState.paused)
	await click(bar.pause_button.get_global_rect().get_center())
	check("pause_control",GameState.paused and bar.pause_button.button_pressed)
	var old_day: int = GameState.day_index
	for b in bar.find_children("*","Button",true,false):
		if b.text=="+1 deň": await click(b.get_global_rect().get_center())
	check("advance_one_day",GameState.day_index==old_day+1)
	await click(bar.resources_button.get_global_rect().get_center())
	await host.get_tree().create_timer(.4).timeout
	check("drawer_animation",drawer.visible and is_equal_approx(drawer.modulate.a,1.0) and viewport.encloses(drawer.get_global_rect()))
	check("resource_values",drawer.last_snapshot.known and drawer.row_controls.electricity.fields.produced.text!="—" and drawer.energy_label.text.contains("MW"))
	var start := Time.get_ticks_usec()
	for i in 30:
		bar.refresh()
		drawer.refresh()
	timings["hud_refresh_mean_ms_6_firms_30_calls"] = float(Time.get_ticks_usec()-start)/30000.0
	await shot("resources_after")
	await click(drawer.row_controls.electricity.button.get_global_rect().get_center())
	check("map_resource_highlight",host.map.resource_focus=="electricity" and host.map.resource_roles==Data.roles("electricity"))
	await click(drawer.pin.get_global_rect().get_center())
	await click(bar.cards.cash.panel.get_global_rect().get_center())
	await host.get_tree().create_timer(.2).timeout
	check("pinned_stays_open",drawer.visible and drawer.pin.button_pressed)
	var original_size: Vector2 = drawer.size
	var corner: Vector2 = drawer.position+drawer.size-Vector2(3,3)
	await drag(corner,corner-Vector2(220,70))
	check("drawer_resize",drawer.size.x<original_size.x-100 and drawer.size.y<original_size.y-20)
	var origin: Vector2 = drawer.position
	await drag(origin+Vector2(70,18),Vector2(770,200))
	check("drawer_drag",drawer.position.distance_to(origin)>100 and viewport.encloses(drawer.get_global_rect()))
	await shot("pinned_highlight")
	drawer.groups["Výrobky"].button.button_pressed = true
	await frames()
	drawer.scroll.scroll_vertical = 100000
	await frames()
	check("all_resources_reachable",drawer.scroll.scroll_vertical>0 and drawer.scroll.get_global_rect().encloses(drawer.row_controls.ai_services.button.get_global_rect()))
	await shot("products_scrolled")
	drawer.scroll.scroll_vertical = 0
	host.get_window().size = Vector2i(960,720)
	host.get_window().content_scale_factor = 1.5
	await frames(12)
	viewport = host.get_viewport_rect()
	readable = viewport.encloses(bar.get_global_rect()) and viewport.encloses(bar.resources_button.get_global_rect())
	for card in bar.cards.values(): readable = readable and viewport.encloses(card.panel.get_global_rect())
	check("small_150_bar_fits",readable)
	check("small_150_panel_fits",viewport.encloses(drawer.get_global_rect()) and drawer.row_controls.coal.grid.columns==3 and viewport.encloses(drawer.pin.get_global_rect()))
	await shot("small_150_panel")
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	host.get_viewport().push_input(esc,true)
	await host.get_tree().create_timer(.25).timeout
	check("escape_closes_and_clears",not drawer.visible and host.map.resource_focus=="")
	await shot("small_150_after")
	drawer.pin.button_pressed = false
	drawer.toggle()
	await host.get_tree().create_timer(.4).timeout
	await click(bar.cards.cash.panel.get_global_rect().get_center())
	await host.get_tree().create_timer(.25).timeout
	check("unpinned_outside_closes",not drawer.visible)
