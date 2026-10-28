extends RefCounted
# Map-only pixel models; textures are loaded once per type, never generated per frame.
static var _textures: Dictionary = {}
static func texture(industry: String) -> Texture2D:
	if not _textures.has(industry):
		var path = "res://assets/map_models/%s.png" % industry
		_textures[industry] = load(path) if ResourceLoader.exists(path) else null
	return _textures[industry]

static var _images: Dictionary = {}
static func model_rect(p: Vector2, s: float) -> Rect2:
	var pixel_scale = maxf(0.5, floorf(s * 4.0 / 64.0 * 2.0) / 2.0)
	return Rect2(p - Vector2(32,62) * pixel_scale, Vector2(64,72) * pixel_scale)

static func hit(industry: String, p: Vector2, s: float, mouse: Vector2) -> bool:
	var bounds = model_rect(p,s)
	if not bounds.has_point(mouse) or texture(industry) == null: return false
	if not _images.has(industry): _images[industry] = texture(industry).get_image()
	var image: Image = _images[industry]
	var pixel = (mouse - bounds.position) / bounds.size * Vector2(64,72)
	return image.get_pixel(clampi(int(pixel.x),0,63), clampi(int(pixel.y),0,71)).a > 0.2
