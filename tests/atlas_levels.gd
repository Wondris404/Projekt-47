extends RefCounted
const Models = preload("res://scripts/ui/atlas_models.gd")
const Visuals = preload("res://scripts/ui/atlas_upgrade_visuals.gd")

func run(u, host: Node) -> void:
	var kinds: Array = DataLoader.industry_ids + ["bank", "hq", "port", "highway"]
	var complete := true
	var hashes := {}
	for kind in kinds:
		for level in range(1, 4):
			var tex = Models.texture(str(kind), level)
			complete = complete and tex != null and tex.get_size() == Vector2(64, 72)
			if tex != null: hashes[tex.get_image().get_data().hex_encode().sha256_text()] = true
	u._chk("levels_catalog_195", complete and kinds.size() == 65)
	u._chk("levels_no_duplicate_images", hashes.size() == 195)
	u._chk("levels_safe_range", Models.texture("hq", 0) == Models.texture("hq", 1) and Models.texture("hq", 99) == Models.texture("hq", 3))
	u._chk("levels_unknown_is_null", Models.texture("missing_atlas_type", 2) == null)
	var v = Visuals.new()
	v.sync_revision(1)
	u._chk("levels_legacy_default", IndustrySystem.firm_level({}) == 1 and v.weights("a", 1) == [1.0, 0.0, 0.0])
	v.begin("a", 1, 2)
	u._chk("levels_transition_start", v.weights("a", 2) == [1.0, 0.0, 0.0])
	v.advance(Visuals.DURATION * 0.5)
	u._chk("levels_transition_middle", v.weights("a", 2) == [0.5, 0.5, 0.0])
	v.begin("a", 2, 3)
	u._chk("levels_rapid_upgrade_continuity", v.weights("a", 3) == [0.5, 0.5, 0.0])
	v.advance(Visuals.DURATION)
	u._chk("levels_transition_finishes", v.active.is_empty() and v.weights("a", 3) == [0.0, 0.0, 1.0])
	v.begin("a", 1, 2)
	v.sync_revision(2)
	u._chk("levels_new_save_clears_animation", v.active.is_empty())
	var firm = u._juan3_firm()
	GameState.config.dev = true
	firm.industry = "nuclear_plant"
	var map = WorldMap.new()
	host.add_child(map)
	map.atlas = true
	map.zoom = 60.0
	map._zoom_target = 60.0
	map.size = Vector2(800, 600)
	var screen := Vector2(400, 300)
	var wp = map._to_world(screen)
	firm.pos = [wp.x, wp.y]
	map._my_sites() # Prime the once-per-frame cache before upgrading.
	var cost = IndustrySystem.upgrade_cost(firm)
	GameState.player.cash = cost + 1000.0
	var scale_before = float(firm.facilities[0].scale)
	var rng_before = GameState.rng.state
	var err = IndustrySystem.upgrade_firm(str(firm.id))
	u._chk("levels_real_upgrade_cost_and_capacity", err == "" and firm.level == 2 and is_equal_approx(GameState.player.cash, 1000.0) and is_equal_approx(float(firm.facilities[0].scale), scale_before * IndustrySystem.UPGRADE_SCALE))
	u._chk("levels_same_frame_cache_and_signal", map._my_sites()[0].level == 2 and map._atlas_upgrades.active.has(str(firm.id)))
	map._process(0.3)
	u._chk("levels_visuals_preserve_rng", GameState.rng.state == rng_before)
	var cost3 = IndustrySystem.upgrade_cost(firm)
	GameState.player.cash = 0.0
	err = IndustrySystem.upgrade_firm(str(firm.id))
	u._chk("levels_failed_upgrade_preserves_target", err != "" and firm.level == 2 and map._atlas_upgrades.active[str(firm.id)].target == 2)
	GameState.player.cash = cost3
	IndustrySystem.upgrade_firm(str(firm.id))
	map._process(1.0)
	u._chk("levels_real_upgrade_to_three", firm.level == 3 and map._my_sites()[0].level == 3 and map._atlas_upgrades.active.is_empty())
	var cash = GameState.player.cash
	u._chk("levels_max_upgrade_unchanged", IndustrySystem.upgrade_firm(str(firm.id)) != "" and GameState.player.cash == cash)
	var save = GameState.to_dict()
	u._chk("levels_v3_roundtrip", save.v == 3 and GameState.from_dict(save) == "" and GameState.player_firms()[0].level == 3)
	for f in save.firms: f.erase("level")
	u._chk("levels_v3_missing_level", GameState.from_dict(save) == "" and IndustrySystem.firm_level(GameState.player_firms()[0]) == 1)
	# Use an added wing pixel, outside the old level silhouette, to test selection.
	var old_image = Models.texture("nuclear_plant", 1).get_image()
	var new_image = Models.texture("nuclear_plant", 3).get_image()
	var bounds = Models.model_rect(screen, 12.0)
	var wing := Vector2.ZERO
	for y in 72:
		for x in 64:
			if new_image.get_pixel(x,y).a > 0.9 and old_image.get_pixel(x,y).a < 0.1:
				wing = bounds.position + (Vector2(x,y) + Vector2(0.5,0.5)) / Vector2(64,72) * bounds.size
				break
		if wing != Vector2.ZERO: break
	u._chk("levels_added_wing_hit", wing != Vector2.ZERO and Models.hit("nuclear_plant",screen,12,wing,3) and not Models.hit("nuclear_plant",screen,12,wing,1))
	u._chk("levels_transparent_corner", not Models.hit("nuclear_plant",screen,12,bounds.position+Vector2(.01,.01),3))
	map.free()
