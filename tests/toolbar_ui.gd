extends RefCounted

func run(host: Node) -> void:
	host.get_window().size = Vector2i(1000, 720)
	host._on_menu_dev()
	await host.get_tree().process_frame
	await host.get_tree().process_frame
	var scroll: ScrollContainer = host.toolbar_scroll
	var hbar = scroll.get_h_scroll_bar()
	var errors: Array[String] = []
	if hbar.max_value <= hbar.page:
		errors.append("toolbar does not overflow in the test window")
	var left: Button = host.find_child("ToolbarScrollLeft", true, false)
	var right: Button = host.find_child("ToolbarScrollRight", true, false)
	right.pressed.emit()
	await host.get_tree().process_frame
	if scroll.scroll_horizontal <= 0:
		errors.append("right arrow did not scroll")
	left.pressed.emit()
	await host.get_tree().process_frame
	if scroll.scroll_horizontal != 0:
		errors.append("left arrow did not return to start")
	var gesture = InputEventPanGesture.new()
	gesture.position = scroll.get_global_rect().get_center()
	gesture.delta = Vector2(2, 0)
	if not host._scroll_toolbar_input(gesture) or scroll.scroll_horizontal <= 0:
		errors.append("touchpad gesture did not scroll")
	var wheel = InputEventMouseButton.new()
	wheel.position = gesture.position
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	if not host._scroll_toolbar_input(wheel) or scroll.scroll_horizontal != 0:
		errors.append("wheel did not scroll back")
	for i in 20:
		right.pressed.emit()
	await host.get_tree().process_frame
	var pipe: Button = host.find_child("Build_pipe", true, false)
	if pipe == null or not scroll.get_global_rect().encloses(pipe.get_global_rect()):
		errors.append("last pipeline button is not reachable")
	await RenderingServer.frame_post_draw
	host.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://toolbar_right.png"))
	if errors.is_empty():
		print("P47_TOOLBAR_OK max=%.0f page=%.0f position=%d" % [hbar.max_value, hbar.page, scroll.scroll_horizontal])
	else:
		for error in errors:
			print("P47_TOOLBAR_FAIL ", error)
	host.get_tree().quit(0 if errors.is_empty() else 1)
