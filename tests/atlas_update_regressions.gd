extends RefCounted
const Traffic = preload("res://scripts/ui/atlas_traffic.gd")
func run(u, host: Node) -> void:
	var detached = WorldMap.new()
	detached._ready() # Existing compatibility tests initialize maps outside the tree.
	u._chk("camera_detached_initialization", detached.shapes.size() == 165)
	detached.free()
	u._new()
	u._chk("traffic_idle", Traffic.train_count(0.0) == 0)
	u._chk("traffic_density", Traffic.train_count(0.15) < Traffic.train_count(1.0))
	u._chk("traffic_cap", Traffic.train_count(10000.0) == 4)
	u._chk("traffic_partial_train_has_empty_wagons", Traffic.wagon_load(0.5,0,3) == 1.0 and Traffic.wagon_load(0.5,1,3) == 0.5 and Traffic.wagon_load(0.5,2,3) == 0.0)
	u._chk("traffic_full_train", Traffic.wagon_load(1.0,2,3) == 1.0)
	var r = Rect2(0,0,100,100)
	u._chk("traffic_offscreen", Traffic.clipped(Vector2(-10,-10), Vector2(-20,120), r).is_empty())
	var clipped = Traffic.clipped(Vector2(-100000,50), Vector2(100000,50), r)
	u._chk("traffic_extreme_zoom_clip", clipped.size() == 2 and clipped[0].distance_to(Vector2(0,50)) < 0.01 and clipped[1].distance_to(Vector2(100,50)) < 0.01)
	u._chk("traffic_zero_segment", Traffic.clipped(Vector2(50,50), Vector2(50,50), r).size() == 2)
	var models_ok = true
	for id in DataLoader.industry_ids + ["bank"]:
		var texture = preload("res://scripts/ui/atlas_models.gd").texture(str(id))
		models_ok = models_ok and texture != null and texture.get_size() == Vector2(64,72)
	u._chk("all_catalog_map_models", models_ok)
	var firm = u._juan3_firm()
	u._chk("baseline_full_efficiency", is_equal_approx(IndustrySystem.firm_efficiency(firm), 1.0))
	u._chk("baseline_full_purchase", IndustrySystem.buy_share(firm) == 1.0)
	firm.workers = 1.0
	IndustrySystem.close_month(2024,1)
	u._chk("baseline_replenishes_workers", is_equal_approx(float(firm.workers), IndustrySystem.target_workers(firm)))
	IndustrySystem.hire_manager(str(firm.id), {"name":"Pôvodný manažér", "skill":0.8, "salary":3000.0})
	var original = firm.manager.duplicate(true)
	var saved = GameState.to_dict()
	u._chk("manager_v3_roundtrip", GameState.from_dict(saved) == "" and GameState.player_firms()[0].manager == original)
	firm = GameState.player_firms()[0]
	u._chk("manager_original_bonus", is_equal_approx(IndustrySystem.firm_efficiency(firm), 1.14))
	firm.manager.skill = 0.0
	u._chk("manager_never_penalizes", IndustrySystem.firm_efficiency(firm) >= 1.0)
	IndustrySystem.fire_manager(str(firm.id))
	u._chk("firing_restores_baseline", not IndustrySystem.has_manager(firm) and is_equal_approx(IndustrySystem.firm_efficiency(firm), 1.0))
	var old = GameState.to_dict()
	for f in old.firms: f.erase("manager")
	u._chk("v3_missing_manager_loads", GameState.from_dict(old) == "")
	GameState.simulate_day()
	u._chk("v3_missing_manager_runs", is_finite(float(GameState.player_firms()[0].cash)))
	# Smooth cursor anchoring across a parent layout change.
	var map = WorldMap.new()
	host.add_child(map)
	map.size = Vector2(800,600)
	map._initialize_camera_frame()
	map._zoom_target = 30.0
	map._zoom_anchor = Vector2(300,200)
	var anchor = map.get_global_transform() * map._zoom_anchor
	var point = map._to_world(map._zoom_anchor)
	map.position = Vector2(100,0)
	map._preserve_camera_layout()
	map._process(0.016)
	u._chk("camera_smooth_layout_anchor", (map.get_global_transform() * map._to_screen(point)).distance_to(anchor) < 0.01)
	map.atlas = true
	map._zoom_at(Vector2(400,300),60.0)
	firm = GameState.player_firms()[0]
	firm.industry = "nuclear_plant"
	var ground = Vector2(400,300)
	var wp = map._to_world(ground)
	firm.pos = [wp.x,wp.y]
	map._ms_f = -1
	var model_size = clampf(map._fit() * map.zoom * 0.55,5.0,22.0)
	var models = preload("res://scripts/ui/atlas_models.gd")
	var bounds = models.model_rect(ground,model_size)
	var image = models.texture("nuclear_plant").get_image()
	var roof = Vector2.ZERO
	for y in range(30):
		for x in range(64):
			if image.get_pixel(x,y).a > 0.9:
				roof = bounds.position + (Vector2(x,y) + Vector2(0.5,0.5)) / Vector2(64,72) * bounds.size
				break
		if roof != Vector2.ZERO: break
	u._chk("camera_click_visible_roof", roof.distance_to(ground) > map.icon_px() * 0.6 + 2.0 and map.firm_at_screen(roof) == str(firm.id), "roof=%s ground=%s selected=%s expected=%s zoom=%s sites=%s" % [roof,ground,map.firm_at_screen(roof),firm.id,map.zoom,map._my_sites()])
	u._chk("camera_model_transparency", not models.hit("nuclear_plant",ground,model_size,bounds.position + Vector2(0.1,0.1)))
	map.free()
