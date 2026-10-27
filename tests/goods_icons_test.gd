extends RefCounted

const Icons = preload("res://scripts/ui/goods_icons.gd")

func run(u) -> void:
	u._new()
	var missing := []
	var sizes := []
	for cid in DataLoader.commodity_ids:
		var icon = Icons.icon(str(cid))
		if icon == null:
			missing.append(cid)
		elif icon.get_width() != 32 or icon.get_height() != 32:
			sizes.append(cid)
	u._chk("goods_icons_complete", missing.is_empty(), str(missing))
	u._chk("goods_icons_size", sizes.is_empty(), str(sizes))
	u._chk("goods_icons_cache", Icons.icon("wheat") == Icons.icon("wheat"))
	u._chk("goods_icons_unknown", Icons.icon("neexistuje") == null)
	var row = HFlowContainer.new()
	Icons.fill(row, "cafe")
	var item = row.get_node_or_null("GoodIcon_coffee")
	u._chk("goods_icons_inputs", item != null and str(item.tooltip_text).contains("Káva"))
	u._chk("goods_icons_outputs", row.get_node_or_null("GoodIcon_food_service") != null)
	Icons.fill(row, "bank")
	u._chk("goods_icons_no_recipe", row.get_child_count() == 0)
	row.free()
