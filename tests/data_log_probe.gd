extends SceneTree
# Run with isolated APPDATA/HOME; this intentionally appends to user://data_warnings.log.
func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var project_file := "res://docs/DATA.md"
	var before := FileAccess.get_sha256(project_file) if FileAccess.file_exists(project_file) else "absent"
	var marker := "P47_LOG_PROBE_" + str(Time.get_ticks_usec())
	var loader = root.get_node("DataLoader")
	loader._log_data(marker + "_a")
	loader._log_data(marker + "_b")
	var after := FileAccess.get_sha256(project_file) if FileAccess.file_exists(project_file) else "absent"
	var path := "user://data_warnings.log"
	var output := FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	var unchanged := before == after
	var appended := output.contains(marker + "_a") and output.contains(marker + "_b")
	print("P47_DATA_LOG_CHECK unchanged=", unchanged, " append=", appended)
	quit(0 if unchanged and appended else 1)
