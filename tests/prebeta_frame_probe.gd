extends SceneTree

const SAMPLE_FRAMES = 240
const WARMUP_FRAMES = 90
var game: Node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 5: await process_frame
	game._end_splash()
	var gs = root.get_node("GameState")
	for speed in [1, 2, 3]:
		game._on_start({"country": "SK", "year": 2024, "seed": 47, "starter": false, "tutorial": false, "dev": false})
		game._set_speed(speed)
		for i in WARMUP_FRAMES: await process_frame
		var start_day = gs.day_index
		var last = Time.get_ticks_usec()
		var samples: Array[float] = []
		for i in SAMPLE_FRAMES:
			await process_frame
			var now = Time.get_ticks_usec()
			samples.append(float(now - last) / 1000.0)
			last = now
		var elapsed = 0.0
		var slow = 0
		for ms in samples:
			elapsed += ms
			if ms > 16.67: slow += 1
		samples.sort()
		print("P47_FRAME speed=%d frames=%d days=%d mean_ms=%.3f p95_ms=%.3f p99_ms=%.3f max_ms=%.3f over_16_67=%d" % [speed, samples.size(), gs.day_index - start_day, elapsed / samples.size(), samples[int((samples.size() - 1) * 0.95)], samples[int((samples.size() - 1) * 0.99)], samples.back(), slow])
	gs.paused = true
	quit()
