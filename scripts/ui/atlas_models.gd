extends RefCounted
# Map-only pixel models; textures are loaded once per type, never generated per frame.
static var _textures: Dictionary = {}
static func texture(industry: String) -> Texture2D:
	if not _textures.has(industry):
		var path = "res://assets/map_models/%s.png" % industry
		_textures[industry] = load(path) if ResourceLoader.exists(path) else null
	return _textures[industry]
