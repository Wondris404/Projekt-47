extends PanelContainer

func set_breakdown(parts: Array) -> void:
	tooltip_text = P47Mechanics.breakdown_text(parts)

func _make_custom_tooltip(text: String) -> Object:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = minf(380,get_viewport_rect().size.x-32)
	label.add_theme_font_size_override("font_size",13)
	return label
