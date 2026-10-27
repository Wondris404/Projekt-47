extends RefCounted

const TexUtil = preload("res://scripts/ui/tex_util.gd")
static var _cache := {}

static func icon(cid: String) -> Texture2D:
	if not _cache.has(cid):
		var path = "res://assets/goods_icons/%s.png" % cid
		_cache[cid] = TexUtil.load_tex(path) if FileAccess.file_exists(path) else null
	return _cache[cid]

static func fill(parent: Container, industry: String) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
	var ind: Dictionary = DataLoader.industries.get(industry, {})
	var recipe: Dictionary = DataLoader.recipes.get(str(ind.get("recipe", "")), {})
	for group in [["Vstupy", "inputs"], ["Výstupy", "outputs"]]:
		var goods: Dictionary = recipe.get(group[1], {})
		if goods.is_empty():
			continue
		var label = Label.new()
		label.text = "%s:" % group[0]
		parent.add_child(label)
		for cid in goods:
			var texture = icon(str(cid))
			if texture == null:
				continue
			var item = TextureRect.new()
			item.name = "GoodIcon_" + str(cid)
			item.texture = texture
			item.custom_minimum_size = Vector2(24, 24)
			item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			item.mouse_filter = Control.MOUSE_FILTER_PASS
			var commodity: Dictionary = DataLoader.commodity(str(cid))
			item.tooltip_text = "%s: %s (%s)" % [group[0], str(commodity.get("name", cid)), str(commodity.get("unit", ""))]
			parent.add_child(item)
