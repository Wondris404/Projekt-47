extends SceneTree

const WARMUP = 45
const FRAMES = 180

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 5: await process_frame
	game._end_splash()
	var gs = root.get_node("GameState")
	for mode in ["atlas", "3d"]:
		for speed in [1, 2, 3]:
			if game._prototype_3d != null: game._toggle_3d_prototype()
			game._on_start({"country": "SK", "year": 2024, "seed": 47, "starter": false, "tutorial": false, "dev": false})
			gs.config.progression = false
			gs.player.cash = 5.0e10
			var count = 0
			for iso in ["SK", "CZ", "DE", "PL", "AT", "FR", "IT", "US", "CN", "GB", "ES", "JP"]:
				for kind in ["cafe", "coal_mine", "steel_mill", "power_coal"]:
					if gs.found_firm(kind, "Meranie %d" % count, iso) == "": count += 1
			game.set_map_style("hoi")
			game.acc = 0.0
			game._set_speed(speed)
			var open_ms = 0.0
			if mode == "3d":
				var start = Time.get_ticks_usec()
				game._toggle_3d_prototype()
				open_ms = float(Time.get_ticks_usec() - start) / 1000.0
			for i in WARMUP: await process_frame
			var day_start = gs.day_index
			var last = Time.get_ticks_usec()
			var samples: Array[float] = []
			for i in FRAMES:
				await process_frame
				var now = Time.get_ticks_usec()
				samples.append(float(now - last) / 1000.0)
				last = now
			var total = 0.0
			for ms in samples: total += ms
			samples.sort()
			print("P47_3D_PROFILE mode=%s speed=%d firms=%d days=%d open_ms=%.2f mean_ms=%.2f p95_ms=%.2f p99_ms=%.2f max_ms=%.2f" % [mode, speed, count, gs.day_index - day_start, open_ms, total / samples.size(), samples[int((samples.size() - 1) * 0.95)], samples[int((samples.size() - 1) * 0.99)], samples.back()])
	gs.paused = true
	quit()
