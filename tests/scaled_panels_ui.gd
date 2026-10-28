extends SceneTree
var game
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func frames(n := 4) -> void:
	for i in n: await process_frame
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(5)
	game._end_splash()
	game._on_menu_dev()
	await frames(8)
	game.win_mgr.persist = false
	game.win_mgr.rects.clear()
	var gs = root.get_node("GameState")
	gs.paused = true
	gs.player.cash = 5.0e9
	var err = gs.found_firm("cafe", "Test kaviareň", "SK")
	var firms = gs.player_firms()
	if err != "" or firms.is_empty():
		print("P47_PANEL_SETUP_FAIL ", err)
		quit(1)
		return
	for factor in [1.0, 1.25, 1.5]:
		var dims = Vector2i(1280, 720)
		root.content_scale_factor = factor
		root.size = dims
		await frames(5)
		for kind in ["country", "city", "firm", "burza", "empire"]:
			match kind:
				"country": game.open_country_firms("SK")
				"city": game.open_city_panel("SK", "Bratislava")
				"firm": game.open_firm_detail(str(firms[0].id))
				"burza": game.toggle_burza()
				"empire": game.toggle_empire()
			await frames(5)
			var panel: Control = game.win_mgr.wins[kind].panel
			var viewport = root.get_visible_rect()
			var close: Button
			for b in panel.find_children("*", "Button", true, false):
				if "✕" in str(b.text): close = b; break
			var scrollers = panel.find_children("*", "ScrollContainer", true, false)
			var scroll_ok = false
			if not scrollers.is_empty():
				var sc: ScrollContainer = scrollers[0]
				var bar = sc.get_v_scroll_bar()
				if bar.max_value > bar.page:
					sc.scroll_vertical = int(bar.max_value - bar.page)
					await frames(2)
					scroll_ok = sc.scroll_vertical > 0
					sc.scroll_vertical = 0
				else: scroll_ok = true
			var close_fits = close != null and close.is_visible_in_tree() and viewport.encloses(close.get_global_rect())
			var fits = panel.visible and viewport.encloses(panel.get_global_rect())
			await RenderingServer.frame_post_draw
			if close:
				var point = close.get_global_rect().get_center()
				for down in [true, false]:
					var event = InputEventMouseButton.new()
					event.button_index = MOUSE_BUTTON_LEFT
					event.pressed = down
					event.position = point
					event.global_position = point
					root.push_input(event, true)
					await process_frame
			print("P47_PANELS ",kind," scale=",factor," physical=",dims," viewport=",viewport.size," fits=",fits," close=",close_fits," scroll=",scroll_ok," closed=",not panel.visible)
			if not (fits and close_fits and scroll_ok and not panel.visible): failures += 1
			panel.visible = false
			await frames(3)
	quit(0 if failures == 0 else 1)

