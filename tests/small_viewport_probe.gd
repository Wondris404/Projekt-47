extends SceneTree
# Diagnostika hranice malého viewportu; nemení save ani nastavenia okien.
func _initialize() -> void:
	call_deferred("_probe")

func _probe() -> void:
	root.size = Vector2i(240, 150)
	await process_frame
	await process_frame
	print("P47_SMALL_ROOT physical=", root.size, " logical=", root.get_visible_rect().size)
	var sub := SubViewport.new()
	sub.size = Vector2i(240, 150)
	root.add_child(sub)
	var panel := PanelContainer.new()
	sub.add_child(panel)
	var manager = load("res://scripts/ui/window_drag.gd").new()
	root.add_child(manager)
	manager.persist = false
	manager.register(panel, "probe", func(): return Rect2(0, 0, 400, 300))
	manager.place("probe")
	await process_frame
	print("P47_SMALL_PANEL viewport=", sub.size, " panel=", panel.size, " fits=", panel.size.x <= sub.size.x and panel.size.y <= sub.size.y)
	quit()
