extends RefCounted

const Descriptions = preload("res://scripts/business_descriptions.gd")
const BuildMenu = preload("res://scripts/ui/build_menu.gd")

func run(u) -> void:
	var missing_summary: Array[String] = []
	var missing_goods: Array[String] = []
	var missing_menu: Array[String] = []
	var listed := {}
	for group in BuildMenu.GROUPS.values():
		for id in group:
			listed[str(id)] = true
	for id in DataLoader.industry_ids:
		var description = Descriptions.describe(id)
		if not Descriptions.SUMMARY.has(id) or description.length() < 30:
			missing_summary.append(id)
		if not listed.has(id):
			missing_menu.append(id)
		var recipe: Dictionary = DataLoader.recipes.get(str(DataLoader.industries[id].get("recipe", "")), {})
		if recipe.is_empty():
			missing_goods.append(id + ":recipe")
		elif not recipe.get("trade", false):
			for cid in recipe.get("inputs", {}).keys() + recipe.get("outputs", {}).keys():
				var name = str(DataLoader.commodity(str(cid)).get("name", cid)).to_lower()
				if not description.to_lower().contains(name):
					missing_goods.append(id + ":" + str(cid))
	u._chk("descriptions_all_industries", missing_summary.is_empty(), str(missing_summary))
	u._chk("descriptions_match_recipes", missing_goods.is_empty(), str(missing_goods))
	u._chk("descriptions_build_menu_coverage", missing_menu.is_empty(), str(missing_menu))
	u._chk("description_bank", Descriptions.describe("bank").contains("vklady") and Descriptions.describe("bank").contains("úvery"))
