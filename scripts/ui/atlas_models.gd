extends RefCounted
# Map-only pixel models; textures are loaded once per type, never generated per frame.
static var _textures: Dictionary = {}
static func texture(industry: String, level: int = 1) -> Texture2D:
	var key := "%s_%d" % [industry, clampi(level, 1, 3)]
	if not _textures.has(key):
		var path := "res://assets/map_models/levels/%s.png" % key
		if not ResourceLoader.exists(path):
			path = "res://assets/map_models/%s.png" % industry
		_textures[key] = load(path) if ResourceLoader.exists(path) else null
	return _textures[key]

static var _images: Dictionary = {}
static func model_rect(p: Vector2, s: float) -> Rect2:
	var pixel_scale = maxf(0.375, floorf(s * 4.0 / 64.0 * 8.0) / 8.0)
	return Rect2(p - Vector2(32,62) * pixel_scale, Vector2(64,72) * pixel_scale)

static func draw_model(canvas: CanvasItem, industry: String, p: Vector2, s: float, level: int = 1, weights: Array = []) -> void:
	if weights.is_empty():
		weights = preload("res://scripts/ui/atlas_upgrade_visuals.gd").still(level)
	for i in 3:
		if float(weights[i]) <= 0.0:
			continue
		var tex := texture(industry, i + 1)
		if tex != null:
			canvas.draw_texture_rect(tex, model_rect(p, s), false, Color(1, 1, 1, float(weights[i])))

static func hit(industry: String, p: Vector2, s: float, mouse: Vector2, level: int = 1, weights: Array = []) -> bool:
	var bounds = model_rect(p,s)
	if not bounds.has_point(mouse): return false
	if weights.is_empty():
		weights = preload("res://scripts/ui/atlas_upgrade_visuals.gd").still(level)
	var pixel = (mouse - bounds.position) / bounds.size * Vector2(64,72)
	var alpha := 0.0
	for i in 3:
		if float(weights[i]) <= 0.0 or texture(industry, i + 1) == null: continue
		var key := "%s_%d" % [industry, i + 1]
		if not _images.has(key): _images[key] = texture(industry, i + 1).get_image()
		var image: Image = _images[key]
		alpha += image.get_pixel(clampi(int(pixel.x),0,63), clampi(int(pixel.y),0,71)).a * float(weights[i])
	return alpha > 0.2
