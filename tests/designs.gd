extends RefCounted
# P47 DESIGNS: kontrola systemu dizajnov. Spustenie:
#   XDG_DATA_HOME=/workspace/coding-p47/.userdata/designs godot --headless --path . -- designs_unit
# Vypisuje P47_UNIT_* riadky (rovnako ako tests/unit.gd).

func run(unit) -> void:
	var dm = DesignManager
	var start_id = dm.current_id
	var cfg_path = dm.SETTINGS
	var had_cfg = FileAccess.file_exists(cfg_path)
	var backup = FileAccess.get_file_as_string(cfg_path) if had_cfg else ""
	# vlastne testovacie nastavenia hry
	var cf = ConfigFile.new()
	cf.load(cfg_path)
	cf.set_value("ui", "scale", 1.25)
	cf.set_value("graphics", "map_style", "hoi")
	cf.set_value("test", "marker", "p47")
	cf.save(cfg_path)
	var before = _snapshot(cfg_path)
	var gs_before = JSON.stringify(GameState.game_settings)

	# 1) discovery
	var ids: Array = dm.design_ids()
	unit._chk("design_discovery_current_first", ids.size() > 0 and ids[0] == "current", str(ids))
	unit._chk("design_discovery_d01", "d01" in ids, str(ids))
	var dir = DirAccess.open("res://themes/")
	var all_ok = true
	if dir:
		for d in dir.get_directories():
			if FileAccess.file_exists("res://themes/%s/design.json" % d) and not (str(d) in ids):
				all_ok = false
				unit._chk("design_discovery_valid_%s" % d, false, "design.json je, ale dizajn je neplatny (theme.tres / JSON)")
	unit._chk("design_discovery_all_folders", all_ok, "%d dizajnov" % (ids.size() - 1))
	for id in ids:
		if id == "current":
			continue
		var s: Dictionary = dm.read_spec(id)
		unit._chk("design_spec_name_%s" % id, str(s.get("name", "")) != "", str(s.get("name", "")))
		unit._chk("design_theme_loads_%s" % id, load(str(s._theme_path)) is Theme)

	# 2) prepnutie na d01 a spat na current
	var used = dm.set_design("d01")
	unit._chk("design_switch_d01", used == "d01" and dm.current_id == "d01" and dm.load_setting() == "d01")
	unit._chk("design_theme_d01", dm.get_theme().resource_path.begins_with("res://themes/d01/"), dm.get_theme().resource_path)
	unit._chk("design_motion_d01", float(dm.motion("dur_normal", -1.0)) > 0.0)
	used = dm.set_design("current")
	unit._chk("design_switch_back_current", used == "current" and dm.load_setting() == "current")
	unit._chk("design_current_is_p47", dm.get_theme().resource_path == "res://ui/theme_p47.tres", dm.get_theme().resource_path)
	unit._chk("design_current_motion_default", dm.motion("dur_normal", -1.0) == -1.0 and dm.color("accent", Color.RED) == Color.RED)
	unit._chk("design_settings_unchanged", _snapshot(cfg_path) == before, str(_snapshot(cfg_path)))
	unit._chk("design_game_settings_unchanged", JSON.stringify(GameState.game_settings) == gs_before)

	# 3) neplatne dizajny -> current
	for bad in ["d99_neexistuje", "", "../ui", "res://ui", "current/../d01"]:
		used = dm.set_design(bad)
		unit._chk("design_invalid_fallback_%s" % bad.validate_filename(), used == "current" and dm.current_id == "current" and dm.load_setting() == "current")
	# neplatna hodnota priamo v settings.cfg -> po nacitani current
	cf = ConfigFile.new()
	cf.load(cfg_path)
	cf.set_value("ui", "design", "d77_zle")
	cf.save(cfg_path)
	unit._chk("design_invalid_setting_fallback", dm._activate(dm.load_setting()) == "current")
	unit._chk("design_settings_unchanged_after_invalid", _snapshot(cfg_path) == before)

	# 4) save hry nema dizajn (SAVE_VERSION ostava 3)
	unit._chk("design_save_version_3", int(GameState.SAVE_VERSION) == 3)
	var save_dict = GameState.to_dict() if GameState.has_method("to_dict") else {}
	unit._chk("design_not_in_save", not JSON.stringify(save_dict).contains("\"design\""))

	# upratanie
	if had_cfg:
		var f = FileAccess.open(cfg_path, FileAccess.WRITE)
		f.store_string(backup)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(cfg_path))
	dm._activate(start_id)

# Vsetky kluce settings.cfg okrem ui/design (ten je jediny, ktory DesignManager smie menit).
func _snapshot(path: String) -> Dictionary:
	var cf = ConfigFile.new()
	cf.load(path)
	var out = {}
	for sec in cf.get_sections():
		for k in cf.get_section_keys(sec):
			if sec == "ui" and k == "design":
				continue
			out["%s/%s" % [sec, k]] = cf.get_value(sec, k)
	return out
