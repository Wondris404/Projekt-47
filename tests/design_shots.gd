extends Node
# Node (nie RefCounted): pridava sa ako child hosta, aby korutina s await neskoncila uvolnenim objektu.
# P47 DESIGNS: 3 screenshoty aktivneho dizajnu (spusta tools/design_shots.sh, nie headless – treba Xvfb).
#   godot --path . -- design_shots design=dNN out=/abs/priecinok
# Vystup: 01_menu.png, 02_mapa.png, 03_burza.png; na konci vypise P47_DESIGN_SHOTS_OK.

func _arg(key: String, def: String) -> String:
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with(key + "="):
			return str(a).substr(key.length() + 1)
	return def

func _shot(host: Node, path: String, frames: int) -> void:
	for _f in frames:
		await host.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var err = host.get_viewport().get_texture().get_image().save_png(path)
	print("P47_DESIGN_SHOT %s err=%d" % [path, err])

func run(host: Node) -> void:
	var out = _arg("out", "/tmp/p47_design_shots")
	DirAccess.make_dir_recursive_absolute(out)
	print("P47_DESIGN_ACTIVE %s" % DesignManager.current_id)
	await _shot(host, out + "/01_menu.png", 90)
	host._on_menu_dev()
	await _shot(host, out + "/02_mapa.png", 60)
	host.toggle_burza()
	await _shot(host, out + "/03_burza.png", 30)
	print("P47_DESIGN_SHOTS_OK %s" % DesignManager.current_id)
	host.get_tree().quit(0)
