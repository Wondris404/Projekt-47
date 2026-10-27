extends RefCounted
# JUAN23: kvalita grafiky (user://settings.cfg [gfx] quality = "auto" | "high" | "low")
# auto = nizka na integrovanej grafike (napr. AMD Ryzen notebook), inak vysoka. Nemeni hratelnost, len kreslenie.
static var _low := -1

static func setting() -> String:
	var cfg = ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		var v = str(cfg.get_value("gfx", "quality", "auto"))
		if v in ["auto", "high", "low"]:
			return v
	return "auto"

static func set_setting(v: String) -> void:
	var cfg = ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("gfx", "quality", v)
	cfg.save("user://settings.cfg")
	_low = -1
	apply()

static func integrated() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	return RenderingServer.get_video_adapter_type() == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU or RenderingServer.get_video_adapter_name().to_lower().contains("radeon(tm) graphics") or RenderingServer.get_video_adapter_name().to_lower().contains("vega")

static func low() -> bool:
	if _low < 0:
		var s = setting()
		_low = 1 if (s == "low" or (s == "auto" and integrated())) else 0
	return _low == 1

static func apply() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_user_args().size() > 0:
		return  # testy/nahlady bez obmedzenia
	Engine.max_fps = 60  # bez zbytocneho kreslenia 200+ FPS v menu (notebook sa neprehrieva)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
