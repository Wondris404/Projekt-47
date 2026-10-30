extends RefCounted
const DIR := "res://assets/ui/strategic/"
const TEXT := Color("e6dcc5")
const MUTED := Color("a8aa9e")
const GOLD := Color("d6b876")
const UP := Color("92c79b")
const DOWN := Color("e08d7b")
const AMBER := Color("ddb56a")
static var textures: Dictionary = {}

static func icon(id: String) -> Texture2D:
	if not textures.has(id): textures[id] = preload("res://scripts/ui/tex_util.gd").load_tex(DIR+id+".png")
	return textures[id]

static func frame(panel: bool = false) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = icon("panel_frame" if panel else "metric_frame")
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		box.set_texture_margin(side,8)
		box.set_content_margin(side,10 if panel else 6)
	return box

static func button(button: Button) -> void:
	button.add_theme_stylebox_override("normal",frame())
	var hover := frame()
	hover.modulate_color = Color(1.20,1.14,1.02)
	button.add_theme_stylebox_override("hover",hover)
	var pressed := frame()
	pressed.modulate_color = Color(1.35,1.16,.80)
	button.add_theme_stylebox_override("pressed",pressed)
	button.add_theme_color_override("font_color",TEXT)
	button.add_theme_color_override("font_pressed_color",TEXT)
	button.add_theme_color_override("font_hover_color",Color("fff0cc"))
	button.add_theme_color_override("font_hover_pressed_color",Color("fff0cc"))
	button.add_theme_font_size_override("font_size",13)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func badge(texture: Texture2D, background: Color = Color("343c3c"), extent: int = 28) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = Color("76674e")
	box.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel",box)
	panel.custom_minimum_size = Vector2(extent,extent)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var img := TextureRect.new()
	img.texture = texture
	img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(img)
	return panel
