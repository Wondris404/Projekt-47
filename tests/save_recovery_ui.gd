extends RefCounted
# GUI overenie, že hra oznámi načítanie zo staršej záložnej kópie.
func run(host) -> void:
	host._on_menu_dev()
	for i in 3:
		await host.get_tree().process_frame
	var previous_dir = SaveSystem.base_dir
	SaveSystem.base_dir = "user://audit_recovery_ui_%d" % Time.get_ticks_usec()
	var original_cash = float(GameState.player.cash)
	var path = SaveSystem.save_slot(1)
	GameState.player.cash = original_cash + 12345.0
	var saved = SaveSystem.save_slot(1)
	var moved = DirAccess.rename_absolute(path, path + ".held") == OK
	host._on_menu_load(1)
	for i in 4:
		await host.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var args = OS.get_cmdline_user_args()
	if args.size() > 1:
		var shot_dir = "res://audit/screenshots/save-audit"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(shot_dir))
		host.get_viewport().get_texture().get_image().save_png(shot_dir.path_join("recovery_%s.png" % str(args[1]).validate_filename()))
	var loaded = saved == path and moved and is_equal_approx(float(GameState.player.cash), original_cash)
	var informed = host.feedback_label != null and host.feedback_label.text.contains("záložnej kópie")
	print("P47_RECOVERY_%s loaded" % ["OK" if loaded else "FAIL"])
	print("P47_RECOVERY_%s informed" % ["OK" if informed else "FAIL"])
	SaveSystem.base_dir = previous_dir
	host.get_tree().quit(0 if loaded and informed else 1)
