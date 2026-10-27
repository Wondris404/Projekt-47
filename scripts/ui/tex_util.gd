extends RefCounted
# JUAN7: nacitanie PNG aj ked Godot este nema import (.godot/imported chyba, napr. spustenie bez editora)
static func load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var t = load(path)
		if t is Texture2D:
			return t
	var img = Image.new()
	var err = img.load(ProjectSettings.globalize_path(path))
	if err != OK:
		return null
	return ImageTexture.create_from_image(img)
